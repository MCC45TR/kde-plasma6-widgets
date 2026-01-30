import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore

Item {
    id: configAppearance

    readonly property bool isPanel: Plasmoid.formFactor === PlasmaCore.Types.Horizontal || Plasmoid.formFactor === PlasmaCore.Types.Vertical

    property var title

    property string cfg_iconPack
    property bool cfg_useCustomFont
    property string cfg_customFontFamily
    property double cfg_backgroundOpacity
    property string cfg_panelMode
    property string cfg_layoutMode
    property int cfg_panelFontSize
    property int cfg_panelIconSize
    property int cfg_edgeMargin
    property bool cfg_showForecastUnits
    property int cfg_forecastDays
    property string cfg_cornerRadius

    property string cfg_apiKey
    property string cfg_apiKey2
    property string cfg_weatherProvider
    property string cfg_locationMode
    property string cfg_location
    property string cfg_location2
    property string cfg_location3
    property string cfg_units
    property bool cfg_useSystemUnits
    property int cfg_updateInterval
    property string cfg_cachedWeather
    property double cfg_lastUpdate

    property string cfg_apiKeyDefault
    property string cfg_apiKey2Default
    property string cfg_weatherProviderDefault
    property string cfg_locationModeDefault
    property string cfg_locationDefault
    property string cfg_location2Default
    property string cfg_location3Default
    property string cfg_unitsDefault
    property bool cfg_useSystemUnitsDefault
    property int cfg_updateIntervalDefault
    property string cfg_cachedWeatherDefault
    property double cfg_lastUpdateDefault
    property string cfg_iconPackDefault
    property bool cfg_useCustomFontDefault
    property string cfg_customFontFamilyDefault
    property double cfg_backgroundOpacityDefault
    property string cfg_panelModeDefault
    property string cfg_layoutModeDefault
    property int cfg_panelFontSizeDefault
    property int cfg_panelIconSizeDefault
    property int cfg_edgeMarginDefault
    property bool cfg_showForecastUnitsDefault
    property int cfg_forecastDaysDefault
    property string cfg_cornerRadiusDefault

    property var iconPacksModel: ["default", "system", "google_v3", "google_v2", "google_v1"]
    property var iconPacksLabels: [i18n("Default (Colorful SVG)"), i18n("System Theme"), i18n("Google Weather v3 (Flat SVG)"), i18n("Google Weather v2 (Realistic PNG)"), i18n("Google Weather v1 (Classic PNG)")]

    onCfg_iconPackChanged: {
        var idx = iconPacksModel.indexOf(cfg_iconPack)
        if (idx >= 0 && idx !== iconPackCombo.currentIndex) {
            iconPackCombo.currentIndex = idx
        }
    }

    function getOpacityIndex(val) {
        var bestIdx = 0
        var minDiff = 100
        for (var i = 0; i < opacityCombo.opacityValues.length; i++) {
            var diff = Math.abs(val - opacityCombo.opacityValues[i])
            if (diff < minDiff) {
                minDiff = diff
                bestIdx = i
            }
        }
        return bestIdx
    }

    ScrollView {
        id: scrollView
        anchors.fill: parent
        clip: true

        ScrollBar.vertical.policy: ScrollBar.AsNeeded
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

        ColumnLayout {
            id: layout
            width: scrollView.availableWidth
            spacing: 15

        GroupBox {
            title: i18n("Appearance")
            Layout.fillWidth: true

            ColumnLayout {
                anchors.fill: parent
                spacing: 10

                CheckBox {
                    text: i18n("Show Units in Forecast")
                    checked: configAppearance.cfg_showForecastUnits
                    onCheckedChanged: {
                        configAppearance.cfg_showForecastUnits = checked
                    }
                }

                Label {
                    text: i18n("Layout Mode:")
                    font.bold: true
                }

                ComboBox {
                    id: layoutModeCombo
                    Layout.fillWidth: true
                    model: [i18n("Automatic"), i18n("Small"), i18n("Wide"), i18n("Large")]

                    onCurrentIndexChanged: {
                        var modes = ["auto", "small", "wide", "large"]
                        configAppearance.cfg_layoutMode = modes[currentIndex]
                    }
                }

                Label {
                    text: i18n("Icon Pack:")
                    font.bold: true
                }

                ComboBox {
                    id: iconPackCombo
                    Layout.fillWidth: true
                    model: iconPacksLabels

                    onCurrentIndexChanged: {
                        configAppearance.cfg_iconPack = iconPacksModel[currentIndex]
                    }
                }

                Label {
                    text: iconPackCombo.currentIndex > 1 ?
                          i18n("Select the visual style for weather icons. (Note: older packs like v1/v2 may have missing icons for some conditions)") :
                          i18n("Select the visual style for weather icons.")
                    font.pixelSize: 10
                    opacity: 0.7
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }

                Label {
                    text: i18n("Widget Margin:")
                    font.bold: true
                }

                ComboBox {
                    id: edgeMarginCombo
                    Layout.fillWidth: true
                    model: [i18n("Normal (10px)"), i18n("Less (5px)"), i18n("None (0px)")]

                    onCurrentIndexChanged: {
                        if (currentIndex === 0) configAppearance.cfg_edgeMargin = 10
                        else if (currentIndex === 1) configAppearance.cfg_edgeMargin = 5
                        else if (currentIndex === 2) configAppearance.cfg_edgeMargin = 0
                    }
                }

                Label {
                    text: i18n("Corner Radius:")
                    font.bold: true
                }

                ComboBox {
                    id: cornerRadiusCombo
                    Layout.fillWidth: true
                    model: [i18n("Normal"), i18n("Small"), i18n("Square")]

                    onCurrentIndexChanged: {
                        if (currentIndex === 0) configAppearance.cfg_cornerRadius = "normal"
                        else if (currentIndex === 1) configAppearance.cfg_cornerRadius = "small"
                        else if (currentIndex === 2) configAppearance.cfg_cornerRadius = "square"
                    }
                }
            }
        }

        GroupBox {
            title: i18n("Font Settings")
            Layout.fillWidth: true

            ColumnLayout {
                anchors.fill: parent
                spacing: 10

                CheckBox {
                    id: useSystemFontParams
                    text: i18n("Use Default System Font")
                    checked: !configAppearance.cfg_useCustomFont
                    onCheckedChanged: {
                        configAppearance.cfg_useCustomFont = !checked
                    }
                }

                Label {
                    text: i18n("Custom Font Family:")
                    font.bold: true
                    opacity: useSystemFontParams.checked ? 0.5 : 1.0
                }

                ComboBox {
                    id: fontCombo
                    Layout.fillWidth: true
                    model: Qt.fontFamilies()
                    enabled: !useSystemFontParams.checked

                    onCurrentTextChanged: {
                         if (!useSystemFontParams.checked) {
                             configAppearance.cfg_customFontFamily = currentText
                         }
                    }
                }
            }
        }

        GroupBox {
            title: i18n("Panel Settings")
            Layout.fillWidth: true
            enabled: configAppearance.isPanel
            opacity: configAppearance.isPanel ? 1.0 : 0.5

            ColumnLayout {
                anchors.fill: parent
                spacing: 10

                Label {
                    text: i18n("Representation:")
                    font.bold: true
                }

                ComboBox {
                    id: panelModeCombo
                    Layout.fillWidth: true
                    model: [i18n("Simple Panel"), i18n("Detailed Panel")]

                    onCurrentIndexChanged: {
                        configAppearance.cfg_panelMode = currentIndex === 0 ? "simple" : "detailed"
                    }
                }

                Label {
                    text: i18n("Font Size (0 = Auto):")
                    font.bold: true
                }

                SpinBox {
                    id: fontSizeSpin
                    from: 0
                    to: 100
                    stepSize: 1
                    editable: true
                    Layout.fillWidth: true

                    onValueModified: {
                        configAppearance.cfg_panelFontSize = value
                    }
                }

                Label {
                    text: i18n("Icon Size (0 = Auto):")
                    font.bold: true
                }

                SpinBox {
                    id: iconSizeSpin
                    from: 0
                    to: 100
                    stepSize: 1
                    editable: true
                    Layout.fillWidth: true

                    onValueModified: {
                        configAppearance.cfg_panelIconSize = value
                    }
                }
            }
        }

        GroupBox {
            title: i18n("Background Settings")
            Layout.fillWidth: true

            ColumnLayout {
                anchors.fill: parent
                spacing: 10

                Label {
                    text: i18n("Background Opacity:")
                    font.bold: true
                }

                ComboBox {
                    id: opacityCombo
                    Layout.fillWidth: true
                    model: ["100%", "75%", "50%", "25%", "10%", "5%", "0%", i18n("0% (No Backgrounds)")]

                    property var opacityValues: [1.0, 0.75, 0.5, 0.25, 0.1, 0.05, 0.0, -1.0]

                    onCurrentIndexChanged: {
                         configAppearance.cfg_backgroundOpacity = opacityValues[currentIndex]
                    }
                }
            }
            }
        }
    }

    Component.onCompleted: {
         var savedPack = plasmoid.configuration.iconPack || "default"
         var idx = iconPacksModel.indexOf(savedPack)
         if (idx >= 0) iconPackCombo.currentIndex = idx

         if (plasmoid.configuration.customFontFamily) {
             var fIdx = fontCombo.find(plasmoid.configuration.customFontFamily)
             if (fIdx >= 0) fontCombo.currentIndex = fIdx
         }

         var currentOp = (plasmoid.configuration.backgroundOpacity !== undefined) ? plasmoid.configuration.backgroundOpacity : 0.9
         opacityCombo.currentIndex = getOpacityIndex(currentOp)

         var pMode = plasmoid.configuration.panelMode || "simple"
         panelModeCombo.currentIndex = (pMode === "detailed") ? 1 : 0

         var lMode = plasmoid.configuration.layoutMode || "auto"
         var lModes = ["auto", "small", "wide", "large"]
         var lIdx = lModes.indexOf(lMode)
         if (lIdx >= 0) layoutModeCombo.currentIndex = lIdx

         fontSizeSpin.value = plasmoid.configuration.panelFontSize !== undefined ? plasmoid.configuration.panelFontSize : 0

         iconSizeSpin.value = plasmoid.configuration.panelIconSize !== undefined ? plasmoid.configuration.panelIconSize : 0

         var margin = plasmoid.configuration.edgeMargin !== undefined ? plasmoid.configuration.edgeMargin : 10
         if (margin === 10) edgeMarginCombo.currentIndex = 0
         else if (margin === 5) edgeMarginCombo.currentIndex = 1
         else if (margin === 0) edgeMarginCombo.currentIndex = 2
         else edgeMarginCombo.currentIndex = 0

         var radiusMode = plasmoid.configuration.cornerRadius || "normal"
         if (radiusMode === "normal") cornerRadiusCombo.currentIndex = 0
         else if (radiusMode === "small") cornerRadiusCombo.currentIndex = 1
         else if (radiusMode === "square") cornerRadiusCombo.currentIndex = 2
         else cornerRadiusCombo.currentIndex = 0
    }
}
