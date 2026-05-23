import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import "../js/PreviewUtils.js" as PreviewUtils

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
    property var previewSettings: ({"images": false, "videos": false, "text": false, "documents": false, "applications": false})
    property bool previewShowResults: true
    property int previewInlineMode: 1
    property int previewSize: 1
    
    // Logic controller for context menu actions
    property var logic: null
    
    // Current selection index
    property int currentIndex: 0
    
    // Signals
    signal itemClicked(int index, string display, string decoration, string category, string matchId, string filePath)
    signal itemRightClicked(var item, real x, real y)
    
    // Localization
    property string searchText: ""
    property bool isLoading: false
    
    // Pin support
    property var isPinnedFunc: function(matchId) { return false }
    property var togglePinFunc: function(item) { }
    
    // RSS settings from config
    property bool rssShowImages: true
    property bool rssExpandableCards: true
    property var expandedItems: ({})

    function rssMetaLine(item) {
        var parts = []
        if (item.subtext && item.subtext.length > 0) {
            parts.push(item.subtext)
        }
        if (item.url && item.url.length > 0) {
            parts.push(item.url)
        }
        return parts.join("  •  ")
    }
    
    clip: true
    ScrollBar.vertical.policy: ScrollBar.AlwaysOff
    
    // Use flat sorted data (JS Array) instead of raw model for consistency
    property var flatSortedData: [] 
    
    ListView {
        id: resultsList
        width: parent.width
        model: resultsListRoot.flatSortedData
        spacing: 4
        currentIndex: resultsListRoot.currentIndex
        cacheBuffer: 2000
        
        highlight: Rectangle {
            color: Qt.rgba(resultsListRoot.accentColor.r, resultsListRoot.accentColor.g, resultsListRoot.accentColor.b, 0.15)
            radius: 8
            visible: resultsList.currentItem && !resultsList.currentItem.isRSS // Hide highlight for RSS cards
        }
        highlightFollowsCurrentItem: true
        
        // Category section header
        section.property: "category"
        section.delegate: Item {
            width: resultsList.width
            height: 32
            
            Text {
                anchors.left: parent.left
                anchors.leftMargin: 4
                anchors.verticalCenter: parent.verticalCenter
                text: section === "RSS" ? resultsListRoot.locNews : section
                font.pixelSize: 11
                font.bold: true
                color: Qt.rgba(resultsListRoot.textColor.r, resultsListRoot.textColor.g, resultsListRoot.textColor.b, 0.6)
            }
        }
        
        delegate: Item {
            id: delegateRoot
            width: resultsList.width
            height: isRSS ? rssCardLayout.implicitHeight + 24 : (rssCardLayout.implicitHeight + 12)
            
            readonly property bool isRSS: modelData.category === "RSS" || 
                                          modelData.category === resultsListRoot.locNews || 
                                          (modelData.duplicateId && modelData.duplicateId.toString().startsWith("rss:"))
            property bool isExpanded: isRSS && resultsListRoot.rssExpandableCards && !!resultsListRoot.expandedItems[modelData.duplicateId]

            property bool animateHeight: false

            Behavior on height {
                enabled: delegateRoot.animateHeight
                NumberAnimation { 
                    duration: 250; 
                    easing.type: Easing.InOutQuad 
                    onFinished: delegateRoot.animateHeight = false
                }
            }

            property bool isPreviewAvailable: PreviewUtils.isPreviewAvailable(modelData.url || "", modelData.category || "", resultsListRoot.previewSettings)
            property bool previewActive: resultsListRoot.previewEnabled && !isRSS && isPreviewAvailable && (resultsListRoot.previewInlineMode === 0 ? resultMouseArea.containsMouse : (resultsList.currentIndex === index))
            property bool showInlinePreview: resultsListRoot.previewEnabled && resultsListRoot.previewShowResults && resultsListRoot.previewInlineMode === 1 && !isRSS && isPreviewAvailable && (resultsList.currentIndex === index)
            property string previewPath: previewActive ? PreviewUtils.getLocalPreviewPath(modelData.url || "") : ""
            property string previewSource: previewActive ? PreviewUtils.getPreviewSource(modelData.url || "", resultsListRoot.previewEnabled, resultsListRoot.previewSettings) : ""
            property string previewFileType: previewActive ? PreviewUtils.getFileTypeLabel(modelData.url || "") : ""
            
            onShowInlinePreviewChanged: {
                delegateRoot.animateHeight = true;
                if (showInlinePreview) {
                    if (isTextFile) {
                        loadTextSnippet();
                    }
                }
            }

            property bool isTextFile: {
                if (!previewPath) return false;
                var ext = previewPath.split('.').pop().toLowerCase();
                var txtExts = ['txt', 'js', 'py', 'qml', 'html', 'css', 'json', 'md', 'sh', 'c', 'cpp', 'h', 'hpp', 'rs', 'go', 'java', 'xml', 'yml', 'yaml', 'ini', 'conf', 'log'];
                return txtExts.indexOf(ext) !== -1;
            }

            function loadTextSnippet() {
                if (!previewPath || !logic) return;
                logic.readLocalTextSnippet(previewPath, function(content, bytes) {
                    var lines = content.split('\n').slice(0, 5).join('\n');
                    textSnippet.text = lines;
                    
                    var sizeStr = "";
                    if (bytes < 1024) sizeStr = bytes + " B";
                    else if (bytes < 1048576) sizeStr = (bytes / 1024).toFixed(1) + " KB";
                    else sizeStr = (bytes / 1048576).toFixed(1) + " MB";
                    fileSizeText.text = "<b>" + i18nd("plasma_applet_com.mcc45tr.filesearch", "Size") + ":</b> " + sizeStr;
                });
            }

            // Background Container
            Rectangle {
                anchors.fill: parent
                anchors.margins: isRSS ? 4 : 0
                color: (resultMouseArea.containsMouse || (resultsList.currentIndex === index && !isRSS)) ? Qt.rgba(resultsListRoot.accentColor.r, resultsListRoot.accentColor.g, resultsListRoot.accentColor.b, 0.15) : 
                       (isRSS ? Qt.rgba(resultsListRoot.accentColor.r, resultsListRoot.accentColor.g, resultsListRoot.accentColor.b, 0.05) : "transparent")
                radius: isRSS ? 12 : 4
                border.width: (isRSS || resultsList.currentIndex === index) ? 1 : 0
                border.color: (isRSS || resultsList.currentIndex === index) ? Qt.rgba(resultsListRoot.accentColor.r, resultsListRoot.accentColor.g, resultsListRoot.accentColor.b, 0.3) : "transparent"
                clip: true
                
                ColumnLayout {
                    id: rssCardLayout
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: isRSS ? 12 : 6
                    spacing: isRSS ? 10 : 4
                    
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12
                        
                        // Icon Container
                        Item {
                            Layout.preferredWidth: isRSS ? 36 : resultsListRoot.listIconSize
                            Layout.preferredHeight: isRSS ? 36 : resultsListRoot.listIconSize
                            
                            Kirigami.Icon {
                                anchors.fill: parent
                                source: (isRSS && modelData.sourceIcon) ? modelData.sourceIcon : (modelData.decoration || (isRSS ? "news-subscribe" : "application-x-executable"))
                                color: isRSS ? resultsListRoot.accentColor : resultsListRoot.textColor
                            }
                        }
                        
                        // Text Content
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1
                            
                            Text {
                                text: modelData.display || ""
                                color: resultsListRoot.textColor
                                font.pixelSize: isRSS ? 15 : 13
                                font.bold: isRSS
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                            
                            Text {
                                text: {
                                    if (isRSS) return modelData.subtext || "";
                                    var path = (modelData.url || "").toString().replace("file://", "");
                                    path = path.replace(/^\/home\/[^\/]+\//, "");
                                    return path || modelData.subtext || "";
                                }
                                color: Qt.rgba(resultsListRoot.textColor.r, resultsListRoot.textColor.g, resultsListRoot.textColor.b, 0.6)
                                font.pixelSize: isRSS ? 11 : 10
                                elide: Text.ElideMiddle
                                Layout.fillWidth: true
                            }
                        }
 
                        // Right side icons
                        Kirigami.Icon {
                            source: "pin"
                            implicitWidth: 14
                            implicitHeight: 14
                            visible: resultsListRoot.isPinnedFunc(modelData.duplicateId || modelData.display)
                            color: resultsListRoot.accentColor
                        }
                    }
                    
                    ColumnLayout {
                        id: rssExpandedContent
                        Layout.fillWidth: true
                        visible: isRSS
                        spacing: 8
                        
                        Text {
                            id: descriptionLabel
                            text: (delegateRoot.isExpanded ? (modelData.fullContent || modelData.description) : modelData.description) || ""
                            color: resultsListRoot.textColor
                            font.pixelSize: 13
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                            maximumLineCount: delegateRoot.isExpanded ? 100 : 3
                            elide: Text.ElideRight
                            opacity: 0.85
                            lineHeight: 1.3
                            
                            Behavior on maximumLineCount {
                                NumberAnimation { duration: 250 }
                            }
                        }
                        
                        // Image for RSS
                        Image {
                            id: rssListImage
                            source: (delegateRoot.isExpanded && resultsListRoot.rssShowImages) ? (modelData.imageUrl || "") : ""
                            Layout.fillWidth: true
                            Layout.preferredHeight: source.length > 0 ? Math.min(300, implicitHeight) : 0
                            fillMode: Image.PreserveAspectFit
                            visible: source.length > 0 && delegateRoot.isExpanded
                            asynchronous: true
                            cache: true
                        }
 
                        Text {
                            text: resultsListRoot.rssMetaLine(modelData)
                            color: Qt.rgba(resultsListRoot.textColor.r, resultsListRoot.textColor.g, resultsListRoot.textColor.b, 0.5)
                            font.pixelSize: 10
                            font.italic: true
                            wrapMode: Text.WrapAnywhere
                            Layout.fillWidth: true
                            visible: delegateRoot.isExpanded && text.length > 0
                        }
                        
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            
                            // Haberi Oku - Karo Tasarımı (Primary Action)
                            Rectangle {
                                Layout.preferredHeight: 32
                                Layout.preferredWidth: 120
                                color: Qt.rgba(resultsListRoot.accentColor.r, resultsListRoot.accentColor.g, resultsListRoot.accentColor.b, 0.4)
                                radius: 6
                                visible: delegateRoot.isExpanded
                                
                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 6
                                    Kirigami.Icon { source: "internet-services"; implicitWidth: 16; implicitHeight: 16 }
                                    Text {
                                        text: resultsListRoot.locReadNews
                                        color: resultsListRoot.textColor
                                        font.bold: true
                                        font.pixelSize: 11
                                    }
                                }
                                
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: if (modelData.url) Qt.openUrlExternally(modelData.url)
                                }
                            }
 
                            Button {
                                text: resultsListRoot.locShare
                                icon.name: "edit-copy"
                                flat: true
                                visible: delegateRoot.isExpanded
                                Layout.preferredHeight: 32
                                onClicked: logic.copyToClipboard(modelData.url)
                            }
 
                            Item { Layout.fillWidth: true }
                            
                            // Genişlet/Daralt Butonu (Sağ Alt)
                            Button {
                                icon.name: delegateRoot.isExpanded ? "arrow-up" : "arrow-down"
                                Layout.preferredWidth: 32
                                Layout.preferredHeight: 32
                                flat: true
                                visible: resultsListRoot.rssExpandableCards
                                onClicked: {
                                    delegateRoot.animateHeight = true
                                    toggleExpansion()
                                }
                                
                                background: Rectangle {
                                    color: parent.hovered ? Qt.rgba(resultsListRoot.textColor.r, resultsListRoot.textColor.g, resultsListRoot.textColor.b, 0.1) : "transparent"
                                    radius: 16
                                }
                            }
                        }
                    }

                    // Native Inline Preview Card
                    ColumnLayout {
                        id: inlinePreviewCard
                        Layout.fillWidth: true
                        visible: delegateRoot.showInlinePreview
                        spacing: 8
                        Layout.topMargin: 8

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 1
                            color: Qt.rgba(resultsListRoot.textColor.r, resultsListRoot.textColor.g, resultsListRoot.textColor.b, 0.15)
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 12
                            Layout.leftMargin: 4
                            Layout.rightMargin: 4

                            // Left Column: Thumbnail or large icon
                            Item {
                                id: thumbContainer
                                Layout.preferredWidth: resultsListRoot.previewSize === 0 ? 64 : (resultsListRoot.previewSize === 1 ? 120 : 200)
                                Layout.preferredHeight: resultsListRoot.previewSize === 0 ? 48 : (resultsListRoot.previewSize === 1 ? 90 : 150)
                                visible: delegateRoot.previewSource.length > 0 || delegateRoot.previewFileType.length > 0

                                // Background fallback placeholder
                                Rectangle {
                                    anchors.fill: parent
                                    color: Qt.rgba(resultsListRoot.textColor.r, resultsListRoot.textColor.g, resultsListRoot.textColor.b, 0.05)
                                    radius: 4
                                }

                                Kirigami.Icon {
                                    anchors.centerIn: parent
                                    implicitWidth: 32
                                    implicitHeight: 32
                                    source: modelData.decoration || "application-x-executable"
                                    color: resultsListRoot.textColor
                                    opacity: 0.3
                                    visible: imgPreview.status !== Image.Ready
                                }

                                Image {
                                    id: imgPreview
                                    anchors.fill: parent
                                    source: delegateRoot.previewSource
                                    fillMode: Image.PreserveAspectFit
                                    visible: source.length > 0
                                    cache: true
                                    asynchronous: true
                                }
                            }

                            // Right Column: Metadata
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 4

                                Text {
                                    text: modelData.display || ""
                                    color: resultsListRoot.textColor
                                    font.bold: true
                                    font.pixelSize: 12
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }

                                Text {
                                    text: "<b>" + resultsListRoot.locCategory + ":</b> " + (modelData.category || "Other")
                                    color: Qt.rgba(resultsListRoot.textColor.r, resultsListRoot.textColor.g, resultsListRoot.textColor.b, 0.7)
                                    font.pixelSize: 10
                                    textFormat: Text.StyledText
                                }

                                Text {
                                    text: "<b>" + resultsListRoot.locFileType + ":</b> " + delegateRoot.previewFileType
                                    color: Qt.rgba(resultsListRoot.textColor.r, resultsListRoot.textColor.g, resultsListRoot.textColor.b, 0.7)
                                    font.pixelSize: 10
                                    visible: delegateRoot.previewFileType.length > 0
                                    textFormat: Text.StyledText
                                }

                                Text {
                                    id: fileSizeText
                                    text: ""
                                    color: Qt.rgba(resultsListRoot.textColor.r, resultsListRoot.textColor.g, resultsListRoot.textColor.b, 0.7)
                                    font.pixelSize: 10
                                    visible: text.length > 0
                                    textFormat: Text.StyledText
                                }

                                Text {
                                    text: "<b>" + resultsListRoot.locPath + ":</b> " + delegateRoot.previewPath
                                    color: Qt.rgba(resultsListRoot.textColor.r, resultsListRoot.textColor.g, resultsListRoot.textColor.b, 0.5)
                                    font.pixelSize: 9
                                    wrapMode: Text.WrapAnywhere
                                    Layout.fillWidth: true
                                    textFormat: Text.StyledText
                                }
                            }
                        }

                        // Text File Snippet Preview
                        Rectangle {
                            id: textSnippetBox
                            Layout.fillWidth: true
                            Layout.preferredHeight: textSnippet.implicitHeight + 12
                            color: Qt.rgba(0, 0, 0, 0.2)
                            radius: 4
                            border.width: 1
                            border.color: Qt.rgba(resultsListRoot.textColor.r, resultsListRoot.textColor.g, resultsListRoot.textColor.b, 0.1)
                            visible: delegateRoot.isTextFile && textSnippet.text.length > 0

                            Text {
                                id: textSnippet
                                anchors.fill: parent
                                anchors.margins: 6
                                text: ""
                                color: resultsListRoot.textColor
                                font.family: "Monospace"
                                font.pixelSize: 10
                                wrapMode: Text.Wrap
                            }
                        }

                        // Quick Actions
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            Button {
                                text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Copy Path")
                                icon.name: "edit-copy"
                                flat: true
                                Layout.preferredHeight: 28
                                onClicked: if (resultsListRoot.logic) resultsListRoot.logic.copyToClipboard(delegateRoot.previewPath)
                            }

                            Button {
                                text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Open Folder")
                                icon.name: "folder-open"
                                flat: true
                                Layout.preferredHeight: 28
                                visible: delegateRoot.previewPath.length > 0 && delegateRoot.previewPath.includes("/")
                                onClicked: {
                                    if (resultsListRoot.logic && delegateRoot.previewPath) {
                                        resultsListRoot.logic.openContainingFolder(delegateRoot.previewPath)
                                    }
                                }
                            }
                        }
                    }
                }
            }

            function toggleExpansion() {
                delegateRoot.animateHeight = true
                var matchId = modelData.duplicateId || modelData.display || ""
                var newExpanded = {}
                // We need to trigger a property change for the expandedItems
                for (var key in resultsListRoot.expandedItems) {
                    newExpanded[key] = resultsListRoot.expandedItems[key]
                }
                newExpanded[matchId] = !newExpanded[matchId]
                resultsListRoot.expandedItems = newExpanded
            }
            
            MouseArea {
                id: resultMouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                
                onClicked: (mouse) => {
                    var matchId = modelData.duplicateId || modelData.display || ""
                    var filePath = (modelData.url || "").toString()
                    var modelIndex = (modelData.index !== undefined && modelData.index !== null) ? modelData.index : index
                    
                    if (mouse.button === Qt.RightButton) {
                        resultsListRoot.itemRightClicked({
                            display: modelData.display || "",
                            decoration: modelData.decoration || "application-x-executable",
                            category: modelData.category || "",
                            matchId: matchId,
                            filePath: filePath,
                            isApplication: (modelData.category === "Applications"),
                            uuid: ""
                        }, mouse.x + delegateRoot.x, mouse.y + delegateRoot.y)
                    } else {
                        if (isRSS && resultsListRoot.rssExpandableCards) {
                            delegateRoot.animateHeight = true
                            var newExpanded = {}
                            Object.assign(newExpanded, resultsListRoot.expandedItems)
                            newExpanded[matchId] = !newExpanded[matchId]
                            resultsListRoot.expandedItems = newExpanded
                        } else if (isRSS && filePath.length > 0) {
                            Qt.openUrlExternally(filePath)
                        } else {
                            resultsListRoot.itemClicked(modelIndex, modelData.display || "", modelData.decoration || "application-x-executable", modelData.category || "Other", matchId, filePath)
                        }
                    }
                }
            }

            ToolTip {
                visible: resultsListRoot.previewInlineMode === 0 && delegateRoot.previewSource.length > 0
                delay: 400
                timeout: 10000
                x: delegateRoot.width + 4
                y: 0

                contentItem: Column {
                    spacing: 6

                    Text {
                        text: modelData.display || ""
                        font.bold: true
                        font.pixelSize: 12
                        color: resultsListRoot.textColor
                    }

                    Image {
                        source: delegateRoot.previewSource
                        width: source.length > 0 ? 150 : 0
                        height: source.length > 0 ? 100 : 0
                        fillMode: Image.PreserveAspectFit
                        visible: source.length > 0
                        cache: true
                        asynchronous: true
                    }

                    Text {
                        text: resultsListRoot.locCategory + ": " + (modelData.category || "")
                        font.pixelSize: 10
                        color: Qt.rgba(resultsListRoot.textColor.r, resultsListRoot.textColor.g, resultsListRoot.textColor.b, 0.7)
                        visible: (modelData.category || "").length > 0
                    }

                    Text {
                        text: resultsListRoot.locFileType + ": " + delegateRoot.previewFileType
                        font.pixelSize: 10
                        color: Qt.rgba(resultsListRoot.textColor.r, resultsListRoot.textColor.g, resultsListRoot.textColor.b, 0.7)
                        visible: delegateRoot.previewFileType.length > 0
                    }

                    Text {
                        text: resultsListRoot.locPath + ": " + delegateRoot.previewPath
                        font.pixelSize: 10
                        color: Qt.rgba(resultsListRoot.textColor.r, resultsListRoot.textColor.g, resultsListRoot.textColor.b, 0.7)
                        wrapMode: Text.WrapAnywhere
                        width: 300
                        visible: delegateRoot.previewPath.length > 0
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
        
        // Empty state
        Column {
            anchors.centerIn: parent
            spacing: 10
            visible: resultsListRoot.flatSortedData.length === 0 && resultsListRoot.searchText.length > 0

            BusyIndicator {
                anchors.horizontalCenter: parent.horizontalCenter
                running: resultsListRoot.isLoading
                visible: resultsListRoot.isLoading
            }

            Text {
                text: resultsListRoot.isLoading
                    ? locSearching
                    : locNoResults
                color: Qt.rgba(resultsListRoot.textColor.r, resultsListRoot.textColor.g, resultsListRoot.textColor.b, 0.5)
                font.pixelSize: 12
            }
        }
    }
    
    // Performance optimization: limit how many results are animated at once
    property int maxAnimatedResults: 15
    
    // Cached localized strings to prevent repeated i18nd calls during rendering
    readonly property string locCategory: i18nd("plasma_applet_com.mcc45tr.filesearch", "Category")
    readonly property string locFileType: i18nd("plasma_applet_com.mcc45tr.filesearch", "File Type")
    readonly property string locPath: i18nd("plasma_applet_com.mcc45tr.filesearch", "Path")
    readonly property string locNews: i18nd("plasma_applet_com.mcc45tr.filesearch", "News")
    readonly property string locReadNews: i18nd("plasma_applet_com.mcc45tr.filesearch", "Read News")
    readonly property string locShare: i18nd("plasma_applet_com.mcc45tr.filesearch", "Share")
    readonly property string locSearching: i18nd("plasma_applet_com.mcc45tr.filesearch", "Searching...")
    readonly property string locNoResults: i18nd("plasma_applet_com.mcc45tr.filesearch", "No results found")

    property int count: resultsList.count
    
    function moveUp() {
        if (currentIndex > 0) currentIndex--
    }
    
    function moveDown() {
        if (currentIndex < resultsList.count - 1) currentIndex++
    }
}
