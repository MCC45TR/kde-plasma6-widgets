.pragma library

var cache = {
    current: null,
    forecast: null,
    timestamp: 0,
    ttl: 5 * 60 * 1000,
    key: ""
}

var currentProvider = "openweathermap"
var REQUEST_TIMEOUT_MS = 15000

function createRequestController() {
    return {
        cancelled: false,
        requests: [],
        cancel: function () {
            if (this.cancelled) return
            this.cancelled = true
            for (var i = 0; i < this.requests.length; i++) {
                try { this.requests[i].abort() } catch (e) {}
            }
            this.requests = []
        }
    }
}

function configureRequest(xhr, finish, controller) {
    controller.requests.push(xhr)
    xhr.timeout = REQUEST_TIMEOUT_MS
    xhr.ontimeout = function () {
        if (!controller.cancelled) finish({ success: false, error: "Weather request timed out" })
    }
    xhr.onerror = function () {
        if (!controller.cancelled) finish({ success: false, error: "Weather network error" })
    }
}

function getCacheKey(config) {
    return [config.provider || "openmeteo", config.autoDetect ? "auto" : (config.location || ""), config.units || "metric"].join("|")
}

function fetchOpenWeatherMap(apiKey, location, units, callback, controller) {
    var completed = false
    function finish(result) {
        if (completed || controller.cancelled) return
        completed = true
        callback(result)
    }
    var baseUrl = "https://api.openweathermap.org/data/2.5/"

    var currentUrl = baseUrl + "weather?q=" + encodeURIComponent(location) + "&appid=" + encodeURIComponent(apiKey) + "&units=" + units

    var xhr = new XMLHttpRequest()
    xhr.open("GET", currentUrl)
    configureRequest(xhr, finish, controller)
    xhr.onreadystatechange = function () {
        if (controller.cancelled) return
        if (xhr.readyState === XMLHttpRequest.DONE) {
            if (xhr.status === 200) {
                try {
                    var data = JSON.parse(xhr.responseText)
                    var current = {
                        temp: Math.round(data.main.temp),
                        feels_like: Math.round(data.main.feels_like),
                        temp_min: Math.round(data.main.temp_min),
                        temp_max: Math.round(data.main.temp_max),
                        humidity: data.main.humidity,
                        pressure: data.main.pressure,
                        visibility: data.visibility ? Math.round(data.visibility / (units === "imperial" ? 1609.344 : 1000)) : null,
                        wind_speed: data.wind ? Math.round(data.wind.speed * (units === "imperial" ? 1 : 3.6)) : null,
                        wind_deg: data.wind ? data.wind.deg : null,
                        wind_gust: data.wind && data.wind.gust ? Math.round(data.wind.gust * (units === "imperial" ? 1 : 3.6)) : null,
                        clouds: data.clouds ? data.clouds.all : null,
                        sunrise: data.sys && data.sys.sunrise ? data.sys.sunrise * 1000 : null,
                        sunset: data.sys && data.sys.sunset ? data.sys.sunset * 1000 : null,
                        condition: normalizeCondition(data.weather[0].main),
                        description: data.weather[0].description,
                        icon: data.weather[0].icon,
                        code: data.weather[0].id,
                        location: data.name,
                        coord: { lat: data.coord.lat, lon: data.coord.lon },
                        timestamp: Date.now()
                    }

                    var forecastUrl = baseUrl + "forecast?q=" + encodeURIComponent(location) + "&appid=" + encodeURIComponent(apiKey) + "&units=" + units
                    var xhr2 = new XMLHttpRequest()
                    xhr2.open("GET", forecastUrl)
                    configureRequest(xhr2, finish, controller)
                    xhr2.onreadystatechange = function () {
                        if (controller.cancelled) return
                        if (xhr2.readyState === XMLHttpRequest.DONE) {
                            if (xhr2.status === 200) {
                                try {
                                    var forecastData = JSON.parse(xhr2.responseText)
                                    var forecast = parseForecastOpenWeather(forecastData)
                                    finish({ success: true, current: current, forecast: forecast, provider: "openweathermap" })
                                } catch (e) {
                                    finish({ success: false, error: "Failed to parse forecast: " + e })
                                }
                            } else {
                                finish({ success: false, error: "Forecast API error: " + xhr2.status })
                            }
                        }
                    }
                    xhr2.send()
                } catch (e) {
                    finish({ success: false, error: "Failed to parse current weather: " + e })
                }
            } else if (xhr.status === 401) {
                finish({ success: false, error: "Invalid API key", code: 401 })
            } else {
                finish({ success: false, error: "API error: " + xhr.status, code: xhr.status })
            }
        }
    }
    xhr.send()
}

function parseAstroTime(dateStr, timeStr) {
    if (!timeStr) return null
    var parts = timeStr.match(/(\d+):(\d+) (AM|PM)/)
    if (!parts) return null

    var hours = parseInt(parts[1])
    var minutes = parseInt(parts[2])
    var ampm = parts[3]

    if (ampm === "PM" && hours < 12) hours += 12
    if (ampm === "AM" && hours === 12) hours = 0

    var d = new Date(dateStr)
    d.setHours(hours, minutes, 0, 0)
    return d.getTime()
}

function fetchWeatherAPI(apiKey, location, units, callback, controller) {
    var completed = false
    function finish(result) {
        if (completed || controller.cancelled) return
        completed = true
        callback(result)
    }
    var baseUrl = "https://api.weatherapi.com/v1/"
    var url = baseUrl + "forecast.json?key=" + encodeURIComponent(apiKey) + "&q=" + encodeURIComponent(location) + "&days=7&aqi=no&alerts=no"

    var xhr = new XMLHttpRequest()
    xhr.open("GET", url)
    configureRequest(xhr, finish, controller)
    xhr.onreadystatechange = function () {
        if (controller.cancelled) return
        if (xhr.readyState === XMLHttpRequest.DONE) {
            if (xhr.status === 200) {
                try {
                    var data = JSON.parse(xhr.responseText)
                    var today = data.forecast.forecastday[0]
                    var imperial = units === "imperial"
                    var current = {
                        temp: Math.round(imperial ? data.current.temp_f : data.current.temp_c),
                        feels_like: Math.round(imperial ? data.current.feelslike_f : data.current.feelslike_c),
                        temp_min: Math.round(imperial ? today.day.mintemp_f : today.day.mintemp_c),
                        temp_max: Math.round(imperial ? today.day.maxtemp_f : today.day.maxtemp_c),
                        humidity: data.current.humidity,
                        pressure: Math.round(imperial ? data.current.pressure_in * 33.8639 : data.current.pressure_mb),
                        visibility: Math.round(imperial ? data.current.vis_miles : data.current.vis_km),
                        wind_speed: Math.round(imperial ? data.current.wind_mph : data.current.wind_kph),
                        wind_gust: Math.round(imperial ? data.current.gust_mph : data.current.gust_kph),
                        wind_deg: data.current.wind_degree,
                        sunrise: parseAstroTime(today.date, today.astro.sunrise),
                        sunset: parseAstroTime(today.date, today.astro.sunset),
                        condition: normalizeCondition(data.current.condition.text),
                        description: data.current.condition.text,
                        icon: "",
                        code: data.current.condition.code,
                        location: data.location.name,
                        timestamp: Date.now()
                    }

                    var forecast = parseForecastWeatherAPI(data.forecast.forecastday, units)
                    finish({ success: true, current: current, forecast: forecast, provider: "weatherapi" })
                } catch (e) {
                    finish({ success: false, error: "Failed to parse WeatherAPI data: " + e })
                }
            } else if (xhr.status === 401 || xhr.status === 403) {
                finish({ success: false, error: "Invalid API key", code: 401 })
            } else {
                finish({ success: false, error: "WeatherAPI error: " + xhr.status, code: xhr.status })
            }
        }
    }
    xhr.send()
}

function fetchOpenMeteo(location, units, callback, controller) {
    var completed = false
    function finish(result) {
        if (completed || controller.cancelled) return
        completed = true
        callback(result)
    }
    var geocodeUrl = "https://geocoding-api.open-meteo.com/v1/search?name=" + encodeURIComponent(location) + "&count=1&language=en&format=json"

    var xhr = new XMLHttpRequest()
    xhr.open("GET", geocodeUrl)
    configureRequest(xhr, finish, controller)
    xhr.onreadystatechange = function () {
        if (controller.cancelled) return
        if (xhr.readyState === XMLHttpRequest.DONE) {
            if (xhr.status === 200) {
                try {
                    var geoData = JSON.parse(xhr.responseText)
                    if (!geoData.results || geoData.results.length === 0) {
                        finish({ success: false, error: "Location not found" })
                        return
                    }

                    var place = geoData.results[0]
                    var lat = place.latitude
                    var lon = place.longitude
                    var locationName = place.name

                    var tempUnit = units === "imperial" ? "&temperature_unit=fahrenheit&wind_speed_unit=mph" : "&temperature_unit=celsius&wind_speed_unit=kmh"
                    var weatherUrl = "https://api.open-meteo.com/v1/forecast?" +
                        "latitude=" + lat + "&longitude=" + lon +
                        "&current=temperature_2m,relative_humidity_2m,apparent_temperature,precipitation,weather_code,cloud_cover,pressure_msl,surface_pressure,wind_speed_10m,wind_direction_10m,wind_gusts_10m,visibility,dew_point_2m" +
                        "&daily=temperature_2m_max,temperature_2m_min,apparent_temperature_max,apparent_temperature_min,weather_code,sunrise,sunset,uv_index_max,precipitation_sum,precipitation_probability_max,wind_speed_10m_max,wind_direction_10m_dominant,relative_humidity_2m_max" +
                        "&forecast_days=" + (16) +
                        "&hourly=temperature_2m,weather_code,precipitation,precipitation_probability&forecast_hours=48" +
                        "&timezone=auto" +
                        tempUnit

                    var xhr2 = new XMLHttpRequest()
                    xhr2.open("GET", weatherUrl)
                    configureRequest(xhr2, finish, controller)
                    xhr2.onreadystatechange = function () {
                        if (controller.cancelled) return
                        if (xhr2.readyState === XMLHttpRequest.DONE) {
                            if (xhr2.status === 200) {
                                try {
                                    var data = JSON.parse(xhr2.responseText)

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
                                        wind_gust: data.current.wind_gusts_10m ? Math.round(data.current.wind_gusts_10m) : null,
                                        precipitation: data.current.precipitation,
                                        uv_index: data.daily.uv_index_max ? Math.round(data.daily.uv_index_max[0]) : null,
                                        sunrise: data.daily.sunrise ? data.daily.sunrise[0] : null,
                                        sunset: data.daily.sunset ? data.daily.sunset[0] : null,
                                        weather_code: data.current.weather_code, /* Keep raw code for debugging/logic if needed */
                                        visibility: data.current.visibility ? Math.round(data.current.visibility / (units === "imperial" ? 1609.344 : 1000)) : null,
                                        dew_point: Math.round(data.current.dew_point_2m),
                                        cloud_cover: data.current.cloud_cover,
                                        description: getOpenMeteoCondition(data.current.weather_code),
                                        condition: getOpenMeteoCondition(data.current.weather_code),
                                        icon: "",
                                        code: data.current.weather_code,
                                        location: locationName,
                                        coord: { lat: lat, lon: lon },
                                        timestamp: Date.now()
                                    }

                                    var forecast = parseForecastOpenMeteo(data)
                                    finish({ success: true, current: current, forecast: forecast, provider: "openmeteo" })
                                } catch (e) {
                                    finish({ success: false, error: "Failed to parse Open-Meteo data: " + e })
                                }
                            } else {
                                finish({ success: false, error: "Open-Meteo API error: " + xhr2.status })
                            }
                        }
                    }
                    xhr2.send()
                } catch (e) {
                    finish({ success: false, error: "Geocoding error: " + e })
                }
            } else {
                finish({ success: false, error: "Geocoding API error: " + xhr.status })
            }
        }
    }
    xhr.send()
}

function fetchIpAndWeather(config, callback, controller) {
    var completed = false
    function finish(result) {
        if (completed || controller.cancelled) return
        completed = true
        callback(result)
    }
    var xhr = new XMLHttpRequest()
    var url = "https://ipinfo.io/json"
    xhr.open("GET", url)
    configureRequest(xhr, finish, controller)
    xhr.onreadystatechange = function () {
        if (controller.cancelled) return
        if (xhr.readyState === XMLHttpRequest.DONE) {
            if (xhr.status === 200) {
                try {
                    var data = JSON.parse(xhr.responseText)
                    if (data.city) {
                        var newConfig = {
                            apiKey: config.apiKey,
                            apiKey2: config.apiKey2,
                            location: data.city,
                            units: config.units,
                            provider: config.provider,
                            forecastDays: config.forecastDays,
                            _cacheKey: config._cacheKey
                        }
                        fetchWeatherInternal(newConfig, finish, controller)
                    } else {
                        finish({ success: false, error: "Could not detect location from IP" })
                    }
                } catch (e) {
                    console.log("Failed to parse IP info: " + e)
                    finish({ success: false, error: "Could not detect location from IP" })
                }
            } else {
                console.log("IP detection failed: " + xhr.status)
                finish({ success: false, error: "Could not detect location from IP" })
            }
        }
    }
    xhr.send()
}

function fetchWeatherInternal(config, callback, controller) {
    var apiKey = config.apiKey || ""
    var apiKey2 = config.apiKey2 || ""
    var location = config.location || ""
    var units = config.units || "metric"
    var provider = config.provider || "openmeteo"
    var forecastDays = config.forecastDays || 12
    var resultCacheKey = config._cacheKey || getCacheKey(config)

    console.log("Fetching weather using provider: " + provider + ", days: " + forecastDays)

    if (provider === "openweathermap") {
        if (apiKey) {
            fetchOpenWeatherMap(apiKey, location, units, function (result) {
                if (result.success) {
                    cache.current = result.current
                    cache.forecast = result.forecast
                    cache.timestamp = Date.now()
                    cache.key = resultCacheKey
                    callback(result)
                } else {
                    callback(result)
                }
            }, controller)
        } else {
            callback({ success: false, error: "OpenWeatherMap API Key missing" })
        }
        return
    }

    if (provider === "weatherapi") {
        if (apiKey2) {
            fetchWeatherAPI(apiKey2, location, units, function (result) {
                if (result.success) {
                    cache.current = result.current
                    cache.forecast = result.forecast
                    cache.timestamp = Date.now()
                    cache.key = resultCacheKey
                    callback(result)
                } else {
                    callback(result)
                }
            }, controller)
        } else {
            callback({ success: false, error: "WeatherAPI.com API Key missing" })
        }
        return
    }

    fetchOpenMeteo(location, units, function (result) {
        if (result.success) {
            cache.current = result.current
            cache.forecast = result.forecast
            cache.timestamp = Date.now()
            cache.key = resultCacheKey
        }

        if (result.success && result.forecast && result.forecast.daily) {
            var finalResult = {
                success: result.success,
                current: result.current,
                forecast: {
                    daily: result.forecast.daily.slice(0, forecastDays),
                    hourly: result.forecast.hourly
                },
                provider: result.provider
            }
            callback(finalResult)
        } else {
            callback(result)
        }
    }, controller)
}

function fetchWeather(config, callback) {
    var controller = createRequestController()
    function deliver(result) {
        if (!controller.cancelled) callback(result)
    }
    var now = Date.now()
    var requestedKey = getCacheKey(config)
    config._cacheKey = requestedKey

    var forceRefresh = false
    if (cache.current && cache.current.location && cache.current.location.indexOf(",") !== -1) {
        forceRefresh = true
    }

    var allowMemoryCache = config.refreshInterval !== 0
    if (allowMemoryCache && !forceRefresh && cache.key === requestedKey && cache.current && cache.forecast && (now - cache.timestamp) < cache.ttl) {
        var requestedDays = config.forecastDays || 5

        if (cache.forecast.daily && cache.forecast.daily.length >= requestedDays) {
            var result = {
                success: true,
                current: cache.current,
                forecast: {
                    daily: cache.forecast.daily.slice(0, requestedDays),
                    hourly: cache.forecast.hourly
                },
                fromCache: true
            }
            deliver(result)
            return controller
        }
    }

    if (config.autoDetect === true) {
        fetchIpAndWeather(config, deliver, controller)
    } else if (!config.location) {
        deliver({ success: false, error: "Location is required" })
    } else {
        fetchWeatherInternal(config, deliver, controller)
    }
    return controller
}

function parseForecastOpenWeather(data) {
    var daily = []
    var hourly = []
    var seenDays = {}

    for (var i = 0; i < data.list.length && i < 40; i++) {
        var item = data.list[i]
        var date = new Date(item.dt * 1000)
        var dayKey = date.toDateString()

        if (hourly.length < 24) {
            hourly.push({
                time: date.getHours() + ":00",
                timestamp: date.getTime(),
                temp: Math.round(item.main.temp),
                code: item.weather[0].id,
                condition: normalizeCondition(item.weather[0].main),
                icon: item.weather[0].icon
            })
        }

        if (!seenDays[dayKey] && daily.length < 10) {
            var hours = date.getHours()
            if (hours >= 11 && hours <= 14) {
                seenDays[dayKey] = true
                daily.push({
                    day: date.getDay(),
                    temp: Math.round(item.main.temp),
                    temp_min: Math.round(item.main.temp_min),
                    temp_max: Math.round(item.main.temp_max),
                    code: item.weather[0].id,
                    condition: normalizeCondition(item.weather[0].main),
                    icon: item.weather[0].icon
                })
            }
        }
    }

    return { daily: daily, hourly: hourly }
}

function parseForecastWeatherAPI(forecastDays, units) {
    var daily = []
    var hourly = []

    for (var i = 0; i < forecastDays.length && i < 7; i++) {
        var day = forecastDays[i]
        var date = new Date(day.date)
        var imperial = units === "imperial"

        daily.push({
            day: date.getDay(),
            temp: Math.round(imperial ? day.day.avgtemp_f : day.day.avgtemp_c),
            temp_min: Math.round(imperial ? day.day.mintemp_f : day.day.mintemp_c),
            temp_max: Math.round(imperial ? day.day.maxtemp_f : day.day.maxtemp_c),
            humidity: day.day.avghumidity,
            wind_speed: Math.round(imperial ? day.day.maxwind_mph : day.day.maxwind_kph),
            precipitation_probability: day.day.daily_chance_of_rain,
            sunrise: day.astro ? parseAstroTime(day.date, day.astro.sunrise) : null,
            sunset: day.astro ? parseAstroTime(day.date, day.astro.sunset) : null,
            date: day.date,
            code: day.day.condition.code,
            condition: normalizeCondition(day.day.condition.text),
            icon: ""
        })

        if (i === 0 && day.hour) {
            for (var h = 0; h < day.hour.length && hourly.length < 8; h += 3) {
                var hour = day.hour[h]
                var hourDate = new Date(hour.time)
                hourly.push({
                    time: hourDate.getHours() + ":00",
                    timestamp: hourDate.getTime(),
                    temp: Math.round(imperial ? hour.temp_f : hour.temp_c),
                    code: hour.condition.code,
                    condition: normalizeCondition(hour.condition.text),
                    icon: ""
                })
            }
        }
    }

    return { daily: daily, hourly: hourly }
}

function parseForecastOpenMeteo(data) {
    var daily = []
    var hourly = []

    if (data.daily && data.daily.time) {
        for (var i = 0; i < data.daily.time.length; i++) {
            var date = new Date(data.daily.time[i])
            daily.push({
                day: date.getDay(),
                date: data.daily.time[i],
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
                sunrise: data.daily.sunrise ? data.daily.sunrise[i] : null,
                sunset: data.daily.sunset ? data.daily.sunset[i] : null,
                code: data.daily.weather_code ? data.daily.weather_code[i] : 0,
                condition: getOpenMeteoCondition(data.daily.weather_code ? data.daily.weather_code[i] : 0),
                icon: "",
                hasDetails: true
            })
        }
    }

    if (data.hourly && data.hourly.time) {
        for (var h = 0; h < data.hourly.time.length && hourly.length < 24; h++) {
            var hourDate = new Date(data.hourly.time[h])
            if (hourDate > new Date()) {
                hourly.push({
                    time: hourDate.getHours() + ":00",
                    timestamp: hourDate.getTime(),
                    temp: Math.round(data.hourly.temperature_2m[h]),
                    code: data.hourly.weather_code ? data.hourly.weather_code[h] : 0,
                    condition: getOpenMeteoCondition(data.hourly.weather_code ? data.hourly.weather_code[h] : 0),
                    precipitation: data.hourly.precipitation ? data.hourly.precipitation[h] : 0,
                    precipitation_probability: data.hourly.precipitation_probability ? data.hourly.precipitation_probability[h] : 0,
                    icon: ""
                })
            }
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

function normalizeCondition(text) {
    if (!text) return ""
    var t = text.trim()
    if (t === "Clouds") return "Cloudy"
    return t
}

function clearCache() {
    cache.current = null
    cache.forecast = null
    cache.timestamp = 0
    cache.key = ""
}

// Smart Clothing Suggestion based on weather conditions
function getClothingSuggestion(current, units) {
    if (!current) return null

    var temp = current.temp
    var code = current.code || 0
    var wind = current.wind_speed || 0
    var isMetric = (units !== "imperial")

    // Convert to Celsius for logic if imperial
    var tempC = isMetric ? temp : Math.round((temp - 32) * 5 / 9)
    var windKmh = isMetric ? wind : Math.round(wind * 1.60934)

    var suggestions = []

    // Rain/Snow check (WMO codes)
    var rainCodes = [51, 53, 55, 56, 57, 61, 63, 65, 66, 67, 80, 81, 82]
    var snowCodes = [71, 73, 75, 77, 85, 86]
    var stormCodes = [95, 96, 99]

    if (rainCodes.indexOf(code) >= 0 || stormCodes.indexOf(code) >= 0) {
        suggestions.push({ icon: "☔", text: "umbrella" })
    }

    if (snowCodes.indexOf(code) >= 0) {
        suggestions.push({ icon: "🧤", text: "gloves" })
    }

    // Temperature-based suggestions
    if (tempC <= 0) {
        suggestions.push({ icon: "🧥", text: "heavy coat" })
    } else if (tempC <= 10) {
        suggestions.push({ icon: "🧥", text: "coat" })
    } else if (tempC <= 18) {
        suggestions.push({ icon: "🧶", text: "sweater" })
    } else if (tempC >= 30) {
        suggestions.push({ icon: "🕶️", text: "sunglasses" })
    }

    // Wind chill
    if (windKmh > 40 && tempC < 15) {
        suggestions.push({ icon: "💨", text: "windbreaker" })
    }

    return suggestions.length > 0 ? suggestions : null
}
