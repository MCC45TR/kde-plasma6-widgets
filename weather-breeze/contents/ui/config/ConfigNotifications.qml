import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.notification

Kirigami.ScrollablePage {
    id: page

    property var title

    Notification {
        id: demoNotification
        componentName: "weatherbreeze"
        eventId: "notification"
    }

    Timer {
        id: closeTimer
        interval: 10000
        onTriggered: demoNotification.close()
    }

    function sendNotification(title, body, icon, alert) {
        demoNotification.eventId = alert ? "alert" : "notification"
        demoNotification.title = title
        demoNotification.text = body
        demoNotification.iconName = icon
        demoNotification.sendEvent()
        if (alert) closeTimer.restart()
    }

    function minutesToTime(minutes) {
        var hours = Math.floor(minutes / 60)
        var mins = minutes % 60
        return hours.toString().padStart(2, "0") + ":" + mins.toString().padStart(2, "0")
    }

    function timeToMinutes(text) {
        var parts = text.split(":")
        if (parts.length !== 2) return 0
        var hours = parseInt(parts[0])
        var minutes = parseInt(parts[1])
        return isNaN(hours) || isNaN(minutes) ? 0 : hours * 60 + minutes
    }

    property alias cfg_notifyEnabled: masterToggle.checked
    property alias cfg_notifyRoutineEnabled: routineToggle.checked
    property string cfg_notifyRoutineType
    property alias cfg_notifyRoutineTime1: routineTime1Spin.value
    property alias cfg_notifyRoutineTime2: routineTime2Spin.value
    property alias cfg_notifyRoutineTime2Enabled: routineTime2Toggle.checked
    property alias cfg_notifySevereWeather: severeToggle.checked
    property alias cfg_notifyRain: rainToggle.checked
    property alias cfg_notifyTemperatureDrop: lowTempToggle.checked
    property alias cfg_notifyTemperatureThreshold: lowTempSpin.value
    property alias cfg_notifyHighTemp: highTempToggle.checked
    property alias cfg_notifyHighTempThreshold: highTempSpin.value
    property alias cfg_notifyUvIndex: uvToggle.checked
    property alias cfg_notifyUvThreshold: uvSpin.value
    property alias cfg_notifyWind: windToggle.checked
    property alias cfg_notifyWindThreshold: windSpin.value

    property bool cfg_notifyEnabledDefault
    property bool cfg_notifyRoutineEnabledDefault
    property string cfg_notifyRoutineTypeDefault
    property int cfg_notifyRoutineTime1Default
    property int cfg_notifyRoutineTime2Default
    property bool cfg_notifyRoutineTime2EnabledDefault
    property bool cfg_notifySevereWeatherDefault
    property bool cfg_notifyRainDefault
    property bool cfg_notifyTemperatureDropDefault
    property int cfg_notifyTemperatureThresholdDefault
    property bool cfg_notifyHighTempDefault
    property int cfg_notifyHighTempThresholdDefault
    property bool cfg_notifyUvIndexDefault
    property int cfg_notifyUvThresholdDefault
    property bool cfg_notifyWindDefault
    property int cfg_notifyWindThresholdDefault

    property string cfg_apiKey; property string cfg_apiKeyDefault
    property string cfg_apiKey2; property string cfg_apiKey2Default
    property string cfg_weatherProvider; property string cfg_weatherProviderDefault
    property string cfg_locationMode; property string cfg_locationModeDefault
    property string cfg_location; property string cfg_locationDefault
    property string cfg_location2; property string cfg_location2Default
    property string cfg_location3; property string cfg_location3Default
    property string cfg_units; property string cfg_unitsDefault
    property bool cfg_useSystemUnits; property bool cfg_useSystemUnitsDefault
    property int cfg_updateInterval; property int cfg_updateIntervalDefault
    property string cfg_cachedWeather; property string cfg_cachedWeatherDefault
    property double cfg_lastUpdate; property double cfg_lastUpdateDefault
    property string cfg_iconPack; property string cfg_iconPackDefault
    property bool cfg_useCustomFont; property bool cfg_useCustomFontDefault
    property string cfg_customFontFamily; property string cfg_customFontFamilyDefault
    property double cfg_backgroundOpacity; property double cfg_backgroundOpacityDefault
    property string cfg_panelMode; property string cfg_panelModeDefault
    property string cfg_layoutMode; property string cfg_layoutModeDefault
    property int cfg_panelFontSize; property int cfg_panelFontSizeDefault
    property int cfg_panelIconSize; property int cfg_panelIconSizeDefault
    property int cfg_forecastDays; property int cfg_forecastDaysDefault
    property int cfg_edgeMargin; property int cfg_edgeMarginDefault
    property bool cfg_showForecastUnits; property bool cfg_showForecastUnitsDefault
    property string cfg_cornerRadius; property string cfg_cornerRadiusDefault
    property string cfg_lastRoutineDate1; property string cfg_lastRoutineDate1Default
    property string cfg_lastRoutineDate2; property string cfg_lastRoutineDate2Default
    property double cfg_lastSevereNotify; property double cfg_lastSevereNotifyDefault
    property double cfg_lastRainNotify; property double cfg_lastRainNotifyDefault
    property double cfg_lastTempNotify; property double cfg_lastTempNotifyDefault
    property double cfg_lastHighTempNotify; property double cfg_lastHighTempNotifyDefault
    property double cfg_lastUvNotify; property double cfg_lastUvNotifyDefault
    property double cfg_lastWindNotify; property double cfg_lastWindNotifyDefault
    property double cfg_triggerTestNotification; property double cfg_triggerTestNotificationDefault

    Kirigami.FormLayout {
        width: page.availableWidth

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Weather Notifications")
        }

        QQC2.Switch {
            id: masterToggle
            Kirigami.FormData.label: i18n("Notifications:")
            text: i18n("Enable weather notifications")
        }

        Kirigami.InlineMessage {
            Kirigami.FormData.label: ""
            Layout.fillWidth: true
            visible: masterToggle.checked
            type: Kirigami.MessageType.Information
            text: i18n("Alerts are evaluated whenever weather data is refreshed. Cooldowns prevent duplicate notifications.")
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Daily Summary")
        }

        QQC2.Switch {
            id: routineToggle
            Kirigami.FormData.label: i18n("Summary:")
            text: i18n("Send a daily weather summary")
            enabled: masterToggle.checked
        }

        QQC2.ComboBox {
            id: routineTypeCombo
            Kirigami.FormData.label: i18n("Content:")
            Layout.fillWidth: true
            enabled: masterToggle.checked && routineToggle.checked
            textRole: "text"
            valueRole: "value"
            model: [
                { text: i18n("3-day forecast summary"), value: "forecast_3day" },
                { text: i18n("Today's weather changes"), value: "daily_change" }
            ]
            currentIndex: page.cfg_notifyRoutineType === "daily_change" ? 1 : 0
            onActivated: page.cfg_notifyRoutineType = currentValue
        }

        QQC2.SpinBox {
            id: routineTime1Spin
            Kirigami.FormData.label: i18n("First time:")
            enabled: masterToggle.checked && routineToggle.checked
            from: 0
            to: 1439
            stepSize: 15
            editable: true
            textFromValue: function(value, locale) { return page.minutesToTime(value) }
            valueFromText: function(text, locale) { return page.timeToMinutes(text) }
        }

        QQC2.CheckBox {
            id: routineTime2Toggle
            Kirigami.FormData.label: i18n("Second summary:")
            text: i18n("Enable a second delivery time")
            enabled: masterToggle.checked && routineToggle.checked
        }

        QQC2.SpinBox {
            id: routineTime2Spin
            Kirigami.FormData.label: i18n("Second time:")
            enabled: masterToggle.checked && routineToggle.checked && routineTime2Toggle.checked
            from: 0
            to: 1439
            stepSize: 15
            editable: true
            textFromValue: function(value, locale) { return page.minutesToTime(value) }
            valueFromText: function(text, locale) { return page.timeToMinutes(text) }
        }

        Kirigami.InlineMessage {
            Kirigami.FormData.label: ""
            Layout.fillWidth: true
            visible: routineTime2Toggle.checked && routineTime1Spin.value === routineTime2Spin.value
            type: Kirigami.MessageType.Warning
            text: i18n("Choose two different delivery times.")
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Weather Alerts")
        }

        QQC2.Switch {
            id: severeToggle
            Kirigami.FormData.label: i18n("Severe weather:")
            text: i18n("Thunderstorm, heavy snow, and dense fog")
            enabled: masterToggle.checked
        }

        QQC2.Switch {
            id: rainToggle
            Kirigami.FormData.label: i18n("Rain:")
            text: i18n("Rain expected in the next few hours")
            enabled: masterToggle.checked
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Strong wind:")
            enabled: masterToggle.checked

            QQC2.Switch {
                id: windToggle
                text: i18n("Alert")
            }
            QQC2.SpinBox {
                id: windSpin
                from: 10
                to: 200
                stepSize: 5
                enabled: windToggle.checked
                editable: true
                textFromValue: function(value, locale) { return value + " km/h" }
                valueFromText: function(text, locale) { return parseInt(text) || 50 }
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("UV index:")
            enabled: masterToggle.checked

            QQC2.Switch {
                id: uvToggle
                text: i18n("Alert")
            }
            QQC2.SpinBox {
                id: uvSpin
                from: 1
                to: 11
                enabled: uvToggle.checked
                editable: true
                textFromValue: function(value, locale) { return "UV " + value }
                valueFromText: function(text, locale) { return parseInt(text.replace("UV ", "")) || 6 }
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Low temperature:")
            enabled: masterToggle.checked

            QQC2.Switch {
                id: lowTempToggle
                text: i18n("Alert")
            }
            QQC2.SpinBox {
                id: lowTempSpin
                from: -50
                to: 50
                enabled: lowTempToggle.checked
                editable: true
                textFromValue: function(value, locale) { return value + "°C" }
                valueFromText: function(text, locale) { return parseInt(text) || 0 }
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("High temperature:")
            enabled: masterToggle.checked

            QQC2.Switch {
                id: highTempToggle
                text: i18n("Alert")
            }
            QQC2.SpinBox {
                id: highTempSpin
                from: 20
                to: 60
                enabled: highTempToggle.checked
                editable: true
                textFromValue: function(value, locale) { return value + "°C" }
                valueFromText: function(text, locale) { return parseInt(text) || 30 }
            }
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Test")
        }

        Flow {
            Kirigami.FormData.label: i18n("Preview:")
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            QQC2.Button {
                text: i18n("General")
                icon.name: "weather-clear"
                onClicked: page.sendNotification(i18n("Weather Breeze"),
                                                 i18n("Weather notifications are working."),
                                                 "weather-clear", false)
            }
            QQC2.Button {
                text: i18n("Rain")
                icon.name: "weather-showers"
                onClicked: page.sendNotification(i18n("Rain Forecast"),
                                                 i18n("Rain is expected in the next few hours."),
                                                 "weather-showers", true)
            }
            QQC2.Button {
                text: i18n("Storm")
                icon.name: "weather-storm"
                onClicked: page.sendNotification(i18n("Thunderstorm Warning"),
                                                 i18n("A thunderstorm is expected. Stay indoors and avoid open areas."),
                                                 "weather-storm", true)
            }
        }
    }
}
