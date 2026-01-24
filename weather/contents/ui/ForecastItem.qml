import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import org.kde.kirigami as Kirigami

// ForecastItem.qml - Responsive Forecast Card Component
Item {
    id: itemRoot
    
    // Required properties from delegate
    required property string label // "FRI" or "5 PM"
    required property string iconPath
    required property int temp
    required property bool isHourly
    property string units: "metric"
    property bool showUnits: true
    
    // Responsive sizing properties
    property real availableWidth: 300  // Total ListView width
    property int cardCount: 5           // Number of cards
    property real cardSpacing: 2        // Spacing between cards
    
    // Calculate responsive width: divide available space equally
    readonly property real calculatedWidth: Math.max(55, Math.min(110, 
        (availableWidth - cardSpacing * (cardCount - 1)) / Math.max(1, cardCount)))
    
    implicitWidth: calculatedWidth
    implicitHeight: parent ? parent.height : 120
    
    // Corner Radii properties
    property real radiusTL: 10
    property real radiusTR: 10
    property real radiusBL: 10
    property real radiusBR: 10

    // Card Background - Using Shape for individual corner radii
    Shape {
        anchors.fill: parent
        // Enable multisampling for smoother edges if supported/needed
        layer.enabled: true
        layer.samples: 4

        ShapePath {
            strokeWidth: 0
            strokeColor: "transparent"
            fillColor: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.1)

            PathRectangle {
                x: 0; y: 0
                width: itemRoot.width
                height: itemRoot.height
                topLeftRadius: itemRoot.radiusTL
                topRightRadius: itemRoot.radiusTR
                bottomLeftRadius: itemRoot.radiusBL
                bottomRightRadius: itemRoot.radiusBR
            }
        }
    }

    // Hover effect overlay
    Shape {
        anchors.fill: parent
        visible: opacity > 0
        opacity: mouseArea.containsMouse ? 0.15 : 0
        Behavior on opacity { NumberAnimation { duration: 150 } }
        
        layer.enabled: true
        layer.samples: 4

        ShapePath {
            strokeWidth: 0
            strokeColor: "transparent"
            fillColor: Kirigami.Theme.highlightColor

            PathRectangle {
                x: 0; y: 0
                width: itemRoot.width
                height: itemRoot.height
                topLeftRadius: itemRoot.radiusTL
                topRightRadius: itemRoot.radiusTR
                bottomLeftRadius: itemRoot.radiusBL
                bottomRightRadius: itemRoot.radiusBR
            }
        }
    }
    
    // Content Column (centered)
    ColumnLayout {
        anchors.centerIn: parent
        width: parent.width - 8
        spacing: 4
        
        // Weather Icon (fixed size based on 70px min width)
        // Weather Icon (fixed size based on 70px min width)
        Kirigami.Icon {
            source: itemRoot.iconPath
            Layout.preferredWidth: 35  // 70 * 0.5 = 35
            Layout.preferredHeight: 35
            Layout.alignment: Qt.AlignHCenter
            isMask: false
            smooth: true
        }
        
        // Day/Time Label (fixed size based on 70px min width)
        Text {
            text: itemRoot.label
            color: Kirigami.Theme.textColor
            font.family: "Roboto Condensed"
            font.bold: true
            font.pixelSize: 13  // 70 * 0.18 ≈ 12.6
            Layout.alignment: Qt.AlignHCenter
            elide: Text.ElideRight
            Layout.maximumWidth: parent.width - 8
        }
        
        // Temperature (fixed size based on 70px min width)
        Text {
            text: itemRoot.temp + "°" + (itemRoot.showUnits ? (itemRoot.units === "imperial" ? "F" : "C") : "")
            color: Kirigami.Theme.textColor
            font.family: "Roboto Condensed"
            font.bold: true
            font.pixelSize: 18  // 70 * 0.25 = 17.5
            Layout.alignment: Qt.AlignHCenter
        }
    }
    
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
    }
}
