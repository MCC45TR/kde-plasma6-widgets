import QtQuick
import org.kde.notification
import "NotificationRules.js" as NotificationRules

// NotificationManager - Handles weather notification logic
Item {
    id: notifManager

    required property var currentWeather
    required property var forecastHourly
    required property var forecastDaily
    required property string units
    required property var stateStore

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

    property double lastRoutineTimestamp: 0

    // Cooldown periods in milliseconds.
    readonly property int severeCooldown: 4 * 60 * 60 * 1000    // 4 hours
    readonly property int rainCooldown: 4 * 60 * 60 * 1000      // 4 hours
    readonly property int tempCooldown: 6 * 60 * 60 * 1000      // 6 hours for low/high temp
    readonly property int windCooldown: 6 * 60 * 60 * 1000      // 6 hours
    readonly property int uvCooldown: 12 * 60 * 60 * 1000       // 12 hours (UV is daily max usually)
    readonly property int routineWindowMinutes: 10

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
        var lastRoutineDate1 = stateStore.lastRoutineDate1 || ""
        var lastRoutineDate2 = stateStore.lastRoutineDate2 || ""

        var lastSevereNotify = stateStore.lastSevereNotify || 0
        var lastRainNotify = stateStore.lastRainNotify || 0
        var lastTempNotify = stateStore.lastTempNotify || 0
        var lastHighTempNotify = stateStore.lastHighTempNotify || 0
        var lastUvNotify = stateStore.lastUvNotify || 0
        var lastWindNotify = stateStore.lastWindNotify || 0

        // 1. Routine Notifications
        if (routineEnabled) {
            // Check global routine cooldown (2 mins) to avoid spamming multiple times in quick succession
            if (nowTime - lastRoutineTimestamp > 120000) { 
                 var sentAny = false
                 
                 // First routine time
                 if (lastRoutineDate1 !== todayStr) {
                      if (nowMin >= routineTime1 && nowMin < routineTime1 + routineWindowMinutes) {
                          sendRoutineNotification()
                          stateStore.lastRoutineDate1 = todayStr
                          sentAny = true
                      }
                 }
                 
                 // Second routine time
                 if (!sentAny && routineTime2Enabled && lastRoutineDate2 !== todayStr) {
                      if (nowMin >= routineTime2 && nowMin < routineTime2 + routineWindowMinutes) {
                          sendRoutineNotification()
                          stateStore.lastRoutineDate2 = todayStr
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
            var currentAlertCode = NotificationRules.weatherCode(currentWeather)
            if (severeWeatherCodes.indexOf(currentAlertCode) >= 0) {
                 if (nowTime - lastSevereNotify > severeCooldown) {
                    sendSevereWeatherNotification(currentAlertCode, -1)
                    stateStore.lastSevereNotify = nowTime
                    handledSevere = true
                }
            }
            else if (forecastHourly && forecastHourly.length > 0) {
                var upcomingSevere = checkUpcomingSevere()
                if (upcomingSevere && (nowTime - lastSevereNotify > severeCooldown)) {
                     sendSevereWeatherNotification(upcomingSevere.code, upcomingSevere.startIndex)
                     stateStore.lastSevereNotify = nowTime
                     handledSevere = true
                }
            }
        }

        // 3. Rain Alert (only if not severe)
        if (rainEnabled && !handledSevere && forecastHourly && forecastHourly.length > 0) {
            if (nowTime - lastSevereNotify > severeCooldown) { // Still respect severe cooldown
                var rainIncoming = checkUpcomingRain()
                if (rainIncoming && nowTime - lastRainNotify > rainCooldown) {
                    sendRainNotification(rainIncoming)
                    stateStore.lastRainNotify = nowTime
                }
            }
        }

        // 4. Low Temperature Alert
        if (temperatureDropEnabled && currentWeather.temp !== undefined) {
            var temp = currentWeather.temp
            var threshold = temperatureThreshold
            var isImperial = (units === "imperial")
            
            // Normalize the configured threshold to the active temperature unit.
            // Assuming config threshold is always in C (as per label). Convert to F if needed.
            if (isImperial) {
                threshold = (temperatureThreshold * 9 / 5) + 32
            }

            if (temp <= threshold) {
                if (nowTime - lastTempNotify > tempCooldown) {
                    sendLowTempNotification(temp)
                    stateStore.lastTempNotify = nowTime
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
                if (nowTime - lastHighTempNotify > tempCooldown) {
                    sendHighTempNotification(hTemp)
                    stateStore.lastHighTempNotify = nowTime
                }
            }
        }

        // 6. UV Index Alert
        if (notifyUvIndex && forecastDaily && forecastDaily.length > 0) {
            var today = forecastDaily[0]
            if (today.uv_index !== undefined && today.uv_index !== null) {
                if (today.uv_index >= notifyUvThreshold) {
                    if (nowTime - lastUvNotify > uvCooldown) {
                        sendUvNotification(today.uv_index)
                        stateStore.lastUvNotify = nowTime
                    }
                }
            }
        }

        // 7. Wind Alert
        if (notifyWind && currentWeather.wind_speed !== undefined) {
            var windSpeed = currentWeather.wind_speed
            var wThreshold = notifyWindThreshold

            if (windSpeed >= wThreshold) {
                if (nowTime - lastWindNotify > windCooldown) {
                    sendWindNotification(windSpeed)
                    stateStore.lastWindNotify = nowTime
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
        var dayName = Qt.locale().dayName(today.day, Locale.LongFormat).toUpperCase()
        
        var title = i18n("📅 Today is %1 and %2° %3", dayName, temp, i18n(condition))
        var body = ""
        
        for (var i = 1; i <= 3 && i < forecastDaily.length; i++) {
            var day = forecastDaily[i]
            var dName = Qt.locale().dayName(day.day, Locale.ShortFormat).toUpperCase()
            
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

        var changes = NotificationRules.collectDailyChanges(forecastHourly, Date.now(), 6)
        
        // No entries remain when the hourly forecast is empty or entirely in the past.
        if (changes.length === 0) {
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
        return NotificationRules.findUpcoming(forecastHourly, severeWeatherCodes, Date.now(), 6 * 60 * 60 * 1000)
    }

    function sendSevereWeatherNotification(code, startIndex) {
        var currentEvent = startIndex < 0
        var info = currentEvent ? {
            conditionName: currentWeather.condition,
            startTemp: Math.round(currentWeather.temp)
        } : analyzeEventDuration(startIndex, severeWeatherCodes)
        
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

        var body = currentEvent ? i18n("%1 is occurring now", i18n(info.conditionName)) : i18n("%1 expected between %2 - %3", i18n(info.conditionName), info.startTime, info.endTime)
        var unit = units === "metric" ? "°C" : "°F"
        body += currentEvent ? "\n" + i18n("Temperature: %1%2", info.startTemp, unit) : "\n" + i18n("Temperature: %1%2 → %3%4", info.startTemp, unit, info.endTemp, unit)
        
        var advice = getAdviceForCode(code)
        if (advice) {
            body += "\n" + advice
        }

        sendNotification(title, body, icon, true)
    }

    function checkUpcomingRain() {
        return NotificationRules.findUpcoming(forecastHourly, rainCodes, Date.now(), 3 * 60 * 60 * 1000)
    }

    function sendRainNotification(rainInfo) {
        var info = analyzeEventDuration(rainInfo.startIndex, rainCodes)
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

    function analyzeEventDuration(startIndex, codeList) {
        return NotificationRules.analyzeEventDuration(forecastHourly, startIndex, codeList)
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
        var displaySpeed = units === "imperial" ? speed * 0.621371 : speed
        var title = i18n("💨 Strong Wind Alert")
        var body = i18n("Wind speed: %1 %2", Math.round(displaySpeed), unit)
        body += "\n" + i18n("Secure loose objects and drive carefully.")
        sendNotification(title, body, "weather-wind", true)
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
