import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

// History Tile View - Displays search history in tile/grid format
Item {
    id: historyTile
    
    // Required properties
    required property var categorizedHistory
    required property int iconSize
    required property color textColor
    required property color accentColor
    
    // Signals
    signal itemClicked(var item)
    signal clearClicked()
    
    // Localization function
    property var trFunc: function(key) { return key }
    
    // Header with title and clear button
    RowLayout {
        id: historyHeader
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 32
        
        Text {
            text: historyTile.trFunc("recent_searches")
            font.pixelSize: 13
            font.bold: true
            color: Qt.rgba(historyTile.textColor.r, historyTile.textColor.g, historyTile.textColor.b, 0.7)
            Layout.fillWidth: true
        }
        
        // Clear History Button
        Rectangle {
            id: clearHistoryBtn
            Layout.preferredWidth: clearBtnText.implicitWidth + 16
            Layout.preferredHeight: 26
            radius: 4
            color: clearHistoryMouseArea.containsMouse ? Qt.rgba(historyTile.accentColor.r, historyTile.accentColor.g, historyTile.accentColor.b, 0.2) : "transparent"
            border.width: 1
            border.color: Qt.rgba(historyTile.textColor.r, historyTile.textColor.g, historyTile.textColor.b, 0.2)
            
            Text {
                id: clearBtnText
                anchors.centerIn: parent
                text: historyTile.trFunc("clear_history")
                font.pixelSize: 11
                color: historyTile.textColor
            }
            
            MouseArea {
                id: clearHistoryMouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: historyTile.clearClicked()
            }
        }
    }
    
    // Tile Grid
    ScrollView {
        anchors.top: historyHeader.bottom
        anchors.topMargin: 8
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        clip: true
        ScrollBar.vertical.policy: ScrollBar.AlwaysOff
        
        ListView {
            id: tileView
            model: historyTile.categorizedHistory
            spacing: 16
            interactive: false
            
            delegate: Column {
                width: tileView.width
                spacing: 8
                
                // Category Header
                RowLayout {
                    width: parent.width
                    spacing: 8
                    
                    Text {
                        text: modelData.categoryName
                        font.pixelSize: 13
                        font.bold: true
                        color: Qt.rgba(historyTile.textColor.r, historyTile.textColor.g, historyTile.textColor.b, 0.6)
                    }
                    
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 1
                        color: Qt.rgba(historyTile.textColor.r, historyTile.textColor.g, historyTile.textColor.b, 0.2)
                    }
                }
                
                // Tile Flow
                Flow {
                    width: parent.width
                    spacing: 8
                    
                    Repeater {
                        model: modelData.items
                        
                        Item {
                            width: historyTile.iconSize + 40
                            height: historyTile.iconSize + 50
                            
                            Rectangle {
                                anchors.fill: parent
                                radius: 8
                                color: tileMouseArea.containsMouse ? Qt.rgba(historyTile.accentColor.r, historyTile.accentColor.g, historyTile.accentColor.b, 0.15) : "transparent"
                                
                                Column {
                                    anchors.centerIn: parent
                                    spacing: 6
                                    
                                    Kirigami.Icon {
                                        width: historyTile.iconSize
                                        height: historyTile.iconSize
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        source: modelData.decoration || "application-x-executable"
                                        color: historyTile.textColor
                                    }
                                    
                                    Text {
                                        width: historyTile.iconSize + 32
                                        text: modelData.display || ""
                                        color: historyTile.textColor
                                        font.pixelSize: historyTile.iconSize > 32 ? 11 : 9
                                        horizontalAlignment: Text.AlignHCenter
                                        elide: Text.ElideMiddle
                                        maximumLineCount: 2
                                        wrapMode: Text.Wrap
                                    }
                                }
                                
                                MouseArea {
                                    id: tileMouseArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: historyTile.itemClicked(modelData)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
