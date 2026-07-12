import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

Kirigami.ScrollablePage {
    id: page

    property string cfg_weatherProvider
    property string cfg_locationMode
    property alias cfg_apiKey: apiKeyField.text
    property alias cfg_apiKey2: apiKey2Field.text
    property alias cfg_location: locationField.text
    property alias cfg_location2: location2Field.text
    property alias cfg_location3: location3Field.text
    property string cfg_units
    property bool cfg_useSystemUnits
    property int cfg_updateInterval
    property int cfg_forecastDays

    property string cfg_weatherProviderDefault
    property string cfg_locationModeDefault
    property string cfg_apiKeyDefault
    property string cfg_apiKey2Default
    property string cfg_locationDefault
    property string cfg_location2Default
    property string cfg_location3Default
    property string cfg_unitsDefault
    property bool cfg_useSystemUnitsDefault
    property int cfg_updateIntervalDefault
    property int cfg_forecastDaysDefault

    // Plasma initializes every KConfig key on every page. Keep non-page values intact.
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
    property int cfg_edgeMargin; property int cfg_edgeMarginDefault
    property bool cfg_showForecastUnits; property bool cfg_showForecastUnitsDefault
    property string cfg_cornerRadius; property string cfg_cornerRadiusDefault
    property bool cfg_notifyEnabled; property bool cfg_notifyEnabledDefault
    property bool cfg_notifyRoutineEnabled; property bool cfg_notifyRoutineEnabledDefault
    property int cfg_notifyRoutineTime1; property int cfg_notifyRoutineTime1Default
    property int cfg_notifyRoutineTime2; property int cfg_notifyRoutineTime2Default
    property bool cfg_notifyRoutineTime2Enabled; property bool cfg_notifyRoutineTime2EnabledDefault
    property string cfg_notifyRoutineType; property string cfg_notifyRoutineTypeDefault
    property bool cfg_notifySevereWeather; property bool cfg_notifySevereWeatherDefault
    property bool cfg_notifyRain; property bool cfg_notifyRainDefault
    property bool cfg_notifyTemperatureDrop; property bool cfg_notifyTemperatureDropDefault
    property int cfg_notifyTemperatureThreshold; property int cfg_notifyTemperatureThresholdDefault
    property bool cfg_notifyHighTemp; property bool cfg_notifyHighTempDefault
    property int cfg_notifyHighTempThreshold; property int cfg_notifyHighTempThresholdDefault
    property bool cfg_notifyUvIndex; property bool cfg_notifyUvIndexDefault
    property int cfg_notifyUvThreshold; property int cfg_notifyUvThresholdDefault
    property bool cfg_notifyWind; property bool cfg_notifyWindDefault
    property int cfg_notifyWindThreshold; property int cfg_notifyWindThresholdDefault
    property string cfg_lastRoutineDate1; property string cfg_lastRoutineDate1Default
    property string cfg_lastRoutineDate2; property string cfg_lastRoutineDate2Default
    property double cfg_lastRoutineNotify; property double cfg_lastRoutineNotifyDefault
    property double cfg_lastSevereNotify; property double cfg_lastSevereNotifyDefault
    property double cfg_lastRainNotify; property double cfg_lastRainNotifyDefault
    property double cfg_lastTempNotify; property double cfg_lastTempNotifyDefault
    property double cfg_lastHighTempNotify; property double cfg_lastHighTempNotifyDefault
    property double cfg_lastUvNotify; property double cfg_lastUvNotifyDefault
    property double cfg_lastWindNotify; property double cfg_lastWindNotifyDefault
    property double cfg_triggerTestNotification; property double cfg_triggerTestNotificationDefault

    readonly property var providerValues: ["openmeteo", "openweathermap", "weatherapi"]
    readonly property var unitValues: ["metric", "imperial"]
    readonly property var intervalValues: [15, 30, 45, 60, 120, 180, 240, 360, 720, 1440]

    Kirigami.FormLayout {
        width: page.availableWidth

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Weather Source")
        }

        QQC2.ComboBox {
            id: providerCombo
            Kirigami.FormData.label: i18n("Provider:")
            Layout.fillWidth: true
            model: [i18n("Open-Meteo — no API key"),
                    i18n("OpenWeatherMap"),
                    i18n("WeatherAPI.com")]
            currentIndex: Math.max(0, page.providerValues.indexOf(page.cfg_weatherProvider))
            onActivated: page.cfg_weatherProvider = page.providerValues[currentIndex]
        }

        Kirigami.InlineMessage {
            Kirigami.FormData.label: ""
            Layout.fillWidth: true
            type: Kirigami.MessageType.Information
            text: providerCombo.currentIndex === 0
                  ? i18n("Open-Meteo is free and does not require an API key.")
                  : i18n("The selected provider requires an API key.")
            visible: true
        }

        QQC2.TextField {
            id: apiKeyField
            Kirigami.FormData.label: i18n("OpenWeatherMap key:")
            Layout.fillWidth: true
            visible: providerCombo.currentIndex === 1
            placeholderText: i18n("API key")
            echoMode: TextInput.PasswordEchoOnEdit
        }

        QQC2.TextField {
            id: apiKey2Field
            Kirigami.FormData.label: i18n("WeatherAPI.com key:")
            Layout.fillWidth: true
            visible: providerCombo.currentIndex === 2
            placeholderText: i18n("API key")
            echoMode: TextInput.PasswordEchoOnEdit
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Location")
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Mode:")

            QQC2.RadioButton {
                id: autoModeRadio
                text: i18n("Automatic")
                checked: page.cfg_locationMode === "auto"
                onToggled: if (checked) page.cfg_locationMode = "auto"
            }
            QQC2.RadioButton {
                id: manualModeRadio
                text: i18n("Manual")
                checked: page.cfg_locationMode === "manual"
                onToggled: if (checked) page.cfg_locationMode = "manual"
            }
        }

        QQC2.TextField {
            id: locationField
            Kirigami.FormData.label: i18n("Primary city:")
            Layout.fillWidth: true
            visible: manualModeRadio.checked
            placeholderText: i18n("City, country code, or postal code")
        }

        QQC2.TextField {
            id: location2Field
            Kirigami.FormData.label: i18n("Alternate city 2:")
            Layout.fillWidth: true
            visible: manualModeRadio.checked
            placeholderText: i18n("Optional")
        }

        QQC2.TextField {
            id: location3Field
            Kirigami.FormData.label: i18n("Alternate city 3:")
            Layout.fillWidth: true
            visible: manualModeRadio.checked
            placeholderText: i18n("Optional")
        }

        Kirigami.InlineMessage {
            Kirigami.FormData.label: ""
            Layout.fillWidth: true
            visible: autoModeRadio.checked
            type: Kirigami.MessageType.Information
            text: i18n("Your location is detected from the network address used by the weather provider.")
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Forecast")
        }

        QQC2.CheckBox {
            Kirigami.FormData.label: i18n("Units:")
            text: i18n("Follow system settings")
            checked: page.cfg_useSystemUnits
            onToggled: page.cfg_useSystemUnits = checked
        }

        QQC2.ComboBox {
            Kirigami.FormData.label: i18n("Measurement system:")
            Layout.fillWidth: true
            enabled: !page.cfg_useSystemUnits
            model: [i18n("Metric (°C, km/h)"), i18n("Imperial (°F, mph)")]
            currentIndex: Math.max(0, page.unitValues.indexOf(page.cfg_units))
            onActivated: page.cfg_units = page.unitValues[currentIndex]
        }

        QQC2.ComboBox {
            Kirigami.FormData.label: i18n("Refresh interval:")
            Layout.fillWidth: true
            model: [i18n("15 minutes"), i18n("30 minutes"), i18n("45 minutes"),
                    i18n("1 hour"), i18n("2 hours"), i18n("3 hours"),
                    i18n("4 hours"), i18n("6 hours"), i18n("12 hours"), i18n("1 day")]
            currentIndex: Math.max(0, page.intervalValues.indexOf(page.cfg_updateInterval))
            onActivated: page.cfg_updateInterval = page.intervalValues[currentIndex]
        }

        QQC2.SpinBox {
            Kirigami.FormData.label: i18n("Forecast days:")
            from: 4
            to: 15
            value: page.cfg_forecastDays || 5
            editable: true
            onValueModified: page.cfg_forecastDays = value
        }
    }
}
