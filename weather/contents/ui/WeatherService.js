.pragma library

var cache = {
    current: null,
    forecast: null,
    timestamp: 0,
    ttl: 5 * 60 * 1000
}

var currentProvider = "openweathermap"

function fetchOpenWeatherMap(apiKey, location, units, callback) {
    var baseUrl = "https://api.openweathermap.org/data/2.5/"

    var currentUrl = baseUrl + "weather?q=" + encodeURIComponent(location) + "&appid=" + apiKey + "&units=" + units

    var xhr = new XMLHttpRequest()
    xhr.open("GET", currentUrl)
    xhr.onreadystatechange = function () {
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
                        visibility: data.visibility ? Math.round(data.visibility / 1000) : null,
                        wind_speed: data.wind ? Math.round(data.wind.speed * 3.6) : null,
                        wind_deg: data.wind ? data.wind.deg : null,
                        wind_gust: data.wind && data.wind.gust ? Math.round(data.wind.gust * 3.6) : null,
                        clouds: data.clouds ? data.clouds.all : null,
                        sunrise: data.sys ? data.sys.sunrise : null,
                        sunset: data.sys ? data.sys.sunset : null,
                        condition: normalizeCondition(data.weather[0].main),
                        description: data.weather[0].description,
                        icon: data.weather[0].icon,
                        code: data.weather[0].id,
                        location: data.name,
                        coord: { lat: data.coord.lat, lon: data.coord.lon },
                        timestamp: Date.now()
                    }

                    var forecastUrl = baseUrl + "forecast?q=" + encodeURIComponent(location) + "&appid=" + apiKey + "&units=" + units
                    var xhr2 = new XMLHttpRequest()
                    xhr2.open("GET", forecastUrl)
                    xhr2.onreadystatechange = function () {
                        if (xhr2.readyState === XMLHttpRequest.DONE) {
                            if (xhr2.status === 200) {
                                try {
                                    var forecastData = JSON.parse(xhr2.responseText)
                                    var forecast = parseForecastOpenWeather(forecastData)
                                    callback({ success: true, current: current, forecast: forecast, provider: "openweathermap" })
                                } catch (e) {
                                    callback({ success: false, error: "Failed to parse forecast: " + e })
                                }
                            } else {
                                callback({ success: false, error: "Forecast API error: " + xhr2.status })
                            }
                        }
                    }
                    xhr2.send()
                } catch (e) {
                    callback({ success: false, error: "Failed to parse current weather: " + e })
                }
            } else if (xhr.status === 401) {
                callback({ success: false, error: "Invalid API key", code: 401 })
            } else {
                callback({ success: false, error: "API error: " + xhr.status, code: xhr.status })
            }
        }
    }
    xhr.send()
}

function fetchWeatherAPI(apiKey, location, callback) {
    var baseUrl = "https://api.weatherapi.com/v1/"
    var url = baseUrl + "forecast.json?key=" + apiKey + "&q=" + encodeURIComponent(location) + "&days=7&aqi=no&alerts=no"

    var xhr = new XMLHttpRequest()
    xhr.open("GET", url)
    xhr.onreadystatechange = function () {
        if (xhr.readyState === XMLHttpRequest.DONE) {
            if (xhr.status === 200) {
                try {
                    var data = JSON.parse(xhr.responseText)
                    var current = {
                        temp: Math.round(data.current.temp_c),
                        feels_like: Math.round(data.current.feelslike_c),
                        temp_min: Math.round(data.forecast.forecastday[0].day.mintemp_c),
                        temp_max: Math.round(data.forecast.forecastday[0].day.maxtemp_c),
                        condition: normalizeCondition(data.current.condition.text),
                        description: data.current.condition.text,
                        icon: "",
                        code: data.current.condition.code,
                        location: data.location.name,
                        timestamp: Date.now()
                    }

                    var forecast = parseForecastWeatherAPI(data.forecast.forecastday)
                    callback({ success: true, current: current, forecast: forecast, provider: "weatherapi" })
                } catch (e) {
                    callback({ success: false, error: "Failed to parse WeatherAPI data: " + e })
                }
            } else if (xhr.status === 401 || xhr.status === 403) {
                callback({ success: false, error: "Invalid API key", code: 401 })
            } else {
                callback({ success: false, error: "WeatherAPI error: " + xhr.status, code: xhr.status })
            }
        }
    }
    xhr.send()
}

function fetchOpenMeteo(location, units, callback) {
    var geocodeUrl = "https://geocoding-api.open-meteo.com/v1/search?name=" + encodeURIComponent(location) + "&count=1&language=en&format=json"

    var xhr = new XMLHttpRequest()
    xhr.open("GET", geocodeUrl)
    xhr.onreadystatechange = function () {
        if (xhr.readyState === XMLHttpRequest.DONE) {
            if (xhr.status === 200) {
                try {
                    var geoData = JSON.parse(xhr.responseText)
                    if (!geoData.results || geoData.results.length === 0) {
                        callback({ success: false, error: "Location not found" })
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
                        "&hourly=temperature_2m,weather_code&forecast_hours=48" +
                        "&timezone=auto" +
                        tempUnit

                    var xhr2 = new XMLHttpRequest()
                    xhr2.open("GET", weatherUrl)
                    xhr2.onreadystatechange = function () {
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
                                        visibility: data.current.visibility ? Math.round(data.current.visibility / 1000) : null,
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
                                    callback({ success: true, current: current, forecast: forecast, provider: "openmeteo" })
                                } catch (e) {
                                    callback({ success: false, error: "Failed to parse Open-Meteo data: " + e })
                                }
                            } else {
                                callback({ success: false, error: "Open-Meteo API error: " + xhr2.status })
                            }
                        }
                    }
                    xhr2.send()
                } catch (e) {
                    callback({ success: false, error: "Geocoding error: " + e })
                }
            } else {
                callback({ success: false, error: "Geocoding API error: " + xhr.status })
            }
        }
    }
    xhr.send()
}

function fetchIpAndWeather(config, callback) {
    var xhr = new XMLHttpRequest()
    var url = "https://ipinfo.io/json"
    xhr.open("GET", url)
    xhr.onreadystatechange = function () {
        if (xhr.readyState === XMLHttpRequest.DONE) {
            if (xhr.status === 200) {
                try {
                    var data = JSON.parse(xhr.responseText)
                    if (data.city) {
                        console.log("Detected location from IP: " + data.city)
                        var newConfig = {
                            apiKey: config.apiKey,
                            apiKey2: config.apiKey2,
                            location: data.city,
                            units: config.units
                        }
                        fetchWeatherInternal(newConfig, callback)
                    } else {
                        console.log("Could not detect city from IP, falling back to default.")
                        fetchWeatherInternal(config, callback)
                    }
                } catch (e) {
                    console.log("Failed to parse IP info: " + e)
                    fetchWeatherInternal(config, callback)
                }
            } else {
                console.log("IP detection failed: " + xhr.status)
                fetchWeatherInternal(config, callback)
            }
        }
    }
    xhr.send()
}

function fetchWeatherInternal(config, callback) {
    var apiKey = config.apiKey || ""
    var apiKey2 = config.apiKey2 || ""
    var location = config.location || ""
    var units = config.units || "metric"
    var provider = config.provider || "openmeteo"
    var forecastDays = config.forecastDays || 12

    console.log("Fetching weather using provider: " + provider + ", days: " + forecastDays)

    if (provider === "openweathermap") {
        if (apiKey) {
            fetchOpenWeatherMap(apiKey, location, units, function (result) {
                if (result.success) {
                    cache.current = result.current
                    cache.forecast = result.forecast
                    cache.timestamp = Date.now()
                    callback(result)
                } else {
                    callback(result)
                }
            })
        } else {
            callback({ success: false, error: "OpenWeatherMap API Key missing" })
        }
        return
    }

    if (provider === "weatherapi") {
        if (apiKey2) {
            fetchWeatherAPI(apiKey2, location, function (result) {
                if (result.success) {
                    cache.current = result.current
                    cache.forecast = result.forecast
                    cache.timestamp = Date.now()
                    callback(result)
                } else {
                    callback(result)
                }
            })
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
    })
}

function fetchWeather(config, callback) {
    var now = Date.now()

    var forceRefresh = false
    if (cache.current && cache.current.location && cache.current.location.indexOf(",") !== -1) {
        forceRefresh = true
    }

    if (!forceRefresh && cache.current && cache.forecast && (now - cache.timestamp) < cache.ttl) {
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
            callback(result)
            return
        }
    }

    if (!config.location || config.location === "Ankara") {
        fetchIpAndWeather(config, callback)
    } else {
        fetchWeatherInternal(config, callback)
    }
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

function parseForecastWeatherAPI(forecastDays) {
    var daily = []
    var hourly = []

    for (var i = 0; i < forecastDays.length && i < 7; i++) {
        var day = forecastDays[i]
        var date = new Date(day.date)

        daily.push({
            day: date.getDay(),
            temp: Math.round(day.day.avgtemp_c),
            temp_min: Math.round(day.day.mintemp_c),
            temp_max: Math.round(day.day.maxtemp_c),
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
                    temp: Math.round(hour.temp_c),
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
                    temp: Math.round(data.hourly.temperature_2m[h]),
                    code: data.hourly.weather_code ? data.hourly.weather_code[h] : 0,
                    condition: getOpenMeteoCondition(data.hourly.weather_code ? data.hourly.weather_code[h] : 0),
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

function getDayName(dayIndex) {
    return dayIndex
}

function clearCache() {
    cache.current = null
    cache.forecast = null
    cache.timestamp = 0
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

// AQI Description helper (for Open-Meteo AQI data)
function getAQIDescription(aqi, pm25, pm10) {
    if (!aqi && aqi !== 0) return null
    
    var level, color, advice
    
    if (aqi <= 50) {
        level = "Good"
        color = "#4caf50"
        advice = "Air quality is satisfactory"
    } else if (aqi <= 100) {
        level = "Moderate"
        color = "#ffeb3b"
        advice = "Acceptable for most"
    } else if (aqi <= 150) {
        level = "Unhealthy for Sensitive"
        color = "#ff9800"
        advice = "Limit outdoor activity"
    } else if (aqi <= 200) {
        level = "Unhealthy"
        color = "#f44336"
        advice = "Reduce outdoor activity"
    } else if (aqi <= 300) {
        level = "Very Unhealthy"
        color = "#9c27b0"
        advice = "Avoid outdoor activity"
    } else {
        level = "Hazardous"
        color = "#880e4f"
        advice = "Stay indoors"
    }
    
    return {
        aqi: aqi,
        level: level,
        color: color,
        advice: advice,
        pm25: pm25 || null,
        pm10: pm10 || null
    }
}
