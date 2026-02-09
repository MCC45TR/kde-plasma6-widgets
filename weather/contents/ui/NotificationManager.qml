import QtQuick
import org.kde.notification
import org.kde.plasma.plasmoid

// NotificationManager - Handles weather notification logic
Item {
    id: notifManager

    required property var currentWeather
    required property var forecastHourly
    required property var forecastDaily
    required property string units

    // Config properties
    property bool enabled: false
    property bool routineEnabled: false
    property string routineType: "forecast_3day"
    property int routineTime1: 480 // 08:00 default
    property int routineTime2: 1140 // 19:00 default
    property bool routineTime2Enabled: false
    
    // Alert Toggles
    property bool severeWeatherEnabled: true
    property bool rainEnabled: true
    property bool temperatureDropEnabled: false
    property int temperatureThreshold: 0
    
    // New Alerts
    property bool notifyHighTemp: false
    property int notifyHighTempThreshold: 30
    property bool notifyUvIndex: true
    property int notifyUvThreshold: 6
    property bool notifyWind: true
    property int notifyWindThreshold: 50 // km/h

    property double testNotificationTrigger: 0
    property double lastRoutineTimestamp: 0
    
    onTestNotificationTriggerChanged: {
        if (testNotificationTrigger > 0) {
            sendTestNotification()
        }
    }

    // Cooldown periods (milliseconds)
    // Routine notifications are now date-based, so no integer cooldown needed for them logic wise, 
    // but kept just in case or we simply skip it.
    readonly property int severeCooldown: 4 * 60 * 60 * 1000    // 4 hours
    readonly property int rainCooldown: 4 * 60 * 60 * 1000      // 4 hours
    readonly property int tempCooldown: 6 * 60 * 60 * 1000      // 6 hours for low/high temp
    readonly property int windCooldown: 6 * 60 * 60 * 1000      // 6 hours
    readonly property int uvCooldown: 12 * 60 * 60 * 1000       // 12 hours (UV is daily max usually)

    // Severe weather codes (WMO)
    readonly property var severeWeatherCodes: [
        45, 48,           // Fog
        65, 66, 67,       // Heavy rain, freezing rain
        71, 73, 75, 77,   // Snow
        82,               // Violent rain showers
        85, 86,           // Snow showers
        95, 96, 99        // Thunderstorm
    ]

    // Rain codes
    readonly property var rainCodes: [
        51, 53, 55,       // Drizzle
        61, 63, 65,       // Rain
        66, 67,           // Freezing rain
        80, 81, 82        // Rain showers
    ]

    // Notification object for Plasma 6
    Notification {
        id: weatherNotification
        componentName: "mweather"
        eventId: "notification"
    }

    function getEmojiForIcon(iconName, conditionText) {
        if (iconName && iconName !== "") {
            if (iconName.indexOf("storm") !== -1 || iconName.indexOf("thunder") !== -1) return "⛈️"
            if (iconName.indexOf("rain") !== -1 || iconName.indexOf("showers") !== -1 || iconName.indexOf("drizzle") !== -1) return "🌧️"
            if (iconName.indexOf("snow") !== -1) return "❄️"
            if (iconName.indexOf("fog") !== -1 || iconName.indexOf("mist") !== -1) return "🌫️"
            if (iconName.indexOf("clear") !== -1 || iconName.indexOf("sunny") !== -1) return "☀️"
            if (iconName.indexOf("few-clouds") !== -1) return "⛅"
            if (iconName.indexOf("clouds") !== -1 || iconName.indexOf("overcast") !== -1) return "☁️"
        }
        
        // Fallback to condition text (useful for OpenMeteo which might have empty icons)
        if (conditionText) {
            var lowerCond = conditionText.toLowerCase()
            if (lowerCond.indexOf("storm") !== -1 || lowerCond.indexOf("thunder") !== -1) return "⛈️"
            if (lowerCond.indexOf("rain") !== -1 || lowerCond.indexOf("drizzle") !== -1 || lowerCond.indexOf("shower") !== -1) return "🌧️"
            if (lowerCond.indexOf("snow") !== -1) return "❄️"
            if (lowerCond.indexOf("fog") !== -1 || lowerCond.indexOf("mist") !== -1) return "🌫️"
            if (lowerCond.indexOf("clear") !== -1 || lowerCond.indexOf("sunny") !== -1) return "☀️"
            if (lowerCond.indexOf("partly") !== -1) return "⛅"
            if (lowerCond.indexOf("cloud") !== -1 || lowerCond.indexOf("overcast") !== -1) return "☁️"
        }
        
        return "🌡️"
    }

    function getAdviceForCode(code) {
        if (code === 45 || code === 48) return i18n("Visibility is low. Drive carefully.")
        if ((code >= 71 && code <= 77) || code === 66 || code === 67 || code === 85 || code === 86) return i18n("Roads may be slippery. Allow extra travel time.")
        if (code >= 95) return i18n("Stay indoors and avoid open areas.")
        if (code === 65 || code === 82) return i18n("Heavy rain expected. Don't forget your umbrella!")
        return i18n("Stay safe and check local updates.")
    }


    function sendNotification(title, body, icon, isAlert) {
        weatherNotification.eventId = isAlert ? "alert" : "notification"
        weatherNotification.title = title
        weatherNotification.text = body
        weatherNotification.iconName = icon || "weather"
        weatherNotification.sendEvent()

        if (isAlert) {
            closeTimer.restart()
        } else {
            closeTimer.stop()
        }
    }

    Timer {
        id: closeTimer
        interval: 10000
        repeat: false
        onTriggered: weatherNotification.close()
    }

    // Check and send notifications based on current data
    function checkNotifications() {
        if (!enabled || !currentWeather) return

        var now = new Date()
        var nowMin = now.getHours() * 60 + now.getMinutes()
        var nowTime = now.getTime()
        var todayStr = Qt.formatDate(now, "yyyy-MM-dd")

        // Persistent timestamps
        var lastRoutineDate1 = Plasmoid.configuration.lastRoutineDate1 || ""
        var lastRoutineDate2 = Plasmoid.configuration.lastRoutineDate2 || ""
        
        var lastSevereNotify = Plasmoid.configuration.lastSevereNotify || 0
        var lastRainNotify = Plasmoid.configuration.lastRainNotify || 0
        var lastTempNotify = Plasmoid.configuration.lastTempNotify || 0
        var lastHighTempNotify = Plasmoid.configuration.lastHighTempNotify || 0
        var lastUvNotify = Plasmoid.configuration.lastUvNotify || 0
        var lastWindNotify = Plasmoid.configuration.lastWindNotify || 0

        // 1. Routine Notifications
        if (routineEnabled) {
            // Check global routine cooldown (2 mins) to avoid spamming multiple times in quick succession
            if (nowTime - lastRoutineTimestamp > 120000) { 
                 var sentAny = false
                 
                 // First routine time
                 if (lastRoutineDate1 !== todayStr) {
                      if (nowMin >= routineTime1) {
                          sendRoutineNotification()
                          Plasmoid.configuration.lastRoutineDate1 = todayStr
                          sentAny = true
                      }
                 }
                 
                 // Second routine time
                 if (!sentAny && routineTime2Enabled && lastRoutineDate2 !== todayStr) {
                      if (nowMin >= routineTime2) {
                          sendRoutineNotification()
                          Plasmoid.configuration.lastRoutineDate2 = todayStr
                          sentAny = true
                      }
                 }
                 
                 if (sentAny) {
                     lastRoutineTimestamp = nowTime
                 }
            }
        }

        // 2. Severe Weather Alert
        var handledSevere = false
        if (severeWeatherEnabled) {
            if (currentWeather.code !== undefined && severeWeatherCodes.indexOf(currentWeather.code) >= 0) {
                 if (now - lastSevereNotify > severeCooldown) {
                    sendSevereWeatherNotification(currentWeather.code, 0)
                    Plasmoid.configuration.lastSevereNotify = now
                    handledSevere = true
                }
            } 
            else if (forecastHourly && forecastHourly.length > 0) {
                var upcomingSevere = checkUpcomingSevere()
                if (upcomingSevere && (now - lastSevereNotify > severeCooldown)) {
                     sendSevereWeatherNotification(upcomingSevere.code, upcomingSevere.startIndex)
                     Plasmoid.configuration.lastSevereNotify = now
                     handledSevere = true
                }
            }
        }

        // 3. Rain Alert (only if not severe)
        if (rainEnabled && !handledSevere && forecastHourly && forecastHourly.length > 0) {
            if (now - lastSevereNotify > severeCooldown) { // Still respect severe cooldown
                var rainIncoming = checkUpcomingRain()
                if (rainIncoming && now - lastRainNotify > rainCooldown) {
                    sendRainNotification(rainIncoming)
                    Plasmoid.configuration.lastRainNotify = now
                }
            }
        }

        // 4. Low Temperature Alert
        if (temperatureDropEnabled && currentWeather.temp !== undefined) {
            var temp = currentWeather.temp
            var threshold = temperatureThreshold
            var isImperial = (units === "imperial")
            
            // Normalize threshold to current units if user set it in C but is using F, or vice-versa?
            // Assuming config threshold is always in C (as per label). Convert to F if needed.
            if (isImperial) {
                threshold = (temperatureThreshold * 9 / 5) + 32
            }

            if (temp <= threshold) {
                if (now - lastTempNotify > tempCooldown) {
                    sendLowTempNotification(temp)
                    Plasmoid.configuration.lastTempNotify = now
                }
            }
        }

        // 5. High Temperature Alert
        if (notifyHighTemp && currentWeather.temp !== undefined) {
            var hTemp = currentWeather.temp
            var hThreshold = notifyHighTempThreshold
            var hImperial = (units === "imperial")
            
            // Assume threshold in C from config
            if (hImperial) {
                hThreshold = (notifyHighTempThreshold * 9 / 5) + 32
            }

            if (hTemp >= hThreshold) {
                if (now - lastHighTempNotify > tempCooldown) {
                    sendHighTempNotification(hTemp)
                    Plasmoid.configuration.lastHighTempNotify = now
                }
            }
        }

        // 6. UV Index Alert
        if (notifyUvIndex && forecastDaily && forecastDaily.length > 0) {
            var today = forecastDaily[0]
            if (today.uv_index !== undefined && today.uv_index !== null) {
                if (today.uv_index >= notifyUvThreshold) {
                    if (now - lastUvNotify > uvCooldown) {
                        sendUvNotification(today.uv_index)
                        Plasmoid.configuration.lastUvNotify = now
                    }
                }
            }
        }

        // 7. Wind Alert
        if (notifyWind && currentWeather.wind_speed !== undefined) {
            var windSpeed = currentWeather.wind_speed // assume km/h if metric, mph if imperial
            var wThreshold = notifyWindThreshold

            // Threshold in config is likely km/h. Convert if units are imperial (mph).
            if (units === "imperial") {
                // 1 km/h = 0.621371 mph. Threshold 50 km/h -> ~31 mph.
                // Or user enters mph in config if they are US?
                // Let's assume config is km/h for simplicity and convert threshold to current unit system for comparison.
                wThreshold = notifyWindThreshold * 0.621371
            }

            if (windSpeed >= wThreshold) {
                if (now - lastWindNotify > windCooldown) {
                    sendWindNotification(windSpeed)
                    Plasmoid.configuration.lastWindNotify = now
                }
            }
        }
    }

    function sendRoutineNotification() {
        if (!forecastDaily || forecastDaily.length === 0) return

        // Dispatch based on Routine Type
        if (routineType === "daily_change") {
            sendDailyChangeNotification()
            return
        }

        // Default: Forecast 3 Day
        var today = forecastDaily[0]
        var temp = Math.round(today.temp_max) 
        var condition = today.condition
        var dayName = Qt.locale().dayName(new Date().getDay(), Locale.LongFormat).toUpperCase()
        
        var title = i18n("📅 Today is %1 and %2° %3", dayName, temp, i18n(condition))
        var body = ""
        
        for (var i = 1; i <= 3 && i < forecastDaily.length; i++) {
            var day = forecastDaily[i]
            var dIndex = (new Date().getDay() + i) % 7
            var dName = Qt.locale().dayName(dIndex, Locale.ShortFormat).toUpperCase()
            
            var dTemp = Math.round(day.temp_max) + "°" + (units === "metric" ? "C" : "F")
            var dEmoji = getEmojiForIcon(day.icon || "", day.condition || "")
            var dCond = day.condition
            
            body += dName + ": " + dTemp + " " + dEmoji + " " + i18n(dCond)
            if (i < 3 && i < forecastDaily.length - 1) body += "\n"
        }

        sendNotification(title, body, today.icon, false)
    }

    function sendDailyChangeNotification() {
        if (!forecastHourly || forecastHourly.length === 0) return

        var now = new Date()
        var currentHour = now.getHours()
        var changes = []
        var lastCode = -1
        
        // Find changes for the rest of today
        for (var i = 0; i < forecastHourly.length; i++) {
            var item = forecastHourly[i]
            var timeStr = item.time // "HH:mm"
            
            // Parse hour
            var h = parseInt(timeStr.split(":")[0])
            
            // Stop if we hit the next day (00:00)
            if (timeStr === "00:00" && i > 0) break
            
            // Only consider future hours (or current hour)
            if (h >= currentHour) {
                var code = item.code
                var cond = item.condition
                var temp = Math.round(item.temp)
                
                // If code changes (or it's the first relevant entry to show start state)
                if (changes.length === 0 || code !== lastCode) {
                    changes.push({
                        time: timeStr,
                        cond: cond,
                        temp: temp,
                        icon: item.icon
                    })
                    lastCode = code
                }
            }
        }
        
        // Fallback if no changes found (e.g. end of day or stable)
        // If stable, we should have at least the first entry if 'changes' logic above allows it.
        // changes.length === 0 only if forecastHourly is empty or all in past.
        
        if (changes.length === 0) {
            // Should not happen if data is valid and currentHour is within range
            // But if it does, fallback to 3-day
             var today = forecastDaily[0]
             sendNotification(i18n("📅 Weather Update"), i18n("No significant changes for the rest of the day."), today.icon, false)
             return
        }
        
        var title = i18n("📅 Daily Weather Changes")
        var body = ""
        var unit = units === "metric" ? "°C" : "°F"
        
        // Limit to 5 entries to fit notification
        var limit = Math.min(changes.length, 5)
        
        for (var j = 0; j < limit; j++) {
            var c = changes[j]
            var emoji = getEmojiForIcon(c.icon, c.cond)
            body += c.time + ": " + emoji + " " + i18n(c.cond) + " (" + c.temp + unit + ")"
            if (j < limit - 1) body += "\n"
        }
        
        // Add "..." if truncated
        if (changes.length > limit) {
             body += "\n..."
        }
        
        sendNotification(title, body, changes[0].icon, false)
    }

    function checkUpcomingSevere() {
        var lookahead = Math.min(6, forecastHourly.length)
        for (var i = 0; i < lookahead; i++) {
            var code = forecastHourly[i].code
            if (severeWeatherCodes.indexOf(code) >= 0) {
                return { code: code, startIndex: i }
            }
        }
        return null
    }

    function sendSevereWeatherNotification(code, startIndex) {
        var info = analyzeEventDuration(code, startIndex, severeWeatherCodes)
        
        var title = i18n("⚠️ Weather Alert")
        var icon = "weather-storm"

        if (code >= 95) {
             title = i18n("⛈️ Thunderstorm Warning")
        } else if (code >= 71 || code === 85 || code === 86) {
             icon = "weather-snow"
             title = i18n("❄️ Snow Warning")
        } else if (code === 45 || code === 48) {
             icon = "weather-fog"
             title = i18n("🌫️ Dense Fog Warning")
        } else if (code === 65 || code === 82) {
             icon = "weather-showers"
             title = i18n("🌧️ Heavy Rain Warning")
        }

        var body = i18n("%1 expected between %2 - %3", i18n(info.conditionName), info.startTime, info.endTime)
        var unit = units === "metric" ? "°C" : "°F"
        body += "\n" + i18n("Temperature: %1%2 → %3%4", info.startTemp, unit, info.endTemp, unit)
        
        var advice = getAdviceForCode(code)
        if (advice) {
            body += "\n" + advice
        }

        sendNotification(title, body, icon, true)
    }

    function checkUpcomingRain() {
        var lookahead = Math.min(3, forecastHourly.length)
        for (var i = 0; i < lookahead; i++) {
            var code = forecastHourly[i].code
            if (rainCodes.indexOf(code) >= 0) {
                 return { code: code, startIndex: i }
            }
        }
        return null
    }

    function sendRainNotification(rainInfo) {
        var info = analyzeEventDuration(rainInfo.code, rainInfo.startIndex, rainCodes)
        var title = i18n("🌧️ Rain Forecast")
        var body = i18n("Rain expected between %1 - %2", info.startTime, info.endTime)
        var unit = units === "metric" ? "°C" : "°F"
        
        body += "\n" + i18n("Temperature: %1%2", info.startTemp, unit)

        if (info.maxProb > 0) {
            body += "\n" + i18n("Chance of Rain: %1%", info.maxProb)
        }
        if (info.totalPrecip > 0) {
            body += "\n" + i18n("Precipitation: %1 mm", info.totalPrecip)
        }

        body += "\n" + i18n("Don't forget your umbrella!")
        
        sendNotification(title, body, "weather-showers", true)
    }

    function analyzeEventDuration(targetCode, startIndex, codeList) {
        if (!forecastHourly || forecastHourly.length === 0) return { startTime: "--", endTime: "--", startTemp: 0, endTemp: 0, conditionName: "", totalPrecip: 0, maxProb: 0 }

        var startItem = forecastHourly[startIndex]
        var startTemp = Math.round(startItem.temp)
        var conditionName = startItem.condition
        var startTime = startItem.time 

        var endIndex = startIndex
        for (var i = startIndex + 1; i < forecastHourly.length; i++) {
            var c = forecastHourly[i].code
            if (codeList.indexOf(c) < 0) {
                break
            }
            endIndex = i
        }

        var totalPrecip = 0.0
        var maxProb = 0

        for (var k = startIndex; k <= endIndex; k++) {
            var item = forecastHourly[k]
            if (item.precipitation !== undefined) totalPrecip += item.precipitation
            if (item.precipitation_probability !== undefined) {
                if (item.precipitation_probability > maxProb) maxProb = item.precipitation_probability
            }
        }

        var endItem = forecastHourly[endIndex]
        var endTemp = Math.round(endItem.temp)
        var endTime = endItem.time
        
        if (startIndex === endIndex) {
             var h = parseInt(endTime.split(":")[0])
             var nextH = (h + 1) % 24
             endTime = nextH + ":00"
        }

        return {
            startTime: startTime,
            endTime: endTime,
            startTemp: startTemp,
            endTemp: endTemp,
            conditionName: conditionName,
            totalPrecip: parseFloat(totalPrecip.toFixed(1)),
            maxProb: maxProb
        }
    }

    function sendLowTempNotification(temp) {
        var unit = units === "metric" ? "°C" : "°F"
        var title = i18n("🥶 Low Temperature Alert")
        var body = i18n("Current temperature: %1%2", Math.round(temp), unit)
        sendNotification(title, body, "weather-freezing-rain", true)
    }

    function sendHighTempNotification(temp) {
        var unit = units === "metric" ? "°C" : "°F"
        var title = i18n("🔥 High Temperature Alert")
        var body = i18n("Current temperature: %1%2", Math.round(temp), unit)
        body += "\n" + i18n("Stay hydrated and avoid direct sunlight.")
        sendNotification(title, body, "weather-clear", true)
    }

    function sendUvNotification(uvIndex) {
        var title = i18n("☀️ High UV Index Alert")
        var body = i18n("Current UV Index: %1", uvIndex)
        body += "\n" + i18n("Use sunscreen and wear protective clothing.")
        sendNotification(title, body, "weather-clear", true)
    }

    function sendWindNotification(speed) {
        var unit = units === "metric" ? "km/h" : "mph"
        // If speed is in km/h but units are imperial, convert for display? 
        // WeatherService usually provides raw values in metric or imperial based on request.
        // But here we just display what we have.
        var title = i18n("💨 Strong Wind Alert")
        var body = i18n("Wind speed: %1 %2", Math.round(speed), unit)
        body += "\n" + i18n("Secure loose objects and drive carefully.")
        sendNotification(title, body, "weather-wind", true)
    }

    function sendTestNotification() {
        // Try to verify if routine or severe is better based on current logic, but for test we usually force routine if nothing severe
        // Or we can just send routine as the "Default" test
        sendRoutineNotification()
        
        // Visual feedback if routine didn't send (e.g. no daily forecast)
        if (!forecastDaily || forecastDaily.length === 0) {
            sendNotification(i18n("Test Notification"), i18n("Weather data is missing, cannot generate full report."), "weather-clear", false)
        }
    }

    onRoutineEnabledChanged: checkNotifications()
    onRoutineTime1Changed: checkNotifications()
    onRoutineTime2Changed: checkNotifications()
    onRoutineTime2EnabledChanged: checkNotifications()

    Timer {
        id: checkTimer
        interval: 30000 // Check every 30 seconds
        running: notifManager.enabled
        repeat: true
        onTriggered: notifManager.checkNotifications()
    }
}
