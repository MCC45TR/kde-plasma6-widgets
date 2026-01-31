import QtQuick
import org.kde.plasma.plasma5support as P5Support

// NotificationManager - Handles weather notification logic
Item {
    id: notifManager

    // Required properties from parent
    required property var currentWeather
    required property var forecastHourly
    required property string units

    // Config properties
    property bool enabled: false
    property bool routineEnabled: false
    property int routineHour: 8
    property bool severeWeatherEnabled: true
    property bool rainEnabled: true
    property bool temperatureDropEnabled: false
    property int temperatureThreshold: 0

    // Cooldown tracking (prevent spam)
    property double lastRoutineNotify: 0
    property double lastSevereNotify: 0
    property double lastRainNotify: 0
    property double lastTempNotify: 0

    // Cooldown periods (milliseconds)
    readonly property int routineCooldown: 12 * 60 * 60 * 1000  // 12 hours
    readonly property int severeCooldown: 2 * 60 * 60 * 1000    // 2 hours
    readonly property int rainCooldown: 3 * 60 * 60 * 1000      // 3 hours
    readonly property int tempCooldown: 4 * 60 * 60 * 1000      // 4 hours

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

    // Notification data source
    P5Support.DataSource {
        id: notificationSource
        engine: "notifications"
    }

    function sendNotification(title, body, icon) {
        var service = notificationSource.serviceForSource("notification")
        var op = service.operationDescription("createNotification")
        op["appName"] = "MWeather"
        op["appIcon"] = icon || "weather-many-clouds"
        op["summary"] = title
        op["body"] = body
        op["expireTimeout"] = 8000
        service.startOperationCall(op)
    }

    // Check and send notifications based on current data
    function checkNotifications() {
        if (!enabled || !currentWeather) return

        var now = new Date().getTime()
        var currentHour = new Date().getHours()

        // 1. Routine Notification
        if (routineEnabled && currentHour === routineHour) {
            if (now - lastRoutineNotify > routineCooldown) {
                sendRoutineNotification()
                lastRoutineNotify = now
            }
        }

        // 2. Severe Weather Alert
        if (severeWeatherEnabled && currentWeather.code !== undefined) {
            if (severeWeatherCodes.indexOf(currentWeather.code) >= 0) {
                if (now - lastSevereNotify > severeCooldown) {
                    sendSevereWeatherNotification()
                    lastSevereNotify = now
                }
            }
        }

        // 3. Rain Alert (check hourly forecast)
        if (rainEnabled && forecastHourly && forecastHourly.length > 0) {
            var rainIncoming = checkUpcomingRain()
            if (rainIncoming && now - lastRainNotify > rainCooldown) {
                sendRainNotification(rainIncoming)
                lastRainNotify = now
            }
        }

        // 4. Temperature Drop Alert
        if (temperatureDropEnabled && currentWeather.temp !== undefined) {
            var temp = currentWeather.temp
            // Convert threshold if using Fahrenheit
            var threshold = temperatureThreshold
            if (units === "imperial") {
                threshold = (temperatureThreshold * 9 / 5) + 32
            }

            if (temp <= threshold) {
                if (now - lastTempNotify > tempCooldown) {
                    sendTemperatureNotification(temp)
                    lastTempNotify = now
                }
            }
        }
    }

    function sendRoutineNotification() {
        var temp = currentWeather.temp !== undefined ? Math.round(currentWeather.temp) : "--"
        var unit = units === "metric" ? "°C" : "°F"
        var condition = currentWeather.condition || i18n("Unknown")

        var title = i18n("Daily Weather Summary")
        var body = i18n("Current: %1%2, %3", temp, unit, condition)

        // Add high/low if available
        if (currentWeather.high !== undefined && currentWeather.low !== undefined) {
            body += "\n" + i18n("Today: High %1%2, Low %3%4",
                Math.round(currentWeather.high), unit,
                Math.round(currentWeather.low), unit)
        }

        sendNotification(title, body, "weather-clear")
    }

    function sendSevereWeatherNotification() {
        var condition = currentWeather.condition || i18n("Severe Weather")
        var title = i18n("⚠️ Weather Alert")
        var body = i18n("Current condition: %1", condition)

        var icon = "weather-storm"
        if (currentWeather.code >= 71 && currentWeather.code <= 77) {
            icon = "weather-snow"
        } else if (currentWeather.code === 45 || currentWeather.code === 48) {
            icon = "weather-fog"
        }

        sendNotification(title, body, icon)
    }

    function checkUpcomingRain() {
        // Check next 3 hours
        var hoursToCheck = Math.min(3, forecastHourly.length)
        for (var i = 0; i < hoursToCheck; i++) {
            var hour = forecastHourly[i]
            if (hour && hour.code !== undefined) {
                if (rainCodes.indexOf(hour.code) >= 0) {
                    return {
                        hoursAway: i + 1,
                        condition: hour.condition || i18n("Rain")
                    }
                }
            }
        }
        return null
    }

    function sendRainNotification(rainInfo) {
        var title = i18n("🌧️ Rain Expected")
        var body
        if (rainInfo.hoursAway === 1) {
            body = i18n("%1 expected within the next hour", rainInfo.condition)
        } else {
            body = i18n("%1 expected in about %2 hours", rainInfo.condition, rainInfo.hoursAway)
        }
        sendNotification(title, body, "weather-showers")
    }

    function sendTemperatureNotification(temp) {
        var unit = units === "metric" ? "°C" : "°F"
        var title = i18n("🥶 Low Temperature Alert")
        var body = i18n("Current temperature: %1%2", Math.round(temp), unit)
        sendNotification(title, body, "weather-freezing-rain")
    }

    // Hourly check timer
    Timer {
        interval: 60000 * 5  // Check every 5 minutes
        running: notifManager.enabled
        repeat: true
        onTriggered: {
            var currentHour = new Date().getHours()
            if (notifManager.routineEnabled && currentHour === notifManager.routineHour) {
                notifManager.checkNotifications()
            }
        }
    }
}
