import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import "../js/PreviewUtils.js" as PreviewUtils

// Results Tile View - Displays search results in tile/grid format
// Features: Keyboard navigation, Category collapse/expand, File preview tooltip
FocusScope {
    id: resultsTileRoot
    
    // Required properties
    required property var categorizedData
    required property int iconSize
    required property color textColor
    required property color accentColor
    
    // Signals
    signal itemClicked(int index, string display, string decoration, string category, string matchId, string filePath)
    signal itemRightClicked(var item, real x, real y)
    
    // Localization
    property string searchText: ""
    property bool isLoading: false
    
    // Preview settings from config
    property bool previewEnabled: true
    property var previewSettings: ({"images": true, "videos": false, "text": false, "documents": false})
    property bool previewShowResults: true
    property int previewInlineMode: 1
    property int previewSize: 1
    
    // RSS settings from config
    property bool rssShowImages: true
    property bool rssExpandableCards: true
    property var expandedItems: ({})
    
    // Navigation state
    property int currentCategoryIndex: 0
    property int currentItemIndex: 0
    property var collapsedCategories: ({})
    property var logic: null
    
    // Computed flat list for keyboard navigation
    property var flatItemList: {
        var list = []
        for (var i = 0; i < categorizedData.length; i++) {
            var cat = categorizedData[i]
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
    property int selectedFlatIndex: 0
    
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
            } else if (event.key === Qt.Key_Space) {
                // Toggle preview for selected item
                previewForceVisible = !previewForceVisible
                event.accepted = true
            }
        }
    }
    
    // Preview visibility state
    property bool previewForceVisible: false
    
    function columnsInRow() {
        var itemWidth = tileWidth + 8 // tile width + spacing
        return Math.max(1, Math.floor(resultsTileRoot.width / itemWidth))
    }
    
    // Calculate current column position
    function getCurrentColumn() {
        if (totalItems === 0) return 0
        var cols = columnsInRow()
        // Find position within current category row
        var item = flatItemList[selectedFlatIndex]
        if (!item) return 0
        return item.itemIndex % cols
    }
    
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
             
             // Scan for target
             for (var i = selectedFlatIndex + 1; i < totalItems; i++) {
                 var nextItem = flatItemList[i]
                 
                 // Case 1: Same category
                 if (nextItem.catIndex === currentCatIdx) {
                    if (nextItem.itemIndex === nextRowIndex) {
                        targetGlobalIndex = i
                        break
                    }
                 } 
                 // Case 2: Changed category (Found start of next category)
                 else {
                     // We hit the next category. Find item in row 0 matching currentCol.
                     var newCatIdx = nextItem.catIndex
                     var bestMatch = i // default to first item
                     
                     for (var j = i; j < totalItems; j++) {
                         var cand = flatItemList[j]
                         if (cand.catIndex !== newCatIdx) break; 
                         if (cand.itemIndex >= cols) break; // Went past first row
                         
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
                 // Scan backwards for same cat
                 for (var i = selectedFlatIndex - 1; i >= 0; i--) {
                     var prevItem = flatItemList[i]
                     if (prevItem.catIndex === currentCatIdx && prevItem.itemIndex === prevRowIndex) {
                         targetGlobalIndex = i
                         break
                     }
                     if (prevItem.catIndex !== currentCatIdx) break; 
                 }
             } else {
                 // Fell off top of category. Find last row of previous category.
                 for (var i = selectedFlatIndex - 1; i >= 0; i--) {
                     var prevItem = flatItemList[i]
                     if (prevItem.catIndex !== currentCatIdx) {
                         var prevCatIdx = prevItem.catIndex
                         // prevItem is the last item of prev category. 
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
            ensureItemVisible()
        }
    }
    
    function moveSelection(delta) {
        if (totalItems === 0) return
        var newIndex = Math.max(0, Math.min(totalItems - 1, selectedFlatIndex + delta))
        selectedFlatIndex = newIndex
        ensureItemVisible()
    }
    
    // Scroll to make selected item visible
    function ensureItemVisible() {
        // Will be handled by ListView's positionViewAtIndex if we refactor
        // For now, the ScrollView should follow focus naturally
    }
    
    function activateCurrentItem() {
        if (totalItems === 0) return
        var item = flatItemList[selectedFlatIndex]
        if (item) {
            var data = item.data
            var matchId = data.duplicateId || data.display || ""
            var filePath = (data.url && data.url.toString) ? data.url.toString() : (data.url || "")
            var subtext = data.subtext || ""
            var urls = data.urls || []
            
            if (filePath === "" && urls.length > 0) {
                filePath = urls[0].toString()
            }
            
            if (filePath === "") {
                if (subtext.indexOf("/") === 0) filePath = "file://" + subtext
                else if (subtext.indexOf("file://") === 0) filePath = subtext
            }
            
            itemClicked(data.index, data.display || "", data.decoration || "application-x-executable", data.category || "Other", matchId, filePath)
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
    
    function isWideCategory(cat) {
        if (!cat) return false;
        var c = cat.toLowerCase();
        return c.includes("date") || c.includes("tarih") ||
               c.includes("calculator") || c.includes("hesap") ||
               c.includes("dictionary") || c.includes("sözlük") ||
               c.includes("shell") || c.includes("komut") ||
               c.includes("man page") || c.includes("kılavuz") ||
               c.includes("unit") || c.includes("birim") ||
               c.includes("power") || c.includes("güç");
    }

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
    
    // Computed tile dimensions for grid items
    readonly property real tileWidth: compactTileView ? (iconSize + 16) : (iconSize + 40)
    readonly property real tileHeight: compactTileView ? (iconSize + 40) : (iconSize + 50)
    readonly property real textWidth: compactTileView ? (iconSize + 8) : (iconSize + 32)
    readonly property int textFontSize: compactTileView ? 9 : (iconSize > 32 ? 11 : 9)

    Component {
        id: systemScrollBarComp
        ScrollBar {
            policy: resultsTileRoot.scrollBarStyle === 2 ? ScrollBar.AlwaysOff : ScrollBar.AsNeeded
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
        }
    }

    Component {
        id: minimalScrollBarComp
        ScrollBar {
            policy: resultsTileRoot.scrollBarStyle === 2 ? ScrollBar.AlwaysOff : ScrollBar.AsNeeded
            width: 4
            active: hovered || pressed
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            
            contentItem: Rectangle {
                implicitWidth: 2
                radius: 1
                color: parent.pressed ? resultsTileRoot.accentColor : Qt.rgba(resultsTileRoot.textColor.r, resultsTileRoot.textColor.g, resultsTileRoot.textColor.b, 0.3)
            }
            background: Item {
                implicitWidth: 4
            }
        }
    }

    Loader {
        id: scrollBarLoader
        active: true
        sourceComponent: resultsTileRoot.scrollBarStyle === 1 ? minimalScrollBarComp : systemScrollBarComp
    }

    ScrollView {
        anchors.fill: parent
        clip: true
        ScrollBar.vertical: scrollBarLoader.item
        
        Column {
            id: tileCategoryList
            width: resultsTileRoot.width - 24
            spacing: 16
            
            Repeater {
                model: resultsTileRoot.categorizedData
            
            delegate: Column {
                id: categoryDelegate
                width: tileCategoryList.width
                spacing: 8
                
                property int catIdx: index
                property bool isCollapsed: resultsTileRoot.collapsedCategories[modelData.categoryName] || false
                property bool isWide: resultsTileRoot.isWideCategory(modelData.categoryName)
                property bool animateHeight: false
                
                // Category Header (Clickable to collapse/expand)
                Rectangle {
                    width: parent.width
                    height: 28
                    color: categoryHeaderMouse.containsMouse ? Qt.rgba(resultsTileRoot.accentColor.r, resultsTileRoot.accentColor.g, resultsTileRoot.accentColor.b, 0.1) : "transparent"
                    radius: 4
                    
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 4
                        anchors.rightMargin: 4
                        spacing: 8
                        
                        // Collapse indicator
                        Kirigami.Icon {
                            source: categoryDelegate.isCollapsed ? "arrow-right" : "arrow-down"
                            Layout.preferredWidth: 16
                            Layout.preferredHeight: 16
                            color: resultsTileRoot.textColor
                            opacity: 0.6
                        }
                        
                        Text {
                            text: modelData.categoryName + " (" + modelData.items.length + ")"
                            font.pixelSize: 13
                            font.bold: true
                            color: Qt.rgba(resultsTileRoot.textColor.r, resultsTileRoot.textColor.g, resultsTileRoot.textColor.b, 0.7)
                        }
                        
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 1
                            color: Qt.rgba(resultsTileRoot.textColor.r, resultsTileRoot.textColor.g, resultsTileRoot.textColor.b, 0.2)
                        }
                    }
                    
                    MouseArea {
                        id: categoryHeaderMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            categoryDelegate.animateHeight = true
                            resultsTileRoot.toggleCategory(modelData.categoryName)
                        }
                    }
                }
                
                // Grid Flow (Animated collapse/expand - matches PinnedSection style)
                Item {
                    width: parent.width
                    height: categoryDelegate.isCollapsed ? 0 : categoryFlow.implicitHeight
                    clip: true
                    
                    Behavior on height {
                        enabled: categoryDelegate.animateHeight
                        NumberAnimation { 
                            duration: 200; 
                            easing.type: Easing.InOutQuad
                            onFinished: categoryDelegate.animateHeight = false
                        }
                    }
                    
                    Flow {
                        id: categoryFlow
                        // Calculate exact width to enable horizontal centering
                        width: {
                            var avail = parent.width > 0 ? parent.width : (resultsTileRoot.width - 24);
                            var colW = resultsTileRoot.tileWidth + 8;
                            var cols = Math.floor(avail / colW);
                            if (cols <= 0) return avail;
                            return categoryDelegate.isWide ? avail : (cols * colW - 8);
                        }
                        x: (parent.width - width) / 2
                        anchors.top: parent.top
                        spacing: 8
                    
                    Repeater {
                        model: modelData.items
                        
                        delegate: Item {
                            id: tileDelegate
                            property bool isRSS: modelData.category === "RSS"
                            property bool isPreviewAvailable: PreviewUtils.isPreviewAvailable(modelData.url || "", modelData.category || "", resultsTileRoot.previewSettings)
                            property bool showInlinePreview: resultsTileRoot.previewEnabled && resultsTileRoot.previewShowResults && resultsTileRoot.previewInlineMode === 1 && !isRSS && isPreviewAvailable && tileDelegate.isSelected
                            property bool isExpanded: (isRSS && resultsTileRoot.rssExpandableCards && !!resultsTileRoot.expandedItems[modelData.duplicateId]) || showInlinePreview
                             
                            // Wide vs Grid sizing
                            width: (categoryDelegate.isWide || tileDelegate.isExpanded) ? parent.width : resultsTileRoot.tileWidth
                            height: (categoryDelegate.isWide || tileDelegate.isExpanded) ? (tileContent.implicitHeight + 16) : resultsTileRoot.tileHeight
                             
                            Layout.fillWidth: categoryDelegate.isWide || tileDelegate.isExpanded
                             
                            Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                            Behavior on height { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                             
                            property int itemIdx: index
                            property bool isSelected: resultsTileRoot.isItemSelected(categoryDelegate.catIdx, itemIdx)
                             
                            property bool previewActive: resultsTileRoot.previewEnabled && isPreviewAvailable && (resultsTileRoot.previewInlineMode === 0 ? tileMouseArea.containsMouse : tileDelegate.isSelected)
                            property string previewPath: previewActive ? PreviewUtils.getLocalPreviewPath(modelData.url || "") : ""
                            property string previewFileType: previewActive ? PreviewUtils.getFileTypeLabel(modelData.url || "") : ""
                            property string previewSource: previewActive ? PreviewUtils.getPreviewSource(modelData.url || "", resultsTileRoot.previewEnabled, resultsTileRoot.previewSettings) : ""

                            onShowInlinePreviewChanged: {
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
                                if (!previewPath || !resultsTileRoot.logic) return;
                                resultsTileRoot.logic.readLocalTextSnippet(previewPath, function(content, bytes) {
                                    var lines = content.split('\n').slice(0, 5).join('\n');
                                    textSnippet.text = lines;
                                    
                                    var sizeStr = "";
                                    if (bytes < 1024) sizeStr = bytes + " B";
                                    else if (bytes < 1048576) sizeStr = (bytes / 1024).toFixed(1) + " KB";
                                    else sizeStr = (bytes / 1048576).toFixed(1) + " MB";
                                    fileSizeText.text = "<b>" + i18nd("plasma_applet_com.mcc45tr.filesearch", "Size") + ":</b> " + sizeStr;
                                });
                            }
                            
                            Rectangle {
                                id: tileBg
                                anchors.fill: parent
                                anchors.bottomMargin: (categoryDelegate.isWide || tileDelegate.isExpanded) ? 8 : 0
                                radius: 8
                                color: {
                                    if (tileDelegate.isSelected) 
                                        return Qt.rgba(resultsTileRoot.accentColor.r, resultsTileRoot.accentColor.g, resultsTileRoot.accentColor.b, 0.3)
                                    if (tileMouseArea.containsMouse) 
                                        return Qt.rgba(resultsTileRoot.accentColor.r, resultsTileRoot.accentColor.g, resultsTileRoot.accentColor.b, 0.15)
                                    return "transparent"
                                }
                                border.width: tileDelegate.isSelected ? 2 : 0
                                border.color: resultsTileRoot.accentColor
                                
                                // Sürükle ve Bırak Desteği
                                Drag.active: tileMouseArea.drag.active
                                Drag.dragType: Drag.Automatic
                                Drag.mimeData: {
                                    "text/uri-list": modelData.url || "",
                                    "text/plain": modelData.url || ""
                                }
                                
                                Behavior on border.width { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
                                Behavior on color { ColorAnimation { duration: 150 } }
                                
                                // Focus glow effect for accessibility
                                Rectangle {
                                    id: focusGlow
                                    anchors.fill: parent
                                    anchors.margins: -3
                                    radius: parent.radius + 3
                                    color: "transparent"
                                    border.width: tileDelegate.isSelected ? 2 : 0
                                    border.color: Qt.rgba(resultsTileRoot.accentColor.r, resultsTileRoot.accentColor.g, resultsTileRoot.accentColor.b, 0.4)
                                    visible: tileDelegate.isSelected
                                    opacity: visible ? 1 : 0
                                    
                                    Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutQuad } }
                                }
                                
                                // Content Loader (Grid vs Horizontal Layout)
                                Item {
                                    id: tileContent
                                    anchors.fill: parent
                                    anchors.margins: 8
                                    implicitHeight: loader.item ? loader.item.implicitHeight : 50
                                    
                                    Loader {
                                        id: loader
                                        anchors.fill: parent
                                        sourceComponent: (categoryDelegate.isWide || tileDelegate.isExpanded) ? wideLayoutComp : gridLayoutComp
                                    }
                                }
                            }    
                                Component {
                                    id: gridLayoutComp
                                    Column {
                                        spacing: 6
                                        anchors.centerIn: parent
                                        
                                        Item {
                                            width: resultsTileRoot.iconSize
                                            height: resultsTileRoot.iconSize
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            
                                            Kirigami.Icon {
                                                anchors.fill: parent
                                                source: (tileDelegate.isRSS && modelData.sourceIcon) ? modelData.sourceIcon : (modelData.decoration || "application-x-executable")
                                                color: resultsTileRoot.textColor
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
                                            width: tileDelegate.width - 16
                                            text: modelData.display || ""
                                            color: resultsTileRoot.textColor
                                            font.pixelSize: resultsTileRoot.textFontSize
                                            horizontalAlignment: Text.AlignHCenter
                                            elide: Text.ElideMiddle
                                            maximumLineCount: 2
                                            wrapMode: Text.Wrap
                                        }
                                        
                                        Text {
                                            width: tileDelegate.width - 16
                                            text: {
                                                var cat = modelData.category || ""
                                                var isApp = (cat.toLowerCase().indexOf("app") !== -1 || cat.toLowerCase().indexOf("uygulama") !== -1 || cat === "System Settings");
                                                if (isApp) return modelData.subtext || "";
                                                
                                                var path = (modelData.url && modelData.url.toString) ? modelData.url.toString() : "";
                                                if (!path && modelData.subtext && modelData.subtext.toString().indexOf("/") === 0) {
                                                     path = "file://" + modelData.subtext;
                                                }
                                                 
                                                if (path && path.length > 0) {
                                                    path = path.replace("file://", "");
                                                    if (path.slice(-1) === "/") path = path.slice(0, -1);
                                                    var parts = path.split("/");
                                                    if (parts.length > 1) {
                                                        return parts[parts.length - 2];
                                                    }
                                                }
                                                return modelData.subtext || "";
                                            }
                                            color: Qt.rgba(resultsTileRoot.textColor.r, resultsTileRoot.textColor.g, resultsTileRoot.textColor.b, 0.6)
                                            font.pixelSize: 9
                                            horizontalAlignment: Text.AlignHCenter
                                            elide: Text.ElideMiddle
                                            visible: text.length > 0
                                        }
                                    }
                                }
                                
                                Component {
                                    id: wideLayoutComp
                                    ColumnLayout {
                                        id: wideLayout
                                        spacing: 12
                                        
                                        RowLayout {
                                            spacing: 12
                                            Layout.fillWidth: true
                                            
                                            Kirigami.Icon {
                                                source: (tileDelegate.isRSS && modelData.sourceIcon) ? modelData.sourceIcon : (modelData.decoration || "application-x-executable")
                                                Layout.preferredWidth: resultsTileRoot.iconSize
                                                Layout.preferredHeight: resultsTileRoot.iconSize
                                                color: resultsTileRoot.textColor
                                                visible: !tileDelegate.isExpanded || !tileDelegate.isRSS
                                            }
                                            
                                            ColumnLayout {
                                                Layout.fillWidth: true
                                                spacing: 2
                                                
                                                Text {
                                                    text: modelData.display || ""
                                                    font.pixelSize: tileDelegate.isExpanded ? 16 : 14
                                                    font.bold: true
                                                    color: resultsTileRoot.textColor
                                                    Layout.fillWidth: true
                                                    elide: tileDelegate.isExpanded ? Text.ElideNone : Text.ElideRight
                                                    wrapMode: tileDelegate.isExpanded ? Text.Wrap : Text.NoWrap
                                                }
                                                
                                                Text {
                                                    text: modelData.subtext || ""
                                                    font.pixelSize: 11
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
                                                color: resultsTileRoot.textColor
                                                opacity: 0.5
                                                visible: tileDelegate.isExpanded && tileDelegate.isRSS
                                            }
                                        }

                                        // Expanded RSS Content
                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            visible: tileDelegate.isExpanded && tileDelegate.isRSS
                                            spacing: 12
                                            
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
                                            }
                                            
                                            // Full Text
                                            Text {
                                                text: modelData.fullContent || modelData.description || ""
                                                Layout.fillWidth: true
                                                wrapMode: Text.Wrap
                                                font.pixelSize: 13
                                                color: resultsTileRoot.textColor
                                                opacity: 0.9
                                                visible: text.length > 0
                                            }

                                            RowLayout {
                                                Layout.fillWidth: true
                                                Button {
                                                    text: resultsTileRoot.locReadBrowser
                                                    icon.name: "internet-services"
                                                    onClicked: resultsTileRoot.activateCurrentItem()
                                                }
                                                Label {
                                                    text: modelData.subtext || ""
                                                    font.pixelSize: 10
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
                                            spacing: 8
                                            Layout.topMargin: 8

                                            Rectangle {
                                                Layout.fillWidth: true
                                                Layout.preferredHeight: 1
                                                color: Qt.rgba(resultsTileRoot.textColor.r, resultsTileRoot.textColor.g, resultsTileRoot.textColor.b, 0.15)
                                            }

                                            RowLayout {
                                                Layout.fillWidth: true
                                                spacing: 12
                                                Layout.leftMargin: 4
                                                Layout.rightMargin: 4

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
                                                        radius: 4
                                                    }

                                                    Kirigami.Icon {
                                                        anchors.centerIn: parent
                                                        implicitWidth: 32
                                                        implicitHeight: 32
                                                        source: modelData.decoration || "application-x-executable"
                                                        color: resultsTileRoot.textColor
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
                                                    }
                                                }

                                                // Right Column: Metadata
                                                ColumnLayout {
                                                    Layout.fillWidth: true
                                                    spacing: 4

                                                    Text {
                                                        text: modelData.display || ""
                                                        color: resultsTileRoot.textColor
                                                        font.bold: true
                                                        font.pixelSize: 12
                                                        elide: Text.ElideRight
                                                        Layout.fillWidth: true
                                                    }

                                                    Text {
                                                        text: "<b>" + resultsTileRoot.locCategory + ":</b> " + (modelData.category || "Other")
                                                        color: Qt.rgba(resultsTileRoot.textColor.r, resultsTileRoot.textColor.g, resultsTileRoot.textColor.b, 0.7)
                                                        font.pixelSize: 10
                                                        textFormat: Text.StyledText
                                                    }

                                                    Text {
                                                        text: "<b>" + resultsTileRoot.locFileType + ":</b> " + tileDelegate.previewFileType
                                                        color: Qt.rgba(resultsTileRoot.textColor.r, resultsTileRoot.textColor.g, resultsTileRoot.textColor.b, 0.7)
                                                        font.pixelSize: 10
                                                        visible: tileDelegate.previewFileType.length > 0
                                                        textFormat: Text.StyledText
                                                    }

                                                    Text {
                                                        id: fileSizeText
                                                        text: ""
                                                        color: Qt.rgba(resultsTileRoot.textColor.r, resultsTileRoot.textColor.g, resultsTileRoot.textColor.b, 0.7)
                                                        font.pixelSize: 10
                                                        visible: text.length > 0
                                                        textFormat: Text.StyledText
                                                    }

                                                    Text {
                                                        text: "<b>" + resultsTileRoot.locPath + ":</b> " + tileDelegate.previewPath
                                                        color: Qt.rgba(resultsTileRoot.textColor.r, resultsTileRoot.textColor.g, resultsTileRoot.textColor.b, 0.5)
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
                                                border.color: Qt.rgba(resultsTileRoot.textColor.r, resultsTileRoot.textColor.g, resultsTileRoot.textColor.b, 0.1)
                                                visible: tileDelegate.isTextFile && textSnippet.text.length > 0

                                                Text {
                                                    id: textSnippet
                                                    anchors.fill: parent
                                                    anchors.margins: 6
                                                    text: ""
                                                    color: resultsTileRoot.textColor
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
                                                    onClicked: if (resultsTileRoot.logic) resultsTileRoot.logic.copyToClipboard(tileDelegate.previewPath)
                                                }

                                                Button {
                                                    text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Open Folder")
                                                    icon.name: "folder-open"
                                                    flat: true
                                                    Layout.preferredHeight: 28
                                                    visible: tileDelegate.previewPath.length > 0 && tileDelegate.previewPath.includes("/")
                                                    onClicked: {
                                                        if (resultsTileRoot.logic && tileDelegate.previewPath) {
                                                            resultsTileRoot.logic.openContainingFolder(tileDelegate.previewPath)
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                
                                MouseArea {
                                    id: tileMouseArea
                                    anchors.fill: parent
                                    // DRAG
                                    drag.target: tileBg
                                    drag.threshold: 10

                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                                    
                                    onClicked: (mouse) => {
                                        var matchId = modelData.duplicateId || modelData.display || ""
                                        
                                        // Expansion logic for RSS
                                        if (tileDelegate.isRSS && resultsTileRoot.rssExpandableCards) {
                                            if (mouse.button === Qt.LeftButton) {
                                                var newExpanded = {}
                                                // Option 1: Only one expanded at a time
                                                // var currentVal = resultsTileRoot.expandedItems[matchId]
                                                // newExpanded[matchId] = !currentVal
                                                
                                                // Option 2: Allow multiple (but keep local state simple)
                                                Object.assign(newExpanded, resultsTileRoot.expandedItems)
                                                newExpanded[matchId] = !newExpanded[matchId]
                                                
                                                resultsTileRoot.expandedItems = newExpanded
                                                return;
                                            }
                                        }

                                        var filePath = (modelData.url && modelData.url.toString) ? modelData.url.toString() : (modelData.url || "")
                                        var subtext = modelData.subtext || ""
                                        var urls = modelData.urls || []
                                        
                                        if (filePath === "" && urls.length > 0) {
                                            filePath = urls[0].toString()
                                        }
                                        
                                        if (filePath === "") {
                                            if (subtext.indexOf("/") === 0) filePath = "file://" + subtext
                                            else if (subtext.indexOf("file://") === 0) filePath = subtext
                                        }
                                        
                                        if (mouse.button === Qt.RightButton) {
                                            var cat = modelData.category || ""
                                            var isApp = (cat.toLowerCase().indexOf("app") !== -1 || cat.toLowerCase().indexOf("uygulama") !== -1 || cat === "System Settings")
                                            
                                            resultsTileRoot.itemRightClicked({
                                                display: modelData.display || "",
                                                decoration: modelData.decoration || "application-x-executable",
                                                category: cat,
                                                matchId: matchId,
                                                filePath: filePath,
                                                isApplication: isApp,
                                                uuid: ""
                                            }, mouse.x + tileDelegate.x, mouse.y + tileDelegate.y)
                                        } else {
                                            resultsTileRoot.itemClicked(modelData.index, modelData.display || "", modelData.decoration || "application-x-executable", modelData.category || "Other", matchId, filePath)
                                        }
                                    }
                                }
                                
                                ToolTip {
                                    id: previewTooltip
                                    visible: resultsTileRoot.previewInlineMode === 0 && tileDelegate.previewSource.length > 0 && (tileMouseArea.containsMouse || (tileDelegate.isSelected && resultsTileRoot.previewForceVisible))
                                    delay: tileDelegate.isSelected && resultsTileRoot.previewForceVisible ? 0 : 500
                                    timeout: 10000
                                    x: tileDelegate.width + 4
                                    y: 0
                                    
                                    contentItem: Column {
                                        spacing: 6
                                        
                                        // Title
                                        Text {
                                            text: modelData.display || ""
                                            font.bold: true
                                            font.pixelSize: 12
                                            color: resultsTileRoot.textColor
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
                                        }
                                        
                                        // Category
                                        Text {
                                            text: resultsTileRoot.locCategory + ": " + (modelData.category || "")
                                            font.pixelSize: 10
                                            color: Qt.rgba(resultsTileRoot.textColor.r, resultsTileRoot.textColor.g, resultsTileRoot.textColor.b, 0.7)
                                            visible: (modelData.category || "").length > 0
                                        }
                                        
                                        // File Type (from extension)
                                        Text {
                                            property string fileExt: tileDelegate.previewFileType
                                            text: resultsTileRoot.locFileType + ": " + fileExt
                                            font.pixelSize: 10
                                            color: Qt.rgba(resultsTileRoot.textColor.r, resultsTileRoot.textColor.g, resultsTileRoot.textColor.b, 0.7)
                                            visible: fileExt.length > 0
                                        }
                                        
                                        // Path
                                        Text {
                                            text: resultsTileRoot.locPath + ": " + tileDelegate.previewPath
                                            font.pixelSize: 10
                                            color: Qt.rgba(resultsTileRoot.textColor.r, resultsTileRoot.textColor.g, resultsTileRoot.textColor.b, 0.7)
                                            wrapMode: Text.WrapAnywhere
                                            width: Math.min(300, implicitWidth)
                                            visible: tileDelegate.previewPath.length > 0
                                        }
                                        
                                        // Shortcut hint
                                        Text {
                                            text: "💡 " + resultsTileRoot.locSpacePreview
                                            font.pixelSize: 9
                                            font.italic: true
                                            color: Qt.rgba(resultsTileRoot.textColor.r, resultsTileRoot.textColor.g, resultsTileRoot.textColor.b, 0.5)
                                            visible: !resultsTileRoot.previewForceVisible
                                        }
                                    }
                                    
                                    background: Rectangle {
                                        color: Kirigami.Theme.backgroundColor
                                        border.color: resultsTileRoot.accentColor
                                        border.width: 1
                                        radius: 6
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
    
    
    // Empty state
    Column {
        anchors.centerIn: parent
        spacing: 10
        visible: resultsTileRoot.categorizedData.length === 0 && resultsTileRoot.searchText.length > 0

        BusyIndicator {
            anchors.horizontalCenter: parent.horizontalCenter
            running: resultsTileRoot.isLoading && resultsTileRoot.searchText.length > 0
            visible: running
        }

        Text {
            text: resultsTileRoot.searchText.length > 0
                ? (resultsTileRoot.isLoading ? resultsTileRoot.locSearching : resultsTileRoot.locNoResults)
                : resultsTileRoot.locTypeToSearch
            color: Qt.rgba(resultsTileRoot.textColor.r, resultsTileRoot.textColor.g, resultsTileRoot.textColor.b, 0.5)
            font.pixelSize: 12
        }
    }
    
    // Reset selection when data changes
    onCategorizedDataChanged: {
        selectedFlatIndex = 0
    }
}
