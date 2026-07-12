import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami

Kirigami.ScrollablePage {
    id: page

    readonly property bool isPanel: Plasmoid.formFactor === PlasmaCore.Types.Horizontal
                                    || Plasmoid.formFactor === PlasmaCore.Types.Vertical

    property string cfg_iconPack
    property bool cfg_useCustomFont
    property string cfg_customFontFamily
    property string cfg_panelMode
    property string cfg_layoutMode
    property int cfg_panelFontSize
    property int cfg_panelIconSize
    property bool cfg_showForecastUnits

    property string cfg_iconPackDefault
    property bool cfg_useCustomFontDefault
    property string cfg_customFontFamilyDefault
    property string cfg_panelModeDefault
    property string cfg_layoutModeDefault
    property int cfg_panelFontSizeDefault
    property int cfg_panelIconSizeDefault
    property bool cfg_showForecastUnitsDefault

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
    property int cfg_forecastDays; property int cfg_forecastDaysDefault
    property double cfg_backgroundOpacity; property double cfg_backgroundOpacityDefault
    property int cfg_edgeMargin; property int cfg_edgeMarginDefault
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

    readonly property var layoutValues: ["auto", "small", "wide", "large"]
    readonly property var iconPackValues: ["default", "system", "google_v3", "google_v2", "google_v1"]

    Kirigami.FormLayout {
        width: page.availableWidth

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Widget")
        }

        QQC2.ComboBox {
            Kirigami.FormData.label: i18n("Layout:")
            Layout.fillWidth: true
            model: [i18n("Automatic"), i18n("Compact"), i18n("Wide"), i18n("Dashboard")]
            currentIndex: Math.max(0, page.layoutValues.indexOf(page.cfg_layoutMode))
            onActivated: page.cfg_layoutMode = page.layoutValues[currentIndex]
        }

        QQC2.ComboBox {
            id: iconPackCombo
            Kirigami.FormData.label: i18n("Weather icons:")
            Layout.fillWidth: true
            model: [i18n("Weather Breeze"), i18n("Plasma icon theme"),
                    i18n("Google Weather v3"), i18n("Google Weather v2"),
                    i18n("Google Weather v1")]
            currentIndex: Math.max(0, page.iconPackValues.indexOf(page.cfg_iconPack))
            onActivated: page.cfg_iconPack = page.iconPackValues[currentIndex]
        }

        Kirigami.InlineMessage {
            Kirigami.FormData.label: ""
            Layout.fillWidth: true
            visible: iconPackCombo.currentIndex >= 3
            type: Kirigami.MessageType.Warning
            text: i18n("Older icon sets may not include artwork for every weather condition.")
        }

        QQC2.CheckBox {
            Kirigami.FormData.label: i18n("Forecast:")
            text: i18n("Show the temperature unit on forecast cards")
            checked: page.cfg_showForecastUnits
            onToggled: page.cfg_showForecastUnits = checked
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Typography")
        }

        QQC2.CheckBox {
            Kirigami.FormData.label: i18n("Font:")
            text: i18n("Use a custom font")
            checked: page.cfg_useCustomFont
            onToggled: page.cfg_useCustomFont = checked
        }

        QQC2.ComboBox {
            id: fontCombo
            Kirigami.FormData.label: i18n("Family:")
            Layout.fillWidth: true
            enabled: page.cfg_useCustomFont
            model: Qt.fontFamilies()
            onActivated: page.cfg_customFontFamily = currentText

            Component.onCompleted: {
                var index = find(page.cfg_customFontFamily)
                if (index >= 0) currentIndex = index
            }
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Panel")
        }

        QQC2.ComboBox {
            Kirigami.FormData.label: i18n("Representation:")
            Layout.fillWidth: true
            enabled: page.isPanel
            model: [i18n("Icon and temperature"), i18n("Detailed")]
            currentIndex: page.cfg_panelMode === "detailed" ? 1 : 0
            onActivated: page.cfg_panelMode = currentIndex === 1 ? "detailed" : "simple"
        }

        QQC2.SpinBox {
            Kirigami.FormData.label: i18n("Font size:")
            enabled: page.isPanel
            from: 0
            to: 100
            value: page.cfg_panelFontSize
            editable: true
            textFromValue: function(value, locale) {
                return value === 0 ? i18n("Automatic") : value + " px"
            }
            valueFromText: function(text, locale) { return parseInt(text) || 0 }
            onValueModified: page.cfg_panelFontSize = value
        }

        QQC2.SpinBox {
            Kirigami.FormData.label: i18n("Icon size:")
            enabled: page.isPanel
            from: 0
            to: 100
            value: page.cfg_panelIconSize
            editable: true
            textFromValue: function(value, locale) {
                return value === 0 ? i18n("Automatic") : value + " px"
            }
            valueFromText: function(text, locale) { return parseInt(text) || 0 }
            onValueModified: page.cfg_panelIconSize = value
        }

        Kirigami.InlineMessage {
            Kirigami.FormData.label: ""
            Layout.fillWidth: true
            type: Kirigami.MessageType.Information
            text: i18n("Background, corners, spacing, colors, and controls follow your active Plasma and Breeze settings.")
            visible: true
        }
    }
}
