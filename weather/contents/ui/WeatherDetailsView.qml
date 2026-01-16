import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.kirigami as Kirigami

ColumnLayout {
    id: detailsView
    property var weatherRoot
    property string weatherProvider: "" // Optional if needed explicitly

    spacing: 8

    // Header Row - Compact
    RowLayout {
        Layout.fillWidth: true
        spacing: 10
        
        // Icon
        Image {
            source: weatherRoot.getWeatherIcon(weatherRoot.currentWeather)
            Layout.preferredHeight: 50
            Layout.preferredWidth: 50
            sourceSize.width: 100
            sourceSize.height: 100
            fillMode: Image.PreserveAspectFit
        }
        
        // Location & Condition
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0
            
            Text {
                text: weatherRoot.currentWeather ? weatherRoot.currentWeather.location : weatherRoot.location
                color: Kirigami.Theme.textColor
                font.family: "Roboto Condensed"
                font.bold: true
                font.pixelSize: 16
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
            
            Text {
                text: weatherRoot.currentWeather ? weatherRoot.tr("condition_" + weatherRoot.currentWeather.condition.toLowerCase().replace(/ /g, "_")) : ""
                color: Kirigami.Theme.textColor
                opacity: 0.7
                font.pixelSize: 12
            }
        }
        
        // Temperature Block
        ColumnLayout {
            spacing: 0
            
            RowLayout {
                spacing: 0
                Text {
                    text: weatherRoot.currentWeather ? weatherRoot.currentWeather.temp : "--"
                    color: Kirigami.Theme.textColor
                    font.family: "Roboto Condensed"
                    font.bold: true
                    font.pixelSize: 36
                }
                Text {
                    text: "°"
                    color: Kirigami.Theme.textColor
                    font.family: "Roboto Condensed"
                    font.bold: true
                    font.pixelSize: 22
                    Layout.alignment: Qt.AlignTop
                }
            }
            
            // High/Low inline
            RowLayout {
                spacing: 8
                Layout.alignment: Qt.AlignHCenter
                RowLayout {
                    spacing: 2
                    Text { text: "▲"; color: Kirigami.Theme.positiveTextColor; font.pixelSize: 11 }
                    Text { text: weatherRoot.currentWeather ? weatherRoot.currentWeather.temp_max + "°" : "--"; color: Kirigami.Theme.textColor; font.pixelSize: 11 }
                }
                RowLayout {
                    spacing: 2
                    Text { text: "▼"; color: Kirigami.Theme.negativeTextColor; font.pixelSize: 11 }
                    Text { text: weatherRoot.currentWeather ? weatherRoot.currentWeather.temp_min + "°" : "--"; color: Kirigami.Theme.textColor; font.pixelSize: 11 }
                }
            }
        }
    }
    
    // Stats Cards Row 1
    RowLayout {
        Layout.fillWidth: true
        spacing: 6
        
        // Card: Feels Like
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 45
            radius: 8
            color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.05)
            visible: weatherRoot.currentWeather && weatherRoot.currentWeather.feels_like !== undefined
            
            ColumnLayout {
                anchors.centerIn: parent
                spacing: 1
                Text { text: weatherRoot.tr("feels_like"); color: Kirigami.Theme.textColor; opacity: 0.6; font.pixelSize: 9; Layout.alignment: Qt.AlignHCenter }
                Text { 
                    text: (weatherRoot.currentWeather && weatherRoot.currentWeather.feels_like !== undefined) ? weatherRoot.currentWeather.feels_like + "°" : "--"
                    color: Kirigami.Theme.textColor; font.pixelSize: 15; font.bold: true; Layout.alignment: Qt.AlignHCenter 
                }
            }
        }
        
        // Card: Humidity
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 45
            radius: 8
            color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.05)
            visible: weatherRoot.currentWeather && weatherRoot.currentWeather.humidity !== undefined
            
            ColumnLayout {
                anchors.centerIn: parent
                spacing: 1
                Text { text: "💧 " + weatherRoot.tr("humidity"); color: Kirigami.Theme.textColor; opacity: 0.6; font.pixelSize: 9; Layout.alignment: Qt.AlignHCenter }
                Text { 
                    text: (weatherRoot.currentWeather && weatherRoot.currentWeather.humidity !== undefined) ? weatherRoot.currentWeather.humidity + "%" : "--"
                    color: Kirigami.Theme.textColor; font.pixelSize: 15; font.bold: true; Layout.alignment: Qt.AlignHCenter 
                }
            }
        }
        
        // Card: Wind
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 45
            radius: 8
            color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.05)
            visible: weatherRoot.currentWeather && weatherRoot.currentWeather.wind_speed !== undefined
            
            ColumnLayout {
                anchors.centerIn: parent
                spacing: 1
                Text { text: "💨 " + weatherRoot.tr("wind"); color: Kirigami.Theme.textColor; opacity: 0.6; font.pixelSize: 9; Layout.alignment: Qt.AlignHCenter }
                Text { 
                    text: (weatherRoot.currentWeather && weatherRoot.currentWeather.wind_speed !== undefined) ? weatherRoot.currentWeather.wind_speed + " km/h" : "--"
                    color: Kirigami.Theme.textColor; font.pixelSize: 13; font.bold: true; Layout.alignment: Qt.AlignHCenter 
                }
            }
        }
        
        // Card: Pressure
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 45
            radius: 8
            color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.05)
            visible: weatherRoot.currentWeather && weatherRoot.currentWeather.pressure !== undefined && weatherRoot.currentWeather.pressure !== null
            
            ColumnLayout {
                anchors.centerIn: parent
                spacing: 1
                Text { text: weatherRoot.tr("pressure"); color: Kirigami.Theme.textColor; opacity: 0.6; font.pixelSize: 9; Layout.alignment: Qt.AlignHCenter }
                Text { 
                    text: (weatherRoot.currentWeather && weatherRoot.currentWeather.pressure !== undefined && weatherRoot.currentWeather.pressure !== null) ? weatherRoot.currentWeather.pressure + " hPa" : "--"
                    color: Kirigami.Theme.textColor; font.pixelSize: 11; font.bold: true; Layout.alignment: Qt.AlignHCenter 
                }
            }
        }
    }
    
    // Stats Cards Row 2
    RowLayout {
        Layout.fillWidth: true
        spacing: 6
        visible: {
            // Only show this row if at least one card has data
            var hasData = weatherRoot.currentWeather && (
                weatherRoot.currentWeather.clouds !== undefined ||
                weatherRoot.currentWeather.uv_index !== undefined ||
                weatherRoot.currentWeather.visibility !== undefined ||
                weatherRoot.currentWeather.wind_deg !== undefined
            )
            return hasData
        }
        
        // Card: Clouds
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 45
            radius: 8
            color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.05)
            visible: weatherRoot.currentWeather && weatherRoot.currentWeather.clouds !== undefined
            
            ColumnLayout {
                anchors.centerIn: parent
                spacing: 1
                Text { text: "☁️ " + weatherRoot.tr("clouds"); color: Kirigami.Theme.textColor; opacity: 0.6; font.pixelSize: 9; Layout.alignment: Qt.AlignHCenter }
                Text { 
                    text: (weatherRoot.currentWeather && weatherRoot.currentWeather.clouds !== undefined) ? weatherRoot.currentWeather.clouds + "%" : "--"
                    color: Kirigami.Theme.textColor; font.pixelSize: 15; font.bold: true; Layout.alignment: Qt.AlignHCenter 
                }
            }
        }
        
        // Card: UV Index
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 45
            radius: 8
            color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.05)
            visible: weatherRoot.currentWeather && weatherRoot.currentWeather.uv_index !== undefined
            
            ColumnLayout {
                anchors.centerIn: parent
                spacing: 1
                Text { text: "☀️ " + weatherRoot.tr("uv_index"); color: Kirigami.Theme.textColor; opacity: 0.6; font.pixelSize: 9; Layout.alignment: Qt.AlignHCenter }
                Text { 
                    text: (weatherRoot.currentWeather && weatherRoot.currentWeather.uv_index !== undefined && weatherRoot.currentWeather.uv_index !== null) ? weatherRoot.currentWeather.uv_index.toString() : "--"
                    color: {
                        var uv = (weatherRoot.currentWeather && weatherRoot.currentWeather.uv_index !== undefined) ? weatherRoot.currentWeather.uv_index : 0
                        if (uv >= 11) return "#8B3FC7"
                        if (uv >= 8) return "#D90011"
                        if (uv >= 6) return "#F95901"
                        if (uv >= 3) return "#F7E400"
                        return Kirigami.Theme.textColor
                    }
                    font.pixelSize: 15; font.bold: true; Layout.alignment: Qt.AlignHCenter 
                }
            }
        }
        
        // Card: Visibility
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 45
            radius: 8
            color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.05)
            visible: weatherRoot.currentWeather && weatherRoot.currentWeather.visibility !== undefined && weatherRoot.currentWeather.visibility !== null
            
            ColumnLayout {
                anchors.centerIn: parent
                spacing: 1
                Text { text: "👁️ " + weatherRoot.tr("visibility"); color: Kirigami.Theme.textColor; opacity: 0.6; font.pixelSize: 9; Layout.alignment: Qt.AlignHCenter }
                Text { 
                    text: (weatherRoot.currentWeather && weatherRoot.currentWeather.visibility !== undefined && weatherRoot.currentWeather.visibility !== null) ? weatherRoot.currentWeather.visibility + " km" : "--"
                    color: Kirigami.Theme.textColor; font.pixelSize: 13; font.bold: true; Layout.alignment: Qt.AlignHCenter 
                }
            }
        }
        
        // Card: Wind Direction
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 45
            radius: 8
            color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.05)
            visible: weatherRoot.currentWeather && weatherRoot.currentWeather.wind_deg !== undefined
            
            ColumnLayout {
                anchors.centerIn: parent
                spacing: 1
                Text { text: "🧭 " + weatherRoot.tr("wind_direction"); color: Kirigami.Theme.textColor; opacity: 0.6; font.pixelSize: 9; Layout.alignment: Qt.AlignHCenter }
                Text { 
                    text: {
                        if (!weatherRoot.currentWeather || weatherRoot.currentWeather.wind_deg === undefined) return "--"
                        var deg = weatherRoot.currentWeather.wind_deg
                        var dirs = ["K", "KD", "D", "GD", "G", "GB", "B", "KB"]
                        return dirs[Math.round(deg / 45) % 8]
                    }
                    color: Kirigami.Theme.textColor; font.pixelSize: 13; font.bold: true; Layout.alignment: Qt.AlignHCenter 
                }
            }
        }
    }
    
    // Sunrise/Sunset Row
    RowLayout {
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignHCenter
        spacing: 20
        visible: weatherRoot.currentWeather && (weatherRoot.currentWeather.sunrise !== undefined || weatherRoot.currentWeather.sunset !== undefined)
        RowLayout {
            spacing: 6
            Text { text: "🌅"; font.pixelSize: 14 }
            Text { 
                text: {
                    if (!weatherRoot.currentWeather || !weatherRoot.currentWeather.sunrise) return "--"
                    var sr = weatherRoot.currentWeather.sunrise
                    if (typeof sr === "number") {
                        var d = new Date(sr * 1000)
                        return d.getHours().toString().padStart(2, '0') + ":" + d.getMinutes().toString().padStart(2, '0')
                    } else if (typeof sr === "string") {
                        var d2 = new Date(sr)
                        return d2.getHours().toString().padStart(2, '0') + ":" + d2.getMinutes().toString().padStart(2, '0')
                    }
                    return "--"
                }
                color: Kirigami.Theme.textColor; font.pixelSize: 12; font.bold: true 
            }
        }
        
        RowLayout {
            spacing: 6
            Text { text: "🌇"; font.pixelSize: 14 }
            Text { 
                text: {
                    if (!weatherRoot.currentWeather || !weatherRoot.currentWeather.sunset) return "--"
                    var ss = weatherRoot.currentWeather.sunset
                    if (typeof ss === "number") {
                        var d = new Date(ss * 1000)
                        return d.getHours().toString().padStart(2, '0') + ":" + d.getMinutes().toString().padStart(2, '0')
                    } else if (typeof ss === "string") {
                        var d2 = new Date(ss)
                        return d2.getHours().toString().padStart(2, '0') + ":" + d2.getMinutes().toString().padStart(2, '0')
                    }
                    return "--"
                }
                color: Kirigami.Theme.textColor; font.pixelSize: 12; font.bold: true 
            }
        }
    }
    
    // Close hint
    Text {
        text: weatherRoot.tr("close_hint")
        color: Kirigami.Theme.textColor
        opacity: 0.4
        font.pixelSize: 10
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: 5
    }
}
