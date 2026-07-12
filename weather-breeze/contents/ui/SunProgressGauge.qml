import QtQuick
import QtQuick.Shapes
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

// Reusable sunrise and sunset progress gauge.
Item {
    id: gaugeRoot
    
    // Required: Unix timestamps or ISO strings for sunrise/sunset
    property var sunrise: null  // e.g., "2026-01-31T06:45" or 1706683500
    property var sunset: null   // e.g., "2026-01-31T17:30" or 1706722200
    
    // Configuration
    property color arcColor: Kirigami.Theme.highlightColor
    property color sunColor: Kirigami.Theme.highlightColor
    property color textColor: Kirigami.Theme.textColor
    property string fontFamily: Kirigami.Theme.defaultFont.family
    property real arcWidth: 4
    property int sunSize: Kirigami.Units.iconSizes.smallMedium
    property date currentTime: new Date()
    
    implicitWidth: Kirigami.Units.gridUnit * 11
    implicitHeight: Kirigami.Units.gridUnit * 5.5

    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: gaugeRoot.currentTime = new Date()
    }
    
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
        var rise = parseTime(sunrise)
        var set = parseTime(sunset)
        
        if (!rise || !set) return 0.5
        
        var riseTime = rise.getTime()
        var setTime = set.getTime()
        var nowTime = currentTime.getTime()
        
        if (nowTime < riseTime) return 0  // Before sunrise
        if (nowTime > setTime) return 1   // After sunset
        
        return (nowTime - riseTime) / (setTime - riseTime)
    }
    
    // Daylight state excludes the exact sunrise and sunset boundaries.
    readonly property bool isDaytime: sunProgress > 0 && sunProgress < 1
    
    // Format time for display
    function formatTime(value) {
        var d = parseTime(value)
        if (!d) return "--:--"
        return Qt.formatTime(d, Qt.locale().timeFormat(Locale.ShortFormat))
    }
    
    // Remaining daylight
    readonly property string remainingDaylight: {
        if (!isDaytime) return i18n("Night")
        
        var set = parseTime(sunset)
        if (!set) return "--"

        var diff = set.getTime() - currentTime.getTime()
        var hours = Math.floor(diff / (1000 * 60 * 60))
        var minutes = Math.floor((diff % (1000 * 60 * 60)) / (1000 * 60))
        
        if (hours > 0) {
            return i18n("%1h %2m left", hours, minutes)
        }
        return i18n("%1m left", minutes)
    }
    
    // Use the active Plasma/Kirigami card surface instead of a fixed sky palette.
    Kirigami.AbstractCard {
        anchors.fill: parent
    }
    
    // Arc container
    Item {
        id: arcContainer
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: Kirigami.Units.largeSpacing
        width: Math.min(parent.width - Kirigami.Units.largeSpacing * 4,
                        Kirigami.Units.gridUnit * 10)
        height: width / 2
        
        // Horizon line
        Rectangle {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: 1
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
        Kirigami.Icon {
            id: sunIndicator
            width: gaugeRoot.sunSize
            height: gaugeRoot.sunSize
            source: "weather-clear-symbolic"
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
            
            Behavior on x { NumberAnimation { duration: 1000; easing.type: Easing.InOutQuad } }
            Behavior on y { NumberAnimation { duration: 1000; easing.type: Easing.InOutQuad } }
        }

        // Moon indicator (when night)
        Kirigami.Icon {
            width: gaugeRoot.sunSize * 0.8
            height: gaugeRoot.sunSize * 0.8
            source: "weather-clear-night-symbolic"
            color: gaugeRoot.textColor
            visible: !gaugeRoot.isDaytime
            anchors.centerIn: parent
            anchors.verticalCenterOffset: -arcContainer.height * 0.3
        }
    }
    
    // Time labels
    Row {
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Kirigami.Units.smallSpacing
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: Kirigami.Units.largeSpacing
        anchors.rightMargin: Kirigami.Units.largeSpacing
        
        // Sunrise
        Column {
            width: parent.width / 3
            spacing: Kirigami.Units.smallSpacing / 2

            Kirigami.Icon {
                source: "weather-clear-symbolic"
                width: Kirigami.Units.iconSizes.smallMedium
                height: width
                color: gaugeRoot.arcColor
            }
            PlasmaComponents.Label {
                text: gaugeRoot.formatTime(gaugeRoot.sunrise)
                color: gaugeRoot.textColor
                font: Kirigami.Theme.defaultFont
                font.family: gaugeRoot.fontFamily
                font.weight: Font.DemiBold
            }
            PlasmaComponents.Label {
                text: i18n("Sunrise")
                color: gaugeRoot.textColor
                font: Kirigami.Theme.smallFont
                font.family: gaugeRoot.fontFamily
                opacity: 0.6
            }
        }
        
        // Remaining daylight
        Column {
            width: parent.width / 3
            spacing: Kirigami.Units.smallSpacing / 2
            horizontalAlignment: Text.AlignHCenter

            Kirigami.Icon {
                source: gaugeRoot.isDaytime ? "weather-few-clouds-symbolic" : "weather-clear-night-symbolic"
                width: Kirigami.Units.iconSizes.smallMedium
                height: width
                color: gaugeRoot.arcColor
                anchors.horizontalCenter: parent.horizontalCenter
            }
            PlasmaComponents.Label {
                text: gaugeRoot.remainingDaylight
                color: gaugeRoot.textColor
                font: Kirigami.Theme.defaultFont
                font.family: gaugeRoot.fontFamily
                font.weight: Font.DemiBold
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
        
        // Sunset
        Column {
            width: parent.width / 3
            spacing: Kirigami.Units.smallSpacing / 2
            horizontalAlignment: Text.AlignRight

            Kirigami.Icon {
                source: "weather-clear-night-symbolic"
                width: Kirigami.Units.iconSizes.smallMedium
                height: width
                color: gaugeRoot.arcColor
                anchors.right: parent.right
            }
            PlasmaComponents.Label {
                text: gaugeRoot.formatTime(gaugeRoot.sunset)
                color: gaugeRoot.textColor
                font: Kirigami.Theme.defaultFont
                font.family: gaugeRoot.fontFamily
                font.weight: Font.DemiBold
                anchors.right: parent.right
            }
            PlasmaComponents.Label {
                text: i18n("Sunset")
                color: gaugeRoot.textColor
                font: Kirigami.Theme.smallFont
                font.family: gaugeRoot.fontFamily
                opacity: 0.6
                anchors.right: parent.right
            }
        }
    }
}
