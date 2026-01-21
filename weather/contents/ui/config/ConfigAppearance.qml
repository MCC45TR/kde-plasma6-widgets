import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: configAppearance
    
    property var title // To silence "does not have a property called title" error
    
    // Config binding
    property string cfg_iconPack
    property bool cfg_useCustomFont
    property string cfg_customFontFamily
    property double cfg_backgroundOpacity
    property string cfg_panelMode
    property string cfg_layoutMode
    property int cfg_panelFontSize
    property int cfg_panelIconSize



    // Missing General Config Properties (Required to silence errors)
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
    
    // Default values (Required for 'Defaults' button)
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
    
    // Model for icon packs
    property var iconPacksModel: ["default", "system", "google_v3", "google_v2", "google_v1"]
    property var iconPacksLabels: [i18n("Default (Colorful SVG)"), i18n("System Theme"), i18n("Google Weather v3 (Flat SVG)"), i18n("Google Weather v2 (Realistic PNG)"), i18n("Google Weather v1 (Classic PNG)")]
    
    // Load config
    onCfg_iconPackChanged: {
        var idx = iconPacksModel.indexOf(cfg_iconPack)
        if (idx >= 0 && idx !== iconPackCombo.currentIndex) {
            iconPackCombo.currentIndex = idx
        }
    }
    
    implicitHeight: layout.implicitHeight
    
    ColumnLayout {
        id: layout
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 15
        
        GroupBox {
            title: i18n("Appearance")
            Layout.fillWidth: true
            
            ColumnLayout {
                width: parent.width
                spacing: 10
                
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
                    wrapMode: Text.WordWrap // Enable multiline
                    Layout.fillWidth: true
                }

            }
        }

        GroupBox {
            title: i18n("Font Settings")
            Layout.fillWidth: true

            ColumnLayout {
                width: parent.width
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

            ColumnLayout {
                width: parent.width
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
                width: parent.width
                spacing: 10

                Label {
                    text: i18n("Background Opacity:")
                    font.bold: true
                }

                ComboBox {
                    id: opacityCombo
                    Layout.fillWidth: true
                    model: ["100%", "75%", "50%", "25%", "10%", "5%", "0%"]
                    
                    // Maps index to opacity value
                    property var opacityValues: [1.0, 0.75, 0.5, 0.25, 0.1, 0.05, 0.0]

                    onCurrentIndexChanged: {
                         configAppearance.cfg_backgroundOpacity = opacityValues[currentIndex]
                    }
                }
            }
        }
        

    }
    


    Component.onCompleted: {
         // Initial load
         var savedPack = plasmoid.configuration.iconPack || "default"
         var idx = iconPacksModel.indexOf(savedPack)
         if (idx >= 0) iconPackCombo.currentIndex = idx

         // Initialize Font
         if (plasmoid.configuration.customFontFamily) {
             var fIdx = fontCombo.find(plasmoid.configuration.customFontFamily)
             if (fIdx >= 0) fontCombo.currentIndex = fIdx
         }

         // Initialize Opacity
         // Default is 0.9 in xml, but let's be safe
         var currentOp = (plasmoid.configuration.backgroundOpacity !== undefined) ? plasmoid.configuration.backgroundOpacity : 0.9
         // Find closest index
         var closestIdx = 0
         var minDiff = 100
         for (var i = 0; i < opacityCombo.opacityValues.length; i++) {
             var diff = Math.abs(currentOp - opacityCombo.opacityValues[i])
             if (diff < minDiff) {
                 minDiff = diff
                 closestIdx = i
             }
         }
         opacityCombo.currentIndex = closestIdx

         // Initialize Panel Mode
         var pMode = plasmoid.configuration.panelMode || "simple"
         panelModeCombo.currentIndex = (pMode === "detailed") ? 1 : 0
         
         // Initialize Layout Mode
         var lMode = plasmoid.configuration.layoutMode || "auto"
         var lModes = ["auto", "small", "wide", "large"]
         var lIdx = lModes.indexOf(lMode)
         if (lIdx >= 0) layoutModeCombo.currentIndex = lIdx
         
         // Initialize Font Size
         fontSizeSpin.value = plasmoid.configuration.panelFontSize !== undefined ? plasmoid.configuration.panelFontSize : 0

         // Initialize Icon Size
         iconSizeSpin.value = plasmoid.configuration.panelIconSize !== undefined ? plasmoid.configuration.panelIconSize : 0
    }
}
