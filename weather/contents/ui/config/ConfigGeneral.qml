import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: configRoot
    
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
    }
    
    ColumnLayout {
        anchors.fill: parent
        spacing: 15
        
        // Provider Section
        GroupBox {
            title: "Hava Durumu Sağlayıcısı"
            Layout.fillWidth: true
            
            ColumnLayout {
                anchors.fill: parent
                spacing: 10
                
                ComboBox {
                    id: providerCombo
                    Layout.fillWidth: true
                    model: ["Open-Meteo (Ücretsiz, Anahtar Gerekmez)", "OpenWeatherMap (Anahtar Gerekli)", "WeatherAPI.com (Anahtar Gerekli)"]
                    
                    onCurrentIndexChanged: {
                        configRoot.cfg_weatherProvider = configRoot.providersModel[currentIndex]
                    }
                }
                
                Label {
                    text: providerCombo.currentIndex === 0 ? "En iyi ücretsiz seçenek. API anahtarı gerektirmez." :
                          providerCombo.currentIndex === 1 ? "Standart sağlayıcı. Aşağıda API anahtarı girilmelidir." : "Alternatif sağlayıcı. Aşağıda API anahtarı girilmelidir."
                    font.pixelSize: 10
                    opacity: 0.7
                }
            }
        }

        // API Keys Section
        GroupBox {
            title: "API Anahtarları"
            Layout.fillWidth: true
            visible: providerCombo.currentIndex !== 0 // Hide if Open-Meteo is selected
            
            ColumnLayout {
                anchors.fill: parent
                spacing: 10
                
                Label {
                    text: "OpenWeatherMap API Anahtarı:"
                    font.bold: true
                    visible: providerCombo.currentIndex === 1
                }
                TextField {
                    id: apiKeyField
                    Layout.fillWidth: true
                    placeholderText: "OpenWeatherMap API anahtarınızı girin"
                    visible: providerCombo.currentIndex === 1
                }
                
                Label {
                    text: "WeatherAPI.com API Anahtarı:"
                    font.bold: true
                    visible: providerCombo.currentIndex === 2
                }
                TextField {
                    id: apiKey2Field
                    Layout.fillWidth: true
                    placeholderText: "WeatherAPI.com anahtarınızı girin"
                    visible: providerCombo.currentIndex === 2
                }
            }
        }
        
        // Location Section
        GroupBox {
            title: "Konum"
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
                        text: "IP adresinden otomatik algıla"
                        checked: configRoot.cfg_locationMode === "auto"
                        onCheckedChanged: {
                            if (checked) configRoot.cfg_locationMode = "auto"
                        }
                    }
                    RadioButton {
                        id: manualModeRadio
                        text: "Elle gir"
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
                        text: "Şehir 1:"
                        font.bold: true
                    }
                    TextField {
                        id: locationField
                        Layout.fillWidth: true
                        placeholderText: "Örn: Ankara, Istanbul, London"
                    }
                    
                    Label {
                        text: "Şehir 2:"
                        font.bold: true
                    }
                    TextField {
                        id: location2Field
                        Layout.fillWidth: true
                        placeholderText: "İkinci şehir (opsiyonel)"
                    }
                    
                    Label {
                        text: "Şehir 3:"
                        font.bold: true
                    }
                    TextField {
                        id: location3Field
                        Layout.fillWidth: true
                        placeholderText: "Üçüncü şehir (opsiyonel)"
                    }
                    
                    Label {
                        text: "Şehir ismi, 'Şehir,Ülke Kodu' veya Posta Kodu kullanabilirsiniz."
                        font.pixelSize: 10
                        opacity: 0.7
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }
                }
                
                // Auto mode info
                Label {
                    visible: autoModeRadio.checked
                    text: "Konum, IP adresinize göre otomatik olarak algılanacaktır."
                    font.pixelSize: 10
                    opacity: 0.7
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
            }
        }
        
        // Units Section
        GroupBox {
            title: "Ayarlar"
            Layout.fillWidth: true
            
            GridLayout {
                anchors.fill: parent
                columns: 2
                rowSpacing: 10
                columnSpacing: 10
                
                Label {
                    text: "Birimler:"
                    font.bold: true
                }
                RowLayout {
                    Layout.fillWidth: true
                    
                    CheckBox {
                        id: useSystemUnitsCheck
                        text: "Sistem birimlerini kullan"
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
                    model: ["Metrik (°C)", "Emperyal (°F)"]
                    visible: !useSystemUnitsCheck.checked
                    enabled: !useSystemUnitsCheck.checked
                    
                    onCurrentIndexChanged: {
                        if (!useSystemUnitsCheck.checked) {
                            configRoot.cfg_units = configRoot.unitsModel[currentIndex]
                        }
                    }
                }
                
                Label {
                    text: "Yenileme Sıklığı:"
                    font.bold: true
                }
                ComboBox {
                    id: intervalCombo
                    Layout.fillWidth: true
                    model: ["15 dakika", "30 dakika", "45 dakika", "1 saat", "2 saat", "3 saat", "4 saat", "6 saat", "8 saat", "12 saat", "1 gün"]
                    
                    property var intervalValues: [15, 30, 45, 60, 120, 180, 240, 360, 480, 720, 1440]
                    
                    onCurrentIndexChanged: {
                        configRoot.cfg_updateInterval = intervalValues[currentIndex]
                    }
                }
            }
        }
        
        Item { Layout.fillHeight: true }
    }
}
