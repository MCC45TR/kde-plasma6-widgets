import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: configRoot
    
    property alias cfg_apiKey: apiKeyField.text
    property alias cfg_apiKey2: apiKey2Field.text
    property alias cfg_location: locationField.text
    property alias cfg_units: unitsCombo.currentIndex  
    property alias cfg_updateInterval: updateIntervalSpinBox.value
    
    // Units mapping
    property var unitsModel: ["metric", "imperial"]
    
    Component.onCompleted: {
        // Set units combo index from config
        var unitValue = plasmoid.configuration.units || "metric"
        cfg_units = unitsModel.indexOf(unitValue)
    }
    
    ColumnLayout {
        anchors.fill: parent
        spacing: 15
        
        // API Keys Section
        GroupBox {
            title: "API Keys"
            Layout.fillWidth: true
            
            ColumnLayout {
                anchors.fill: parent
                spacing: 10
                
                Label {
                    text: "OpenWeatherMap API Key (Primary):"
                    font.bold: true
                }
                TextField {
                    id: apiKeyField
                    Layout.fillWidth: true
                    placeholderText: "Enter your OpenWeatherMap API key"
                }
                
                Label {
                    text: "Get your free API key at: https://openweathermap.org/api"
                    font.pixelSize: 10
                    opacity: 0.7
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
                
                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: "gray"
                    opacity: 0.3
                }
                
                Label {
                    text: "WeatherAPI.com API Key (Fallback):"
                    font.bold: true
                }
                TextField {
                    id: apiKey2Field
                    Layout.fillWidth: true
                    placeholderText: "Optional: WeatherAPI.com key for fallback"
                }
                
                Label {
                    text: "Get your free API key at: https://www.weatherapi.com/"
                    font.pixelSize: 10
                    opacity: 0.7
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
            }
        }
        
        // Location Section
        GroupBox {
            title: "Location"
            Layout.fillWidth: true
            
            ColumnLayout {
                anchors.fill: parent
                spacing: 10
                
                Label {
                    text: "City Name:"
                    font.bold: true
                }
                TextField {
                    id: locationField
                    Layout.fillWidth: true
                    placeholderText: "e.g., Ankara, Istanbul, London"
                }
                
                Label {
                    text: "You can use: City name, City,Country code, or ZIP code"
                    font.pixelSize: 10
                    opacity: 0.7
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
            }
        }
        
        // Units Section
        GroupBox {
            title: "Settings"
            Layout.fillWidth: true
            
            GridLayout {
                anchors.fill: parent
                columns: 2
                rowSpacing: 10
                columnSpacing: 10
                
                Label {
                    text: "Units:"
                    font.bold: true
                }
                ComboBox {
                    id: unitsCombo
                    Layout.fillWidth: true
                    model: ["Metric (°C)", "Imperial (°F)"]
                    
                    onCurrentIndexChanged: {
                        plasmoid.configuration.units = configRoot.unitsModel[currentIndex]
                    }
                }
                
                Label {
                    text: "Update Interval:"
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
                        text: "minutes"
                    }
                }
            }
        }
        
        Item { Layout.fillHeight: true }
    }
}
