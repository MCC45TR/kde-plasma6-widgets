import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import org.kde.kirigami as Kirigami

Item {
    id: itemRoot

    required property string label
    required property string iconPath
    required property int temp
    required property bool isHourly
    property bool isHorizontalLayout: false
    property bool showBackground: true
    property string units: "metric"
    property bool showUnits: true
    property string fontFamily: Kirigami.Theme.defaultFont.family
    
    property var forecastData: null
    property int itemIndex: 0
    property bool hasDetails: forecastData && forecastData.hasDetails === true
    
    signal clicked(var data, int index, rect cardRect)

    property real availableWidth: 300
    property int cardCount: 5
    property real cardSpacing: 2

    readonly property real calculatedWidth: Math.max(55, Math.min(110,
        (availableWidth - cardSpacing * (cardCount - 1)) / Math.max(1, cardCount)))

    implicitWidth: calculatedWidth
    implicitHeight: parent ? parent.height : 120
    clip: true

    property real radiusTL: 10
    property real radiusTR: 10
    property real radiusBL: 10
    property real radiusBR: 10

    Shape {
        anchors.fill: parent
        layer.enabled: true
        layer.samples: 4

        ShapePath {
            strokeWidth: 0
            strokeColor: "transparent"
            fillColor: itemRoot.showBackground ? Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.1) : "transparent"

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

    ColumnLayout {
        visible: !itemRoot.isHorizontalLayout
        anchors.centerIn: parent
        width: parent.width - 8
        spacing: 4

        Kirigami.Icon {
            source: itemRoot.iconPath
            Layout.preferredWidth: 35
            Layout.preferredHeight: 35
            Layout.alignment: Qt.AlignHCenter
            isMask: false
            smooth: true
        }

        Text {
            text: itemRoot.label
            color: Kirigami.Theme.textColor
            font.family: itemRoot.fontFamily
            font.bold: true
            font.pixelSize: 13
            Layout.alignment: Qt.AlignHCenter
            elide: Text.ElideRight
            Layout.maximumWidth: parent.width - 8
        }

        Text {
            text: itemRoot.temp + "°" + (itemRoot.showUnits ? (itemRoot.units === "imperial" ? "F" : "C") : "")
            color: Kirigami.Theme.textColor
            font.family: itemRoot.fontFamily
            font.bold: true
            font.pixelSize: 18
            Layout.alignment: Qt.AlignHCenter
        }
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0
        visible: itemRoot.isHorizontalLayout

        // Left: Icon Area
        Item {
            Layout.preferredHeight: parent.height
            Layout.preferredWidth: parent.height // Square aspect ratio
            
            Kirigami.Icon {
                anchors.centerIn: parent
                width: parent.width - 20
                height: parent.height - 20           
                source: itemRoot.iconPath
                isMask: false
                smooth: true
            }
        }

        // Right: Text Area
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0
            
            // Top: Day (Yellow Area placeholder)
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                
                Text {
                    anchors.centerIn: parent
                    text: itemRoot.label
                    color: Kirigami.Theme.textColor
                    font.family: itemRoot.fontFamily
                    font.bold: true
                    font.pixelSize: parent.height * 0.4
                    elide: Text.ElideRight
                }
            }
            
            // Bottom: Temp (Green Area placeholder)
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                
                Text {
                    anchors.centerIn: parent
                    // Reuse unit logic or simplify
                    text: itemRoot.temp + "°"
                    color: Kirigami.Theme.textColor
                    font.family: itemRoot.fontFamily
                    font.bold: true
                    font.pixelSize: parent.height * 0.5
                }
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: itemRoot.hasDetails ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: function(mouse) {
            if (itemRoot.hasDetails && itemRoot.forecastData) {
                var globalPos = itemRoot.mapToGlobal(0, 0)
                itemRoot.clicked(itemRoot.forecastData, itemRoot.itemIndex, Qt.rect(globalPos.x, globalPos.y, itemRoot.width, itemRoot.height))
            }
        }
    }
}
