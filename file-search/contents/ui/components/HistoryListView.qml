import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

// History List View - Displays search history in list format
Item {
    id: historyList
    
    // Required properties
    required property var categorizedHistory
    required property int listIconSize
    required property color textColor
    required property color accentColor
    required property var formatTimeFunc
    
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
            text: historyList.trFunc("recent_searches")
            font.pixelSize: 13
            font.bold: true
            color: Qt.rgba(historyList.textColor.r, historyList.textColor.g, historyList.textColor.b, 0.7)
            Layout.fillWidth: true
        }
        
        // Clear History Button
        Rectangle {
            id: clearHistoryBtn
            Layout.preferredWidth: clearBtnText.implicitWidth + 16
            Layout.preferredHeight: 26
            radius: 4
            color: clearHistoryMouseArea.containsMouse ? Qt.rgba(historyList.accentColor.r, historyList.accentColor.g, historyList.accentColor.b, 0.2) : "transparent"
            border.width: 1
            border.color: Qt.rgba(historyList.textColor.r, historyList.textColor.g, historyList.textColor.b, 0.2)
            
            Text {
                id: clearBtnText
                anchors.centerIn: parent
                text: historyList.trFunc("clear_history")
                font.pixelSize: 11
                color: historyList.textColor
            }
            
            MouseArea {
                id: clearHistoryMouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: historyList.clearClicked()
            }
        }
    }
    
    // History List
    ScrollView {
        anchors.top: historyHeader.bottom
        anchors.topMargin: 8
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        clip: true
        ScrollBar.vertical.policy: ScrollBar.AlwaysOff
        
        ListView {
            id: listView
            model: historyList.categorizedHistory
            spacing: 8
            
            delegate: Column {
                width: listView.width
                spacing: 4
                
                // Category Header
                Text {
                    text: modelData.categoryName
                    font.pixelSize: 11
                    font.bold: true
                    color: Qt.rgba(historyList.textColor.r, historyList.textColor.g, historyList.textColor.b, 0.6)
                }
                
                // Items in category
                Repeater {
                    model: modelData.items
                    
                    Rectangle {
                        width: listView.width
                        height: Math.max(42, historyList.listIconSize + 16)
                        color: itemMouseArea.containsMouse ? Qt.rgba(historyList.accentColor.r, historyList.accentColor.g, historyList.accentColor.b, 0.15) : "transparent"
                        radius: 4
                        
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 10
                            
                            Kirigami.Icon {
                                source: modelData.decoration || "application-x-executable"
                                Layout.preferredWidth: historyList.listIconSize
                                Layout.preferredHeight: historyList.listIconSize
                                color: historyList.textColor
                            }
                            
                            // Name and parent folder column
                            Column {
                                Layout.fillWidth: true
                                spacing: 2
                                
                                Text {
                                    text: modelData.display || ""
                                    color: historyList.textColor
                                    font.pixelSize: 14
                                    elide: Text.ElideRight
                                    width: parent.width
                                }
                                
                                // Parent folder for files
                                Text {
                                    visible: modelData.filePath && modelData.filePath.length > 0 && !modelData.isApplication
                                    text: {
                                        if (!modelData.filePath) return ""
                                        var path = modelData.filePath.toString()
                                        if (path.startsWith("file://")) path = path.substring(7)
                                        var lastSlash = path.lastIndexOf("/")
                                        if (lastSlash > 0) {
                                            var parentPath = path.substring(0, lastSlash)
                                            var parentSlash = parentPath.lastIndexOf("/")
                                            if (parentSlash >= 0) {
                                                return parentPath.substring(parentSlash + 1)
                                            }
                                            return parentPath
                                        }
                                        return ""
                                    }
                                    color: Qt.rgba(historyList.textColor.r, historyList.textColor.g, historyList.textColor.b, 0.5)
                                    font.pixelSize: 11
                                    elide: Text.ElideMiddle
                                    width: parent.width
                                }
                            }
                            
                            // Timestamp
                            Text {
                                text: historyList.formatTimeFunc(modelData.timestamp)
                                color: Qt.rgba(historyList.textColor.r, historyList.textColor.g, historyList.textColor.b, 0.5)
                                font.pixelSize: 11
                                Layout.alignment: Qt.AlignVCenter
                            }
                        }
                        
                        MouseArea {
                            id: itemMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: historyList.itemClicked(modelData)
                        }
                    }
                }
            }
        }
    }
}
