import QtQuick
import QtQuick.Shapes
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

// Reusable temperature and precipitation chart.
Item {
    id: chartRoot

    // Required: Array of forecast data (daily or hourly)
    property var forecastData: []
    
    // Configuration
    property bool showPrecipitation: true
    property string units: "metric"
    property color textColor: Kirigami.Theme.textColor
    property color accentColor: Kirigami.Theme.highlightColor
    property color temperatureColor: Kirigami.Theme.negativeTextColor
    property color precipitationColor: Kirigami.Theme.highlightColor
    property string fontFamily: Kirigami.Theme.defaultFont.family
    property int chartHeight: Kirigami.Units.gridUnit * 6
    property int labelHeight: Kirigami.Units.gridUnit
    
    implicitHeight: chartHeight + labelHeight * 2
    implicitWidth: Kirigami.Units.gridUnit * 16
    
    // Calculate min/max values
    readonly property real minTemp: {
        if (!forecastData || forecastData.length === 0) return 0
        var min = forecastData[0].temp_min || forecastData[0].temp
        for (var i = 1; i < forecastData.length; i++) {
            var t = forecastData[i].temp_min || forecastData[i].temp
            if (t < min) min = t
        }
        return min - 2
    }
    
    readonly property real maxTemp: {
        if (!forecastData || forecastData.length === 0) return 30
        var max = forecastData[0].temp_max || forecastData[0].temp
        for (var i = 1; i < forecastData.length; i++) {
            var t = forecastData[i].temp_max || forecastData[i].temp
            if (t > max) max = t
        }
        return max + 2
    }
    
    readonly property real tempRange: maxTemp - minTemp
    readonly property real maxPrecip: {
        if (!forecastData || forecastData.length === 0) return 10
        var max = 0
        for (var i = 0; i < forecastData.length; i++) {
            var p = forecastData[i].precipitation || 0
            if (p > max) max = p
        }
        return Math.max(max, 1)
    }
    
    // Helper to map temp to Y position
    function tempToY(temp) {
        return chartHeight - ((temp - minTemp) / tempRange) * chartHeight
    }
    
    // Helper to map precipitation to Y position
    function precipToY(precip) {
        return chartHeight - (precip / maxPrecip) * chartHeight * 0.6
    }
    
    // Y-axis labels
    Column {
        anchors.left: parent.left
        anchors.top: chartArea.top
        anchors.bottom: chartArea.bottom
        width: Kirigami.Units.gridUnit * 2
        
        PlasmaComponents.Label {
            id: maximumLabel
            text: Math.round(chartRoot.maxTemp) + "°"
            color: chartRoot.textColor
            font: Kirigami.Theme.smallFont
            font.family: chartRoot.fontFamily
            opacity: 0.7
        }
        
        Item {
            width: 1
            height: Math.max(0, parent.height - maximumLabel.implicitHeight - minimumLabel.implicitHeight)
        }

        PlasmaComponents.Label {
            id: minimumLabel
            text: Math.round(chartRoot.minTemp) + "°"
            color: chartRoot.textColor
            font: Kirigami.Theme.smallFont
            font.family: chartRoot.fontFamily
            opacity: 0.7
        }
    }
    
    // Chart area
    Item {
        id: chartArea
        anchors.left: parent.left
        anchors.leftMargin: Kirigami.Units.gridUnit * 2
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.topMargin: labelHeight
        height: chartRoot.chartHeight
        
        // Grid lines
        Repeater {
            model: 5
            Rectangle {
                y: index * (chartArea.height / 4)
                width: chartArea.width
                height: 1
                color: Qt.rgba(chartRoot.textColor.r, chartRoot.textColor.g, chartRoot.textColor.b, 0.1)
            }
        }
        
        // Precipitation bars (background)
        Row {
            anchors.fill: parent
            spacing: 0
            visible: chartRoot.showPrecipitation
            
            Repeater {
                model: chartRoot.forecastData
                
                Rectangle {
                    width: chartArea.width / (chartRoot.forecastData.length || 1)
                    height: {
                        var precip = modelData.precipitation || 0
                        return (precip / chartRoot.maxPrecip) * chartArea.height * 0.6
                    }
                    anchors.bottom: parent.bottom
                    color: Qt.rgba(chartRoot.precipitationColor.r, chartRoot.precipitationColor.g, chartRoot.precipitationColor.b, 0.3)
                    radius: Kirigami.Units.smallSpacing / 2
                }
            }
        }
        
        // Temperature line using Shape
        Shape {
            anchors.fill: parent
            
            ShapePath {
                strokeColor: chartRoot.temperatureColor
                strokeWidth: 2
                fillColor: "transparent"
                
                startX: 0
                startY: chartRoot.forecastData.length > 0 ? chartRoot.tempToY(chartRoot.forecastData[0].temp) : chartArea.height / 2
                
                PathPolyline {
                    path: {
                        var points = []
                        var stepX = chartArea.width / Math.max(1, chartRoot.forecastData.length - 1)
                        
                        for (var i = 0; i < chartRoot.forecastData.length; i++) {
                            var temp = chartRoot.forecastData[i].temp
                            points.push(Qt.point(i * stepX, chartRoot.tempToY(temp)))
                        }
                        
                        return points
                    }
                }
            }
        }
        
        // Data points
        Repeater {
            model: chartRoot.forecastData
            
            Rectangle {
                x: (index * chartArea.width / Math.max(1, chartRoot.forecastData.length - 1)) - width / 2
                y: chartRoot.tempToY(modelData.temp) - height / 2
                width: Kirigami.Units.smallSpacing
                height: width
                radius: width / 2
                color: chartRoot.temperatureColor
                border.width: 2
                border.color: Kirigami.Theme.backgroundColor
            }
        }
    }
    
    // X-axis labels (days/hours)
    Row {
        anchors.top: chartArea.bottom
        anchors.topMargin: Kirigami.Units.smallSpacing
        anchors.left: chartArea.left
        anchors.right: chartArea.right
        
        Repeater {
            model: chartRoot.forecastData
            
            PlasmaComponents.Label {
                width: chartArea.width / (chartRoot.forecastData.length || 1)
                text: modelData.time || Qt.locale().dayName(modelData.day, Locale.NarrowFormat)
                color: chartRoot.textColor
                font: Kirigami.Theme.smallFont
                font.family: chartRoot.fontFamily
                horizontalAlignment: Text.AlignHCenter
                opacity: 0.7
            }
        }
    }
    
    // Legend
    Row {
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: Kirigami.Units.largeSpacing
        
        Row {
            spacing: Kirigami.Units.smallSpacing
            Rectangle {
                width: Kirigami.Units.gridUnit; height: Math.max(2, Kirigami.Units.smallSpacing / 2)
                color: chartRoot.temperatureColor
                radius: 1
                anchors.verticalCenter: parent.verticalCenter
            }
            PlasmaComponents.Label {
                text: i18n("Temperature")
                color: chartRoot.textColor
                font: Kirigami.Theme.smallFont
                opacity: 0.7
            }
        }
        
        Row {
            spacing: Kirigami.Units.smallSpacing
            visible: chartRoot.showPrecipitation
            Rectangle {
                width: Kirigami.Units.gridUnit; height: Kirigami.Units.smallSpacing
                color: Qt.rgba(chartRoot.precipitationColor.r, chartRoot.precipitationColor.g, chartRoot.precipitationColor.b, 0.3)
                radius: 2
                anchors.verticalCenter: parent.verticalCenter
            }
            PlasmaComponents.Label {
                text: i18n("Precipitation")
                color: chartRoot.textColor
                font: Kirigami.Theme.smallFont
                opacity: 0.7
            }
        }
    }
}
