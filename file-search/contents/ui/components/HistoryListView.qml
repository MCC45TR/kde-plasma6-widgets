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
    required property var previewSettings
    
    // Signals
    signal itemClicked(var item)
    signal clearClicked()
    
    // Localization removed
    // Use standard i18nd("plasma_applet_com.mcc45tr.filesearch", )
    
    // Header with title and clear button
    RowLayout {
        id: historyHeader
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 32
        
        Text {
            text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Recent Searches")
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
                text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Clear History")
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
    
    // Context Menu
    HistoryContextMenu {
        id: contextMenu
        logic: popupRoot.logic
    }

    // History List
    ScrollView {
        visible: historyList.categorizedHistory.length > 0
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
                        color: itemMouseArea.containsMouse || (contextMenu.visible && contextMenu.historyItem === modelData) ? Qt.rgba(historyList.accentColor.r, historyList.accentColor.g, historyList.accentColor.b, 0.15) : "transparent"
                        radius: 4
                        
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 10
                            
                            Kirigami.Icon {
                                source: {
                                    if (historyList.listIconSize <= 22) return modelData.decoration || "application-x-executable";
                                    
                                    var url = (modelData.filePath || "").toString();
                                    // Fallback
                                    if (!url) url = (modelData.url || "").toString();

                                    if (!url) return modelData.decoration || "application-x-executable";
                                    
                                    var ext = url.split('.').pop().toLowerCase();
                                    
                                    if (historyList.previewSettings.images) {
                                        var imageExts = ["png", "jpg", "jpeg", "gif", "bmp", "webp", "svg", "ico", "tiff"]
                                        if (imageExts.indexOf(ext) >= 0) return url
                                    }
                                    
                                    if (historyList.previewSettings.videos) {
                                        var videoExts = ["mp4", "mkv", "avi", "webm", "mov", "flv", "wmv", "mpg", "mpeg"]
                                        if (videoExts.indexOf(ext) >= 0) return "image://preview/" + url
                                    }
                                    
                                    if (historyList.previewSettings.documents) {
                                        var docExts = ["pdf", "odt", "docx", "pptx", "xlsx"]
                                        if (docExts.indexOf(ext) >= 0) return "image://preview/" + url
                                    }
                                    
                                    return modelData.decoration || "application-x-executable"
                                }
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
                                
                                // Parent folder logic matching ResultsListView
                                Text {
                                    text: {
                                        if (modelData.isApplication) return "";

                                        var path = modelData.filePath ? modelData.filePath.toString() : "";
                                        
                                        if (path && path.length > 0) {
                                            path = path.replace("file://", "");
                                            // Remove /home/user/ prefix using regex
                                            path = path.replace(/^\/home\/[^\/]+\//, "");
                                            return path;
                                        }
                                        return "";
                                    }
                                    visible: text.length > 0
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
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            cursorShape: Qt.PointingHandCursor
                            onClicked: (mouse) => {
                                if (mouse.button === Qt.RightButton) {
                                    contextMenu.historyItem = modelData
                                    contextMenu.popup()
                                } else {
                                    historyList.itemClicked(modelData)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // Empty State
    ColumnLayout {
        anchors.centerIn: parent
        visible: historyList.categorizedHistory.length === 0
        spacing: 16

        Kirigami.Icon {
            source: "search"
            Layout.preferredWidth: 64
            Layout.preferredHeight: 64
            Layout.alignment: Qt.AlignHCenter
            color: Qt.rgba(historyList.textColor.r, historyList.textColor.g, historyList.textColor.b, 0.3)
        }

        Text {
            text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Type to search")
            color: Qt.rgba(historyList.textColor.r, historyList.textColor.g, historyList.textColor.b, 0.5)
            font.pixelSize: 16
            Layout.alignment: Qt.AlignHCenter
        }
    }
}
