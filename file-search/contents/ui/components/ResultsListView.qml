import "../js/PreviewUtils.js" as PreviewUtils
import "../js/utils.js" as Utils
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
    property var previewSettings: ({
        "images": false,
        "videos": false,
        "text": false,
        "documents": false,
        "applications": false
    })
    property bool previewShowResults: true
    property int previewInlineMode: 1
    property int previewSize: 1
    // Logic controller for context menu actions
    property var logic: null
    // Current selection index
    property int currentIndex: 0
    // Localization
    property string searchText: ""
    property bool isLoading: false
    // Pin support
    property var isPinnedFunc: function(matchId) {
        return false;
    }
    property var togglePinFunc: function(item) {
    }
    // RSS settings from config
    property bool rssShowImages: true
    property bool rssExpandableCards: true
    property var expandedItems: ({
    })
    // Use flat sorted data (JS Array) instead of raw model for consistency
    property var flatSortedData: []
    property bool resultAnimationsEnabled: true
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

    onFlatSortedDataChanged: {
        resultAnimationsEnabled = false;
        animationSettleTimer.restart();
    }

    Timer {
        id: animationSettleTimer
        interval: 120
        repeat: false
        onTriggered: resultsListRoot.resultAnimationsEnabled = true
    }

    // Signals
    signal itemClicked(int index, string display, string decoration, string category, string matchId, string filePath)
    signal itemRightClicked(var item, real x, real y)

    function rssMetaLine(item) {
        var parts = [];
        if (item.subtext && item.subtext.length > 0)
            parts.push(item.subtext);

        if (item.url && item.url.length > 0)
            parts.push(item.url);

        return parts.join("  •  ");
    }

    function moveUp() {
        if (currentIndex > 0)
            currentIndex--;

    }

    function moveDown() {
        if (currentIndex < resultsList.count - 1)
            currentIndex++;

    }

    clip: true
    ScrollBar.vertical.policy: ScrollBar.AlwaysOff

    ListView {
        id: resultsList

        width: parent.width
        model: resultsListRoot.flatSortedData
        spacing: 4
        currentIndex: resultsListRoot.currentIndex
        cacheBuffer: Math.max(400, resultsList.height * 0.5)
        highlightFollowsCurrentItem: true
        // Category section header
        section.property: "sectionCategory"

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
                text: resultsListRoot.isLoading ? locSearching : locNoResults
                color: Qt.rgba(resultsListRoot.textColor.r, resultsListRoot.textColor.g, resultsListRoot.textColor.b, 0.5)
                font.pixelSize: 12
            }

        }

        highlight: Rectangle {
            color: Qt.rgba(resultsListRoot.accentColor.r, resultsListRoot.accentColor.g, resultsListRoot.accentColor.b, 0.15)
            radius: 8
            visible: resultsList.currentItem && !resultsList.currentItem.isRSS // Hide highlight for RSS cards
        }

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

            Accessible.role: Accessible.ListItem
            Accessible.name: modelData.display || ""
            Accessible.description: [modelData.category || "", modelData.subtext || ""].filter(function(part) { return part.length > 0 }).join(", ")
            Accessible.selectable: true
            Accessible.selected: resultsList.currentIndex === index
            Accessible.focused: resultsList.currentIndex === index
            Accessible.onPressAction: delegateRoot.activateResult()

            readonly property bool inViewport: {
                if (!resultsList)
                    return false;

                var dummy = resultsList.contentY; // Bind to scrolling
                var globalY = delegateRoot.mapToItem(resultsListRoot, 0, 0).y;
                return (globalY + delegateRoot.height >= 0) && (globalY <= resultsListRoot.height);
            }
            property real cachedHeight: 0
            readonly property bool isRSS: modelData.category === "RSS" || modelData.category === resultsListRoot.locNews || (modelData.duplicateId && modelData.duplicateId.toString().startsWith("rss:"))
            property bool isExpanded: isRSS && resultsListRoot.rssExpandableCards && !!resultsListRoot.expandedItems[modelData.duplicateId]
            property bool animateHeight: false
            property bool isPreviewAvailable: PreviewUtils.isPreviewAvailable(modelData.url || "", modelData.category || "", resultsListRoot.previewSettings)
            property bool previewActive: resultsListRoot.previewEnabled && !isRSS && isPreviewAvailable && (resultsListRoot.previewInlineMode === 0 ? resultMouseArea.containsMouse : (resultsList.currentIndex === index))
            property bool showInlinePreview: resultsListRoot.previewEnabled && resultsListRoot.previewShowResults && resultsListRoot.previewInlineMode === 1 && !isRSS && isPreviewAvailable && (resultsList.currentIndex === index)
            property string previewPath: previewActive ? PreviewUtils.getLocalPreviewPath(modelData.url || "") : ""
            property string previewSource: previewActive ? PreviewUtils.getPreviewSource(modelData.url || "", resultsListRoot.previewEnabled, resultsListRoot.previewSettings) : ""
            property string previewFileType: previewActive ? PreviewUtils.getFileTypeLabel(modelData.url || "") : ""
            property int snippetRequestToken: 0
            property bool isTextFile: {
                return PreviewUtils.isTextExtension(PreviewUtils.getExtension(previewPath));
            }

            function loadTextSnippet() {
                if (!previewPath || !logic)
                    return ;

                var token = ++snippetRequestToken;
                logic.readLocalTextSnippet(previewPath, function(content, bytes) {
                    if (token !== delegateRoot.snippetRequestToken)
                        return;
                    var lines = content.split('\n').slice(0, 5).join('\n');
                    textSnippet.text = lines;
                    var sizeStr = "";
                    if (bytes < 1024)
                        sizeStr = bytes + " B";
                    else if (bytes < 1.04858e+06)
                        sizeStr = (bytes / 1024).toFixed(1) + " KB";
                    else
                        sizeStr = (bytes / 1.04858e+06).toFixed(1) + " MB";
                    fileSizeText.text = i18nd("plasma_applet_com.mcc45tr.filesearch", "Size") + ": " + sizeStr;
                });
            }

            Component.onDestruction: snippetRequestToken++

            function toggleExpansion() {
                delegateRoot.animateHeight = true;
                var matchId = modelData.duplicateId || modelData.display || "";
                var newExpanded = {
                };
                // Replace the array so QML observes the state change.
                for (var key in resultsListRoot.expandedItems) {
                    newExpanded[key] = resultsListRoot.expandedItems[key];
                }
                newExpanded[matchId] = !newExpanded[matchId];
                resultsListRoot.expandedItems = newExpanded;
            }

            function resolvedFilePath() {
                var filePath = (modelData.url || "").toString();
                var urls = modelData.urls || [];
                if (!filePath && urls.length > 0 && urls[0])
                    filePath = urls[0].toString();
                if (!filePath && modelData.subtext) {
                    var subtext = modelData.subtext.toString();
                    if (subtext.indexOf("/") === 0)
                        filePath = "file://" + subtext;
                    else if (subtext.indexOf("file://") === 0)
                        filePath = subtext;
                }
                return filePath;
            }

            function activateResult() {
                var matchId = modelData.duplicateId || modelData.display || "";
                var filePath = resolvedFilePath();
                var modelIndex = (modelData.index !== undefined && modelData.index !== null) ? modelData.index : index;
                if (isRSS && resultsListRoot.rssExpandableCards) {
                    toggleExpansion();
                } else if (isRSS && filePath.length > 0) {
                    if (Utils.isSafeExternalUrl(filePath))
                        Qt.openUrlExternally(filePath);
                } else {
                    resultsListRoot.itemClicked(modelIndex, modelData.display || "", modelData.decoration || "application-x-executable", modelData.category || "Other", matchId, filePath);
                }
            }

            width: resultsList.width
            onHeightChanged: {
                if (inViewport && height > 0)
                    cachedHeight = height;

            }
            height: {
                if (!inViewport && cachedHeight > 0)
                    return cachedHeight;

                return isRSS ? rssCardLayout.implicitHeight + 24 : (rssCardLayout.implicitHeight + 12);
            }
            onShowInlinePreviewChanged: {
                delegateRoot.animateHeight = true;
                if (showInlinePreview) {
                    if (isTextFile)
                        loadTextSnippet();

                }
            }

            // Background Container
            Rectangle {
                anchors.fill: parent
                visible: inViewport
                anchors.margins: isRSS ? 4 : 0
                color: (resultMouseArea.containsMouse || (resultsList.currentIndex === index && !isRSS)) ? Qt.rgba(resultsListRoot.accentColor.r, resultsListRoot.accentColor.g, resultsListRoot.accentColor.b, 0.15) : (isRSS ? Qt.rgba(resultsListRoot.accentColor.r, resultsListRoot.accentColor.g, resultsListRoot.accentColor.b, 0.05) : "transparent")
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
                                    if (isRSS)
                                        return modelData.subtext || "";

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
                            textFormat: Text.PlainText
                            color: resultsListRoot.textColor
                            font.pixelSize: 13
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                            maximumLineCount: delegateRoot.isExpanded ? 100 : 3
                            elide: Text.ElideRight
                            opacity: 0.85
                            lineHeight: 1.3

                            Behavior on maximumLineCount {
                                enabled: resultsListRoot.resultAnimationsEnabled
                                NumberAnimation {
                                    duration: 250
                                }

                            }

                        }

                        // Image for RSS
                        Image {
                            id: rssListImage

                            source: (inViewport && delegateRoot.isExpanded && resultsListRoot.rssShowImages) ? (modelData.imageUrl || "") : ""
                            Layout.fillWidth: true
                            Layout.preferredHeight: source.length > 0 ? Math.min(300, implicitHeight) : 0
                            fillMode: Image.PreserveAspectFit
                            visible: source.length > 0 && delegateRoot.isExpanded
                            asynchronous: true
                            cache: true
                            sourceSize.width: Math.max(1, resultsListRoot.width)
                            sourceSize.height: 300

                            Kirigami.Icon {
                                anchors.centerIn: parent
                                width: 48
                                height: 48
                                source: "image-missing"
                                visible: parent.status === Image.Error
                            }
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

                                    Kirigami.Icon {
                                        source: "internet-services"
                                        implicitWidth: 16
                                        implicitHeight: 16
                                    }

                                    Text {
                                        text: resultsListRoot.locReadNews
                                        color: resultsListRoot.textColor
                                        font.bold: true
                                        font.pixelSize: 11
                                    }

                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        if (modelData.url) {
                                            if (Utils.isSafeExternalUrl(modelData.url)) Qt.openUrlExternally(modelData.url);
                                        }
                                    }
                                }

                            }

                            Button {
                                text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Read in Window")
                                icon.name: "window-new"
                                flat: true
                                visible: delegateRoot.isExpanded
                                Layout.preferredHeight: 32
                                onClicked: {
                                    popupRoot.showArticleInWindow(modelData.display || modelData.title || "", modelData.fullContent || modelData.description || "", modelData.url || "");
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

                            Item {
                                Layout.fillWidth: true
                            }

                            // Genişlet/Daralt Butonu (Sağ Alt)
                            Button {
                                icon.name: delegateRoot.isExpanded ? "arrow-up" : "arrow-down"
                                Layout.preferredWidth: 32
                                Layout.preferredHeight: 32
                                flat: true
                                visible: resultsListRoot.rssExpandableCards
                                onClicked: {
                                    delegateRoot.animateHeight = true;
                                    toggleExpansion();
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
                                    sourceSize.width: Math.max(1, thumbContainer.width)
                                    sourceSize.height: Math.max(1, thumbContainer.height)
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
                                    text: resultsListRoot.locCategory + ": " + (modelData.category || "Other")
                                    color: Qt.rgba(resultsListRoot.textColor.r, resultsListRoot.textColor.g, resultsListRoot.textColor.b, 0.7)
                                    font.pixelSize: 10
                                    textFormat: Text.PlainText
                                }

                                Text {
                                    text: resultsListRoot.locFileType + ": " + delegateRoot.previewFileType
                                    color: Qt.rgba(resultsListRoot.textColor.r, resultsListRoot.textColor.g, resultsListRoot.textColor.b, 0.7)
                                    font.pixelSize: 10
                                    visible: delegateRoot.previewFileType.length > 0
                                    textFormat: Text.PlainText
                                }

                                Text {
                                    id: fileSizeText

                                    text: ""
                                    color: Qt.rgba(resultsListRoot.textColor.r, resultsListRoot.textColor.g, resultsListRoot.textColor.b, 0.7)
                                    font.pixelSize: 10
                                    visible: text.length > 0
                                    textFormat: Text.PlainText
                                }

                                Text {
                                    text: resultsListRoot.locPath + ": " + delegateRoot.previewPath
                                    color: Qt.rgba(resultsListRoot.textColor.r, resultsListRoot.textColor.g, resultsListRoot.textColor.b, 0.5)
                                    font.pixelSize: 9
                                    wrapMode: Text.WrapAnywhere
                                    Layout.fillWidth: true
                                    textFormat: Text.PlainText
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
                                onClicked: {
                                    if (resultsListRoot.logic) {
                                        resultsListRoot.logic.copyToClipboard(delegateRoot.previewPath);
                                    }
                                }
                            }

                            Button {
                                text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Open Folder")
                                icon.name: "folder-open"
                                flat: true
                                Layout.preferredHeight: 28
                                visible: delegateRoot.previewPath.length > 0 && delegateRoot.previewPath.includes("/")
                                onClicked: {
                                    if (resultsListRoot.logic && delegateRoot.previewPath)
                                        resultsListRoot.logic.openContainingFolder(delegateRoot.previewPath);

                                }
                            }

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
                    var matchId = modelData.duplicateId || modelData.display || "";
                    var filePath = delegateRoot.resolvedFilePath();
                    if (mouse.button === Qt.RightButton) {
                        resultsListRoot.itemRightClicked({
                            "display": modelData.display || "",
                            "decoration": modelData.decoration || "application-x-executable",
                            "category": modelData.category || "",
                            "matchId": matchId,
                            "filePath": filePath,
                            "isApplication": Utils.isAppCategory(modelData.category, filePath, matchId),
                            "uuid": ""
                        }, mouse.x + delegateRoot.x, mouse.y + delegateRoot.y);
                    } else
                        delegateRoot.activateResult();
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
                        sourceSize.width: 150
                        sourceSize.height: 100
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

            Behavior on height {
                enabled: delegateRoot.animateHeight && resultsListRoot.resultAnimationsEnabled

                NumberAnimation {
                    duration: 250
                    easing.type: Easing.InOutQuad
                    onFinished: delegateRoot.animateHeight = false
                }

            }

        }

    }

}
