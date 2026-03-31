import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import "../js/PreviewUtils.js" as PreviewUtils

// History List View - Displays search history in list format
Item {
    id: historyList
    
    // Required properties
    required property var categorizedHistory
    required property int listIconSize
    required property color textColor
    required property color accentColor
    required property var formatTimeFunc
    required property bool previewEnabled
    required property var previewSettings
    required property var logic
    
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
        height: 24
        
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
        logic: historyList.logic
    }

    // History List
    ScrollView {
        visible: historyList.categorizedHistory.length > 0
        anchors.top: historyHeader.bottom
        anchors.topMargin: 4
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        clip: true
        ScrollBar.vertical.policy: ScrollBar.AlwaysOff
        
        Column {
            id: listView
            width: parent.width
            spacing: 8
            
            Repeater {
                model: historyList.categorizedHistory
            
            delegate: Column {
                id: histListCategoryDelegate
                width: listView.width
                spacing: 4
                
                property int catIdx: index
                property bool isCollapsed: false
                
                // Category Header (Clickable - matches tile view style)
                Rectangle {
                    width: parent.width
                    height: 28
                    color: histListCategoryMouse.containsMouse ? Qt.rgba(historyList.accentColor.r, historyList.accentColor.g, historyList.accentColor.b, 0.1) : "transparent"
                    radius: 4
                    
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 4
                        anchors.rightMargin: 4
                        spacing: 8
                        
                        Kirigami.Icon {
                            source: histListCategoryDelegate.isCollapsed ? "arrow-right" : "arrow-down"
                            Layout.preferredWidth: 16
                            Layout.preferredHeight: 16
                            color: historyList.textColor
                            opacity: 0.6
                        }
                        
                        Text {
                            text: modelData.categoryName + " (" + modelData.items.length + ")"
                            font.pixelSize: 13
                            font.bold: true
                            color: Qt.rgba(historyList.textColor.r, historyList.textColor.g, historyList.textColor.b, 0.6)
                        }
                        
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 1
                            color: Qt.rgba(historyList.textColor.r, historyList.textColor.g, historyList.textColor.b, 0.2)
                        }
                    }
                    
                    MouseArea {
                        id: histListCategoryMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: histListCategoryDelegate.isCollapsed = !histListCategoryDelegate.isCollapsed
                    }
                }
                
                // Items container (Animated collapse/expand)
                Item {
                    width: parent.width
                    height: histListCategoryDelegate.isCollapsed ? 0 : histListContent.implicitHeight
                    clip: true
                    
                    Behavior on height {
                        NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
                    }
                    
                    Column {
                        id: histListContent
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        spacing: 2
                    
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
                                
                                Item {
                                    Layout.preferredWidth: historyList.listIconSize
                                    Layout.preferredHeight: historyList.listIconSize
                                    
                                    Kirigami.Icon {
                                        anchors.fill: parent
                                        source: modelData.decoration || "application-x-executable"
                                        color: historyList.textColor
                                        visible: previewImageHistory.status !== Image.Ready
                                    }
                                    
                                    Image {
                                        id: previewImageHistory
                                        anchors.fill: parent
                                        asynchronous: true
                                        fillMode: Image.PreserveAspectCrop
                                        sourceSize.width: historyList.listIconSize
                                        sourceSize.height: historyList.listIconSize
                                        cache: true
                                        source: historyList.listIconSize > 22
                                            ? PreviewUtils.getPreviewSource((modelData.filePath || modelData.url || "").toString(), historyList.previewEnabled, historyList.previewSettings)
                                            : ""
                                        visible: source.length > 0 && status === Image.Ready
                                    }
                                }
                                
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
                                    
                                    Text {
                                        text: {
                                            if (modelData.isApplication) return "";
                                            var path = modelData.filePath ? modelData.filePath.toString() : "";
                                            if (path && path.length > 0) {
                                                path = path.replace("file://", "");
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
