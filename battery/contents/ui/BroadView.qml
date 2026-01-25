import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import QtQuick.Shapes

Item {
    id: root
    
    // Expects 'devices' list from logic
    property var devices: [] 
    // Expects 'mainDevice' object
    property var mainDevice: null
    property string hostName: ""

    // "Broad" View: > 350w, < 350h
    
    RowLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 12
        
        // Bars container
        RowLayout {
            Layout.fillHeight: true
            spacing: 8
            
            Repeater {
                model: devices.filter(d => !d.isMain) 
                
                BatteryBar {
                    Layout.fillHeight: true
                    Layout.preferredWidth: 60
                    percentage: modelData.percentage
                    iconName: modelData.icon
                    isCharging: modelData.isCharging
                    
                    // Corner Radius Logic
                    // First element (Left) touches widget left edge (TopLeft, BottomLeft)
                    radiusTopLeft: index === 0 ? 8 : 4
                    radiusBottomLeft: index === 0 ? 8 : 4
                    radiusTopRight: 4
                    radiusBottomRight: 4
                }
            }
        }
        
        // Main Details Area (Right Side)
        Item {
            Layout.fillHeight: true
            Layout.fillWidth: true 
            
            // Background Shape with custom corners
            Shape {
                id: cardShape
                anchors.fill: parent
                // specialized renderer for better quality
                preferredRendererType: Shape.CurveRenderer
                
                ShapePath {
                    strokeWidth: 0
                    fillColor: Qt.rgba(1, 1, 1, 0.05)
                    
                    PathRectangle {
                        x: 0; y: 0
                        width: cardShape.width
                        height: cardShape.height
                        topLeftRadius: 4
                        bottomLeftRadius: 4
                        topRightRadius: 8
                        bottomRightRadius: 8
                    }
                }
            }
                
            RowLayout {
                anchors.centerIn: parent
                spacing: 16
                
                // Laptop Icon & Charge Icon
                Item {
                    width: 80
                    height: 80
                    Kirigami.Icon {
                        anchors.centerIn: parent
                        width: 64
                        height: 64
                        source: mainDevice ? mainDevice.icon : "computer-laptop"
                    }
                    // Charge badge
                    Kirigami.Icon {
                        anchors.bottom: parent.bottom
                        anchors.right: parent.right
                        width: 24
                        height: 24
                        source: "battery-charging"
                        visible: mainDevice ? mainDevice.isCharging : false
                    }
                }
                
                ColumnLayout {
                    spacing: 0
                    Text {
                        text: mainDevice ? "%" + mainDevice.percentage : "--"
                        font.pixelSize: 48
                        font.family: "Inter"
                        color: Kirigami.Theme.textColor
                    }
                    Text {
                        text: hostName.toUpperCase().replace(/\n/g, "")
                        font.pixelSize: 14
                        font.bold: true
                        color: Kirigami.Theme.textColor
                        opacity: 0.7
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }
                    Text {
                        text: mainDevice && mainDevice.remainingTime ? "Remaining " + mainDevice.remainingTime : ""
                        visible: text !== ""
                        font.pixelSize: 12
                        color: Kirigami.Theme.textColor
                        opacity: 0.5
                    }
                }
            }
        }
    }
}
