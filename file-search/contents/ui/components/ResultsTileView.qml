import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

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
    
    // Preview settings from config
    property var previewSettings: ({"images": true, "videos": false, "text": false, "documents": false})
    
    // Navigation state
    property int currentCategoryIndex: 0
    property int currentItemIndex: 0
    property var collapsedCategories: ({})
    
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
        var itemWidth = iconSize + 48
        return Math.max(1, Math.floor(width / itemWidth))
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
            
            itemClicked(data.index, data.display || "", data.decoration || "application-x-executable", data.category || "Diğer", matchId, filePath)
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

    ScrollView {
        anchors.fill: parent
        clip: true
        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
            width: 8
            active: hovered || pressed
            anchors.right: parent.right
            anchors.rightMargin: 5
            
            contentItem: Rectangle {
                implicitWidth: 4
                radius: 2
                color: parent.pressed ? resultsTileRoot.accentColor : Qt.rgba(resultsTileRoot.textColor.r, resultsTileRoot.textColor.g, resultsTileRoot.textColor.b, 0.3)
            }
            background: Item {
                implicitWidth: 8
            }
        }
        
        ListView {
            id: tileCategoryList
            width: parent.width
            model: resultsTileRoot.categorizedData
            spacing: 16
            interactive: false
            
            delegate: Column {
                id: categoryDelegate
                width: tileCategoryList.width
                spacing: 8
                
                property int catIdx: index
                property bool isCollapsed: resultsTileRoot.collapsedCategories[modelData.categoryName] || false
                property bool isWide: resultsTileRoot.isWideCategory(modelData.categoryName)
                
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
                        onClicked: resultsTileRoot.toggleCategory(modelData.categoryName)
                    }
                }
                
                // Grid Flow (Hidden when collapsed)
                Flow {
                    width: parent.width
                    spacing: 8
                    visible: !categoryDelegate.isCollapsed
                    
                    Repeater {
                        model: modelData.items
                        
                        delegate: Item {
                            id: tileDelegate
                            // Wide vs Grid sizing
                            width: categoryDelegate.isWide ? parent.width : (resultsTileRoot.iconSize + 40)
                            height: categoryDelegate.isWide ? Math.max(50, resultsTileRoot.iconSize + 16) : (resultsTileRoot.iconSize + 50)
                            
                            property int itemIdx: index
                            property bool isSelected: resultsTileRoot.isItemSelected(categoryDelegate.catIdx, itemIdx)
                            
                            // Staggered fade-in animation
                            opacity: 0
                            
                            Timer {
                                id: tileFadeInTrigger
                                interval: (categoryDelegate.catIdx * 10 + itemIdx) * 10  // 10ms stagger
                                running: true
                                onTriggered: tileFadeInAnim.start()
                            }
                            
                            NumberAnimation {
                                id: tileFadeInAnim
                                target: tileDelegate
                                property: "opacity"
                                from: 0
                                to: 1
                                duration: 100
                                easing.type: Easing.OutQuad
                            }
                            
                            // Reset animation when data changes
                            Connections {
                                target: resultsTileRoot
                                function onSearchTextChanged() {
                                    tileDelegate.opacity = 0
                                    tileFadeInTrigger.restart()
                                }
                            }
                            
                            Rectangle {
                                id: tileBg
                                anchors.fill: parent
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
                                Loader {
                                    anchors.fill: parent
                                    anchors.margins: 6
                                    sourceComponent: categoryDelegate.isWide ? wideLayoutComp : gridLayoutComp
                                }
                                
                                Component {
                                    id: gridLayoutComp
                                    Column {
                                        spacing: 6
                                        anchors.centerIn: parent
                                        
                                        Kirigami.Icon {
                                            width: resultsTileRoot.iconSize
                                            height: resultsTileRoot.iconSize
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            source: {
                                                // standard icon if small
                                                if (resultsTileRoot.iconSize <= 22) return modelData.decoration || "application-x-executable";
                                                
                                                var url = (modelData.url || "").toString();
                                                if (!url) return modelData.decoration || "application-x-executable";
                                                
                                                var ext = url.split('.').pop().toLowerCase();
                                                
                                                if (resultsTileRoot.previewSettings.images) {
                                                    var imageExts = ["png", "jpg", "jpeg", "gif", "bmp", "webp", "svg", "ico", "tiff"]
                                                    if (imageExts.indexOf(ext) >= 0) return url
                                                }
                                                
                                                if (resultsTileRoot.previewSettings.videos) {
                                                    var videoExts = ["mp4", "mkv", "avi", "webm", "mov", "flv", "wmv", "mpg", "mpeg"]
                                                    if (videoExts.indexOf(ext) >= 0) return "image://preview/" + url
                                                }
                                                
                                                if (resultsTileRoot.previewSettings.documents) {
                                                    var docExts = ["pdf", "odt", "docx", "pptx", "xlsx"]
                                                    if (docExts.indexOf(ext) >= 0) return "image://preview/" + url
                                                }
                                                
                                                return modelData.decoration || "application-x-executable"
                                            }
                                            color: resultsTileRoot.textColor
                                        }
                                        
                                        Text {
                                            width: tileDelegate.width - 16
                                            text: modelData.display || ""
                                            color: resultsTileRoot.textColor
                                            font.pixelSize: resultsTileRoot.iconSize > 32 ? 11 : 9
                                            horizontalAlignment: Text.AlignHCenter
                                            elide: Text.ElideMiddle
                                            maximumLineCount: 2
                                            wrapMode: Text.Wrap
                                        }
                                        
                                        Text {
                                            width: tileDelegate.width - 16
                                            text: {
                                                var cat = modelData.category || ""
                                                var isApp = (cat === "Uygulamalar" || cat === "Applications" || cat === "System Settings");
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
                                    RowLayout {
                                        spacing: 12
                                        
                                        Kirigami.Icon {
                                            source: modelData.decoration || "application-x-executable"
                                            Layout.preferredWidth: resultsTileRoot.iconSize
                                            Layout.preferredHeight: resultsTileRoot.iconSize
                                            color: resultsTileRoot.textColor
                                        }
                                        
                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 2
                                            
                                            Text {
                                                text: modelData.display || ""
                                                font.pixelSize: 14 // Larger font for wide cards
                                                font.bold: true
                                                color: resultsTileRoot.textColor
                                                Layout.fillWidth: true
                                                elide: Text.ElideRight
                                            }
                                            
                                            Text {
                                                text: modelData.subtext || ""
                                                font.pixelSize: 11
                                                color: Qt.rgba(resultsTileRoot.textColor.r, resultsTileRoot.textColor.g, resultsTileRoot.textColor.b, 0.7)
                                                Layout.fillWidth: true
                                                elide: Text.ElideRight
                                                visible: text.length > 0
                                            }
                                        }
                                    }
                                }
                                
                                MouseArea {
                                    id: tileMouseArea
                                    anchors.fill: parent

                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                                    
                                    onClicked: (mouse) => {
                                        var matchId = modelData.duplicateId || modelData.display || ""
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
                                            var isApp = (cat === "Uygulamalar" || cat === "Applications" || cat === "System Settings")
                                            
                                            resultsTileRoot.itemRightClicked({
                                                display: modelData.display || "",
                                                decoration: modelData.decoration || "application-x-executable",
                                                category: cat,
                                                matchId: matchId,
                                                filePath: filePath,
                                                isApplication: isApp,
                                                uuid: matchId
                                            }, mouse.x + tileDelegate.x, mouse.y + tileDelegate.y)
                                        } else {
                                            resultsTileRoot.itemClicked(modelData.index, modelData.display || "", modelData.decoration || "application-x-executable", modelData.category || "Diğer", matchId, filePath)
                                        }
                                    }
                                }
                                
                                // File Preview Tooltip
                                ToolTip {
                                    id: previewTooltip
                                    visible: (tileMouseArea.containsMouse || (tileDelegate.isSelected && resultsTileRoot.previewForceVisible)) && (modelData.url || "").length > 0
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
                                            source: {
                                                var url = modelData.url || ""
                                                if (url.length === 0) return ""
                                                var ext = url.split('.').pop().toLowerCase()
                                                
                                                // 1. Images
                                                if (resultsTileRoot.previewSettings.images) {
                                                    var imageExts = ["png", "jpg", "jpeg", "gif", "bmp", "webp", "svg", "ico", "tiff"]
                                                    if (imageExts.indexOf(ext) >= 0) return url
                                                }
                                                
                                                // 2. Videos
                                                if (resultsTileRoot.previewSettings.videos) {
                                                    var videoExts = ["mp4", "mkv", "avi", "webm", "mov", "flv", "wmv", "mpg", "mpeg"]
                                                    if (videoExts.indexOf(ext) >= 0) return "image://preview/" + url
                                                }
                                                
                                                // 3. Documents
                                                if (resultsTileRoot.previewSettings.documents) {
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
                                        
                                        // Category
                                        Text {
                                            text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Category") + ": " + (modelData.category || "")
                                            font.pixelSize: 10
                                            color: Qt.rgba(resultsTileRoot.textColor.r, resultsTileRoot.textColor.g, resultsTileRoot.textColor.b, 0.7)
                                            visible: (modelData.category || "").length > 0
                                        }
                                        
                                        // File Type (from extension)
                                        Text {
                                            property string fileExt: {
                                                var url = modelData.url || ""
                                                if (url.length === 0) return ""
                                                var parts = url.split('.')
                                                return parts.length > 1 ? parts.pop().toUpperCase() : ""
                                            }
                                            text: i18nd("plasma_applet_com.mcc45tr.filesearch", "File Type") + ": " + fileExt
                                            font.pixelSize: 10
                                            color: Qt.rgba(resultsTileRoot.textColor.r, resultsTileRoot.textColor.g, resultsTileRoot.textColor.b, 0.7)
                                            visible: fileExt.length > 0
                                        }
                                        
                                        // Path
                                        Text {
                                            text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Path") + ": " + (modelData.url || "")
                                            font.pixelSize: 10
                                            color: Qt.rgba(resultsTileRoot.textColor.r, resultsTileRoot.textColor.g, resultsTileRoot.textColor.b, 0.7)
                                            wrapMode: Text.WrapAnywhere
                                            width: Math.min(300, implicitWidth)
                                            visible: (modelData.url || "").length > 0
                                        }
                                        
                                        // Shortcut hint
                                        Text {
                                            text: "💡 " + i18nd("plasma_applet_com.mcc45tr.filesearch", "Space to preview")
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
    
    // Empty state
    Text {
        anchors.centerIn: parent
        text: resultsTileRoot.searchText.length > 0 ? i18nd("plasma_applet_com.mcc45tr.filesearch", "No results found") : i18nd("plasma_applet_com.mcc45tr.filesearch", "Type to search")
        color: Qt.rgba(resultsTileRoot.textColor.r, resultsTileRoot.textColor.g, resultsTileRoot.textColor.b, 0.5)
        font.pixelSize: 12
        visible: resultsTileRoot.categorizedData.length === 0
    }
    
    // Reset selection when data changes
    onCategorizedDataChanged: {
        selectedFlatIndex = 0
    }
}
