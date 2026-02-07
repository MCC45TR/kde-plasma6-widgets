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
    property string timeToEvent: ""
    property string currentPowerProfile: "balanced"
    signal setPowerProfile(string profile)

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
                
                ColumnLayout {
                    anchors.left: parent.left
                    anchors.leftMargin: 32
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 0
                    
                    // Icons Row
                    RowLayout {
                        spacing: 12
                        
                        Kirigami.Icon {
                            Layout.preferredWidth: 64
                            Layout.preferredHeight: 64
                            source: mainDevice ? mainDevice.icon : "computer-laptop"
                            color: Kirigami.Theme.textColor
                        }
                        
                        // Vertical Battery Icon with Charging Bolt
                        // Using a standard icon for now, positioned next to laptop
                        Kirigami.Icon {
                            Layout.preferredWidth: 32
                            Layout.preferredHeight: 32
                            source: "battery-charging" 
                            visible: mainDevice ? mainDevice.isCharging : false
                            color: Kirigami.Theme.textColor
                        }
                    }
                    
                    // Spacer
                    Item { Layout.preferredHeight: 10 }
                    
                    Text {
                        text: mainDevice ? "%" + mainDevice.percentage : "--"
                        font.pixelSize: 64

                        font.weight: Font.Light
                        color: Kirigami.Theme.textColor
                    }
                    
                    Text {
                        text: hostName.toUpperCase().replace(/\n/g, "")
                        font.pixelSize: 18
                        font.bold: true
                        color: Kirigami.Theme.textColor
                        opacity: 0.8
                        Layout.maximumWidth: parent.width - 40
                        elide: Text.ElideRight
                    }
                    
                    // Time-to-Event
                    Text {
                        text: timeToEvent
                        visible: timeToEvent.length > 0
                        font.pixelSize: 14
                        font.bold: true
                        color: mainDevice && mainDevice.isCharging ? Kirigami.Theme.positiveColor : Kirigami.Theme.neutralColor
                        opacity: 0.9
                    }
                    
                    // Power Profile Row
                    Row {
                        spacing: 6
                        Layout.topMargin: 8
                        
                        Repeater {
                            model: ["power-saver", "balanced", "performance"]
                            
                            Rectangle {
                                width: 32
                                height: 24
                                radius: 12
                                color: currentPowerProfile === modelData ? Kirigami.Theme.highlightColor : Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.15)
                                
                                Text {
                                    anchors.centerIn: parent
                                    text: modelData === "power-saver" ? "🔋" : (modelData === "balanced" ? "⚖️" : "⚡")
                                    font.pixelSize: 12
                                }
                                
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    hoverEnabled: true
                                    onClicked: root.setPowerProfile(modelData)
                                }
                            }
                        }
                    }
                }
        }
    }
}
