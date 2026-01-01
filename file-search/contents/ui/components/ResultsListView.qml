import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

// Results List View - Displays search results in list format
ScrollView {
    id: resultsListRoot
    
    // Required properties
    required property var resultsModel
    required property int listIconSize
    required property color textColor
    required property color accentColor
    
    // Current selection index
    property int currentIndex: 0
    
    // Signals
    signal itemClicked(int index, string display, string decoration, string category, string matchId, string filePath)
    
    // Localization
    property var trFunc: function(key) { return key }
    property string searchText: ""
    
    clip: true
    ScrollBar.vertical.policy: ScrollBar.AlwaysOff
    
    ListView {
        id: resultsList
        model: resultsListRoot.resultsModel
        spacing: 2
        currentIndex: resultsListRoot.currentIndex
        
        highlight: Rectangle {
            color: Qt.rgba(resultsListRoot.accentColor.r, resultsListRoot.accentColor.g, resultsListRoot.accentColor.b, 0.2)
            radius: 4
        }
        highlightFollowsCurrentItem: true
        
        // Category section header
        section.property: "category"
        section.delegate: Item {
            width: resultsList.width
            height: 28
            
            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: section
                font.pixelSize: 11
                font.bold: true
                color: Qt.rgba(resultsListRoot.textColor.r, resultsListRoot.textColor.g, resultsListRoot.textColor.b, 0.6)
            }
        }
        
        delegate: Rectangle {
            id: resultItem
            width: resultsList.width
            height: Math.max(44, resultsListRoot.listIconSize + 18)
            color: resultMouseArea.containsMouse ? Qt.rgba(resultsListRoot.accentColor.r, resultsListRoot.accentColor.g, resultsListRoot.accentColor.b, 0.15) : "transparent"
            radius: 4
            
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 10
                
                // Icon
                Kirigami.Icon {
                    source: model.decoration || "application-x-executable"
                    Layout.preferredWidth: resultsListRoot.listIconSize
                    Layout.preferredHeight: resultsListRoot.listIconSize
                    color: resultsListRoot.textColor
                }
                
                // Result text with optional parent folder
                Column {
                    Layout.fillWidth: true
                    spacing: 1
                    
                    Text {
                        text: model.display || ""
                        color: resultsListRoot.textColor
                        font.pixelSize: 14
                        elide: Text.ElideRight
                        width: parent.width
                    }
                    
                    // Parent folder for files
                    Text {
                        visible: {
                            if (!model) return false
                            var cat = model.category || ""
                            var isFileCategory = cat.indexOf("Dosya") >= 0 || cat.indexOf("Klasör") >= 0 || 
                                                cat.indexOf("File") >= 0 || cat.indexOf("Folder") >= 0 ||
                                                cat.indexOf("Document") >= 0 || cat.indexOf("Belge") >= 0
                            return !!(isFileCategory && model.url && model.url.toString().length > 0)
                        }
                        text: {
                            if (!model.url) return ""
                            var path = model.url.toString()
                            if (path.startsWith("file://")) path = path.substring(7)
                            var lastSlash = path.lastIndexOf("/")
                            if (lastSlash > 0) {
                                return path.substring(0, lastSlash)
                            }
                            return ""
                        }
                        color: Qt.rgba(resultsListRoot.textColor.r, resultsListRoot.textColor.g, resultsListRoot.textColor.b, 0.5)
                        font.pixelSize: 10
                        elide: Text.ElideMiddle
                        width: parent.width
                    }
                }
            }
            
            MouseArea {
                id: resultMouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                
                onClicked: {
                    var matchId = (model.duplicateId !== undefined ? model.duplicateId : model.display) || ""
                    var filePath = model.url || ""
                    resultsListRoot.itemClicked(index, model.display || "", model.decoration || "application-x-executable", model.category || "Diğer", matchId, filePath)
                }

                // File Preview Tooltip
                ToolTip {
                    id: previewTooltip
                    visible: resultMouseArea.containsMouse && (model.url || "").length > 0 && (typeof resultsListRoot.parent.parent.previewEnabled !== 'undefined' ? resultsListRoot.parent.parent.previewEnabled : true)
                    delay: 500
                    timeout: 10000
                    x: resultItem.width + 10
                    y: (resultItem.height - height) / 2
                    
                    contentItem: Column {
                        spacing: 6
                        
                        // Title
                        Text {
                            text: model.display || ""
                            font.bold: true
                            font.pixelSize: 12
                            color: resultsListRoot.textColor
                        }
                        
                        // Thumbnail for images
                        Image {
                            source: {
                                var url = model.url || ""
                                if (url.length === 0) return ""
                                var ext = url.split('.').pop().toLowerCase()
                                var imageExts = ["png", "jpg", "jpeg", "gif", "bmp", "webp", "svg"]
                                if (imageExts.indexOf(ext) >= 0) {
                                    return url
                                }
                                return ""
                            }
                            width: source.length > 0 ? Math.min(150, sourceSize.width) : 0
                            height: source.length > 0 ? Math.min(100, sourceSize.height) : 0
                            fillMode: Image.PreserveAspectFit
                            visible: source.length > 0
                            cache: true
                            asynchronous: true
                        }
                        
                        // Path
                        Text {
                            text: (model.url || "")
                            font.pixelSize: 10
                            color: Qt.rgba(resultsListRoot.textColor.r, resultsListRoot.textColor.g, resultsListRoot.textColor.b, 0.7)
                            wrapMode: Text.WrapAnywhere
                            width: Math.min(300, implicitWidth)
                            visible: (model.url || "").length > 0
                        }
                    }
                    
                    background: Rectangle {
                        color: Kirigami.Theme.backgroundColor
                        border.color: resultsListRoot.accentColor
                        border.width: 1
                        radius: 6
                    }
                }
            }
        }
        
        // Empty state
        Text {
            anchors.centerIn: parent
            text: resultsListRoot.searchText.length > 0 ? resultsListRoot.trFunc("no_results") : resultsListRoot.trFunc("type_to_search")
            color: Qt.rgba(resultsListRoot.textColor.r, resultsListRoot.textColor.g, resultsListRoot.textColor.b, 0.5)
            font.pixelSize: 12
            visible: resultsList.count === 0 && resultsListRoot.searchText.length > 0
        }
    }
    
    // Expose count for external use
    property int count: resultsList.count
    
    // Navigate methods
    function moveUp() {
        if (currentIndex > 0) currentIndex--
    }
    
    function moveDown() {
        if (currentIndex < resultsList.count - 1) currentIndex++
    }
}
