import QtQuick
import QtQuick.Shapes
import org.kde.kirigami as Kirigami

// SunProgressGauge - Displays sunrise/sunset arc with current sun position
// TODO: Not yet integrated into UI - add to WeatherDetailsView or LargeModeLayout
Item {
    id: gaugeRoot
    
    // Required: Unix timestamps or ISO strings for sunrise/sunset
    property var sunrise: null  // e.g., "2026-01-31T06:45" or 1706683500
    property var sunset: null   // e.g., "2026-01-31T17:30" or 1706722200
    
    // Configuration
    property color arcColor: Kirigami.Theme.highlightColor
    property color sunColor: "#ffc107"
    property color skyDayColor: "#87CEEB"
    property color skyNightColor: "#1a1a2e"
    property color textColor: Kirigami.Theme.textColor
    property string fontFamily: "Roboto Condensed"
    property real arcWidth: 4
    property int sunSize: 16
    
    implicitWidth: 200
    implicitHeight: 100
    
    // Parse time helper
    function parseTime(value) {
        if (!value) return null
        if (typeof value === "number") {
            return new Date(value * 1000) // Unix timestamp
        }
        return new Date(value) // ISO string
    }
    
    // Current sun progress (0 = sunrise, 1 = sunset)
    readonly property real sunProgress: {
        var now = new Date()
        var rise = parseTime(sunrise)
        var set = parseTime(sunset)
        
        if (!rise || !set) return 0.5
        
        var riseTime = rise.getTime()
        var setTime = set.getTime()
        var nowTime = now.getTime()
        
        if (nowTime < riseTime) return 0  // Before sunrise
        if (nowTime > setTime) return 1   // After sunset
        
        return (nowTime - riseTime) / (setTime - riseTime)
    }
    
    // Is it currently daytime?
    readonly property bool isDaytime: sunProgress > 0 && sunProgress < 1
    
    // Format time for display
    function formatTime(value) {
        var d = parseTime(value)
        if (!d) return "--:--"
        return d.getHours().toString().padStart(2, '0') + ":" + 
               d.getMinutes().toString().padStart(2, '0')
    }
    
    // Remaining daylight
    readonly property string remainingDaylight: {
        if (!isDaytime) return i18n("Night")
        
        var now = new Date()
        var set = parseTime(sunset)
        if (!set) return "--"
        
        var diff = set.getTime() - now.getTime()
        var hours = Math.floor(diff / (1000 * 60 * 60))
        var minutes = Math.floor((diff % (1000 * 60 * 60)) / (1000 * 60))
        
        if (hours > 0) {
            return i18n("%1h %2m left", hours, minutes)
        }
        return i18n("%1m left", minutes)
    }
    
    // Background gradient representing sky
    Rectangle {
        anchors.fill: parent
        radius: 8
        gradient: Gradient {
            GradientStop { 
                position: 0.0
                color: gaugeRoot.isDaytime ? 
                    Qt.lighter(gaugeRoot.skyDayColor, 1.2) : 
                    gaugeRoot.skyNightColor
            }
            GradientStop { 
                position: 1.0
                color: gaugeRoot.isDaytime ? 
                    gaugeRoot.skyDayColor : 
                    Qt.darker(gaugeRoot.skyNightColor, 1.3)
            }
        }
        opacity: 0.2
    }
    
    // Arc container
    Item {
        id: arcContainer
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 10
        width: Math.min(parent.width - 40, 180)
        height: width / 2
        
        // Horizon line
        Rectangle {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: 2
            color: Qt.rgba(gaugeRoot.textColor.r, gaugeRoot.textColor.g, gaugeRoot.textColor.b, 0.3)
        }
        
        // Sun path arc (semi-circle)
        Shape {
            anchors.fill: parent
            
            ShapePath {
                strokeColor: Qt.rgba(gaugeRoot.arcColor.r, gaugeRoot.arcColor.g, gaugeRoot.arcColor.b, 0.3)
                strokeWidth: gaugeRoot.arcWidth
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap
                
                startX: 0
                startY: arcContainer.height
                
                PathArc {
                    x: arcContainer.width
                    y: arcContainer.height
                    radiusX: arcContainer.width / 2
                    radiusY: arcContainer.height
                    useLargeArc: false
                    direction: PathArc.Counterclockwise
                }
            }
            
            // Progress arc (filled portion)
            ShapePath {
                strokeColor: gaugeRoot.arcColor
                strokeWidth: gaugeRoot.arcWidth
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap
                
                startX: 0
                startY: arcContainer.height
                
                PathArc {
                    x: {
                        var angle = Math.PI * gaugeRoot.sunProgress
                        return arcContainer.width / 2 + (arcContainer.width / 2) * Math.cos(Math.PI - angle)
                    }
                    y: {
                        var angle = Math.PI * gaugeRoot.sunProgress
                        return arcContainer.height - arcContainer.height * Math.sin(angle)
                    }
                    radiusX: arcContainer.width / 2
                    radiusY: arcContainer.height
                    useLargeArc: gaugeRoot.sunProgress > 0.5
                    direction: PathArc.Counterclockwise
                }
            }
        }
        
        // Sun indicator
        Rectangle {
            id: sunIndicator
            width: gaugeRoot.sunSize
            height: gaugeRoot.sunSize
            radius: gaugeRoot.sunSize / 2
            color: gaugeRoot.sunColor
            visible: gaugeRoot.isDaytime
            
            x: {
                var angle = Math.PI * gaugeRoot.sunProgress
                return arcContainer.width / 2 + (arcContainer.width / 2) * Math.cos(Math.PI - angle) - width / 2
            }
            y: {
                var angle = Math.PI * gaugeRoot.sunProgress
                return arcContainer.height - arcContainer.height * Math.sin(angle) - height / 2
            }
            
            // Glow effect
            Rectangle {
                anchors.centerIn: parent
                width: parent.width * 1.5
                height: parent.height * 1.5
                radius: width / 2
                color: gaugeRoot.sunColor
                opacity: 0.3
                z: -1
            }
            
            Behavior on x { NumberAnimation { duration: 1000; easing.type: Easing.InOutQuad } }
            Behavior on y { NumberAnimation { duration: 1000; easing.type: Easing.InOutQuad } }
        }
        
        // Moon indicator (when night)
        Rectangle {
            width: gaugeRoot.sunSize * 0.8
            height: gaugeRoot.sunSize * 0.8
            radius: width / 2
            color: "#e0e0e0"
            visible: !gaugeRoot.isDaytime
            anchors.centerIn: parent
            anchors.verticalCenterOffset: -arcContainer.height * 0.3
        }
    }
    
    // Time labels
    Row {
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 4
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        
        // Sunrise
        Column {
            width: parent.width / 3
            spacing: 2
            
            Text {
                text: "☀️"
                font.pixelSize: 14
            }
            Text {
                text: gaugeRoot.formatTime(gaugeRoot.sunrise)
                color: gaugeRoot.textColor
                font.pixelSize: 11
                font.family: gaugeRoot.fontFamily
                font.bold: true
            }
            Text {
                text: i18n("Sunrise")
                color: gaugeRoot.textColor
                font.pixelSize: 9
                font.family: gaugeRoot.fontFamily
                opacity: 0.6
            }
        }
        
        // Remaining daylight
        Column {
            width: parent.width / 3
            spacing: 2
            horizontalAlignment: Text.AlignHCenter
            
            Text {
                text: gaugeRoot.isDaytime ? "🌤️" : "🌙"
                font.pixelSize: 14
                anchors.horizontalCenter: parent.horizontalCenter
            }
            Text {
                text: gaugeRoot.remainingDaylight
                color: gaugeRoot.textColor
                font.pixelSize: 11
                font.family: gaugeRoot.fontFamily
                font.bold: true
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
        
        // Sunset
        Column {
            width: parent.width / 3
            spacing: 2
            horizontalAlignment: Text.AlignRight
            
            Text {
                text: "🌅"
                font.pixelSize: 14
                anchors.right: parent.right
            }
            Text {
                text: gaugeRoot.formatTime(gaugeRoot.sunset)
                color: gaugeRoot.textColor
                font.pixelSize: 11
                font.family: gaugeRoot.fontFamily
                font.bold: true
                anchors.right: parent.right
            }
            Text {
                text: i18n("Sunset")
                color: gaugeRoot.textColor
                font.pixelSize: 9
                font.family: gaugeRoot.fontFamily
                opacity: 0.6
                anchors.right: parent.right
            }
        }
    }
}
