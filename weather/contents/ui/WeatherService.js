.pragma library

// Provider adapters return one normalized contract:
// - temperatures use the selected display unit
// - wind speeds are always km/h
// - visibility is always km
// - sunrise, sunset and hourly timestamps are epoch milliseconds
// - alert_code is a WMO-compatible code used by notification rules

var CACHE_TTL_MS = 5 * 60 * 1000
var LOCATION_CACHE_TTL_MS = 24 * 60 * 60 * 1000

var caches = {}
var activeRequests = {}
var requestSerial = 0
var geocodeCache = {}
var ipLocationCache = { city: "", timestamp: 0 }

function hasValue(value) {
    return value !== undefined && value !== null
}

function clampForecastDays(value, maximum) {
    var parsed = parseInt(value)
    if (isNaN(parsed) || parsed < 1) parsed = 5
    return Math.min(parsed, maximum)
}

function normalizedLocation(location) {
    return String(location || "").trim().toLowerCase()
}

function cacheKeyForConfig(config) {
    var provider = config.provider || "openmeteo"
    var units = config.units || "metric"
    var location = config.autoDetect ? "@auto" : normalizedLocation(config.location)
    return provider + "|" + units + "|" + location + "|days=" + clampForecastDays(config.forecastDays, 16)
}

function copyConfig(config) {
    return {
        apiKey: config.apiKey || "",
        apiKey2: config.apiKey2 || "",
        location: config.location || "",
        units: config.units || "metric",
        provider: config.provider || "openmeteo",
        autoDetect: config.autoDetect === true,
        forecastDays: config.forecastDays || 5,
        forceRefresh: config.forceRefresh === true,
        clientId: String(config.clientId || "default"),
        _cacheKey: config._cacheKey,
        _requestScope: config._requestScope,
        _requestToken: config._requestToken
    }
}

function finishRequest(xhr) {
    if (xhr._mweatherComplete) return false
    xhr._mweatherComplete = true
    return true
}

function configureRequest(xhr, label, callback) {
    // QML's XMLHttpRequest reports transport failures as DONE with status 0.
    // The caller owns a watchdog Timer so a request that never reaches DONE
    // cannot leave the widget in a permanent loading state.
    xhr._mweatherLabel = label
}

function parseDateParts(value) {
    var match = String(value || "").match(/^(\d{4})-(\d{2})-(\d{2})(?:[T ](\d{2}):(\d{2})(?::(\d{2}))?)?/)
    if (!match) return null
    return {
        year: parseInt(match[1]),
        month: parseInt(match[2]),
        day: parseInt(match[3]),
        hour: parseInt(match[4] || "0"),
        minute: parseInt(match[5] || "0"),
        second: parseInt(match[6] || "0")
    }
}

function parseLocationTime(value, utcOffsetSeconds) {
    var parts = parseDateParts(value)
    if (!parts) return NaN
    return Date.UTC(parts.year, parts.month - 1, parts.day, parts.hour, parts.minute, parts.second) - (utcOffsetSeconds || 0) * 1000
}

function dateKeyFromValue(value) {
    var parts = parseDateParts(value)
    if (!parts) return ""
    return String(parts.year).padStart(4, "0") + "-" + String(parts.month).padStart(2, "0") + "-" + String(parts.day).padStart(2, "0")
}

function localDateKey(epochMs, utcOffsetSeconds) {
    var shifted = new Date(epochMs + (utcOffsetSeconds || 0) * 1000)
    return shifted.getUTCFullYear() + "-" + String(shifted.getUTCMonth() + 1).padStart(2, "0") + "-" + String(shifted.getUTCDate()).padStart(2, "0")
}

function localTimeLabel(epochMs, utcOffsetSeconds) {
    var shifted = new Date(epochMs + (utcOffsetSeconds || 0) * 1000)
    return String(shifted.getUTCHours()).padStart(2, "0") + ":" + String(shifted.getUTCMinutes()).padStart(2, "0")
}

function dayIndexForDateKey(dateKey) {
    var parts = parseDateParts(dateKey)
    if (!parts) return 0
    return new Date(Date.UTC(parts.year, parts.month - 1, parts.day)).getUTCDay()
}

function parseAstroTime(dateStr, timeStr, utcOffsetSeconds) {
    if (!timeStr) return null
    var parts = String(timeStr).match(/(\d+):(\d+)\s*(AM|PM)/i)
    if (!parts) return null

    var hours = parseInt(parts[1])
    var minutes = parseInt(parts[2])
    var ampm = parts[3].toUpperCase()
    if (ampm === "PM" && hours < 12) hours += 12
    if (ampm === "AM" && hours === 12) hours = 0

    return parseLocationTime(dateStr + "T" + String(hours).padStart(2, "0") + ":" + String(minutes).padStart(2, "0"), utcOffsetSeconds)
}

function windToKmh(speed, units) {
    if (!hasValue(speed)) return null
    if (units === "imperial") return Math.round(speed * 1.609344)
    return Math.round(speed * 3.6)
}

function weatherApiUtcOffset(location) {
    if (!location || !hasValue(location.localtime_epoch) || !location.localtime) return 0
    var localAsUtc = parseLocationTime(String(location.localtime).replace(" ", "T"), 0)
    if (isNaN(localAsUtc)) return 0
    return Math.round(localAsUtc / 1000 - location.localtime_epoch)
}

function mapOpenWeatherAlertCode(code) {
    if (code >= 200 && code < 300) return 95
    if (code >= 300 && code < 400) return 53
    if (code === 511) return 67
    if (code >= 500 && code < 600) return code >= 502 ? 65 : 61
    if (code >= 600 && code < 700) return code === 602 || code === 622 ? 75 : 71
    if (code === 741) return 45
    if (code >= 700 && code < 800) return 48
    if (code === 800) return 0
    if (code > 800) return code >= 803 ? 3 : 2
    return -1
}

function mapWeatherApiAlertCode(code) {
    if (code === 1000) return 0
    if (code === 1003) return 2
    if (code === 1006 || code === 1009) return 3
    if (code === 1030 || code === 1135 || code === 1147) return 45
    if (code === 1063 || (code >= 1150 && code <= 1201) || (code >= 1240 && code <= 1252)) return 61
    if (code === 1066 || code === 1114 || code === 1117 || (code >= 1210 && code <= 1237) || (code >= 1255 && code <= 1264)) return 71
    if (code === 1069 || code === 1072) return 57
    if (code === 1087 || code >= 1273) return 95
    return -1
}

function getWeatherApiCondition(code) {
    var wmoCode = mapWeatherApiAlertCode(code)
    if (wmoCode >= 0) return getOpenMeteoCondition(wmoCode)
    return "Unknown"
}

function normalizeCondition(text) {
    var value = String(text || "").trim().toLowerCase()
    if (value === "clear") return "Clear"
    if (value === "clouds" || value === "cloudy") return "Cloudy"
    if (value === "mist") return "Mist"
    if (value === "smoke") return "Smoke"
    if (value === "haze") return "Haze"
    if (value === "dust") return "Dust"
    if (value === "sand") return "Sand"
    if (value === "ash") return "Ash"
    if (value === "squall") return "Squall"
    if (value === "tornado") return "Tornado"
    if (value.indexOf("thunder") !== -1) return "Thunderstorm"
    if (value.indexOf("snow") !== -1) return "Snow"
    if (value.indexOf("rain") !== -1) return "Rain"
    if (value.indexOf("drizzle") !== -1) return "Drizzle"
    if (value.indexOf("fog") !== -1) return "Fog"
    if (value.indexOf("overcast") !== -1) return "Overcast"
    if (value.indexOf("partly") !== -1) return "Partly Cloudy"
    return "Unknown"
}

function fetchOpenWeatherMap(apiKey, location, units, callback) {
    var baseUrl = "https://api.openweathermap.org/data/2.5/"
    var currentUrl = baseUrl + "weather?q=" + encodeURIComponent(location) + "&appid=" + apiKey + "&units=" + units
    var xhr = new XMLHttpRequest()
    configureRequest(xhr, "OpenWeatherMap", callback)
    xhr.open("GET", currentUrl)
    xhr.onreadystatechange = function () {
        if (xhr.readyState !== XMLHttpRequest.DONE || !finishRequest(xhr)) return
        if (xhr.status !== 200) {
            callback({ success: false, error: xhr.status === 401 ? "Invalid API key" : (xhr.status === 0 ? "OpenWeatherMap network request failed" : "OpenWeatherMap API error: " + xhr.status), code: xhr.status })
            return
        }

        try {
            var data = JSON.parse(xhr.responseText)
            var timezoneOffset = data.timezone || 0
            var currentCode = data.weather && data.weather.length ? data.weather[0].id : -1
            var current = {
                temp: Math.round(data.main.temp),
                feels_like: Math.round(data.main.feels_like),
                temp_min: Math.round(data.main.temp_min),
                temp_max: Math.round(data.main.temp_max),
                humidity: data.main.humidity,
                pressure: data.main.pressure,
                visibility: hasValue(data.visibility) ? Math.round(data.visibility / 1000) : null,
                wind_speed: data.wind ? windToKmh(data.wind.speed, units) : null,
                wind_deg: data.wind ? data.wind.deg : null,
                wind_gust: data.wind && hasValue(data.wind.gust) ? windToKmh(data.wind.gust, units) : null,
                clouds: data.clouds ? data.clouds.all : null,
                sunrise: data.sys && hasValue(data.sys.sunrise) ? data.sys.sunrise * 1000 : null,
                sunset: data.sys && hasValue(data.sys.sunset) ? data.sys.sunset * 1000 : null,
                condition: normalizeCondition(data.weather && data.weather.length ? data.weather[0].main : ""),
                description: normalizeCondition(data.weather && data.weather.length ? data.weather[0].main : ""),
                icon: data.weather && data.weather.length ? data.weather[0].icon : "",
                code: currentCode,
                alert_code: mapOpenWeatherAlertCode(currentCode),
                location: data.name,
                coord: { lat: data.coord.lat, lon: data.coord.lon },
                timezone_offset: timezoneOffset,
                timestamp: hasValue(data.dt) ? data.dt * 1000 : Date.now()
            }

            var forecastUrl = baseUrl + "forecast?q=" + encodeURIComponent(location) + "&appid=" + apiKey + "&units=" + units
            var xhr2 = new XMLHttpRequest()
            configureRequest(xhr2, "OpenWeatherMap forecast", callback)
            xhr2.open("GET", forecastUrl)
            xhr2.onreadystatechange = function () {
                if (xhr2.readyState !== XMLHttpRequest.DONE || !finishRequest(xhr2)) return
                if (xhr2.status !== 200) {
                    callback({ success: false, error: xhr2.status === 0 ? "OpenWeatherMap forecast network request failed" : "OpenWeatherMap forecast API error: " + xhr2.status })
                    return
                }
                try {
                    var forecastData = JSON.parse(xhr2.responseText)
                    callback({ success: true, current: current, forecast: parseForecastOpenWeather(forecastData, current, units), provider: "openweathermap" })
                } catch (error) {
                    console.warn("MWeather: failed to parse OpenWeatherMap forecast:", error)
                    callback({ success: false, error: "Failed to parse OpenWeatherMap forecast data" })
                }
            }
            xhr2.send()
        } catch (error) {
            console.warn("MWeather: failed to parse OpenWeatherMap current data:", error)
            callback({ success: false, error: "Failed to parse OpenWeatherMap data" })
        }
    }
    xhr.send()
}

function fetchWeatherAPI(apiKey, location, units, forecastDays, callback) {
    var days = clampForecastDays(forecastDays, 7)
    var url = "https://api.weatherapi.com/v1/forecast.json?key=" + apiKey + "&q=" + encodeURIComponent(location) + "&days=" + days + "&aqi=no&alerts=no"
    var xhr = new XMLHttpRequest()
    configureRequest(xhr, "WeatherAPI.com", callback)
    xhr.open("GET", url)
    xhr.onreadystatechange = function () {
        if (xhr.readyState !== XMLHttpRequest.DONE || !finishRequest(xhr)) return
        if (xhr.status !== 200) {
            var invalidKey = xhr.status === 401 || xhr.status === 403
            callback({ success: false, error: invalidKey ? "Invalid API key" : (xhr.status === 0 ? "WeatherAPI.com network request failed" : "WeatherAPI.com API error: " + xhr.status), code: xhr.status })
            return
        }

        try {
            var data = JSON.parse(xhr.responseText)
            var today = data.forecast.forecastday[0]
            var offset = weatherApiUtcOffset(data.location)
            var useImperial = units === "imperial"
            var currentCode = data.current.condition.code
            var current = {
                temp: Math.round(useImperial ? data.current.temp_f : data.current.temp_c),
                feels_like: Math.round(useImperial ? data.current.feelslike_f : data.current.feelslike_c),
                temp_min: Math.round(useImperial ? today.day.mintemp_f : today.day.mintemp_c),
                temp_max: Math.round(useImperial ? today.day.maxtemp_f : today.day.maxtemp_c),
                humidity: data.current.humidity,
                pressure: Math.round(data.current.pressure_mb),
                wind_speed: Math.round(data.current.wind_kph),
                wind_deg: data.current.wind_degree,
                wind_gust: hasValue(data.current.gust_kph) ? Math.round(data.current.gust_kph) : null,
                clouds: data.current.cloud,
                visibility: hasValue(data.current.vis_km) ? Math.round(data.current.vis_km) : null,
                precipitation: data.current.precip_mm,
                uv_index: hasValue(data.current.uv) ? Math.round(data.current.uv) : null,
                sunrise: parseAstroTime(today.date, today.astro.sunrise, offset),
                sunset: parseAstroTime(today.date, today.astro.sunset, offset),
                condition: getWeatherApiCondition(currentCode),
                description: getWeatherApiCondition(currentCode),
                icon: "",
                code: currentCode,
                alert_code: mapWeatherApiAlertCode(currentCode),
                location: data.location.name,
                coord: { lat: data.location.lat, lon: data.location.lon },
                timezone_offset: offset,
                timestamp: hasValue(data.current.last_updated_epoch) ? data.current.last_updated_epoch * 1000 : Date.now()
            }
            var forecast = parseForecastWeatherAPI(data.forecast.forecastday, units, offset, Date.now())
            callback({ success: true, current: current, forecast: forecast, provider: "weatherapi" })
        } catch (error) {
            console.warn("MWeather: failed to parse WeatherAPI.com data:", error)
            callback({ success: false, error: "Failed to parse WeatherAPI.com data" })
        }
    }
    xhr.send()
}

function fetchOpenMeteoAtPlace(place, units, forecastDays, callback) {
    var lat = place.latitude
    var lon = place.longitude
    var days = clampForecastDays(forecastDays, 16)
    var temperatureUnit = units === "imperial" ? "fahrenheit" : "celsius"
    var weatherUrl = "https://api.open-meteo.com/v1/forecast?" +
        "latitude=" + lat + "&longitude=" + lon +
        "&current=temperature_2m,relative_humidity_2m,apparent_temperature,precipitation,weather_code,cloud_cover,pressure_msl,surface_pressure,wind_speed_10m,wind_direction_10m,wind_gusts_10m,visibility,dew_point_2m" +
        "&daily=temperature_2m_max,temperature_2m_min,apparent_temperature_max,apparent_temperature_min,weather_code,sunrise,sunset,uv_index_max,precipitation_sum,precipitation_probability_max,wind_speed_10m_max,wind_direction_10m_dominant,relative_humidity_2m_max" +
        "&forecast_days=" + days +
        "&hourly=temperature_2m,weather_code,precipitation,precipitation_probability&forecast_hours=48" +
        "&timezone=auto&temperature_unit=" + temperatureUnit + "&wind_speed_unit=kmh"

    var xhr = new XMLHttpRequest()
    configureRequest(xhr, "Open-Meteo forecast", callback)
    xhr.open("GET", weatherUrl)
    xhr.onreadystatechange = function () {
        if (xhr.readyState !== XMLHttpRequest.DONE || !finishRequest(xhr)) return
        if (xhr.status !== 200) {
            callback({ success: false, error: xhr.status === 0 ? "Open-Meteo network request failed" : "Open-Meteo API error: " + xhr.status })
            return
        }
        try {
            var data = JSON.parse(xhr.responseText)
            var offset = data.utc_offset_seconds || 0
            var code = data.current.weather_code
            var current = {
                temp: Math.round(data.current.temperature_2m),
                feels_like: Math.round(data.current.apparent_temperature),
                temp_min: Math.round(data.daily.temperature_2m_min[0]),
                temp_max: Math.round(data.daily.temperature_2m_max[0]),
                humidity: data.current.relative_humidity_2m,
                pressure: Math.round(data.current.pressure_msl),
                clouds: data.current.cloud_cover,
                wind_speed: Math.round(data.current.wind_speed_10m),
                wind_deg: data.current.wind_direction_10m,
                wind_gust: hasValue(data.current.wind_gusts_10m) ? Math.round(data.current.wind_gusts_10m) : null,
                precipitation: data.current.precipitation,
                uv_index: data.daily.uv_index_max ? Math.round(data.daily.uv_index_max[0]) : null,
                sunrise: data.daily.sunrise ? parseLocationTime(data.daily.sunrise[0], offset) : null,
                sunset: data.daily.sunset ? parseLocationTime(data.daily.sunset[0], offset) : null,
                visibility: hasValue(data.current.visibility) ? Math.round(data.current.visibility / 1000) : null,
                dew_point: Math.round(data.current.dew_point_2m),
                description: getOpenMeteoCondition(code),
                condition: getOpenMeteoCondition(code),
                icon: "",
                code: code,
                alert_code: code,
                location: place.name,
                coord: { lat: lat, lon: lon },
                timezone_offset: offset,
                timestamp: data.current.time ? parseLocationTime(data.current.time, offset) : Date.now()
            }
            callback({ success: true, current: current, forecast: parseForecastOpenMeteo(data, Date.now()), provider: "openmeteo" })
        } catch (error) {
            console.warn("MWeather: failed to parse Open-Meteo data:", error)
            callback({ success: false, error: "Failed to parse Open-Meteo data" })
        }
    }
    xhr.send()
}

function fetchOpenMeteo(location, units, forecastDays, callback) {
    var key = normalizedLocation(location)
    var cached = geocodeCache[key]
    if (cached && Date.now() - cached.timestamp < LOCATION_CACHE_TTL_MS) {
        fetchOpenMeteoAtPlace(cached.place, units, forecastDays, callback)
        return
    }

    var url = "https://geocoding-api.open-meteo.com/v1/search?name=" + encodeURIComponent(location) + "&count=1&language=en&format=json"
    var xhr = new XMLHttpRequest()
    configureRequest(xhr, "Open-Meteo geocoding", callback)
    xhr.open("GET", url)
    xhr.onreadystatechange = function () {
        if (xhr.readyState !== XMLHttpRequest.DONE || !finishRequest(xhr)) return
        if (xhr.status !== 200) {
            callback({ success: false, error: xhr.status === 0 ? "Open-Meteo geocoding network request failed" : "Open-Meteo geocoding API error: " + xhr.status })
            return
        }
        try {
            var data = JSON.parse(xhr.responseText)
            if (!data.results || data.results.length === 0) {
                callback({ success: false, error: "Location not found" })
                return
            }
            var place = data.results[0]
            geocodeCache[key] = { place: place, timestamp: Date.now() }
            fetchOpenMeteoAtPlace(place, units, forecastDays, callback)
        } catch (error) {
            console.warn("MWeather: failed to parse Open-Meteo geocoding data:", error)
            callback({ success: false, error: "Failed to parse geocoding data" })
        }
    }
    xhr.send()
}

function fetchIpAndWeather(config, callback) {
    if (ipLocationCache.city && Date.now() - ipLocationCache.timestamp < LOCATION_CACHE_TTL_MS) {
        var cachedConfig = copyConfig(config)
        cachedConfig.location = ipLocationCache.city
        fetchWeatherInternal(cachedConfig, callback)
        return
    }

    var xhr = new XMLHttpRequest()
    configureRequest(xhr, "Automatic location detection", callback)
    xhr.open("GET", "https://ipinfo.io/json")
    xhr.onreadystatechange = function () {
        if (xhr.readyState !== XMLHttpRequest.DONE || !finishRequest(xhr)) return
        if (xhr.status !== 200) {
            callback({ success: false, error: xhr.status === 0 ? "Automatic location detection network request failed" : "Automatic location detection failed: " + xhr.status })
            return
        }
        try {
            var data = JSON.parse(xhr.responseText)
            if (!data.city) {
                callback({ success: false, error: "Automatic location detection returned no city" })
                return
            }
            ipLocationCache = { city: data.city, timestamp: Date.now() }
            var detectedConfig = copyConfig(config)
            detectedConfig.location = data.city
            fetchWeatherInternal(detectedConfig, callback)
        } catch (error) {
            console.warn("MWeather: failed to parse automatic location response:", error)
            callback({ success: false, error: "Failed to parse automatic location response" })
        }
    }
    xhr.send()
}

function completeWeatherRequest(config, result, callback) {
    if (!result.success) {
        callback(result)
        return
    }

    var requestedDays = clampForecastDays(config.forecastDays, 16)
    if (result.forecast && result.forecast.daily) result.forecast.daily = result.forecast.daily.slice(0, requestedDays)
    result.fetchedAt = Date.now()

    if (activeRequests[config._requestScope] === config._requestToken) {
        caches[config._cacheKey] = {
            current: result.current,
            forecast: result.forecast,
            provider: result.provider,
            timestamp: result.fetchedAt
        }
    }
    callback(result)
}

function fetchWeatherInternal(config, callback) {
    var location = String(config.location || "").trim()
    if (!location) {
        callback({ success: false, error: "Please configure a location" })
        return
    }

    var providerCallback = function (result) { completeWeatherRequest(config, result, callback) }
    if (config.provider === "openweathermap") {
        if (!config.apiKey) {
            callback({ success: false, error: "OpenWeatherMap API key is missing" })
            return
        }
        fetchOpenWeatherMap(config.apiKey, location, config.units, providerCallback)
        return
    }

    if (config.provider === "weatherapi") {
        if (!config.apiKey2) {
            callback({ success: false, error: "WeatherAPI.com API key is missing" })
            return
        }
        fetchWeatherAPI(config.apiKey2, location, config.units, config.forecastDays, providerCallback)
        return
    }

    fetchOpenMeteo(location, config.units, config.forecastDays, providerCallback)
}

function fetchWeather(config, callback) {
    var normalized = copyConfig(config)
    normalized._cacheKey = cacheKeyForConfig(normalized)
    normalized._requestScope = normalized._cacheKey + "|client=" + normalized.clientId
    normalized._requestToken = ++requestSerial
    activeRequests[normalized._requestScope] = normalized._requestToken

    var cached = caches[normalized._cacheKey]
    var requestedDays = clampForecastDays(normalized.forecastDays, 16)
    if (!normalized.forceRefresh && cached && Date.now() - cached.timestamp < CACHE_TTL_MS) {
        callback({
            success: true,
            current: cached.current,
            forecast: {
                daily: cached.forecast.daily.slice(0, requestedDays),
                hourly: cached.forecast.hourly
            },
            provider: cached.provider,
            fetchedAt: cached.timestamp,
            fromCache: true
        })
        return
    }

    if (normalized.autoDetect) fetchIpAndWeather(normalized, callback)
    else fetchWeatherInternal(normalized, callback)
}

function cancelRequest(config) {
    var key = cacheKeyForConfig(config)
    var scope = key + "|client=" + String(config.clientId || "default")
    activeRequests[scope] = ++requestSerial
}

function parseForecastOpenWeather(data, current, units, nowMs) {
    var daily = []
    var hourly = []
    var dailyByKey = {}
    var offset = data.city && data.city.timezone ? data.city.timezone : (current.timezone_offset || 0)
    var now = hasValue(nowMs) ? nowMs : Date.now()
    var todayKey = localDateKey(now, offset)

    dailyByKey[todayKey] = {
        day: dayIndexForDateKey(todayKey),
        date: todayKey,
        temp: current.temp,
        temp_min: current.temp_min,
        temp_max: current.temp_max,
        code: current.code,
        alert_code: current.alert_code,
        condition: current.condition,
        icon: current.icon,
        timezone_offset: offset,
        representativeDistance: 99,
        hasDetails: false
    }

    for (var i = 0; i < data.list.length; i++) {
        var item = data.list[i]
        var timestamp = item.dt * 1000
        var dayKey = localDateKey(timestamp, offset)
        var shifted = new Date(timestamp + offset * 1000)
        var hour = shifted.getUTCHours()
        var rawCode = item.weather[0].id

        if (timestamp > now && hourly.length < 24) {
            hourly.push({
                time: localTimeLabel(timestamp, offset),
                date: dayKey,
                timestamp: timestamp,
                interval_ms: 3 * 60 * 60 * 1000,
                timezone_offset: offset,
                temp: Math.round(item.main.temp),
                code: rawCode,
                alert_code: mapOpenWeatherAlertCode(rawCode),
                condition: normalizeCondition(item.weather[0].main),
                precipitation: item.rain && hasValue(item.rain["3h"]) ? item.rain["3h"] : 0,
                precipitation_probability: hasValue(item.pop) ? Math.round(item.pop * 100) : 0,
                icon: item.weather[0].icon
            })
        }

        var entry = dailyByKey[dayKey]
        if (!entry) {
            entry = {
                day: dayIndexForDateKey(dayKey),
                date: dayKey,
                temp: Math.round(item.main.temp),
                temp_min: Math.round(item.main.temp_min),
                temp_max: Math.round(item.main.temp_max),
                code: rawCode,
                alert_code: mapOpenWeatherAlertCode(rawCode),
                condition: normalizeCondition(item.weather[0].main),
                icon: item.weather[0].icon,
                timezone_offset: offset,
                representativeDistance: 99,
                hasDetails: false
            }
            dailyByKey[dayKey] = entry
        }
        entry.temp_min = Math.min(entry.temp_min, Math.round(item.main.temp_min))
        entry.temp_max = Math.max(entry.temp_max, Math.round(item.main.temp_max))

        var distance = Math.abs(hour - 12)
        if (distance < entry.representativeDistance) {
            entry.representativeDistance = distance
            entry.temp = Math.round(item.main.temp)
            entry.code = rawCode
            entry.alert_code = mapOpenWeatherAlertCode(rawCode)
            entry.condition = normalizeCondition(item.weather[0].main)
            entry.icon = item.weather[0].icon
        }
    }

    var keys = Object.keys(dailyByKey).sort()
    for (var k = 0; k < keys.length; k++) {
        var day = dailyByKey[keys[k]]
        delete day.representativeDistance
        daily.push(day)
    }
    return { daily: daily, hourly: hourly }
}

function parseForecastWeatherAPI(forecastDays, units, utcOffsetSeconds, nowMs) {
    var daily = []
    var hourly = []
    var useImperial = units === "imperial"
    var now = hasValue(nowMs) ? nowMs : Date.now()

    for (var i = 0; i < forecastDays.length; i++) {
        var day = forecastDays[i]
        var code = day.day.condition.code
        daily.push({
            day: dayIndexForDateKey(day.date),
            date: day.date,
            temp: Math.round(useImperial ? day.day.avgtemp_f : day.day.avgtemp_c),
            temp_min: Math.round(useImperial ? day.day.mintemp_f : day.day.mintemp_c),
            temp_max: Math.round(useImperial ? day.day.maxtemp_f : day.day.maxtemp_c),
            humidity: hasValue(day.day.avghumidity) ? Math.round(day.day.avghumidity) : null,
            wind_speed: hasValue(day.day.maxwind_kph) ? Math.round(day.day.maxwind_kph) : null,
            uv_index: hasValue(day.day.uv) ? Math.round(day.day.uv) : null,
            precipitation: hasValue(day.day.totalprecip_mm) ? day.day.totalprecip_mm : null,
            precipitation_probability: hasValue(day.day.daily_chance_of_rain) ? day.day.daily_chance_of_rain : null,
            sunrise: day.astro ? parseAstroTime(day.date, day.astro.sunrise, utcOffsetSeconds) : null,
            sunset: day.astro ? parseAstroTime(day.date, day.astro.sunset, utcOffsetSeconds) : null,
            code: code,
            alert_code: mapWeatherApiAlertCode(code),
            condition: getWeatherApiCondition(code),
            icon: "",
            timezone_offset: utcOffsetSeconds,
            hasDetails: true
        })

        if (!day.hour) continue
        for (var h = 0; h < day.hour.length && hourly.length < 48; h++) {
            var hour = day.hour[h]
            var timestamp = hasValue(hour.time_epoch) ? hour.time_epoch * 1000 : parseLocationTime(hour.time, utcOffsetSeconds)
            if (timestamp <= now) continue
            var hourCode = hour.condition.code
            hourly.push({
                time: String(hour.time).slice(11, 16),
                date: day.date,
                timestamp: timestamp,
                interval_ms: 60 * 60 * 1000,
                timezone_offset: utcOffsetSeconds,
                temp: Math.round(useImperial ? hour.temp_f : hour.temp_c),
                code: hourCode,
                alert_code: mapWeatherApiAlertCode(hourCode),
                condition: getWeatherApiCondition(hourCode),
                precipitation: hasValue(hour.precip_mm) ? hour.precip_mm : 0,
                precipitation_probability: hasValue(hour.chance_of_rain) ? hour.chance_of_rain : 0,
                icon: ""
            })
        }
    }
    return { daily: daily, hourly: hourly }
}

function parseForecastOpenMeteo(data, nowMs) {
    var daily = []
    var hourly = []
    var offset = data.utc_offset_seconds || 0
    var now = hasValue(nowMs) ? nowMs : Date.now()

    if (data.daily && data.daily.time) {
        for (var i = 0; i < data.daily.time.length; i++) {
            var dateKey = dateKeyFromValue(data.daily.time[i])
            var code = data.daily.weather_code ? data.daily.weather_code[i] : -1
            daily.push({
                day: dayIndexForDateKey(dateKey),
                date: dateKey,
                temp: Math.round((data.daily.temperature_2m_max[i] + data.daily.temperature_2m_min[i]) / 2),
                temp_min: Math.round(data.daily.temperature_2m_min[i]),
                temp_max: Math.round(data.daily.temperature_2m_max[i]),
                feels_like: data.daily.apparent_temperature_max ? Math.round((data.daily.apparent_temperature_max[i] + data.daily.apparent_temperature_min[i]) / 2) : null,
                feels_like_max: data.daily.apparent_temperature_max ? Math.round(data.daily.apparent_temperature_max[i]) : null,
                feels_like_min: data.daily.apparent_temperature_min ? Math.round(data.daily.apparent_temperature_min[i]) : null,
                wind_speed: data.daily.wind_speed_10m_max ? Math.round(data.daily.wind_speed_10m_max[i]) : null,
                wind_deg: data.daily.wind_direction_10m_dominant ? data.daily.wind_direction_10m_dominant[i] : null,
                uv_index: data.daily.uv_index_max ? Math.round(data.daily.uv_index_max[i]) : null,
                precipitation: data.daily.precipitation_sum ? data.daily.precipitation_sum[i] : null,
                precipitation_probability: data.daily.precipitation_probability_max ? data.daily.precipitation_probability_max[i] : null,
                humidity: data.daily.relative_humidity_2m_max ? Math.round(data.daily.relative_humidity_2m_max[i]) : null,
                sunrise: data.daily.sunrise ? parseLocationTime(data.daily.sunrise[i], offset) : null,
                sunset: data.daily.sunset ? parseLocationTime(data.daily.sunset[i], offset) : null,
                code: code,
                alert_code: code,
                condition: getOpenMeteoCondition(code),
                icon: "",
                timezone_offset: offset,
                hasDetails: true
            })
        }
    }

    if (data.hourly && data.hourly.time) {
        for (var h = 0; h < data.hourly.time.length && hourly.length < 48; h++) {
            var timestamp = parseLocationTime(data.hourly.time[h], offset)
            if (timestamp <= now) continue
            var hourCode = data.hourly.weather_code ? data.hourly.weather_code[h] : -1
            hourly.push({
                time: String(data.hourly.time[h]).slice(11, 16),
                date: dateKeyFromValue(data.hourly.time[h]),
                timestamp: timestamp,
                interval_ms: 60 * 60 * 1000,
                timezone_offset: offset,
                temp: Math.round(data.hourly.temperature_2m[h]),
                code: hourCode,
                alert_code: hourCode,
                condition: getOpenMeteoCondition(hourCode),
                precipitation: data.hourly.precipitation ? data.hourly.precipitation[h] : 0,
                precipitation_probability: data.hourly.precipitation_probability ? data.hourly.precipitation_probability[h] : 0,
                icon: ""
            })
        }
    }
    return { daily: daily, hourly: hourly }
}

function getOpenMeteoCondition(code) {
    if (code === 0) return "Clear"
    if (code === 1) return "Mainly Clear"
    if (code === 2) return "Partly Cloudy"
    if (code === 3) return "Overcast"
    if (code === 45 || code === 48) return "Fog"
    if (code === 51 || code === 53 || code === 55) return "Drizzle"
    if (code === 56 || code === 57) return "Freezing Drizzle"
    if (code === 61 || code === 63 || code === 65) return "Rain"
    if (code === 66 || code === 67) return "Freezing Rain"
    if (code === 71 || code === 73 || code === 75) return "Snow"
    if (code === 77) return "Snow Grains"
    if (code === 80 || code === 81 || code === 82) return "Rain Showers"
    if (code === 85 || code === 86) return "Snow Showers"
    if (code === 95) return "Thunderstorm"
    if (code === 96 || code === 99) return "Thunderstorm with Hail"
    return "Unknown"
}

function getClothingSuggestion(current, units) {
    if (!current) return null
    var tempC = units === "imperial" ? Math.round((current.temp - 32) * 5 / 9) : current.temp
    var windKmh = current.wind_speed || 0
    var code = hasValue(current.alert_code) ? current.alert_code : current.code
    var suggestions = []

    if ([51, 53, 55, 56, 57, 61, 63, 65, 66, 67, 80, 81, 82, 95, 96, 99].indexOf(code) >= 0) suggestions.push({ icon: "☔", text: "umbrella" })
    if ([71, 73, 75, 77, 85, 86].indexOf(code) >= 0) suggestions.push({ icon: "🧤", text: "gloves" })

    if (tempC <= 0) suggestions.push({ icon: "🧥", text: "heavy coat" })
    else if (tempC <= 10) suggestions.push({ icon: "🧥", text: "coat" })
    else if (tempC <= 18) suggestions.push({ icon: "🧶", text: "sweater" })
    else if (tempC >= 30) suggestions.push({ icon: "🕶️", text: "sunglasses" })

    if (windKmh > 40 && tempC < 15) suggestions.push({ icon: "💨", text: "windbreaker" })
    return suggestions.length > 0 ? suggestions : null
}
