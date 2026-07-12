import "../js/PreviewUtils.js" as PreviewUtils
import "../js/utils.js" as Utils
import QtQuick
import QtQuick.Layouts
import QtCore
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.extras as PlasmaExtras

// Tile-based search results with keyboard navigation and inline previews.
FocusScope {
    id: resultsTileRoot

    // Required properties
    required property var categorizedData
    required property int iconSize
    required property color textColor
    required property color accentColor
    // Localization
    property string searchText: ""
    property bool isLoading: false
    // Preview settings from config
    property bool previewEnabled: true
    property var previewSettings: ({
        "images": true,
        "videos": false,
        "text": false,
        "documents": false
    })
    property bool previewShowResults: true
    property int previewInlineMode: 1
    property int previewSize: 1
    // RSS settings from config
    property bool rssShowImages: true
    property bool rssExpandableCards: true
    property var expandedItems: ({
    })
    // Navigation state
    property int currentCategoryIndex: 0
    property int currentItemIndex: 0
    property var collapsedCategories: ({
    })
    property var logic: null
    // Computed flat list for keyboard navigation
    property var flatItemList: {
        var list = [];
        for (var i = 0; i < categorizedData.length; i++) {
            var cat = categorizedData[i];
            if (collapsedCategories[cat.categoryName])
                continue;

            for (var j = 0; j < cat.items.length; j++) {
                var item = cat.items[j];
                item._tileCategoryIndex = i;
                item._tileItemIndex = j;
                list.push(item);
            }
        }
        return list;
    }
    property int totalItems: flatItemList.length
    property int selectedFlatIndex: 0
    property string selectedMatchId: ""
    // Preview visibility state
    property bool previewForceVisible: false
    property bool resultAnimationsEnabled: true
    property int scrollBarStyle: 0
    // Compact tile view mode
    property bool compactTileView: false
    // Cached localized strings to prevent repeated i18nd calls during rendering
    readonly property string locCategory: i18nd("plasma_applet_com.mcc45tr.filesearch", "Category")
    readonly property string locFileType: i18nd("plasma_applet_com.mcc45tr.filesearch", "File Type")
    readonly property string locPath: i18nd("plasma_applet_com.mcc45tr.filesearch", "Path")
    readonly property string locSpacePreview: i18nd("plasma_applet_com.mcc45tr.filesearch", "Space to preview")
    readonly property string locReadBrowser: i18nd("plasma_applet_com.mcc45tr.filesearch", "Read in Browser")
    readonly property string locSearching: i18nd("plasma_applet_com.mcc45tr.filesearch", "Searching...")
    readonly property string locNoResults: i18nd("plasma_applet_com.mcc45tr.filesearch", "No results found")
    readonly property string locTypeToSearch: i18nd("plasma_applet_com.mcc45tr.filesearch", "Type to search")
    readonly property string thumbnailCacheBase: Utils.decodeLocalPath(StandardPaths.writableLocation(StandardPaths.HomeLocation)) + "/.cache/thumbnails"
    // Computed tile dimensions for grid items
    readonly property real tileWidth: compactTileView ? (iconSize + 16) : (iconSize + 40)
    readonly property real tileHeight: compactTileView ? (iconSize + 40) : (iconSize + 50)
    readonly property real textWidth: compactTileView ? (iconSize + 8) : (iconSize + 32)
    readonly property int virtualColumnCount: Math.max(1, Math.floor(Math.max(1, width - 24) / (tileWidth + 8)))

    // Flatten categories into small, virtualizable rows. A row contains at most
    // one screenful of tiles, so ListView can release everything off screen.
    readonly property var virtualRows: {
        var rows = [];
        var columns = virtualColumnCount;
        for (var catIdx = 0; catIdx < categorizedData.length; catIdx++) {
            var category = categorizedData[catIdx];
            var name = category.categoryName || "";
            var items = category.items || [];
            var wide = isWideCategory(name);
            rows.push({
                kind: "header",
                catIdx: catIdx,
                categoryName: name,
                itemCount: items.length,
                isWide: wide
            });
            if (collapsedCategories[name])
                continue;

            var rowSize = wide ? 1 : columns;
            for (var start = 0; start < items.length; start += rowSize) {
                rows.push({
                    kind: "items",
                    catIdx: catIdx,
                    categoryName: name,
                    isWide: wide,
                    startIndex: start,
                    items: items.slice(start, start + rowSize)
                });
            }
        }
        return rows;
    }

    // Signals
    signal itemClicked(int index, string display, string decoration, string category, string matchId, string filePath)
    signal itemRightClicked(var item, var visualParent, real x, real y)
    // Signals for Tab navigation
    signal tabPressed()
    signal shiftTabPressed()
    signal viewModeChangeRequested(int mode)

    function columnsInRow() {
        return virtualColumnCount;
    }

    // Calculate current column position
    function getCurrentColumn() {
        if (totalItems === 0)
            return 0;

        var cols = columnsInRow();
        // Find position within current category row
        var item = flatItemList[selectedFlatIndex];
        if (!item)
            return 0;

        return item._tileItemIndex % cols;
    }

    function moveUp() {
        smartMoveVertical(-1);
    }

    function moveDown() {
        smartMoveVertical(1);
    }

    function moveLeft() {
        moveSelection(-1);
    }

    function moveRight() {
        moveSelection(1);
    }

    function movePrev() {
        moveSelection(-1);
    }

    function moveNext() {
        moveSelection(1);
    }

    // Smart vertical movement that maintains column position
    function smartMoveVertical(direction) {
        if (totalItems === 0)
            return ;

        var cols = columnsInRow();
        var currentItem = flatItemList[selectedFlatIndex];
        if (!currentItem)
            return ;

        var currentCatIdx = currentItem._tileCategoryIndex;
        var currentItemIdx = currentItem._tileItemIndex;
        var currentCol = currentItemIdx % cols;
        var targetGlobalIndex = -1;
        if (direction === 1) {
            // Move down within the category or into the next category.
            var nextRowIndex = currentItemIdx + cols;
            for (var i = selectedFlatIndex + 1; i < totalItems; i++) {
                var nextItem = flatItemList[i];
                if (nextItem._tileCategoryIndex === currentCatIdx) {
                    if (nextItem._tileItemIndex === nextRowIndex) {
                        targetGlobalIndex = i;
                        break;
                    }
                } else {
                    // Preserve the column when entering the next category.
                    var newCatIdx = nextItem._tileCategoryIndex;
                    var bestMatch = i; // default to first item
                    for (var j = i; j < totalItems; j++) {
                        var cand = flatItemList[j];
                        if (cand._tileCategoryIndex !== newCatIdx)
                            break;

                        if (cand._tileItemIndex >= cols)
                            break;
                        if ((cand._tileItemIndex % cols) === currentCol) {
                            targetGlobalIndex = j;
                            break;
                        }
                        bestMatch = j;
                    }
                    if (targetGlobalIndex === -1)
                        targetGlobalIndex = bestMatch;

                    break;
                }
            }
        } else {
            // Up
            var prevRowIndex = currentItemIdx - cols;
            if (prevRowIndex >= 0) {
                // Move to the previous row in the current category.
                for (var i = selectedFlatIndex - 1; i >= 0; i--) {
                    var prevItem = flatItemList[i];
                    if (prevItem._tileCategoryIndex === currentCatIdx && prevItem._tileItemIndex === prevRowIndex) {
                        targetGlobalIndex = i;
                        break;
                    }
                    if (prevItem._tileCategoryIndex !== currentCatIdx)
                        break;

                }
            } else {
                // Preserve the column in the final row of the previous category.
                for (var i = selectedFlatIndex - 1; i >= 0; i--) {
                    var prevItem = flatItemList[i];
                    if (prevItem._tileCategoryIndex !== currentCatIdx) {
                        var prevCatIdx = prevItem._tileCategoryIndex;
                        var endpointRow = Math.floor(prevItem._tileItemIndex / cols);
                        var desiredIndex = endpointRow * cols + currentCol;
                        if (desiredIndex > prevItem._tileItemIndex) {
                            // Column doesn't exist in last row, pick last item
                            targetGlobalIndex = i;
                        } else {
                            // Find exact match
                            for (var j = i; j >= 0; j--) {
                                var cand = flatItemList[j];
                                if (cand._tileCategoryIndex !== prevCatIdx)
                                    break;

                                if (cand._tileItemIndex === desiredIndex) {
                                    targetGlobalIndex = j;
                                    break;
                                }
                            }
                        }
                        break;
                    }
                }
            }
        }
        if (targetGlobalIndex !== -1) {
            selectedFlatIndex = targetGlobalIndex;
            ensureItemVisible();
        }
    }

    function moveSelection(delta) {
        if (totalItems === 0)
            return ;

        var newIndex = Math.max(0, Math.min(totalItems - 1, selectedFlatIndex + delta));
        selectedFlatIndex = newIndex;
        ensureItemVisible();
    }

    // Scroll to make selected item visible
    function ensureItemVisible() {
        var selected = flatItemList[selectedFlatIndex];
        if (!selected || !resultsTileList)
            return;

        for (var rowIndex = 0; rowIndex < virtualRows.length; rowIndex++) {
            var row = virtualRows[rowIndex];
            if (row.kind !== "items" || row.catIdx !== selected._tileCategoryIndex)
                continue;
            var endIndex = row.startIndex + row.items.length;
            if (selected._tileItemIndex >= row.startIndex && selected._tileItemIndex < endIndex) {
                resultsTileList.positionViewAtIndex(rowIndex, ListView.Contain);
                return;
            }
        }
    }

    function activateCurrentItem() {
        if (totalItems === 0)
            return ;

        var item = flatItemList[selectedFlatIndex];
        if (item) {
            var data = item;
            var matchId = data.duplicateId || data.display || "";
            var filePath = (data.url && data.url.toString) ? data.url.toString() : (data.url || "");
            var subtext = data.subtext || "";
            var urls = data.urls || [];
            if (filePath === "" && urls.length > 0 && urls[0])
                filePath = urls[0].toString();

            if (filePath === "") {
                if (subtext.indexOf("/") === 0)
                    filePath = "file://" + subtext;
                else if (subtext.indexOf("file://") === 0)
                    filePath = subtext;
            }
            itemClicked(data.index, data.display || "", data.decoration || "application-x-executable", data.category || "Other", matchId, filePath);
        }
    }

    function toggleCategory(categoryName) {
        var newCollapsed = Object.assign({
        }, collapsedCategories);
        newCollapsed[categoryName] = !newCollapsed[categoryName];
        collapsedCategories = newCollapsed;
    }

    function isItemSelected(catIdx, itemIdx) {
        if (totalItems === 0)
            return false;

        var item = flatItemList[selectedFlatIndex];
        return item && item._tileCategoryIndex === catIdx && item._tileItemIndex === itemIdx;
    }

    function isWideCategory(cat) {
        return Utils.isWideCategory(cat);
    }

    focus: true
    // Keyboard handling
    Keys.onUpPressed: smartMoveVertical(-1)
    Keys.onDownPressed: smartMoveVertical(1)
    Keys.onLeftPressed: moveSelection(-1)
    Keys.onRightPressed: moveSelection(1)
    Keys.onReturnPressed: (event) => {
        activateCurrentItem();
        event.accepted = true;
    }
    Keys.onEnterPressed: (event) => {
        activateCurrentItem();
        event.accepted = true;
    }
    Keys.onTabPressed: (event) => {
        if (event.modifiers & Qt.ShiftModifier)
            shiftTabPressed();
        else
            tabPressed();
        event.accepted = true;
    }
    Keys.onPressed: (event) => {
        if (event.modifiers & Qt.ControlModifier) {
            if (event.key === Qt.Key_1) {
                viewModeChangeRequested(0);
                event.accepted = true;
            } else if (event.key === Qt.Key_2) {
                viewModeChangeRequested(1);
                event.accepted = true;
            } else if (event.key === Qt.Key_Space) {
                // Toggle preview for selected item
                previewForceVisible = !previewForceVisible;
                event.accepted = true;
            }
        }
    }
    onSelectedFlatIndexChanged: {
        var selected = flatItemList[selectedFlatIndex]
        selectedMatchId = selected ? (selected.duplicateId || selected.display || "") : ""
    }

    // Preserve keyboard selection across plain-array model replacement.
    onCategorizedDataChanged: {
        resultAnimationsEnabled = false;
        animationSettleTimer.restart();
        var nextIndex = 0
        if (selectedMatchId) {
            for (var i = 0; i < flatItemList.length; i++) {
                var data = flatItemList[i]
                if (data && (data.duplicateId || data.display || "") === selectedMatchId) {
                    nextIndex = i
                    break
                }
            }
        }
        selectedFlatIndex = Math.min(nextIndex, Math.max(0, flatItemList.length - 1));
    }

    Timer {
        id: animationSettleTimer
        interval: 120
        repeat: false
        onTriggered: resultsTileRoot.resultAnimationsEnabled = true
    }

    ListView {
        id: resultsTileList

        anchors.fill: parent
        anchors.leftMargin: Kirigami.Units.largeSpacing
        anchors.rightMargin: Kirigami.Units.largeSpacing
        clip: true
        spacing: Kirigami.Units.smallSpacing * 2
        cacheBuffer: Math.max(height * 0.5, resultsTileRoot.tileHeight * 2)
        model: resultsTileRoot.virtualRows
        reuseItems: true
        PlasmaComponents.ScrollBar.vertical: PlasmaComponents.ScrollBar {
            policy: resultsTileRoot.scrollBarStyle === 2
                ? PlasmaComponents.ScrollBar.AlwaysOff
                : PlasmaComponents.ScrollBar.AsNeeded
        }

        delegate: Item {
                    id: categoryDelegate

                    readonly property var rowData: modelData
                    readonly property int catIdx: rowData.catIdx
                    readonly property bool isHeader: rowData.kind === "header"
                    readonly property bool isWide: !!rowData.isWide

                    width: resultsTileList.width
                    height: isHeader
                        ? Kirigami.Units.gridUnit + Kirigami.Units.smallSpacing
                        : Math.max(resultsTileRoot.tileHeight, categoryFlow.implicitHeight)

                    CategoryHeader {
                        visible: categoryDelegate.isHeader
                        width: parent.width
                        categoryName: categoryDelegate.rowData.categoryName || ""
                        itemCount: categoryDelegate.rowData.itemCount === undefined ? -1 : categoryDelegate.rowData.itemCount
                        collapsed: !!resultsTileRoot.collapsedCategories[categoryDelegate.rowData.categoryName]
                        textColor: resultsTileRoot.textColor
                        accentColor: resultsTileRoot.accentColor
                        onToggleRequested: resultsTileRoot.toggleCategory(categoryDelegate.rowData.categoryName)
                    }

                    // Grid Flow (Animated collapse/expand - matches PinnedSection style)
                    Item {
                        visible: !categoryDelegate.isHeader
                        width: parent.width
                        height: categoryFlow.implicitHeight
                        clip: true

                        Flow {
                            id: categoryFlow

                            // Calculate exact width to enable horizontal centering
                            width: {
                                var avail = parent.width > 0 ? parent.width : (resultsTileRoot.width - 24);
                                var colW = resultsTileRoot.tileWidth + 8;
                                var cols = Math.floor(avail / colW);
                                if (cols <= 0)
                                    return avail;

                                return categoryDelegate.isWide ? avail : (cols * colW - 8);
                            }
                            x: (parent.width - width) / 2
                            anchors.top: parent.top
                            spacing: Kirigami.Units.smallSpacing * 2

                            Repeater {
                                model: categoryDelegate.isHeader ? [] : categoryDelegate.rowData.items

                                delegate: Item {
                                    id: tileDelegate

                                    Accessible.role: Accessible.ListItem
                                    Accessible.name: modelData.display || ""
                                    Accessible.description: [modelData.category || "", modelData.subtext || ""].filter(function(part) { return part.length > 0 }).join(", ")
                                    Accessible.selectable: true
                                    Accessible.selected: tileDelegate.isSelected
                                    Accessible.focused: tileDelegate.isSelected
                                    Accessible.onPressAction: tileDelegate.activateResult()

                                    property bool isRSS: modelData.category === "RSS"
                                    property bool isPreviewAvailable: PreviewUtils.isPreviewAvailable(modelData.url || "", modelData.category || "", resultsTileRoot.previewSettings)
                                    property bool showInlinePreview: resultsTileRoot.previewEnabled && resultsTileRoot.previewShowResults && resultsTileRoot.previewInlineMode === 1 && !isRSS && isPreviewAvailable && tileDelegate.isSelected
                                    property bool isExpanded: (isRSS && resultsTileRoot.rssExpandableCards && !!resultsTileRoot.expandedItems[modelData.duplicateId]) || showInlinePreview
                                    property int itemIdx: categoryDelegate.rowData.startIndex + index
                                    property bool isSelected: resultsTileRoot.isItemSelected(categoryDelegate.catIdx, itemIdx)
                                    readonly property color contentColor: isSelected ? Kirigami.Theme.highlightedTextColor : resultsTileRoot.textColor
                                    property bool previewActive: resultsTileRoot.previewEnabled && isPreviewAvailable && (resultsTileRoot.previewInlineMode === 0 ? (tileContentLoader.item && tileContentLoader.item.hovered) : tileDelegate.isSelected)
                                    property string previewPath: previewActive ? PreviewUtils.getLocalPreviewPath(modelData.url || "") : ""
                                    property string previewFileType: previewActive ? PreviewUtils.getFileTypeLabel(modelData.url || "") : ""
                                    property string previewSource: previewActive ? PreviewUtils.getPreviewSource(modelData.url || "", resultsTileRoot.previewEnabled, resultsTileRoot.previewSettings, resultsTileRoot.thumbnailCacheBase) : ""
                                    property bool isTextFile: {
                                        return PreviewUtils.isTextExtension(PreviewUtils.getExtension(previewPath));
                                    }

                                    function resolvedFilePath() {
                                        var filePath = (modelData.url && modelData.url.toString) ? modelData.url.toString() : (modelData.url || "");
                                        var subtext = modelData.subtext || "";
                                        var urls = modelData.urls || [];
                                        if (filePath === "" && urls.length > 0 && urls[0])
                                            filePath = urls[0].toString();
                                        if (filePath === "") {
                                            if (subtext.indexOf("/") === 0)
                                                filePath = "file://" + subtext;
                                            else if (subtext.indexOf("file://") === 0)
                                                filePath = subtext;
                                        }
                                        return filePath;
                                    }

                                    function activateResult() {
                                        var matchId = modelData.duplicateId || modelData.display || "";
                                        if (tileDelegate.isRSS && resultsTileRoot.rssExpandableCards) {
                                            var newExpanded = {};
                                            Object.assign(newExpanded, resultsTileRoot.expandedItems);
                                            newExpanded[matchId] = !newExpanded[matchId];
                                            resultsTileRoot.expandedItems = newExpanded;
                                            return;
                                        }
                                        resultsTileRoot.itemClicked(modelData.index, modelData.display || "", modelData.decoration || "application-x-executable", modelData.category || "Other", matchId, resolvedFilePath());
                                    }

                                    // Wide vs Grid sizing
                                    width: (categoryDelegate.isWide || tileDelegate.isExpanded) ? parent.width : resultsTileRoot.tileWidth
                                    height: {
                                        return (categoryDelegate.isWide || tileDelegate.isExpanded) && tileContentLoader.item
                                            ? (tileContentLoader.item.contentImplicitHeight + 16)
                                            : resultsTileRoot.tileHeight;
                                    }
                                    Layout.fillWidth: categoryDelegate.isWide || tileDelegate.isExpanded
                                    Loader {
                                        id: tileContentLoader
                                        anchors.fill: parent
                                        active: true
                                        asynchronous: true

                                        sourceComponent: Component {
                                            Item {
                                                id: materializedTile
                                                anchors.fill: parent
                                                readonly property bool hovered: tileMouseArea.containsMouse
                                                readonly property real contentImplicitHeight: tileContent.implicitHeight

                                                function loadTextSnippet() {
                                                    if (!tileDelegate.previewPath || !resultsTileRoot.logic) return
                                                    resultsTileRoot.logic.readLocalTextSnippet(tileDelegate.previewPath, function(content, bytes) {
                                                        if (tileContentLoader.item !== materializedTile) return
                                                        if (!loader.item) return
                                                        loader.item.snippetText = content.split('\n').slice(0, 5).join('\n')
                                                        var sizeStr = bytes < 1024 ? bytes + " B"
                                                            : (bytes < 1048580 ? (bytes / 1024).toFixed(1) + " KB"
                                                            : (bytes / 1048580).toFixed(1) + " MB")
                                                        loader.item.sizeText = i18nd("plasma_applet_com.mcc45tr.filesearch", "Size") + ": " + sizeStr
                                                    })
                                                }

                                    Rectangle {
                                        id: tileBg

                                        anchors.fill: parent
                                        anchors.bottomMargin: (categoryDelegate.isWide || tileDelegate.isExpanded) ? 8 : 0
                                        radius: Kirigami.Units.cornerRadius
                                        color: "transparent"

                                        PlasmaExtras.Highlight {
                                            anchors.fill: parent
                                            visible: tileDelegate.isSelected || tileMouseArea.containsMouse
                                            active: tileDelegate.isSelected
                                            hovered: tileMouseArea.containsMouse
                                            pressed: tileDelegate.isSelected
                                        }

                                        // Content Loader (Grid vs Horizontal Layout)
                                        Item {
                                            id: tileContent

                                            anchors.fill: parent
                                            anchors.margins: Kirigami.Units.largeSpacing
                                            implicitHeight: loader.item ? loader.item.implicitHeight : 50

                                            Loader {
                                                id: loader

                                                anchors.fill: parent
                                                asynchronous: true
                                                sourceComponent: (categoryDelegate.isWide || tileDelegate.isExpanded) ? wideLayoutComp : gridLayoutComp
                                                onLoaded: {
                                                    if (tileDelegate.showInlinePreview && tileDelegate.isTextFile) materializedTile.loadTextSnippet()
                                                }
                                            }

                                        }

                                    }

                                    Component {
                                        id: gridLayoutComp

                                        Column {
                                            spacing: Kirigami.Units.smallSpacing
                                            anchors.centerIn: parent

                                            Item {
                                                width: resultsTileRoot.iconSize
                                                height: resultsTileRoot.iconSize
                                                anchors.horizontalCenter: parent.horizontalCenter

                                                Kirigami.Icon {
                                                    anchors.fill: parent
                                                    source: (tileDelegate.isRSS && modelData.sourceIcon) ? modelData.sourceIcon : (modelData.decoration || "application-x-executable")
                                                    color: tileDelegate.contentColor
                                                    visible: previewImageGrid.status !== Image.Ready
                                                }

                                                Image {
                                                    id: previewImageGrid

                                                    anchors.fill: parent
                                                    asynchronous: true
                                                    cache: true
                                                    fillMode: Image.PreserveAspectCrop
                                                    sourceSize.width: resultsTileRoot.iconSize
                                                    sourceSize.height: resultsTileRoot.iconSize
                                                    source: resultsTileRoot.iconSize > 22 ? tileDelegate.previewSource : ""
                                                    visible: source.length > 0 && status === Image.Ready
                                                }

                                            }

                                            Text {
                                                width: tileDelegate.width - (Kirigami.Units.smallSpacing * 2)
                                                text: modelData.display || ""
                                                color: tileDelegate.contentColor
                                                font.family: Kirigami.Theme.smallFont.family
                                                font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                                                horizontalAlignment: Text.AlignHCenter
                                                elide: Text.ElideRight
                                                maximumLineCount: 1
                                                wrapMode: Text.NoWrap
                                            }

                                            Text {
                                                width: tileDelegate.width - 16
                                                text: {
                                                    var cat = modelData.category || "";
                                                    var isApp = Utils.isAppCategory(cat, tileDelegate.resolvedFilePath(), modelData.duplicateId || modelData.display || "", modelData.decoration || "");
                                                    if (isApp)
                                                        return modelData.subtext || "";

                                                    var path = (modelData.url && modelData.url.toString) ? modelData.url.toString() : "";
                                                    if (!path && modelData.subtext && modelData.subtext.toString().indexOf("/") === 0)
                                                        path = "file://" + modelData.subtext;

                                                    if (path && path.length > 0) {
                                                        path = path.replace("file://", "");
                                                        if (path.slice(-1) === "/")
                                                            path = path.slice(0, -1);

                                                        var parts = path.split("/");
                                                        if (parts.length > 1)
                                                            return parts[parts.length - 2];

                                                    }
                                                    return modelData.subtext || "";
                                                }
                                                color: Qt.rgba(tileDelegate.contentColor.r, tileDelegate.contentColor.g, tileDelegate.contentColor.b, 0.75)
                                                font.family: Kirigami.Theme.smallFont.family
                                                font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                                                horizontalAlignment: Text.AlignHCenter
                                                elide: Text.ElideRight
                                                visible: true
                                                opacity: text.length > 0 ? 1 : 0
                                            }

                                        }

                                    }

                                    Component {
                                        id: wideLayoutComp

                                        ColumnLayout {
                                            id: wideLayout
                                            property alias snippetText: textSnippet.text
                                            property alias sizeText: fileSizeText.text

                                            spacing: Kirigami.Units.largeSpacing

                                            RowLayout {
                                                spacing: Kirigami.Units.largeSpacing
                                                Layout.fillWidth: true

                                                Kirigami.Icon {
                                                    source: (tileDelegate.isRSS && modelData.sourceIcon) ? modelData.sourceIcon : (modelData.decoration || "application-x-executable")
                                                    Layout.preferredWidth: resultsTileRoot.iconSize
                                                    Layout.preferredHeight: resultsTileRoot.iconSize
                                                    color: tileDelegate.contentColor
                                                    visible: !tileDelegate.isExpanded || !tileDelegate.isRSS
                                                }

                                                ColumnLayout {
                                                    Layout.fillWidth: true
                                                    spacing: 2

                                                    Text {
                                                        text: modelData.display || ""
                                                        font.pixelSize: tileDelegate.isExpanded
                                                            ? Math.round(Kirigami.Theme.defaultFont.pixelSize * 1.25)
                                                            : Kirigami.Theme.defaultFont.pixelSize
                                                        font.bold: true
                                                        color: tileDelegate.contentColor
                                                        Layout.fillWidth: true
                                                        elide: tileDelegate.isExpanded ? Text.ElideNone : Text.ElideRight
                                                        wrapMode: tileDelegate.isExpanded ? Text.Wrap : Text.NoWrap
                                                    }

                                                    Text {
                                                        text: modelData.subtext || ""
                                                        font.family: Kirigami.Theme.smallFont.family
                                                        font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                                                        color: Qt.rgba(resultsTileRoot.textColor.r, resultsTileRoot.textColor.g, resultsTileRoot.textColor.b, 0.7)
                                                        Layout.fillWidth: true
                                                        elide: Text.ElideRight
                                                        visible: text.length > 0 && !tileDelegate.isExpanded
                                                    }

                                                }

                                                // Close/Shrink button for RSS
                                                Kirigami.Icon {
                                                    source: "window-restore"
                                                    Layout.preferredWidth: 16
                                                    Layout.preferredHeight: 16
                                                    color: tileDelegate.contentColor
                                                    opacity: 0.5
                                                    visible: tileDelegate.isExpanded && tileDelegate.isRSS
                                                }

                                            }

                                            // Expanded RSS Content
                                            ColumnLayout {
                                                Layout.fillWidth: true
                                                visible: tileDelegate.isExpanded && tileDelegate.isRSS
                                                spacing: Kirigami.Units.largeSpacing

                                                // Image
                                                Image {
                                                    id: expandedImage

                                                    source: (tileDelegate.isExpanded && resultsTileRoot.rssShowImages) ? (modelData.imageUrl || "") : ""
                                                    Layout.fillWidth: true
                                                    Layout.preferredHeight: source.length > 0 ? Math.min(250, implicitHeight) : 0
                                                    fillMode: Image.PreserveAspectFit
                                                    visible: source.length > 0
                                                    asynchronous: true
                                                    cache: true
                                                    sourceSize.width: Math.max(1, resultsTileRoot.width)
                                                    sourceSize.height: 250

                                                    Kirigami.Icon {
                                                        anchors.centerIn: parent
                                                        width: 48
                                                        height: 48
                                                        source: "image-missing"
                                                        visible: parent.status === Image.Error
                                                    }
                                                }

                                                // Full Text
                                                Text {
                                                    text: modelData.fullContent || modelData.description || ""
                                                    textFormat: Text.PlainText
                                                    Layout.fillWidth: true
                                                    wrapMode: Text.Wrap
                                                    font.family: Kirigami.Theme.defaultFont.family
                                                    font.pixelSize: Kirigami.Theme.defaultFont.pixelSize
                                                    color: tileDelegate.contentColor
                                                    opacity: 0.9
                                                    visible: text.length > 0
                                                }

                                                RowLayout {
                                                    Layout.fillWidth: true

                                                    PlasmaComponents.Button {
                                                        text: resultsTileRoot.locReadBrowser
                                                        icon.name: "internet-services"
                                                        onClicked: resultsTileRoot.activateCurrentItem()
                                                    }

                                                    PlasmaComponents.Button {
                                                        text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Read in Window")
                                                        icon.name: "window-new"
                                                        flat: true
                                                        onClicked: {
                                                            popupRoot.showArticleInWindow(modelData.display || modelData.title || "", modelData.fullContent || modelData.description || "", modelData.url || "");
                                                        }
                                                    }

                                                    PlasmaComponents.Label {
                                                        text: modelData.subtext || ""
                                                        font.family: Kirigami.Theme.smallFont.family
                                                        font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                                                        opacity: 0.6
                                                        Layout.fillWidth: true
                                                        horizontalAlignment: Text.AlignRight
                                                    }

                                                }

                                            }

                                            // Native Inline Preview Card for files
                                            ColumnLayout {
                                                id: inlinePreviewCard

                                                Layout.fillWidth: true
                                                visible: tileDelegate.showInlinePreview
                                                spacing: Kirigami.Units.smallSpacing * 2
                                                Layout.topMargin: Kirigami.Units.largeSpacing

                                                Rectangle {
                                                    Layout.fillWidth: true
                                                    Layout.preferredHeight: 1
                                                    color: Qt.rgba(resultsTileRoot.textColor.r, resultsTileRoot.textColor.g, resultsTileRoot.textColor.b, 0.15)
                                                }

                                                RowLayout {
                                                    Layout.fillWidth: true
                                                    spacing: Kirigami.Units.largeSpacing
                                                    Layout.leftMargin: Kirigami.Units.smallSpacing
                                                    Layout.rightMargin: Kirigami.Units.smallSpacing

                                                    // Left Column: Thumbnail or large icon
                                                    Item {
                                                        id: thumbContainer

                                                        Layout.preferredWidth: resultsTileRoot.previewSize === 0 ? 64 : (resultsTileRoot.previewSize === 1 ? 120 : 200)
                                                        Layout.preferredHeight: resultsTileRoot.previewSize === 0 ? 48 : (resultsTileRoot.previewSize === 1 ? 90 : 150)
                                                        visible: tileDelegate.previewSource.length > 0 || tileDelegate.previewFileType.length > 0

                                                        // Background fallback placeholder
                                                        Rectangle {
                                                            anchors.fill: parent
                                                            color: Qt.rgba(resultsTileRoot.textColor.r, resultsTileRoot.textColor.g, resultsTileRoot.textColor.b, 0.05)
                                                            radius: Kirigami.Units.cornerRadius
                                                        }

                                                        Kirigami.Icon {
                                                            anchors.centerIn: parent
                                                            implicitWidth: 32
                                                            implicitHeight: 32
                                                            source: modelData.decoration || "application-x-executable"
                                                            color: tileDelegate.contentColor
                                                            opacity: 0.3
                                                            visible: imgPreview.status !== Image.Ready
                                                        }

                                                        Image {
                                                            id: imgPreview

                                                            anchors.fill: parent
                                                            source: tileDelegate.previewSource
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
                                                        spacing: Kirigami.Units.smallSpacing

                                                        Text {
                                                            text: modelData.display || ""
                                                            color: tileDelegate.contentColor
                                                            font.bold: true
                                                            font.family: Kirigami.Theme.defaultFont.family
                                                            font.pixelSize: Kirigami.Theme.defaultFont.pixelSize
                                                            elide: Text.ElideRight
                                                            Layout.fillWidth: true
                                                        }

                                                        Text {
                                                            text: resultsTileRoot.locCategory + ": " + (modelData.category || "Other")
                                                            color: Qt.rgba(resultsTileRoot.textColor.r, resultsTileRoot.textColor.g, resultsTileRoot.textColor.b, 0.7)
                                                            font.family: Kirigami.Theme.smallFont.family
                                                            font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                                                            textFormat: Text.PlainText
                                                        }

                                                        Text {
                                                            text: resultsTileRoot.locFileType + ": " + tileDelegate.previewFileType
                                                            color: Qt.rgba(resultsTileRoot.textColor.r, resultsTileRoot.textColor.g, resultsTileRoot.textColor.b, 0.7)
                                                            font.family: Kirigami.Theme.smallFont.family
                                                            font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                                                            visible: tileDelegate.previewFileType.length > 0
                                                            textFormat: Text.PlainText
                                                        }

                                                        Text {
                                                            id: fileSizeText

                                                            text: ""
                                                            color: Qt.rgba(resultsTileRoot.textColor.r, resultsTileRoot.textColor.g, resultsTileRoot.textColor.b, 0.7)
                                                            font.family: Kirigami.Theme.smallFont.family
                                                            font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                                                            visible: text.length > 0
                                                            textFormat: Text.PlainText
                                                        }

                                                        Text {
                                                            text: resultsTileRoot.locPath + ": " + tileDelegate.previewPath
                                                            color: Qt.rgba(resultsTileRoot.textColor.r, resultsTileRoot.textColor.g, resultsTileRoot.textColor.b, 0.5)
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
                                                    border.color: Qt.rgba(resultsTileRoot.textColor.r, resultsTileRoot.textColor.g, resultsTileRoot.textColor.b, 0.1)
                                                    visible: tileDelegate.isTextFile && textSnippet.text.length > 0

                                                    Text {
                                                        id: textSnippet

                                                        anchors.fill: parent
                                                        anchors.margins: Kirigami.Units.smallSpacing
                                                        text: ""
                                                        color: tileDelegate.contentColor
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
                                                        onClicked: {
                                                            if (resultsTileRoot.logic) {
                                                                resultsTileRoot.logic.copyToClipboard(tileDelegate.previewPath);
                                                            }
                                                        }
                                                    }

                                                    PlasmaComponents.Button {
                                                        text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Open Folder")
                                                        icon.name: "folder-open"
                                                        flat: true
                                                        Layout.preferredHeight: 28
                                                        visible: tileDelegate.previewPath.length > 0 && tileDelegate.previewPath.includes("/")
                                                        onClicked: {
                                                            if (resultsTileRoot.logic && tileDelegate.previewPath)
                                                                resultsTileRoot.logic.openContainingFolder(tileDelegate.previewPath);

                                                        }
                                                    }

                                                }

                                            }

                                        }

                                    }

                                    MouseArea {
                                        id: tileMouseArea

                                        anchors.fill: parent
                                        // Drag payload
                                        drag.target: dragProxy
                                        drag.threshold: 10
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                                        onClicked: (mouse) => {
                                            var matchId = modelData.duplicateId || modelData.display || "";
                                            var filePath = tileDelegate.resolvedFilePath();
                                            if (mouse.button === Qt.RightButton) {
                                                var cat = modelData.category || "";
                                                var isApp = Utils.isAppCategory(cat, filePath, matchId, modelData.decoration || "");
                                                resultsTileRoot.itemRightClicked({
                                                    "display": modelData.display || "",
                                                    "decoration": modelData.decoration || "application-x-executable",
                                                    "category": cat,
                                                    "matchId": matchId,
                                                    "filePath": filePath,
                                                    "isApplication": isApp,
                                                    "uuid": ""
                                                }, tileMouseArea, mouse.x, mouse.y);
                                            } else
                                                tileDelegate.activateResult();
                                        }
                                    }

                                    PlasmaComponents.ToolTip {
                                        visible: tileMouseArea.containsMouse && tileDelegate.previewSource.length === 0
                                        text: (modelData.display || "") + (modelData.subtext ? "\n" + modelData.subtext : "")
                                    }

                                    Item {
                                        id: dragProxy
                                        width: 1
                                        height: 1
                                        Drag.active: tileMouseArea.drag.active
                                        Drag.dragType: Drag.Automatic
                                        Drag.mimeData: {
                                            var filePath = tileDelegate.resolvedFilePath();
                                            return {
                                                "text/uri-list": filePath,
                                                "text/plain": filePath || (modelData.display || "")
                                            };
                                        }
                                    }

                                    PlasmaComponents.ToolTip {
                                        id: previewTooltip

                                        visible: resultsTileRoot.previewInlineMode === 0 && tileDelegate.previewSource.length > 0 && (tileMouseArea.containsMouse || (tileDelegate.isSelected && resultsTileRoot.previewForceVisible))
                                        delay: tileDelegate.isSelected && resultsTileRoot.previewForceVisible ? 0 : 500
                                        timeout: 10000
                                        x: tileDelegate.width + 4
                                        y: 0

                                        contentItem: Column {
                                            spacing: Kirigami.Units.smallSpacing

                                            // Title
                                            Text {
                                                text: modelData.display || ""
                                                font.bold: true
                                                font.family: Kirigami.Theme.defaultFont.family
                                                font.pixelSize: Kirigami.Theme.defaultFont.pixelSize
                                                color: tileDelegate.contentColor
                                            }

                                            // Thumbnail for images
                                            Image {
                                                id: thumbnailImage

                                                source: tileDelegate.previewSource
                                                width: source.length > 0 ? Math.min(150, sourceSize.width) : 0
                                                height: source.length > 0 ? Math.min(100, sourceSize.height) : 0
                                                fillMode: Image.PreserveAspectFit
                                                visible: source.length > 0
                                                cache: true
                                                asynchronous: true
                                                sourceSize.width: 150
                                                sourceSize.height: 100
                                            }

                                            // Category
                                            Text {
                                                text: resultsTileRoot.locCategory + ": " + (modelData.category || "")
                                                font.family: Kirigami.Theme.smallFont.family
                                                font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                                                color: Qt.rgba(resultsTileRoot.textColor.r, resultsTileRoot.textColor.g, resultsTileRoot.textColor.b, 0.7)
                                                visible: (modelData.category || "").length > 0
                                            }

                                            // File Type (from extension)
                                            Text {
                                                property string fileExt: tileDelegate.previewFileType

                                                text: resultsTileRoot.locFileType + ": " + fileExt
                                                font.family: Kirigami.Theme.smallFont.family
                                                font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                                                color: Qt.rgba(resultsTileRoot.textColor.r, resultsTileRoot.textColor.g, resultsTileRoot.textColor.b, 0.7)
                                                visible: fileExt.length > 0
                                            }

                                            // Path
                                            Text {
                                                text: resultsTileRoot.locPath + ": " + tileDelegate.previewPath
                                                font.family: Kirigami.Theme.smallFont.family
                                                font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                                                color: Qt.rgba(resultsTileRoot.textColor.r, resultsTileRoot.textColor.g, resultsTileRoot.textColor.b, 0.7)
                                                wrapMode: Text.WrapAnywhere
                                                width: Math.min(300, implicitWidth)
                                                visible: tileDelegate.previewPath.length > 0
                                            }

                                            // Shortcut hint
                                            Text {
                                                text: "💡 " + resultsTileRoot.locSpacePreview
                                                font.family: Kirigami.Theme.smallFont.family
                                                font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                                                font.italic: true
                                                color: Qt.rgba(resultsTileRoot.textColor.r, resultsTileRoot.textColor.g, resultsTileRoot.textColor.b, 0.5)
                                                visible: !resultsTileRoot.previewForceVisible
                                            }

                                        }

                                        background: Rectangle {
                                            color: Kirigami.Theme.backgroundColor
                                            border.color: resultsTileRoot.accentColor
                                            border.width: 1
                                            radius: Kirigami.Units.cornerRadius
                                        }

                                    }

                                            }
                                        }
                                    }

                                    Behavior on width {
                                        enabled: resultsTileRoot.resultAnimationsEnabled
                                        NumberAnimation {
                                            duration: 250
                                            easing.type: Easing.OutCubic
                                        }
                                    }

                                    Behavior on height {
                                        enabled: resultsTileRoot.resultAnimationsEnabled
                                        NumberAnimation {
                                            duration: 250
                                            easing.type: Easing.OutCubic
                                        }
                                    }

                                }

                            }

                        }

                    }

                }

            }

    // Empty state
    Column {
        anchors.centerIn: parent
        spacing: Kirigami.Units.largeSpacing
        visible: resultsTileRoot.categorizedData.length === 0 && resultsTileRoot.searchText.length > 0

        PlasmaComponents.BusyIndicator {
            anchors.horizontalCenter: parent.horizontalCenter
            running: resultsTileRoot.isLoading && resultsTileRoot.searchText.length > 0
            visible: running
        }

        Text {
            text: resultsTileRoot.searchText.length > 0 ? (resultsTileRoot.isLoading ? resultsTileRoot.locSearching : resultsTileRoot.locNoResults) : resultsTileRoot.locTypeToSearch
            color: Qt.rgba(resultsTileRoot.textColor.r, resultsTileRoot.textColor.g, resultsTileRoot.textColor.b, 0.5)
            font.family: Kirigami.Theme.defaultFont.family
            font.pixelSize: Kirigami.Theme.defaultFont.pixelSize
        }

    }

}
