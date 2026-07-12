import QtQuick
import QtQuick.Layouts
import QtCore
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.extras as PlasmaExtras
import "../js/PreviewUtils.js" as PreviewUtils

// History Tile View - Displays search history in tile/grid format
// Features: Keyboard navigation, Category collapse/expand
FocusScope {
    id: historyTile

    // Required properties
    required property var categorizedHistory
    required property int iconSize
    required property color textColor
    required property color accentColor
    required property bool previewEnabled
    required property var previewSettings
    property bool previewShowHistory: true
    property int previewInlineMode: 1
    property int previewSize: 1
    required property var logic
    readonly property string thumbnailCacheBase: StandardPaths.writableLocation(StandardPaths.HomeLocation).toString().replace(/^file:\/\/\/?/, "/") + "/.cache/thumbnails"

    // Signals
    signal itemClicked(var item)
    signal clearClicked()
    signal hintSelected(string text)

    // Localization removed
    // Use standard i18nd("plasma_applet_com.mcc45tr.filesearch", )

    // Navigation state
    property var collapsedCategories: ({})
    property int selectedFlatIndex: 0
    property string selectedUuid: ""

    // Computed flat list for keyboard navigation
    property var flatItemList: {
        var list = []
        for (var i = 0; i < categorizedHistory.length; i++) {
            var cat = categorizedHistory[i]
            if (collapsedCategories[cat.categoryName]) continue
            for (var j = 0; j < cat.items.length; j++) {
                list.push({
                    catIndex: i,
                    itemIndex: j,
                    globalIndex: list.length,
                    data: cat.items[j]
                })
            }
        }
        return list
    }

    property int totalItems: flatItemList.length

    // Signals for Tab navigation
    signal tabPressed()
    signal shiftTabPressed()
    signal viewModeChangeRequested(int mode)

    focus: true

    // Keyboard handling
    Keys.onUpPressed: smartMoveVertical(-1)
    Keys.onDownPressed: smartMoveVertical(1)
    Keys.onLeftPressed: moveSelection(-1)
    Keys.onRightPressed: moveSelection(1)
    Keys.onReturnPressed: (event) => {
        activateCurrentItem()
        event.accepted = true
    }
    Keys.onEnterPressed: (event) => {
        activateCurrentItem()
        event.accepted = true
    }
    Keys.onTabPressed: (event) => {
        if (event.modifiers & Qt.ShiftModifier) {
            shiftTabPressed()
        } else {
            tabPressed()
        }
        event.accepted = true
    }
    Keys.onPressed: (event) => {
        if (event.modifiers & Qt.ControlModifier) {
            if (event.key === Qt.Key_1) {
                viewModeChangeRequested(0)
                event.accepted = true
            } else if (event.key === Qt.Key_2) {
                viewModeChangeRequested(1)
                event.accepted = true
            }
        }
    }

    function columnsInRow() {
        var itemWidth = tileWidth + 8 // tile width + spacing
        return Math.max(1, Math.floor(historyTile.width / itemWidth))
    }

    // Calculate current column position
    function getCurrentColumn() {
        if (totalItems === 0) return 0
        var cols = columnsInRow()
        var item = flatItemList[selectedFlatIndex]
        if (!item) return 0
        return item.itemIndex % cols
    }

    // Navigation methods
    function moveUp() { smartMoveVertical(-1) }
    function moveDown() { smartMoveVertical(1) }
    function moveLeft() { moveSelection(-1) }
    function moveRight() { moveSelection(1) }
    function movePrev() { moveSelection(-1) }
    function moveNext() { moveSelection(1) }

    // Smart vertical movement that maintains column position
    function smartMoveVertical(direction) {
        if (totalItems === 0) return

        var cols = columnsInRow()
        var currentItem = flatItemList[selectedFlatIndex]
        if (!currentItem) return

        var currentCatIdx = currentItem.catIndex
        var currentItemIdx = currentItem.itemIndex
        var currentCol = currentItemIdx % cols

        var targetGlobalIndex = -1

        if (direction === 1) { // Down
             var nextRowIndex = currentItemIdx + cols

             for (var i = selectedFlatIndex + 1; i < totalItems; i++) {
                 var nextItem = flatItemList[i]

                 if (nextItem.catIndex === currentCatIdx) {
                    if (nextItem.itemIndex === nextRowIndex) {
                        targetGlobalIndex = i
                        break
                    }
                 }
                 else {
                     // Preserve the column when entering the next category.
                     var newCatIdx = nextItem.catIndex
                     var bestMatch = i // default to first item

                     for (var j = i; j < totalItems; j++) {
                         var cand = flatItemList[j]
                         if (cand.catIndex !== newCatIdx) break;
                         if (cand.itemIndex >= cols) break;

                         if ((cand.itemIndex % cols) === currentCol) {
                             targetGlobalIndex = j
                             break
                         }
                         bestMatch = j
                     }
                     if (targetGlobalIndex === -1) targetGlobalIndex = bestMatch
                     break;
                 }
             }
        } else { // Up
             var prevRowIndex = currentItemIdx - cols

             if (prevRowIndex >= 0) {
                 // Move to the previous row in the current category.
                 for (var i = selectedFlatIndex - 1; i >= 0; i--) {
                     var prevItem = flatItemList[i]
                     if (prevItem.catIndex === currentCatIdx && prevItem.itemIndex === prevRowIndex) {
                         targetGlobalIndex = i
                         break
                     }
                     if (prevItem.catIndex !== currentCatIdx) break;
                 }
             } else {
                 // Preserve the column in the final row of the previous category.
                 for (var i = selectedFlatIndex - 1; i >= 0; i--) {
                     var prevItem = flatItemList[i]
                     if (prevItem.catIndex !== currentCatIdx) {
                         var prevCatIdx = prevItem.catIndex
                         var endpointRow = Math.floor(prevItem.itemIndex / cols)
                         var desiredIndex = endpointRow * cols + currentCol

                         if (desiredIndex > prevItem.itemIndex) {
                             // Column doesn't exist in last row, pick last item
                             targetGlobalIndex = i
                         } else {
                             // Find exact match
                             for (var j = i; j >= 0; j--) {
                                 var cand = flatItemList[j]
                                 if (cand.catIndex !== prevCatIdx) break
                                 if (cand.itemIndex === desiredIndex) {
                                     targetGlobalIndex = j
                                     break
                                 }
                             }
                         }
                         break
                     }
                 }
             }
        }

        if (targetGlobalIndex !== -1) {
            selectedFlatIndex = targetGlobalIndex
        }
    }

    function moveSelection(delta) {
        if (totalItems === 0) return
        var newIndex = Math.max(0, Math.min(totalItems - 1, selectedFlatIndex + delta))
        selectedFlatIndex = newIndex
    }

    function activateCurrentItem() {
        if (totalItems === 0) return
        var item = flatItemList[selectedFlatIndex]
        if (item) {
            historyTile.itemClicked(item.data)
        }
    }

    function toggleCategory(categoryName) {
        var newCollapsed = Object.assign({}, collapsedCategories)
        newCollapsed[categoryName] = !newCollapsed[categoryName]
        collapsedCategories = newCollapsed
    }

    function isItemSelected(catIdx, itemIdx) {
        if (totalItems === 0) return false
        var item = flatItemList[selectedFlatIndex]
        return item && item.catIndex === catIdx && item.itemIndex === itemIdx
    }

    // Context Menu
    HistoryContextMenu {
        id: contextMenu
        logic: historyTile.logic
    }

    // Tile Grid
    property int scrollBarStyle: 0

    // Compact tile view mode
    property bool compactTileView: false

    // Computed tile dimensions
    readonly property real tileWidth: compactTileView ? (iconSize + 16) : (iconSize + 40)
    readonly property real tileHeight: compactTileView ? (iconSize + 40) : (iconSize + 50)
    readonly property real textWidth: tileWidth - (Kirigami.Units.smallSpacing * 2)

    PlasmaComponents.ScrollView {
        visible: true
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        clip: true
        PlasmaComponents.ScrollBar.vertical.policy: historyTile.scrollBarStyle === 2
            ? PlasmaComponents.ScrollBar.AlwaysOff
            : PlasmaComponents.ScrollBar.AsNeeded

        Column {
            id: tileView
            width: historyTile.width - 24
            spacing: Kirigami.Units.smallSpacing * 2

            Repeater {
                model: historyTile.categorizedHistory

            delegate: Column {
                id: histCategoryDelegate
                width: tileView.width
                spacing: Kirigami.Units.smallSpacing

                property int catIdx: index
                property bool isCollapsed: historyTile.collapsedCategories[modelData.categoryName] || false
                property bool animateHeight: false

                CategoryHeader {
                    width: parent.width
                    categoryName: modelData.categoryName
                    itemCount: modelData.items.length
                    collapsed: histCategoryDelegate.isCollapsed
                    textColor: historyTile.textColor
                    accentColor: historyTile.accentColor
                    actionIcon: index === 0 ? "edit-clear-history" : ""
                    actionText: i18nd("plasma_applet_com.mcc45tr.filesearch", "Clear History")
                    onToggleRequested: {
                        histCategoryDelegate.animateHeight = true
                        historyTile.toggleCategory(modelData.categoryName)
                    }
                    onActionTriggered: historyTile.clearClicked()
                }

                // Tile Flow (Animated collapse/expand - matches PinnedSection style)
                Item {
                    width: histCategoryDelegate.width
                    height: histCategoryDelegate.isCollapsed ? 0 : histCategoryFlow.implicitHeight
                    clip: true

                    Behavior on height {
                        enabled: histCategoryDelegate.animateHeight
                        NumberAnimation {
                            duration: 200;
                            easing.type: Easing.InOutQuad
                            onFinished: histCategoryDelegate.animateHeight = false
                        }
                    }

                    Flow {
                        id: histCategoryFlow
                        width: {
                            var avail = parent.width > 0 ? parent.width : (historyTile.width - 24);
                            var colW = historyTile.tileWidth + 8;
                            var cols = Math.floor(avail / colW);
                            if (cols <= 0) return avail;
                            return cols * colW - 8;
                        }
                        x: (parent.width - width) / 2
                        anchors.top: parent.top
                        spacing: Kirigami.Units.smallSpacing * 2

                    Repeater {
                        // Destroy preview-heavy delegates for collapsed categories.
                        model: histCategoryDelegate.isCollapsed ? [] : modelData.items

                        Item {
                            id: histTileDelegate
                            property bool isPreviewAvailable: PreviewUtils.isPreviewAvailable(modelData.filePath || modelData.url || "", modelData.category || "", historyTile.previewSettings)
                            property bool showInlinePreview: historyTile.previewEnabled && historyTile.previewShowHistory && historyTile.previewInlineMode === 1 && isPreviewAvailable && histTileDelegate.isSelected

                            // Wide vs Grid sizing
                            width: showInlinePreview ? parent.width : historyTile.tileWidth
                            height: showInlinePreview ? (wideContent.implicitHeight + 16) : historyTile.tileHeight

                            Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                            Behavior on height { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

                            property int itemIdx: index
                            property bool isSelected: historyTile.isItemSelected(histCategoryDelegate.catIdx, itemIdx)
                            readonly property color contentColor: isSelected ? Kirigami.Theme.highlightedTextColor : historyTile.textColor

                            readonly property bool previewActive: historyTile.previewEnabled && isPreviewAvailable && (historyTile.previewInlineMode === 0 ? histTileMouseArea.containsMouse : histTileDelegate.isSelected)
                            readonly property string previewPath: previewActive ? PreviewUtils.getLocalPreviewPath(modelData.filePath || modelData.url || "") : ""
                            readonly property string previewFileType: previewActive ? PreviewUtils.getFileTypeLabel(modelData.filePath || modelData.url || "") : ""
                            readonly property string previewSource: previewActive
                                ? PreviewUtils.getPreviewSource((modelData.filePath || modelData.url || "").toString(), historyTile.previewEnabled, historyTile.previewSettings, historyTile.thumbnailCacheBase)
                                : ""

                            onShowInlinePreviewChanged: {
                                if (showInlinePreview) {
                                    if (isTextFile) {
                                        loadTextSnippet();
                                    }
                                }
                            }

                            property bool isTextFile: {
                                return PreviewUtils.isTextExtension(PreviewUtils.getExtension(previewPath));
                            }
                            property int snippetRequestToken: 0

                            function loadTextSnippet() {
                                if (!previewPath || !historyTile.logic) return;
                                var token = ++snippetRequestToken
                                historyTile.logic.readLocalTextSnippet(previewPath, function(content, bytes) {
                                        if (token === snippetRequestToken) {
                                            var lines = content.split('\n').slice(0, 5).join('\n');
                                            textSnippet.text = lines;

                                            var sizeStr = "";
                                            if (bytes < 1024) sizeStr = bytes + " B";
                                            else if (bytes < 1048576) sizeStr = (bytes / 1024).toFixed(1) + " KB";
                                            else sizeStr = (bytes / 1048576).toFixed(1) + " MB";
                                            fileSizeText.text = i18nd("plasma_applet_com.mcc45tr.filesearch", "Size") + ": " + sizeStr;
                                        }
                                })
                            }
                            Component.onDestruction: snippetRequestToken++

                            Rectangle {
                                id: histTileBg
                                anchors.fill: parent
                                radius: Kirigami.Units.cornerRadius
                                color: "transparent"

                                PlasmaExtras.Highlight {
                                    anchors.fill: parent
                                    visible: histTileDelegate.isSelected || histTileMouseArea.containsMouse || (contextMenu.visible && contextMenu.historyItem === modelData)
                                    active: histTileDelegate.isSelected
                                    hovered: histTileMouseArea.containsMouse
                                    pressed: histTileDelegate.isSelected
                                }

                                Column {
                                    anchors.centerIn: parent
                                    spacing: Kirigami.Units.smallSpacing
                                    visible: !histTileDelegate.showInlinePreview

                                    // Icon Container
                                    Item {
                                        width: historyTile.iconSize
                                        height: historyTile.iconSize
                                        anchors.horizontalCenter: parent.horizontalCenter

                                        // 1. Fallback Icon
                                        Kirigami.Icon {
                                            anchors.fill: parent
                                            source: modelData.decoration || "application-x-executable"
                                            color: histTileDelegate.contentColor
                                            visible: !previewImageTile.item || previewImageTile.item.status !== Image.Ready
                                        }

                                        // 2. Preview Image
                                        Loader {
                                            id: previewImageTile
                                            anchors.fill: parent
                                            active: historyTile.iconSize > 22 && histTileDelegate.previewActive
                                            sourceComponent: Image {
                                                asynchronous: true
                                                fillMode: Image.PreserveAspectCrop
                                                sourceSize.width: historyTile.iconSize
                                                sourceSize.height: historyTile.iconSize
                                                cache: true
                                                source: histTileDelegate.previewSource
                                                visible: source.length > 0 && status === Image.Ready
                                            }
                                        }
                                    }

                                    Text {
                                        width: historyTile.textWidth
                                        text: modelData.display || ""
                                        color: histTileDelegate.contentColor
                                        font.family: Kirigami.Theme.smallFont.family
                                        font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                                        horizontalAlignment: Text.AlignHCenter
                                        elide: Text.ElideRight
                                        maximumLineCount: 1
                                        wrapMode: Text.NoWrap
                                    }

                                    // Parent folder name (Grid mode)
                                    Text {
                                        width: historyTile.textWidth
                                        text: {
                                            if (modelData.isApplication) return "";

                                            var path = modelData.filePath ? modelData.filePath.toString() : (modelData.url ? modelData.url.toString() : "");
                                            if (path && path.length > 0) {
                                                path = path.replace("file://", "");
                                                if (path.endsWith("/")) path = path.slice(0, -1);
                                                var parts = path.split("/");
                                                if (parts.length > 1) {
                                                    // Return parent folder name
                                                    return parts[parts.length - 2];
                                                }
                                            }
                                            return "";
                                        }
                                        color: Qt.rgba(histTileDelegate.contentColor.r, histTileDelegate.contentColor.g, histTileDelegate.contentColor.b, 0.75)
                                        font.family: Kirigami.Theme.smallFont.family
                                        font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                                        horizontalAlignment: Text.AlignHCenter
                                        elide: Text.ElideRight
                                        visible: true
                                        opacity: text.length > 0 ? 1 : 0
                                    }
                                }

                                ColumnLayout {
                                    id: wideContent
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.top: parent.top
                                    anchors.margins: Kirigami.Units.largeSpacing
                                    spacing: Kirigami.Units.smallSpacing * 2
                                    visible: histTileDelegate.showInlinePreview

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: Kirigami.Units.largeSpacing

                                        Kirigami.Icon {
                                            source: modelData.decoration || "application-x-executable"
                                            Layout.preferredWidth: historyTile.iconSize
                                            Layout.preferredHeight: historyTile.iconSize
                                            color: histTileDelegate.contentColor
                                        }

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 2

                                            Text {
                                                text: modelData.display || ""
                                                font.family: Kirigami.Theme.defaultFont.family
                                                font.pixelSize: Kirigami.Theme.defaultFont.pixelSize
                                                font.bold: true
                                                color: histTileDelegate.contentColor
                                                Layout.fillWidth: true
                                                elide: Text.ElideRight
                                            }

                                            Text {
                                                text: {
                                                    if (modelData.isApplication) return "";
                                                    var path = modelData.filePath ? modelData.filePath.toString() : (modelData.url ? modelData.url.toString() : "");
                                                    if (path && path.length > 0) {
                                                        path = path.replace("file://", "");
                                                        path = path.replace(/^\/home\/[^\/]+\//, "");
                                                        return path;
                                                    }
                                                    return "";
                                                }
                                                font.family: Kirigami.Theme.smallFont.family
                                                font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                                                color: Qt.rgba(historyTile.textColor.r, historyTile.textColor.g, historyTile.textColor.b, 0.7)
                                                Layout.fillWidth: true
                                                elide: Text.ElideRight
                                                visible: true
                                                opacity: text.length > 0 ? 1 : 0
                                            }
                                        }
                                    }

                                    // Inline Preview Card
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: Kirigami.Units.smallSpacing * 2
                                        Layout.topMargin: Kirigami.Units.largeSpacing

                                        Rectangle {
                                            Layout.fillWidth: true
                                            Layout.preferredHeight: 1
                                            color: Qt.rgba(historyTile.textColor.r, historyTile.textColor.g, historyTile.textColor.b, 0.15)
                                        }

                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: Kirigami.Units.largeSpacing
                                            Layout.leftMargin: Kirigami.Units.smallSpacing
                                            Layout.rightMargin: Kirigami.Units.smallSpacing

                                            // Left Column: Thumbnail or large icon
                                            Item {
                                                id: thumbContainer
                                                Layout.preferredWidth: historyTile.previewSize === 0 ? 64 : (historyTile.previewSize === 1 ? 120 : 200)
                                                Layout.preferredHeight: historyTile.previewSize === 0 ? 48 : (historyTile.previewSize === 1 ? 90 : 150)
                                                visible: histTileDelegate.previewSource.length > 0 || histTileDelegate.previewFileType.length > 0

                                                // Background fallback placeholder
                                                Rectangle {
                                                    anchors.fill: parent
                                                    color: Qt.rgba(historyTile.textColor.r, historyTile.textColor.g, historyTile.textColor.b, 0.05)
                                                    radius: Kirigami.Units.cornerRadius
                                                }

                                                Kirigami.Icon {
                                                    anchors.centerIn: parent
                                                    implicitWidth: 32
                                                    implicitHeight: 32
                                                    source: modelData.decoration || "application-x-executable"
                                                    color: historyTile.textColor
                                                    opacity: 0.3
                                                    visible: imgPreview.status !== Image.Ready
                                                }

                                                Image {
                                                    id: imgPreview
                                                    anchors.fill: parent
                                                    source: histTileDelegate.previewSource
                                                    fillMode: Image.PreserveAspectFit
                                                    visible: source.length > 0
                                                    cache: true
                                                    asynchronous: true
                                                }
                                            }

                                            // Right Column: Metadata
                                            ColumnLayout {
                                                Layout.fillWidth: true
                                                spacing: Kirigami.Units.smallSpacing

                                                Text {
                                                    text: modelData.display || ""
                                                    color: historyTile.textColor
                                                    font.bold: true
                                                    font.family: Kirigami.Theme.defaultFont.family
                                                    font.pixelSize: Kirigami.Theme.defaultFont.pixelSize
                                                    elide: Text.ElideRight
                                                    Layout.fillWidth: true
                                                }

                                                Text {
                                                    text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Category") + ": " + (modelData.category || "Other")
                                                    color: Qt.rgba(historyTile.textColor.r, historyTile.textColor.g, historyTile.textColor.b, 0.7)
                                                    font.family: Kirigami.Theme.smallFont.family
                                                    font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                                                    textFormat: Text.PlainText
                                                }

                                                Text {
                                                    text: i18nd("plasma_applet_com.mcc45tr.filesearch", "File Type") + ": " + histTileDelegate.previewFileType
                                                    color: Qt.rgba(historyTile.textColor.r, historyTile.textColor.g, historyTile.textColor.b, 0.7)
                                                    font.family: Kirigami.Theme.smallFont.family
                                                    font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                                                    visible: histTileDelegate.previewFileType.length > 0
                                                    textFormat: Text.PlainText
                                                }

                                                Text {
                                                    id: fileSizeText
                                                    text: ""
                                                    color: Qt.rgba(historyTile.textColor.r, historyTile.textColor.g, historyTile.textColor.b, 0.7)
                                                    font.family: Kirigami.Theme.smallFont.family
                                                    font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                                                    visible: text.length > 0
                                                    textFormat: Text.PlainText
                                                }

                                                Text {
                                                    text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Path") + ": " + histTileDelegate.previewPath
                                                    color: Qt.rgba(historyTile.textColor.r, historyTile.textColor.g, historyTile.textColor.b, 0.5)
                                                    font.family: Kirigami.Theme.smallFont.family
                                                    font.pixelSize: Kirigami.Theme.smallFont.pixelSize
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
                                            radius: Kirigami.Units.cornerRadius
                                            border.width: 1
                                            border.color: Qt.rgba(historyTile.textColor.r, historyTile.textColor.g, historyTile.textColor.b, 0.1)
                                            visible: histTileDelegate.isTextFile && textSnippet.text.length > 0

                                            Text {
                                                id: textSnippet
                                                anchors.fill: parent
                                                anchors.margins: Kirigami.Units.smallSpacing
                                                text: ""
                                                color: historyTile.textColor
                                                font.family: "Monospace"
                                                font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                                                wrapMode: Text.Wrap
                                            }
                                        }

                                        // Quick Actions
                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: Kirigami.Units.largeSpacing

                                            PlasmaComponents.Button {
                                                text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Copy Path")
                                                icon.name: "edit-copy"
                                                flat: true
                                                Layout.preferredHeight: 28
                                                onClicked: if (historyTile.logic) historyTile.logic.copyToClipboard(histTileDelegate.previewPath)
                                            }

                                            PlasmaComponents.Button {
                                                text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Open Folder")
                                                icon.name: "folder-open"
                                                flat: true
                                                Layout.preferredHeight: 28
                                                visible: histTileDelegate.previewPath.length > 0 && histTileDelegate.previewPath.includes("/")
                                                onClicked: {
                                                    if (historyTile.logic && histTileDelegate.previewPath) {
                                                        historyTile.logic.openContainingFolder(histTileDelegate.previewPath)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }

                                MouseArea {
                                    id: histTileMouseArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: (mouse) => {
                                        if (mouse.button === Qt.RightButton) {
                                            contextMenu.historyItem = modelData
                                            contextMenu.popup()
                                        } else {
                                            historyTile.itemClicked(modelData)
                                        }
                                    }
                                }

                                PlasmaComponents.ToolTip {
                                    visible: histTileMouseArea.containsMouse && histTileDelegate.previewSource.length === 0
                                    text: (modelData.display || "") + (modelData.filePath ? "\n" + modelData.filePath.toString().replace("file://", "") : "")
                                }

                                Loader {
                                    active: historyTile.previewInlineMode === 0
                                            && histTileDelegate.previewSource.length > 0
                                            && histTileMouseArea.containsMouse
                                    sourceComponent: PlasmaComponents.ToolTip {
                                        visible: true
                                        delay: 500
                                        timeout: 10000
                                        x: histTileDelegate.width + 4
                                        y: 0

                                        contentItem: Column {
                                        spacing: Kirigami.Units.smallSpacing

                                        Text {
                                            text: modelData.display || ""
                                            font.bold: true
                                            font.family: Kirigami.Theme.defaultFont.family
                                            font.pixelSize: Kirigami.Theme.defaultFont.pixelSize
                                            color: historyTile.textColor
                                        }

                                        Image {
                                            source: histTileDelegate.previewSource
                                            width: source.length > 0 ? 150 : 0
                                            height: source.length > 0 ? 100 : 0
                                            fillMode: Image.PreserveAspectFit
                                            visible: source.length > 0
                                            cache: true
                                            asynchronous: true
                                        }

                                        Text {
                                            text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Category") + ": " + (modelData.category || "")
                                            font.family: Kirigami.Theme.smallFont.family
                                            font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                                            color: Qt.rgba(historyTile.textColor.r, historyTile.textColor.g, historyTile.textColor.b, 0.7)
                                            visible: (modelData.category || "").length > 0
                                        }

                                        Text {
                                            text: i18nd("plasma_applet_com.mcc45tr.filesearch", "File Type") + ": " + histTileDelegate.previewFileType
                                            font.family: Kirigami.Theme.smallFont.family
                                            font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                                            color: Qt.rgba(historyTile.textColor.r, historyTile.textColor.g, historyTile.textColor.b, 0.7)
                                            visible: histTileDelegate.previewFileType.length > 0
                                        }

                                        Text {
                                            text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Path") + ": " + histTileDelegate.previewPath
                                            font.family: Kirigami.Theme.smallFont.family
                                            font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                                            color: Qt.rgba(historyTile.textColor.r, historyTile.textColor.g, historyTile.textColor.b, 0.7)
                                            wrapMode: Text.WrapAnywhere
                                            width: 300
                                            visible: histTileDelegate.previewPath.length > 0
                                        }
                                        }

                                        background: Rectangle {
                                            color: Kirigami.Theme.backgroundColor
                                            border.color: historyTile.accentColor
                                            border.width: 1
                                            radius: Kirigami.Units.cornerRadius
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
    }

    onSelectedFlatIndexChanged: {
        var selected = flatItemList[selectedFlatIndex]
        selectedUuid = selected && selected.data ? (selected.data.uuid || "") : ""
    }

    // Preserve selection by stable identity when the backing array is rebuilt.
    onCategorizedHistoryChanged: {
        var nextIndex = 0
        if (selectedUuid) {
            for (var i = 0; i < flatItemList.length; i++) {
                if (flatItemList[i].data && flatItemList[i].data.uuid === selectedUuid) {
                    nextIndex = i
                    break
                }
            }
        }
        selectedFlatIndex = Math.min(nextIndex, Math.max(0, flatItemList.length - 1))
    }

}
