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
    
    // Preview control - bound from config
    property bool previewEnabled: true
    property var previewSettings: ({"images": true, "videos": false, "text": false, "documents": false})
    
    // Logic controller for context menu actions
    property var logic: null
    
    // Current selection index
    property int currentIndex: 0
    
    // Signals
    signal itemClicked(int index, string display, string decoration, string category, string matchId, string filePath)
    signal itemRightClicked(var item, real x, real y)
    
    // Localization
    // trFunc property removed
    property string searchText: ""
    
    // Pin support
    property var isPinnedFunc: function(matchId) { return false }
    property var togglePinFunc: function(item) { }
    
    clip: true
    ScrollBar.vertical.policy: ScrollBar.AlwaysOff
    
    // Use flat sorted data (JS Array) instead of raw model for consistency
    property var flatSortedData: [] 
    
    ListView {
        id: resultsList
        width: parent.width
        model: resultsListRoot.flatSortedData
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
        
        add: Transition {
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 150 }
            NumberAnimation { property: "scale"; from: 0.96; to: 1.0; duration: 150 }
        }
        
        delegate: Rectangle {
            id: resultItem
            width: resultsList.width
            height: Math.max(44, resultsListRoot.listIconSize + 18)
            color: resultMouseArea.containsMouse ? Qt.rgba(resultsListRoot.accentColor.r, resultsListRoot.accentColor.g, resultsListRoot.accentColor.b, 0.15) : "transparent"
            radius: 4
            
            // Ensure visible initially
            opacity: 1 
            
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 10
                
                // Icon
                Kirigami.Icon {
                    source: {
                        if (resultsListRoot.listIconSize <= 22) return modelData.decoration || "application-x-executable";
                        
                        var url = (modelData.url || "").toString();
                        if (!url) return modelData.decoration || "application-x-executable";
                        
                        var ext = url.split('.').pop().toLowerCase();
                        
                        if (resultsListRoot.previewSettings.images) {
                            var imageExts = ["png", "jpg", "jpeg", "gif", "bmp", "webp", "svg", "ico", "tiff"]
                            if (imageExts.indexOf(ext) >= 0) return url
                        }
                        
                        if (resultsListRoot.previewSettings.videos) {
                            var videoExts = ["mp4", "mkv", "avi", "webm", "mov", "flv", "wmv", "mpg", "mpeg"]
                            if (videoExts.indexOf(ext) >= 0) return "image://preview/" + url
                        }
                        
                        if (resultsListRoot.previewSettings.documents) {
                            var docExts = ["pdf", "odt", "docx", "pptx", "xlsx"]
                            if (docExts.indexOf(ext) >= 0) return "image://preview/" + url
                        }
                        
                        return modelData.decoration || "application-x-executable"
                    }
                    Layout.preferredWidth: resultsListRoot.listIconSize
                    Layout.preferredHeight: resultsListRoot.listIconSize
                    color: resultsListRoot.textColor
                }
                
                // Result text with optional parent folder
                Column {
                    Layout.fillWidth: true
                    spacing: 1
                    
                    Text {
                        text: modelData.display || ""
                        color: resultsListRoot.textColor
                        font.pixelSize: 14
                        elide: Text.ElideRight
                        width: parent.width
                    }
                    
                    // Parent folder for files or subtext for apps
                    Text {
                        text: {
                            var cat = modelData.category || ""
                            var isApp = (cat === "Uygulamalar" || cat === "Applications" || cat === "System Settings");
                            if (isApp) return modelData.subtext || "";

                            var path = (modelData.url && modelData.url.toString) ? modelData.url.toString() : "";
                            
                            // Fallback to subtext if it looks like a path
                            if (!path && modelData.subtext && modelData.subtext.toString().indexOf("/") === 0) {
                                path = "file://" + modelData.subtext;
                            }
                            
                            if (path && path.length > 0) {
                                path = path.replace("file://", "");
                                // Remove /home/user/ prefix using regex
                                path = path.replace(/^\/home\/[^\/]+\//, "");
                                return path;
                            }
                            return modelData.subtext || "";
                        }
                        visible: text.length > 0
                        color: Qt.rgba(resultsListRoot.textColor.r, resultsListRoot.textColor.g, resultsListRoot.textColor.b, 0.5)
                        font.pixelSize: 10
                        elide: Text.ElideMiddle
                        width: parent.width
                    }
                }
                
                // Pin button
                Item {
                    Layout.preferredWidth: 28
                    Layout.preferredHeight: 28
                    visible: resultMouseArea.containsMouse
                    
                    PinButton {
                        anchors.centerIn: parent
                        isPinned: {
                            var matchId = (modelData.duplicateId !== undefined ? modelData.duplicateId : modelData.display) || ""
                            return resultsListRoot.isPinnedFunc(matchId)
                        }
                        accentColor: resultsListRoot.accentColor
                        textColor: resultsListRoot.textColor
                        // trFunc removed
                        
                        onToggled: (pinned) => {
                            var matchId = (modelData.duplicateId !== undefined ? modelData.duplicateId : modelData.display) || ""
                            resultsListRoot.togglePinFunc({
                                display: modelData.display || "",
                                decoration: modelData.decoration || "application-x-executable",
                                category: modelData.category || "Diğer",
                                matchId: matchId,
                                filePath: modelData.url || ""
                            })
                        }
                    }
                }
            }
            
            MouseArea {
                id: resultMouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                
                onClicked: (mouse) => {
                    var matchId = (modelData.duplicateId !== undefined ? modelData.duplicateId : modelData.display) || ""
                    var filePath = (modelData.url && modelData.url.toString) ? modelData.url.toString() : (modelData.url || "")
                    var subtext = modelData.subtext || ""
                    // Handle urls array if present
                    var urls = modelData.urls || []
                    
                    if (filePath === "" && urls.length > 0) {
                        filePath = urls[0].toString()
                    }
                    
                    if (filePath === "") {
                        if (subtext.indexOf("/") === 0) filePath = "file://" + subtext
                        else if (subtext.indexOf("file://") === 0) filePath = subtext
                    }
                    
                    if (mouse.button === Qt.RightButton) {
                        // Right-click: show context menu
                        var cat = modelData.category || ""
                        var isApp = (cat === "Uygulamalar" || cat === "Applications" || cat === "System Settings")
                        
                        resultsListRoot.itemRightClicked({
                            display: modelData.display || "",
                            decoration: modelData.decoration || "application-x-executable",
                            category: cat,
                            matchId: matchId,
                            filePath: filePath,
                            isApplication: isApp,
                            uuid: matchId // For compatibility with HistoryContextMenu
                        }, mouse.x + resultItem.x, mouse.y + resultItem.y)
                    } else {
                        // Left-click: open item
                        resultsListRoot.itemClicked(index, modelData.display || "", modelData.decoration || "application-x-executable", modelData.category || "Diğer", matchId, filePath)
                    }
                }

                // File Preview Tooltip
                ToolTip {
                    id: previewTooltip
                    visible: resultMouseArea.containsMouse && (modelData.url || "").length > 0 && resultsListRoot.previewEnabled
                    delay: 500
                    timeout: 10000
                    x: resultItem.width + 10
                    y: (resultItem.height - height) / 2
                    
                    contentItem: Column {
                        spacing: 6
                        
                        // Title
                        Text {
                            text: modelData.display || ""
                            font.bold: true
                            font.pixelSize: 12
                            color: resultsListRoot.textColor
                        }
                        
                        // Thumbnail for images
                        Image {
                            source: {
                                var url = modelData.url || ""
                                if (url.length === 0) return ""
                                var ext = url.split('.').pop().toLowerCase()
                                
                                // 1. Images
                                if (resultsListRoot.previewSettings.images) {
                                    var imageExts = ["png", "jpg", "jpeg", "gif", "bmp", "webp", "svg", "ico", "tiff"]
                                    if (imageExts.indexOf(ext) >= 0) return url
                                }
                                
                                // 2. Videos
                                if (resultsListRoot.previewSettings.videos) {
                                    var videoExts = ["mp4", "mkv", "avi", "webm", "mov", "flv", "wmv", "mpg", "mpeg"]
                                    if (videoExts.indexOf(ext) >= 0) return "image://preview/" + url
                                }
                                
                                // 3. Documents
                                if (resultsListRoot.previewSettings.documents) {
                                    var docExts = ["pdf", "odt", "docx", "pptx", "xlsx"]
                                    if (docExts.indexOf(ext) >= 0) return "image://preview/" + url
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
                            text: {
                                var path = (modelData.url && modelData.url.toString) ? modelData.url.toString() : "";
                                if (path && path.length > 0) {
                                    path = path.replace("file://", "");
                                    // Remove /home/user/ prefix using regex
                                    path = path.replace(/^\/home\/[^\/]+\//, "");
                                    return path;
                                }
                                return modelData.url || "";
                            }
                            font.pixelSize: 10
                            color: Qt.rgba(resultsListRoot.textColor.r, resultsListRoot.textColor.g, resultsListRoot.textColor.b, 0.7)
                            wrapMode: Text.WrapAnywhere
                            width: Math.min(300, implicitWidth)
                            visible: (modelData.url || "").length > 0
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
            text: resultsListRoot.searchText.length > 0 ? i18n("No results found") : i18n("Type to start searching")
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
