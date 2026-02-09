import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.notification

Item {
    id: configRoot

    property var title
    
    // Notification object for testing
    Notification {
        id: demoNotification
        componentName: "mweather"
        eventId: "notification"
    }
    
    function sendNotification(title, body, icon, isAlert) {
        demoNotification.eventId = isAlert ? "alert" : "notification"
        demoNotification.title = title
        demoNotification.text = body
        demoNotification.iconName = icon
        demoNotification.sendEvent()

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
        onTriggered: demoNotification.close()
    }
    // Helper functions for time conversion
    function minutesToTime(minutes) {
        var h = Math.floor(minutes / 60)
        var m = minutes % 60
        return h.toString().padStart(2, '0') + ":" + m.toString().padStart(2, '0')
    }

    function timeToMinutes(text) {
        var parts = text.split(":")
        if (parts.length !== 2) return 0
        var h = parseInt(parts[0])
        var m = parseInt(parts[1])
        if (isNaN(h) || isNaN(m)) return 0
        return h * 60 + m
    }

    // Notification settings bindings
    property alias cfg_notifyEnabled: masterToggle.checked
    property alias cfg_notifyRoutineEnabled: routineToggle.checked
    property alias cfg_notifyRoutineType: routineTypeCombo.currentValue
    property alias cfg_notifyRoutineTime1: routineTime1Spin.value
    property alias cfg_notifyRoutineTime2: routineTime2Spin.value
    property alias cfg_notifyRoutineTime2Enabled: routineTime2Toggle.checked
    property alias cfg_notifySevereWeather: severeToggle.checked
    property alias cfg_notifyRain: rainToggle.checked
    property alias cfg_notifyTemperatureDrop: tempDropToggle.checked
    property alias cfg_notifyTemperatureThreshold: tempThresholdSpin.value
    property alias cfg_notifyHighTemp: highTempToggle.checked
    property alias cfg_notifyHighTempThreshold: highTempThresholdSpin.value
    property alias cfg_notifyUvIndex: uvToggle.checked
    property alias cfg_notifyUvThreshold: uvThresholdSpin.value
    property alias cfg_notifyWind: windToggle.checked
    property alias cfg_notifyWindThreshold: windThresholdSpin.value

    // Defaults (required by Plasma config system)
    property bool cfg_notifyEnabledDefault: false
    property bool cfg_notifyRoutineEnabledDefault: false
    property string cfg_notifyRoutineTypeDefault: "forecast_3day"
    property int cfg_notifyRoutineTime1Default: 480
    property int cfg_notifyRoutineTime2Default: 1140 // 19:00
    property bool cfg_notifyRoutineTime2EnabledDefault: false
    property bool cfg_notifySevereWeatherDefault: true
    property bool cfg_notifyRainDefault: true
    property bool cfg_notifyTemperatureDropDefault: false
    property int cfg_notifyTemperatureThresholdDefault: 0
    property bool cfg_notifyHighTempDefault: false
    property int cfg_notifyHighTempThresholdDefault: 30
    property bool cfg_notifyUvIndexDefault: true
    property int cfg_notifyUvThresholdDefault: 6
    property bool cfg_notifyWindDefault: true
    property int cfg_notifyWindThresholdDefault: 50

    // Missing properties to silence "Setting initial properties failed" errors
    property string cfg_apiKey
    property string cfg_apiKeyDefault
    property string cfg_apiKey2
    property string cfg_apiKey2Default
    property string cfg_weatherProvider
    property string cfg_weatherProviderDefault
    property string cfg_locationMode
    property string cfg_locationModeDefault
    property string cfg_location
    property string cfg_locationDefault
    property string cfg_location2
    property string cfg_location2Default
    property string cfg_location3
    property string cfg_location3Default
    property string cfg_units
    property string cfg_unitsDefault
    property bool cfg_useSystemUnits
    property bool cfg_useSystemUnitsDefault
    property int cfg_updateInterval
    property int cfg_updateIntervalDefault
    property string cfg_cachedWeather
    property string cfg_cachedWeatherDefault
    property double cfg_lastUpdate
    property double cfg_lastUpdateDefault
    property string cfg_iconPack
    property string cfg_iconPackDefault
    property bool cfg_useCustomFont
    property bool cfg_useCustomFontDefault
    property string cfg_customFontFamily
    property string cfg_customFontFamilyDefault
    property double cfg_backgroundOpacity
    property double cfg_backgroundOpacityDefault
    property string cfg_panelMode
    property string cfg_panelModeDefault
    property string cfg_layoutMode
    property string cfg_layoutModeDefault
    property int cfg_panelFontSize
    property int cfg_panelFontSizeDefault
    property int cfg_panelIconSize
    property int cfg_panelIconSizeDefault
    property int cfg_forecastDays
    property int cfg_forecastDaysDefault
    property int cfg_edgeMargin
    property int cfg_edgeMarginDefault
    property bool cfg_showForecastUnits
    property bool cfg_showForecastUnitsDefault
    property string cfg_cornerRadius
    property string cfg_cornerRadiusDefault
    property string cfg_lastRoutineDate1
    property string cfg_lastRoutineDate1Default
    property string cfg_lastRoutineDate2
    property string cfg_lastRoutineDate2Default
    property double cfg_lastSevereNotify
    property double cfg_lastSevereNotifyDefault
    property double cfg_lastRainNotify
    property double cfg_lastRainNotifyDefault
    property double cfg_lastTempNotify
    property double cfg_lastTempNotifyDefault
    property double cfg_lastHighTempNotify
    property double cfg_lastHighTempNotifyDefault
    property double cfg_lastUvNotify
    property double cfg_lastUvNotifyDefault
    property double cfg_lastWindNotify
    property double cfg_lastWindNotifyDefault
    property double cfg_triggerTestNotification
    property double cfg_triggerTestNotificationDefault


    ScrollView {
        id: scrollView
        anchors.fill: parent
        clip: true
        ScrollBar.vertical.policy: ScrollBar.AsNeeded
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

        ColumnLayout {
            width: scrollView.availableWidth
            spacing: 15

            // Test Mode Section
            GroupBox {
                title: i18n("Test Notifications")
                Layout.fillWidth: true
                
                ColumnLayout {
                    anchors.fill: parent
                    spacing: 10
                    
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10
                        
                        Switch {
                            id: testModeSwitch
                        }
                        Label {
                            text: i18n("Enable test mode")
                            Layout.fillWidth: true
                        }
                    }
                    
                    // Test buttons - only visible when test mode is enabled
                    Flow {
                        Layout.fillWidth: true
                        spacing: 8
                        visible: testModeSwitch.checked
                        
                        Button {
                            text: i18n("General")
                            icon.name: "weather-clear"
                            onClicked: configRoot.sendNotification(
                                i18n("Test Notification"),
                                i18n("Weather notifications are functioning correctly."),
                                "weather-clear",
                                false
                            )
                        }
                        
                        Button {
                            text: i18n("Routine")
                            icon.name: "weather-few-clouds"
                            onClicked: {
                                var type = routineTypeCombo.currentValue
                                if (type === "daily_change") {
                                    configRoot.sendNotification(
                                        i18n("📅 Daily Weather Changes"),
                                        i18n("08:00: ☀️ Sunny (12°C)\n11:00: ⛅ Partly Cloudy (15°C)\n14:00: 🌧️ Light Rain (14°C)\n17:00: ☁️ Cloudy (13°C)\n20:00: 🌙 Clear (10°C)"),
                                        "weather-showers",
                                        false
                                    )
                                } else {
                                    configRoot.sendNotification(
                                        i18n("📅 Today is SUNDAY, 10°C Cloudy"),
                                        i18n("MON: 6°C 🌪️ Storm\nTUE: 15°C 🌧️ Rainy\nWED: 20°C ☀️ Sunny\nTHU: 17°C ⛅ Partly Cloudy"),
                                        "weather-few-clouds",
                                        false
                                    )
                                }
                            }
                        }
                        
                        Button {
                            text: i18n("Storm")
                            icon.name: "weather-storm"
                            onClicked: configRoot.sendNotification(
                                i18n("⛈️ Thunderstorm Warning"),
                                i18n("Thunderstorm expected between 14:00 - 18:00\nTemperature: 22°C → 18°C\nStay indoors and avoid open areas."),
                                "weather-storm",
                                true
                            )
                        }
                        
                        Button {
                            text: i18n("Rain")
                            icon.name: "weather-showers"
                            onClicked: configRoot.sendNotification(
                                i18n("🌧️ Rain Forecast"),
                                i18n("Rain expected between 10:00 - 16:00\nTemperature: 15°C\nChance of Rain: 80%\nPrecipitation: 4.5 mm\nDon't forget your umbrella!"),
                                "weather-showers",
                                true
                            )
                        }
                        
                        Button {
                            text: i18n("Snow")
                            icon.name: "weather-snow"
                            onClicked: configRoot.sendNotification(
                                i18n("❄️ Snow Warning"),
                                i18n("Snowfall expected between 06:00 - 12:00\nTemperature: -3°C → -5°C\nRoads may be slippery."),
                                "weather-snow",
                                true
                            )
                        }
                        
                        Button {
                            text: i18n("Fog")
                            icon.name: "weather-fog"
                            onClicked: configRoot.sendNotification(
                                i18n("🌫️ Dense Fog Warning"),
                                i18n("Dense fog expected between 05:00 - 09:00\nVisibility: Low\nTemperature: 8°C\nDrive carefully."),
                                "weather-fog",
                                true
                            )
                        }
                        
                        Button {
                            text: i18n("Wind")
                            icon.name: "weather-wind"
                            onClicked: configRoot.sendNotification(
                                i18n("💨 Strong Wind Alert"),
                                i18n("Wind speed: 65 km/h\nSecure loose objects."),
                                "weather-wind",
                                true
                            )
                        }

                        Button {
                            text: i18n("UV Index")
                            icon.name: "weather-clear"
                            onClicked: configRoot.sendNotification(
                                i18n("☀️ High UV Index Alert"),
                                i18n("Current UV Index: 8\nUse sunscreen and wear protective clothing."),
                                "weather-clear",
                                true
                            )
                        }
                        
                        Button {
                            text: i18n("High Temp")
                            icon.name: "weather-clear"
                            onClicked: configRoot.sendNotification(
                                i18n("🔥 High Temperature Alert"),
                                i18n("Current temperature: 35°C\nStay hydrated."),
                                "weather-clear",
                                true
                            )
                        }

                        Button {
                            text: i18n("Low Temp")
                            icon.name: "weather-freezing-rain"
                            onClicked: configRoot.sendNotification(
                                i18n("🥶 Low Temperature Alert"),
                                i18n("Current temperature: -5°C"),
                                "weather-freezing-rain",
                                true
                            )
                        }
                    }
                    
                    Label {
                        text: i18n("Click buttons to test individual notification types")
                        font.pixelSize: 11
                        opacity: 0.6
                        visible: testModeSwitch.checked
                    }
                }
            }

            // Master Toggle
            GroupBox {
                title: i18n("Weather Notifications")
                Layout.fillWidth: true

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 12

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Switch {
                            id: masterToggle
                        }
                        Label {
                            text: i18n("Enable weather notifications")
                            font.bold: true
                            Layout.fillWidth: true
                        }
                    }

                    Label {
                        text: i18n("When enabled, the widget will send Plasma desktop notifications based on weather conditions.")
                        font.pixelSize: 11
                        opacity: 0.7
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }
                }
            }

            // Routine Notifications
            GroupBox {
                title: i18n("Routine Notifications")
                Layout.fillWidth: true
                enabled: masterToggle.checked
                opacity: enabled ? 1.0 : 0.5

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 10

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Switch {
                            id: routineToggle
                        }
                        Label {
                            text: i18n("Daily weather summary")
                            Layout.fillWidth: true
                        }
                    }


                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10
                        enabled: routineToggle.checked
                        opacity: enabled ? 1.0 : 0.5

                        Label {
                            text: i18n("Description:")
                        }
                        ComboBox {
                            id: routineTypeCombo
                            Layout.fillWidth: true
                            textRole: "text"
                            valueRole: "value"
                            model: [
                                { text: i18n("3-Day Forecast Summary"), value: "forecast_3day" },
                                { text: i18n("Today's Weather Changes"), value: "daily_change" }
                            ]
                        }
                    }

                    // First Time
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10
                        enabled: routineToggle.checked
                        opacity: enabled ? 1.0 : 0.5

                        Label {
                            text: i18n("Notification time 1:")
                            Layout.preferredWidth: 120
                        }
                        SpinBox {
                            id: routineTime1Spin
                            from: 0
                            to: 1439
                            value: 480 // 08:00
                            editable: true
                            stepSize: 15

                            validator: RegularExpressionValidator { regularExpression: /^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$/ }

                            textFromValue: function(value, locale) {
                                return configRoot.minutesToTime(value)
                            }
                            valueFromText: function(text, locale) {
                                return configRoot.timeToMinutes(text)
                            }
                            
                            onValueChanged: {
                                if (value === routineTime2Spin.value && routineTime2Toggle.checked) {
                                    // Visual warning logic could go here, for now relying on user noticing
                                }
                            }
                        }
                    }

                    // Second Time
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10
                        enabled: routineToggle.checked
                        opacity: enabled ? 1.0 : 0.5

                        CheckBox {
                            id: routineTime2Toggle
                            text: i18n("Enable second time")
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10
                        enabled: routineToggle.checked && routineTime2Toggle.checked
                        opacity: enabled ? 1.0 : 0.5

                        Label {
                            text: i18n("Notification time 2:")
                            Layout.preferredWidth: 120
                        }
                        SpinBox {
                            id: routineTime2Spin
                            from: 0
                            to: 1439
                            value: 1140 // 19:00
                            editable: true
                            stepSize: 15
                            
                            validator: RegularExpressionValidator { regularExpression: /^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$/ }

                            textFromValue: function(value, locale) {
                                return configRoot.minutesToTime(value)
                            }
                            valueFromText: function(text, locale) {
                                return configRoot.timeToMinutes(text)
                            }
                        }
                        
                        Label {
                            text: i18n("Duplicate time!")
                            color: Kirigami.Theme.negativeTextColor
                            visible: routineTime2Spin.value === routineTime1Spin.value
                        }
                    }

                    Label {
                        text: i18n("Receive a daily notification with current weather and today's forecast.")
                        font.pixelSize: 11
                        opacity: 0.7
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }
                }
            }

            // Severe Weather Alerts
            GroupBox {
                title: i18n("Weather Alerts")
                Layout.fillWidth: true
                enabled: masterToggle.checked
                opacity: enabled ? 1.0 : 0.5

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 12

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Switch {
                            id: severeToggle
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Label {
                                text: i18n("Severe weather alerts")
                            }
                            Label {
                                text: i18n("Thunderstorm, heavy snow, dense fog")
                                font.pixelSize: 10
                                opacity: 0.6
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Switch {
                            id: rainToggle
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Label {
                                text: i18n("Rain forecast alert")
                            }
                            Label {
                                text: i18n("Notify when rain is expected in the next few hours")
                                font.pixelSize: 10
                                opacity: 0.6
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Switch {
                            id: windToggle
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Label {
                                text: i18n("Strong wind alert")
                            }
                            RowLayout {
                                Label {
                                    text: i18n("Threshold:")
                                    font.pixelSize: 10
                                    opacity: 0.6
                                }
                                SpinBox {
                                    id: windThresholdSpin
                                    from: 10
                                    to: 200
                                    value: 50
                                    stepSize: 5
                                    editable: true
                                    font.pixelSize: 10
                                    
                                    textFromValue: function(value, locale) {
                                        return value + " km/h"
                                    }
                                    valueFromText: function(text, locale) {
                                        return parseInt(text.replace(" km/h", "")) || 50
                                    }
                                }
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Switch {
                            id: uvToggle
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Label {
                                text: i18n("High UV Index alert")
                            }
                            RowLayout {
                                Label {
                                    text: i18n("Threshold:")
                                    font.pixelSize: 10
                                    opacity: 0.6
                                }
                                SpinBox {
                                    id: uvThresholdSpin
                                    from: 1
                                    to: 11
                                    value: 6
                                    editable: true
                                    font.pixelSize: 10
                                    
                                    textFromValue: function(value, locale) {
                                        return "UV " + value
                                    }
                                    valueFromText: function(text, locale) {
                                        return parseInt(text.replace("UV ", "")) || 6
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Temperature Alerts
            GroupBox {
                title: i18n("Temperature Alerts")
                Layout.fillWidth: true
                enabled: masterToggle.checked
                opacity: enabled ? 1.0 : 0.5

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 10

                    // Low Temp
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Switch {
                            id: tempDropToggle
                        }
                        Label {
                            text: i18n("Low temperature warning")
                            Layout.fillWidth: true
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10
                        enabled: tempDropToggle.checked
                        opacity: enabled ? 1.0 : 0.5

                        Label {
                            text: i18n("Alert when below:")
                        }
                        SpinBox {
                            id: tempThresholdSpin
                            from: -50
                            to: 50
                            value: 0
                            editable: true

                            textFromValue: function(value, locale) {
                                return value + "°C"
                            }
                            valueFromText: function(text, locale) {
                                return parseInt(text.replace("°C", "")) || 0
                            }
                        }
                    }

                    // High Temp
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Switch {
                            id: highTempToggle
                        }
                        Label {
                            text: i18n("High temperature warning")
                            Layout.fillWidth: true
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10
                        enabled: highTempToggle.checked
                        opacity: enabled ? 1.0 : 0.5

                        Label {
                            text: i18n("Alert when above:")
                        }
                        SpinBox {
                            id: highTempThresholdSpin
                            from: 20
                            to: 60
                            value: 30
                            editable: true

                            textFromValue: function(value, locale) {
                                return value + "°C"
                            }
                            valueFromText: function(text, locale) {
                                return parseInt(text.replace("°C", "")) || 30
                            }
                        }
                    }

                    Label {
                        text: i18n("Receive alerts when temperature goes beyond your thresholds.")
                        font.pixelSize: 11
                        opacity: 0.7
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }
                }
            }

            // Info Box
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: infoCol.height + 20
                color: Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.1)
                radius: 8
                visible: masterToggle.checked

                ColumnLayout {
                    id: infoCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 10
                    spacing: 4

                    RowLayout {
                        spacing: 8
                        Kirigami.Icon {
                            source: "dialog-information"
                            Layout.preferredWidth: 16
                            Layout.preferredHeight: 16
                        }
                        Label {
                            text: i18n("How it works")
                            font.bold: true
                        }
                    }
                    Label {
                        text: i18n("Notifications are checked each time weather data is refreshed. To avoid spam, each alert type has a cooldown period.")
                        font.pixelSize: 11
                        opacity: 0.8
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }
                }
            }

            Item { Layout.fillHeight: true }
        }
    }
}
