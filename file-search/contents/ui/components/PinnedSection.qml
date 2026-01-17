import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

// PinnedSection - Displays pinned items at the top of results
Item {
    id: pinnedSectionRoot
    
    // Required properties
    required property var pinnedItems
    required property color textColor
    required property color accentColor
    required property int iconSize
    required property bool isTileView
    
    // Collapsed state
    property bool isExpanded: true
    
    // Localization function
    property var trFunc: function(key) { return key }
    
    // Signals
    signal itemClicked(var item)
    signal unpinClicked(string matchId)
    
    // Height calculation
    implicitHeight: pinnedItems.length > 0 ? contentColumn.implicitHeight : 0
    visible: pinnedItems.length > 0
    
    ColumnLayout {
        id: contentColumn
        anchors.fill: parent
        spacing: 8
        
        // Section header
        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            
            MouseArea {
                id: headerMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: pinnedSectionRoot.isExpanded = !pinnedSectionRoot.isExpanded
            }
            
            Kirigami.Icon {
                source: pinnedSectionRoot.isExpanded ? "arrow-down" : "arrow-right"
                Layout.preferredWidth: 16
                Layout.preferredHeight: 16
                color: pinnedSectionRoot.accentColor
                
                Behavior on rotation { NumberAnimation { duration: 200 } }
            }
            
            Kirigami.Icon {
                source: "pin"
                Layout.preferredWidth: 16
                Layout.preferredHeight: 16
                color: pinnedSectionRoot.accentColor
            }
            
            Text {
                text: pinnedSectionRoot.trFunc("pinned_items")
                font.pixelSize: 12
                font.bold: true
                color: Qt.rgba(pinnedSectionRoot.textColor.r, pinnedSectionRoot.textColor.g, pinnedSectionRoot.textColor.b, 0.7)
            }
            
            Item { Layout.fillWidth: true }
            
            Text {
                text: pinnedSectionRoot.pinnedItems.length
                font.pixelSize: 10
                color: Qt.rgba(pinnedSectionRoot.textColor.r, pinnedSectionRoot.textColor.g, pinnedSectionRoot.textColor.b, 0.5)
            }
        }
        
        // Pinned Container
        Rectangle {
            Layout.fillWidth: true
            // Reduced padding to 4px top/bottom (Total +8)
            Layout.preferredHeight: pinnedSectionRoot.isExpanded ? (pinnedContent.implicitHeight + 8) : 0
            radius: 10
            color: Qt.rgba(pinnedSectionRoot.textColor.r, pinnedSectionRoot.textColor.g, pinnedSectionRoot.textColor.b, 0.05)
            clip: true // Important for animation
            
            Behavior on Layout.preferredHeight {
                NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
            }
            
            ColumnLayout {
                id: pinnedContent
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                anchors.topMargin: 4
                spacing: 8
                
                // Pinned items - List view
                Loader {
                    Layout.fillWidth: true
                    Layout.preferredHeight: item ? item.implicitHeight : 0
                    active: !pinnedSectionRoot.isTileView && pinnedSectionRoot.pinnedItems.length > 0
                    
                    sourceComponent: Column {
                        spacing: 2
                        
                        Repeater {
                            model: pinnedSectionRoot.pinnedItems
                            
                            delegate: Rectangle {
                                width: parent.width
                                height: 40
                                color: itemMouse.containsMouse 
                                    ? Qt.rgba(pinnedSectionRoot.accentColor.r, pinnedSectionRoot.accentColor.g, pinnedSectionRoot.accentColor.b, 0.15)
                                    : "transparent"
                                radius: 4
                                
                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 8
                                    spacing: 10
                                    
                                    Kirigami.Icon {
                                        source: modelData.decoration || "application-x-executable"
                                        Layout.preferredWidth: 22
                                        Layout.preferredHeight: 22
                                        color: pinnedSectionRoot.textColor
                                    }
                                    
                                    Text {
                                        text: modelData.display || ""
                                        Layout.fillWidth: true
                                        color: pinnedSectionRoot.textColor
                                        font.pixelSize: 13
                                        elide: Text.ElideRight
                                    }
                                    
                                    // Unpin button
                                    PinButton {
                                        isPinned: true
                                        accentColor: pinnedSectionRoot.accentColor
                                        textColor: pinnedSectionRoot.textColor
                                        trFunc: pinnedSectionRoot.trFunc
                                        
                                        onToggled: {
                                            pinnedSectionRoot.unpinClicked(modelData.matchId)
                                        }
                                    }
                                }
                                
                                MouseArea {
                                    id: itemMouse
                                    anchors.fill: parent
                                    anchors.rightMargin: 30 // Leave space for pin button
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    
                                    onClicked: {
                                        pinnedSectionRoot.itemClicked(modelData)
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Pinned items - Tile view
                Loader {
                    Layout.fillWidth: true
                    Layout.preferredHeight: item ? item.implicitHeight : 0
                    active: pinnedSectionRoot.isTileView && pinnedSectionRoot.pinnedItems.length > 0
                    
                    sourceComponent: Flow {
                        spacing: 8
                        
                        Repeater {
                            model: pinnedSectionRoot.pinnedItems
                            
                            delegate: Rectangle {
                                width: pinnedSectionRoot.iconSize + 16
                                height: pinnedSectionRoot.iconSize + 36
                                color: tileMouse.containsMouse 
                                    ? Qt.rgba(pinnedSectionRoot.accentColor.r, pinnedSectionRoot.accentColor.g, pinnedSectionRoot.accentColor.b, 0.15)
                                    : "transparent"
                                radius: 6
                                
                                Column {
                                    anchors.centerIn: parent
                                    spacing: 4
                                    
                                    Item {
                                        width: pinnedSectionRoot.iconSize
                                        height: pinnedSectionRoot.iconSize
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        
                                        Kirigami.Icon {
                                            anchors.fill: parent
                                            source: modelData.decoration || "application-x-executable"
                                            color: pinnedSectionRoot.textColor
                                        }
                                        
                                        // Small pin indicator
                                        Rectangle {
                                            anchors.top: parent.top
                                            anchors.right: parent.right
                                            anchors.margins: -4
                                            width: 14
                                            height: 14
                                            radius: 7
                                            color: pinnedSectionRoot.accentColor
                                            visible: false // Hidden in container mode as per design
                                            
                                            Kirigami.Icon {
                                                anchors.centerIn: parent
                                                width: 10
                                                height: 10
                                                source: "pin"
                                                color: "white"
                                            }
                                        }
                                        
                                        // Use corner badge icon if preferred style
                                        Kirigami.Icon {
                                            source: "pin"
                                            width: 12
                                            height: 12
                                            anchors.top: parent.top
                                            anchors.right: parent.right
                                            anchors.margins: -2
                                            color: pinnedSectionRoot.accentColor
                                            visible: true
                                        }
                                    }
                                    
                                    Text {
                                        text: modelData.display || ""
                                        width: pinnedSectionRoot.iconSize + 8
                                        horizontalAlignment: Text.AlignHCenter
                                        color: pinnedSectionRoot.textColor
                                        font.pixelSize: 10
                                        elide: Text.ElideMiddle
                                    }
                                }
                                
                                MouseArea {
                                    id: tileMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                                    
                                    onClicked: (mouse) => {
                                        if (mouse.button === Qt.RightButton) {
                                            pinnedSectionRoot.unpinClicked(modelData.matchId)
                                        } else {
                                            pinnedSectionRoot.itemClicked(modelData)
                                        }
                                    }
                                }
                                
                                ToolTip {
                                    visible: tileMouse.containsMouse
                                    text: modelData.display + "\n" + pinnedSectionRoot.trFunc("right_click_unpin")
                                    delay: 500
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
