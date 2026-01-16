import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

    property string cfg_weatherProvider
    property alias cfg_apiKey: apiKeyField.text
    property alias cfg_apiKey2: apiKey2Field.text
    property alias cfg_location: locationField.text
    property alias cfg_units: unitsCombo.currentIndex  
    property alias cfg_updateInterval: updateIntervalSpinBox.value
    
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
    
    Component.onCompleted: {
        // Set units combo index from config
        var unitValue = plasmoid.configuration.units || "metric"
        cfg_units = unitsModel.indexOf(unitValue)
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
                
                Label {
                    text: "Şehir İsmi:"
                    font.bold: true
                }
                TextField {
                    id: locationField
                    Layout.fillWidth: true
                    placeholderText: "Örn: Ankara, Istanbul, London"
                }
                
                Label {
                    text: "Şehir ismi, 'Şehir,Ülke Kodu' veya Posta Kodu kullanabilirsiniz."
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
                ComboBox {
                    id: unitsCombo
                    Layout.fillWidth: true
                    model: ["Metrik (°C)", "Emperyal (°F)"]
                    
                    onCurrentIndexChanged: {
                        plasmoid.configuration.units = configRoot.unitsModel[currentIndex]
                    }
                }
                
                Label {
                    text: "Yenileme Sıklığı:"
                    font.bold: true
                }
                RowLayout {
                    Layout.fillWidth: true
                    SpinBox {
                        id: updateIntervalSpinBox
                        from: 5
                        to: 120
                        stepSize: 5
                        value: 30
                    }
                    Label {
                        text: "dakika"
                    }
                }
            }
        }
        
        Item { Layout.fillHeight: true }
    }
}
