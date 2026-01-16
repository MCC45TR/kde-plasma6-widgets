.pragma library
// WeatherService.js - Weather data fetching with OpenWeatherMap + WeatherAPI fallback

var cache = {
    current: null,
    forecast: null,
    timestamp: 0,
    ttl: 5 * 60 * 1000 // 5 minutes
}

var currentProvider = "openweathermap" // or "weatherapi"

// OpenWeatherMap API
function fetchOpenWeatherMap(apiKey, location, units, callback) {
    var baseUrl = "https://api.openweathermap.org/data/2.5/"

    // Fetch current weather
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
                        visibility: data.visibility ? Math.round(data.visibility / 1000) : null, // km
                        wind_speed: data.wind ? Math.round(data.wind.speed * 3.6) : null, // m/s to km/h
                        wind_deg: data.wind ? data.wind.deg : null,
                        wind_gust: data.wind && data.wind.gust ? Math.round(data.wind.gust * 3.6) : null,
                        clouds: data.clouds ? data.clouds.all : null, // %
                        sunrise: data.sys ? data.sys.sunrise : null,
                        sunset: data.sys ? data.sys.sunset : null,
                        condition: data.weather[0].main,
                        description: data.weather[0].description,
                        icon: data.weather[0].icon,
                        code: data.weather[0].id,
                        location: data.name,
                        coord: { lat: data.coord.lat, lon: data.coord.lon },
                        timestamp: Date.now()
                    }

                    // Fetch forecast
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

// WeatherAPI.com fallback
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
                        condition: data.current.condition.text,
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

// Open-Meteo API (Free, no API key required)
function fetchOpenMeteo(location, units, callback) {
    // Step 1: Geocode city name to coordinates
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

                    // Step 2: Fetch weather data (10 days forecast) with extended current data
                    var tempUnit = units === "imperial" ? "&temperature_unit=fahrenheit&wind_speed_unit=mph" : "&temperature_unit=celsius&wind_speed_unit=kmh"
                    var weatherUrl = "https://api.open-meteo.com/v1/forecast?" +
                        "latitude=" + lat + "&longitude=" + lon +
                        "&current=temperature_2m,relative_humidity_2m,apparent_temperature,precipitation,weather_code,cloud_cover,pressure_msl,surface_pressure,wind_speed_10m,wind_direction_10m,wind_gusts_10m" +
                        "&daily=temperature_2m_max,temperature_2m_min,weather_code,sunrise,sunset,uv_index_max,precipitation_sum" +
                        "&forecast_days=10" +
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

                                    // Current weather with extended data
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
                                        condition: getOpenMeteoCondition(data.current.weather_code),
                                        description: getOpenMeteoCondition(data.current.weather_code),
                                        icon: "",
                                        code: data.current.weather_code,
                                        location: locationName,
                                        coord: { lat: lat, lon: lon },
                                        timestamp: Date.now()
                                    }

                                    // Parse forecast
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

// Fetch location from IP (ipinfo.io)
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
                        // Create a new config with the detected city
                        var newConfig = {
                            apiKey: config.apiKey,
                            apiKey2: config.apiKey2,
                            location: data.city,
                            units: config.units
                        }
                        // Proceed to fetch weather with detected city
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

// Internal function to maintain original fetch logic
function fetchWeatherInternal(config, callback) {
    var apiKey = config.apiKey || ""
    var apiKey2 = config.apiKey2 || ""
    var location = config.location || ""
    var units = config.units || "metric"
    var provider = config.provider || "openmeteo"

    console.log("Fetching weather using provider: " + provider)

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

    // Default: Open-Meteo (openmeteo) or fallback
    fetchOpenMeteo(location, units, function (result) {
        if (result.success) {
            cache.current = result.current
            cache.forecast = result.forecast
            cache.timestamp = Date.now()
        }
        callback(result)
    })
}

// Main fetch function with fallback
function fetchWeather(config, callback) {
    var now = Date.now()

    // Setup cache invalidation if needed
    // If the cache contains country name in location, we consider it invalid for the new display requirement
    var forceRefresh = false
    if (cache.current && cache.current.location && cache.current.location.indexOf(",") !== -1) {
        forceRefresh = true
    }

    // Return cached data if still valid and we don't need to force refresh
    if (!forceRefresh && cache.current && cache.forecast && (now - cache.timestamp) < cache.ttl) {
        callback({ success: true, current: cache.current, forecast: cache.forecast, fromCache: true })
        return
    }

    // If location is the default "Ankara" or empty, try auto-detection
    if (!config.location || config.location === "Ankara") {
        fetchIpAndWeather(config, callback)
    } else {
        fetchWeatherInternal(config, callback)
    }
}

// Parse OpenWeatherMap forecast (3-hour intervals)
function parseForecastOpenWeather(data) {
    var daily = []
    var hourly = []
    var seenDays = {}

    for (var i = 0; i < data.list.length && i < 40; i++) {
        var item = data.list[i]
        var date = new Date(item.dt * 1000)
        var dayKey = date.toDateString()

        // Hourly forecast (next 24 hours, every 3 hours)
        if (hourly.length < 24) {
            hourly.push({
                time: date.getHours() + ":00",
                temp: Math.round(item.main.temp),
                code: item.weather[0].id,
                condition: item.weather[0].main,
                icon: item.weather[0].icon
            })
        }

        // Daily forecast (one per day, use noon/midday data)
        if (!seenDays[dayKey] && daily.length < 10) {
            var hours = date.getHours()
            if (hours >= 11 && hours <= 14) { // Use midday data
                seenDays[dayKey] = true
                daily.push({
                    day: getDayName(date.getDay()),
                    temp: Math.round(item.main.temp),
                    temp_min: Math.round(item.main.temp_min),
                    temp_max: Math.round(item.main.temp_max),
                    code: item.weather[0].id,
                    condition: item.weather[0].main,
                    icon: item.weather[0].icon
                })
            }
        }
    }

    return { daily: daily, hourly: hourly }
}

// Parse WeatherAPI forecast
function parseForecastWeatherAPI(forecastDays) {
    var daily = []
    var hourly = []

    for (var i = 0; i < forecastDays.length && i < 7; i++) {
        var day = forecastDays[i]
        var date = new Date(day.date)

        daily.push({
            day: getDayName(date.getDay()),
            temp: Math.round(day.day.avgtemp_c),
            temp_min: Math.round(day.day.mintemp_c),
            temp_max: Math.round(day.day.maxtemp_c),
            code: day.day.condition.code,
            condition: day.day.condition.text,
            icon: ""
        })

        // Hourly forecast from first day
        if (i === 0 && day.hour) {
            for (var h = 0; h < day.hour.length && hourly.length < 8; h += 3) {
                var hour = day.hour[h]
                var hourDate = new Date(hour.time)
                hourly.push({
                    time: hourDate.getHours() + ":00",
                    temp: Math.round(hour.temp_c),
                    code: hour.condition.code,
                    condition: hour.condition.text,
                    icon: ""
                })
            }
        }
    }

    return { daily: daily, hourly: hourly }
}

// Parse Open-Meteo forecast
function parseForecastOpenMeteo(data) {
    var daily = []
    var hourly = []

    // Daily forecast (next 10 days)
    if (data.daily && data.daily.time) {
        for (var i = 0; i < data.daily.time.length && i < 10; i++) {
            var date = new Date(data.daily.time[i])
            daily.push({
                day: getDayName(date.getDay()),
                temp: Math.round((data.daily.temperature_2m_max[i] + data.daily.temperature_2m_min[i]) / 2),
                temp_min: Math.round(data.daily.temperature_2m_min[i]),
                temp_max: Math.round(data.daily.temperature_2m_max[i]),
                code: data.daily.weather_code ? data.daily.weather_code[i] : 0,
                condition: getOpenMeteoCondition(data.daily.weather_code ? data.daily.weather_code[i] : 0),
                icon: ""
            })
        }
    }

    // Hourly forecast (next 24 hours)
    if (data.hourly && data.hourly.time) {
        for (var h = 0; h < data.hourly.time.length && hourly.length < 24; h++) {
            var hourDate = new Date(data.hourly.time[h])
            if (hourDate > new Date()) { // Only future hours
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

// Open-Meteo WMO Weather interpretation codes to text
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

function getDayName(dayIndex) {
    var days = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]
    return days[dayIndex]
}

function clearCache() {
    cache.current = null
    cache.forecast = null
    cache.timestamp = 0
}
