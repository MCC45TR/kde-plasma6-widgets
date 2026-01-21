import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: configRoot
    
    property var title // To silence "does not have a property called title" error
    
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
    property string cfg_cachedWeather
    property double cfg_lastUpdate
    property string cfg_iconPack
    property bool cfg_useCustomFont
    property string cfg_customFontFamily
    property double cfg_backgroundOpacity
    property int cfg_forecastDays
    property bool initialized: false
    
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
    property int cfg_forecastDaysDefault
    
    // Units mapping
    property var unitsModel: ["metric", "imperial"]
    property var providersModel: ["openmeteo", "openweathermap", "weatherapi"]
    
    // When config loads, update UI
    onCfg_weatherProviderChanged: {
        var idx = providersModel.indexOf(cfg_weatherProvider)
        if (idx >= 0 && idx !== providerCombo.currentIndex) {
            providerCombo.currentIndex = idx
        }
    }
    
    onCfg_locationModeChanged: {
        if (cfg_locationMode === "auto") {
            autoModeRadio.checked = true
        } else {
            manualModeRadio.checked = true
        }
    }
    
    Component.onCompleted: {
        // Set units combo index from config
        var unitValue = cfg_units || "metric"
        var unitIdx = unitsModel.indexOf(unitValue)
        if (unitIdx >= 0) unitsCombo.currentIndex = unitIdx
        
        // Set interval combo index from config
        var intervalValue = cfg_updateInterval || 30
        var intervalIdx = intervalCombo.intervalValues.indexOf(intervalValue)
        if (intervalIdx >= 0) intervalCombo.currentIndex = intervalIdx

        // Initialize Forecast Days
        var days = cfg_forecastDays || 5
        var daysIdx = forecastDaysCombo.model.indexOf(String(days))
        if (daysIdx >= 0) forecastDaysCombo.currentIndex = daysIdx
        
        initialized = true
    }
    
    ColumnLayout {
        anchors.fill: parent
        spacing: 15
        
        // Provider Section
        GroupBox {
            title: i18n("Weather Provider")
            Layout.fillWidth: true
            
            ColumnLayout {
                anchors.fill: parent
                spacing: 10
                
                ComboBox {
                    id: providerCombo
                    Layout.fillWidth: true
                    model: [i18n("Open-Meteo (Free, No Key Required)"), i18n("OpenWeatherMap (Key Required)"), i18n("WeatherAPI.com (Key Required)")]
                    
                    onCurrentIndexChanged: {
                        configRoot.cfg_weatherProvider = configRoot.providersModel[currentIndex]
                    }
                }
                
                Label {
                    text: providerCombo.currentIndex === 0 ? i18n("Best free option. No API key required.") :
                          providerCombo.currentIndex === 1 ? i18n("Standard provider. API key required below.") : i18n("Alternative provider. API key required below.")
                    font.pixelSize: 10
                    opacity: 0.7
                }
            }
        }

        // API Keys Section
        GroupBox {
            title: i18n("API Keys")
            Layout.fillWidth: true
            visible: providerCombo.currentIndex !== 0 // Hide if Open-Meteo is selected
            
            ColumnLayout {
                anchors.fill: parent
                spacing: 10
                
                Label {
                    text: i18n("OpenWeatherMap API Key:")
                    font.bold: true
                    visible: providerCombo.currentIndex === 1
                }
                TextField {
                    id: apiKeyField
                    Layout.fillWidth: true
                    placeholderText: i18n("Enter your OpenWeatherMap API key")
                    visible: providerCombo.currentIndex === 1
                }
                
                Label {
                    text: i18n("WeatherAPI.com API Key:")
                    font.bold: true
                    visible: providerCombo.currentIndex === 2
                }
                TextField {
                    id: apiKey2Field
                    Layout.fillWidth: true
                    placeholderText: i18n("Enter your WeatherAPI.com key")
                    visible: providerCombo.currentIndex === 2
                }
            }
        }
        
        // Location Section
        GroupBox {
            title: i18n("Location")
            Layout.fillWidth: true
            
            ColumnLayout {
                anchors.fill: parent
                spacing: 10
                
                // Mode Toggle
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    
                    RadioButton {
                        id: autoModeRadio
                        text: i18n("Auto-detect from IP")
                        checked: configRoot.cfg_locationMode === "auto"
                        onCheckedChanged: {
                            if (checked) configRoot.cfg_locationMode = "auto"
                        }
                    }
                    RadioButton {
                        id: manualModeRadio
                        text: i18n("Enter manually")
                        checked: configRoot.cfg_locationMode === "manual"
                        onCheckedChanged: {
                            if (checked) configRoot.cfg_locationMode = "manual"
                        }
                    }
                }
                
                // Manual Entry Section (visible only when manual mode)
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    visible: manualModeRadio.checked
                    
                    Label {
                        text: i18n("City 1:")
                        font.bold: true
                    }
                    TextField {
                        id: locationField
                        Layout.fillWidth: true
                        placeholderText: i18n("Ex: Ankara, Istanbul, London")
                    }
                    
                    Label {
                        text: i18n("City 2:")
                        font.bold: true
                    }
                    TextField {
                        id: location2Field
                        Layout.fillWidth: true
                        placeholderText: i18n("Second city (optional)")
                    }
                    
                    Label {
                        text: i18n("City 3:")
                        font.bold: true
                    }
                    TextField {
                        id: location3Field
                        Layout.fillWidth: true
                        placeholderText: i18n("Third city (optional)")
                    }
                    
                    Label {
                        text: i18n("You can use City name, 'City,Country Code' or Zip Code.")
                        font.pixelSize: 10
                        opacity: 0.7
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }
                }
                
                // Auto mode info
                Label {
                    visible: autoModeRadio.checked
                    text: i18n("Location will be auto-detected based on your IP address.")
                    font.pixelSize: 10
                    opacity: 0.7
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
            }
        }
        
        // Units Section
        GroupBox {
            title: i18n("Settings")
            Layout.fillWidth: true
            
            GridLayout {
                anchors.fill: parent
                columns: 2
                rowSpacing: 10
                columnSpacing: 10
                
                Label {
                    text: i18n("Units:")
                    font.bold: true
                }
                RowLayout {
                    Layout.fillWidth: true
                    
                    CheckBox {
                        id: useSystemUnitsCheck
                        text: i18n("Use system units")
                        checked: configRoot.cfg_useSystemUnits
                        onCheckedChanged: configRoot.cfg_useSystemUnits = checked
                    }
                }
                
                Label {
                    text: ""
                    visible: !useSystemUnitsCheck.checked
                }
                ComboBox {
                    id: unitsCombo
                    Layout.fillWidth: true
                    model: [i18n("Metric (°C)"), i18n("Imperial (°F)")]
                    visible: !useSystemUnitsCheck.checked
                    enabled: !useSystemUnitsCheck.checked
                    
                    onCurrentIndexChanged: {
                        if (!useSystemUnitsCheck.checked) {
                            configRoot.cfg_units = configRoot.unitsModel[currentIndex]
                        }
                    }
                }
                
                Label {
                    text: i18n("Refresh Interval:")
                    font.bold: true
                }
                ComboBox {
                    id: intervalCombo
                    Layout.fillWidth: true
                    model: [i18n("15 minutes"), i18n("30 minutes"), i18n("45 minutes"), i18n("1 hour"), i18n("2 hours"), i18n("3 hours"), i18n("4 hours"), i18n("6 hours"), i18n("8 hours"), i18n("12 hours"), i18n("1 day")]
                    
                    property var intervalValues: [15, 30, 45, 60, 120, 180, 240, 360, 480, 720, 1440]
                    
                    onCurrentIndexChanged: {
                        if (!configRoot.initialized) return
                        configRoot.cfg_updateInterval = intervalValues[currentIndex]
                    }
                }
                
                Label {
                    text: i18n("Forecast Days:")
                    font.bold: true
                }
                ComboBox {
                    id: forecastDaysCombo
                    Layout.fillWidth: true
                    model: ["4", "5", "6", "7", "8", "9", "10", "11", "12", "13", "14", "15"]
                    
                    onCurrentIndexChanged: {
                         if (!configRoot.initialized) return
                         configRoot.cfg_forecastDays = parseInt(model[currentIndex])
                    }
                }
            }
        }
        
        Item { Layout.fillHeight: true }
    }
}
