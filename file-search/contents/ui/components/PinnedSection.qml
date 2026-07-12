import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import "../js/utils.js" as Utils

// PinnedSection - Displays pinned items at the top of results
// Supports drag-and-drop reordering and context menu
Item {
    id: pinnedSectionRoot

    // Required properties
    required property var pinnedItems
    required property color textColor
    required property color accentColor
    required property int iconSize
    required property bool isTileView
    property var logic: null

    // Collapsed state
    property bool isExpanded: true
    property bool animateHeight: false

    // Localization function removed (using global i18n)

    // Signals
    signal itemClicked(var item)
    signal unpinClicked(string matchId)
    signal reorderRequested(string fromUuid, string toUuid)
    signal openRequested(var item)
    signal copyPathRequested(var item)
    signal openLocationRequested(var item)

    // Drag state
    property int draggedIndex: -1
    property int dropTargetIndex: -1

    // Search state
    property bool isSearching: false

    // Compact vs Normal tile view. Normal = same size as history tiles
    property bool compactPinnedView: false

    // Computed tile dimensions - match HistoryTileView when normal mode
    readonly property real tileWidth: compactPinnedView ? (iconSize + 16) : (iconSize + 40)
    readonly property real tileHeight: compactPinnedView ? (iconSize + 40) : (iconSize + 50)
    readonly property real gridSideInset: Math.max(0, Kirigami.Units.largeSpacing - Kirigami.Units.smallSpacing)
    readonly property int maxVisibleListRows: 8
    readonly property int maxVisibleTileRows: 3

    // Height calculation
    implicitHeight: contentColumn.implicitHeight
    visible: true

    // Calculate height of a single row (Item height + Top Margin + Bottom Padding)
    readonly property real singleRowHeight: (isTileView ? tileHeight : 40) + 12

    ColumnLayout {
        id: contentColumn
        anchors.fill: parent
        spacing: Kirigami.Units.smallSpacing

        CategoryHeader {
            Layout.fillWidth: true
            categoryName: i18nd("plasma_applet_com.mcc45tr.filesearch", "Pinned Items")
            itemCount: pinnedSectionRoot.pinnedItems.length
            collapsed: !pinnedSectionRoot.isExpanded
            textColor: pinnedSectionRoot.textColor
            accentColor: pinnedSectionRoot.accentColor
            onToggleRequested: {
                pinnedSectionRoot.animateHeight = true
                pinnedSectionRoot.isExpanded = !pinnedSectionRoot.isExpanded
            }
        }

        // Pinned Container
        Rectangle {
            Layout.fillWidth: true
            // If collapsed: 0
            // If searching: Single row height (but cap at full height if smaller)
            // Else: Full height
            Layout.preferredHeight: {
                if (!pinnedSectionRoot.isExpanded) return 0;
                var fullHeight = pinnedContent.implicitHeight + 4;
                if (pinnedSectionRoot.isSearching) {
                    return Math.min(fullHeight, pinnedSectionRoot.singleRowHeight);
                }
                return fullHeight;
            }
            radius: 0
            color: "transparent"
            border.width: 0
            clip: true

            Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: 2
                radius: 1
                color: pinnedSectionRoot.accentColor
                opacity: pinnedSectionRoot.pinnedItems.length > 0 ? 0.65 : 0
            }

            Behavior on Layout.preferredHeight {
                enabled: pinnedSectionRoot.animateHeight
                NumberAnimation {
                    duration: Kirigami.Units.shortDuration
                    easing.type: Easing.OutCubic
                    onFinished: pinnedSectionRoot.animateHeight = false
                }
            }

            ColumnLayout {
                id: pinnedContent
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: Kirigami.Units.smallSpacing
                anchors.rightMargin: Kirigami.Units.smallSpacing
                spacing: Kirigami.Units.smallSpacing

                // Pinned items - List view
                Loader {
                    Layout.fillWidth: true
                    Layout.preferredHeight: item ? item.implicitHeight : 0
                    active: pinnedSectionRoot.isExpanded && !pinnedSectionRoot.isTileView && pinnedSectionRoot.pinnedItems.length > 0

                    sourceComponent: ListView {
                        implicitHeight: pinnedSectionRoot.isSearching
                            ? Math.min(contentHeight, pinnedSectionRoot.singleRowHeight)
                            : Math.min(contentHeight, pinnedSectionRoot.maxVisibleListRows * 42)
                        height: implicitHeight
                        spacing: 2
                        clip: true
                        reuseItems: true
                        interactive: contentHeight > height
                        model: pinnedSectionRoot.pinnedItems

                        delegate: Rectangle {
                                width: parent.width
                                height: 40
                                color: itemMouse.containsMouse
                                    ? Qt.rgba(pinnedSectionRoot.accentColor.r, pinnedSectionRoot.accentColor.g, pinnedSectionRoot.accentColor.b, 0.15)
                                    : "transparent"
                                radius: Kirigami.Units.cornerRadius

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: Kirigami.Units.largeSpacing
                                    anchors.rightMargin: Kirigami.Units.largeSpacing
                                    spacing: Kirigami.Units.largeSpacing

                                    Kirigami.Icon {
                                        source: modelData.decoration || "application-x-executable"
                                        Layout.preferredWidth: 22
                                        Layout.preferredHeight: 22
                                        color: pinnedSectionRoot.textColor
                                    }

                                    Text {
                                        text: modelData.display || ""
                                        Layout.fillWidth: true
                                        color: pinnedSectionRoot.textColor
                                        font.family: Kirigami.Theme.defaultFont.family
                                        font.pixelSize: Kirigami.Theme.defaultFont.pixelSize
                                        elide: Text.ElideRight
                                    }

                                    // Unpin button
                                    PinButton {
                                        isPinned: true
                                        accentColor: pinnedSectionRoot.accentColor
                                        textColor: pinnedSectionRoot.textColor

                                        onToggled: {
                                            pinnedSectionRoot.unpinClicked(modelData.matchId)
                                        }
                                    }
                                }

                                MouseArea {
                                    id: itemMouse
                                    anchors.fill: parent
                                    anchors.rightMargin: 30
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    acceptedButtons: Qt.LeftButton | Qt.RightButton

                                    onClicked: (mouse) => {
                                        if (mouse.button === Qt.RightButton) {
                                            pinnedContextMenu.currentItem = modelData
                                            pinnedContextMenu.selectedIndex = index
                                            pinnedContextMenu.popup(itemMouse, mouse.x, mouse.y)
                                        } else {
                                            pinnedSectionRoot.itemClicked(modelData)
                                        }
                                    }
                                }
                        }
                    }
                }

                // Empty state placeholder
                Loader {
                    Layout.fillWidth: true
                    Layout.preferredHeight: active ? item.implicitHeight : 0
                    active: pinnedSectionRoot.pinnedItems.length === 0
                    visible: active

                    sourceComponent: Text {
                        text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Right-click items to pin them")
                        color: Qt.rgba(pinnedSectionRoot.textColor.r, pinnedSectionRoot.textColor.g, pinnedSectionRoot.textColor.b, 0.8)
                        font.family: Kirigami.Theme.defaultFont.family
                        font.pixelSize: Kirigami.Theme.defaultFont.pixelSize
                        wrapMode: Text.Wrap
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                        maximumLineCount: 1
                        padding: 2
                    }
                }

                // Pinned items - Tile view with drag-drop support
                Loader {
                    Layout.fillWidth: true
                    Layout.preferredHeight: item ? item.implicitHeight : 0
                    active: pinnedSectionRoot.isExpanded && pinnedSectionRoot.isTileView && pinnedSectionRoot.pinnedItems.length > 0

                    sourceComponent: GridView {
                        id: tileFlow
                        readonly property int columnCount: Math.max(1, Math.floor((width + 8) / cellWidth))
                        width: {
                            var baseWidth = parent.width > 0 ? parent.width : (pinnedSectionRoot.width - 24);
                            var avail = Math.max(1, baseWidth - (pinnedSectionRoot.gridSideInset * 2));
                            var colW = pinnedSectionRoot.tileWidth + 8;
                            var cols = Math.floor(avail / colW);
                            if (cols <= 0) return avail;
                            return cols * colW - 8;
                        }
                        x: {
                            var baseWidth = parent.width > 0 ? parent.width : (pinnedSectionRoot.width - 24);
                            var alignedWidth = Math.max(1, baseWidth - (pinnedSectionRoot.gridSideInset * 2));
                            return pinnedSectionRoot.gridSideInset + ((alignedWidth - width) / 2);
                        }
                        cellWidth: pinnedSectionRoot.tileWidth + 8
                        cellHeight: pinnedSectionRoot.tileHeight + 8
                        implicitHeight: pinnedSectionRoot.isSearching
                            ? pinnedSectionRoot.tileHeight
                            : Math.min(Math.max(0, Math.ceil(count / columnCount) * cellHeight - 8),
                                       pinnedSectionRoot.maxVisibleTileRows * cellHeight - 8)
                        height: implicitHeight
                        clip: true
                        reuseItems: true
                        interactive: contentHeight > height
                        model: pinnedSectionRoot.pinnedItems

                        delegate: Item {
                                id: tileDelegate
                                width: pinnedSectionRoot.tileWidth
                                height: pinnedSectionRoot.tileHeight

                                property int visualIndex: index
                                property bool isDragging: pinnedSectionRoot.draggedIndex === index

                                // Drop indicator
                                Rectangle {
                                    visible: pinnedSectionRoot.dropTargetIndex === index && pinnedSectionRoot.draggedIndex !== index
                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 3
                                    height: parent.height - 8
                                    radius: 1.5
                                    color: pinnedSectionRoot.accentColor
                                }

                                Rectangle {
                                    id: tileContent
                                    anchors.fill: parent
                                    Drag.active: tileMouse.drag.active
                                    Drag.dragType: Drag.Automatic
                                    Drag.mimeData: {
                                        var path = modelData.filePath || modelData.url || "";
                                        return {
                                            "text/uri-list": path,
                                            "text/plain": path || (modelData.display || "")
                                        };
                                    }
                                    color: tileMouse.containsMouse || isDragging
                                        ? Qt.rgba(pinnedSectionRoot.accentColor.r, pinnedSectionRoot.accentColor.g, pinnedSectionRoot.accentColor.b, 0.15)
                                        : "transparent"
                                    radius: Kirigami.Units.cornerRadius
                                    opacity: isDragging ? 0.6 : 1.0

                                    Behavior on opacity { NumberAnimation { duration: 100 } }

                                    Column {
                                        anchors.centerIn: parent
                                        spacing: Kirigami.Units.smallSpacing

                                        Item {
                                            width: pinnedSectionRoot.iconSize
                                            height: pinnedSectionRoot.iconSize
                                            anchors.horizontalCenter: parent.horizontalCenter

                                            Kirigami.Icon {
                                                anchors.fill: parent
                                                source: modelData.decoration || "application-x-executable"
                                                color: pinnedSectionRoot.textColor
                                            }

                                            // Pin indicator
                                            Kirigami.Icon {
                                                source: "pin"
                                                width: 12
                                                height: 12
                                                anchors.top: parent.top
                                                anchors.right: parent.right
                                                anchors.margins: -2
                                                color: pinnedSectionRoot.accentColor
                                                visible: true
                                            }
                                        }

                                        Text {
                                            text: modelData.display || ""
                                            width: pinnedSectionRoot.tileWidth - (Kirigami.Units.smallSpacing * 2)
                                            horizontalAlignment: Text.AlignHCenter
                                            color: pinnedSectionRoot.textColor
                                            font.family: Kirigami.Theme.defaultFont.family
                                            font.pixelSize: Kirigami.Theme.defaultFont.pixelSize
                                            wrapMode: Text.NoWrap
                                            maximumLineCount: 1
                                            elide: Text.ElideRight
                                        }
                                    }
                                }

                                MouseArea {
                                    id: tileMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: drag.active ? Qt.ClosedHandCursor : Qt.PointingHandCursor
                                    acceptedButtons: Qt.LeftButton | Qt.RightButton

                                    drag.target: tileContent
                                    drag.axis: Drag.XAxis

                                    onPressed: (mouse) => {
                                        if (mouse.button === Qt.LeftButton) {
                                            pinnedSectionRoot.draggedIndex = index
                                        }
                                    }

                                    onReleased: (mouse) => {
                                        if (pinnedSectionRoot.draggedIndex !== -1 && pinnedSectionRoot.dropTargetIndex !== -1) {
                                            if (pinnedSectionRoot.draggedIndex !== pinnedSectionRoot.dropTargetIndex) {
                                                var fromItem = pinnedSectionRoot.pinnedItems[pinnedSectionRoot.draggedIndex]
                                                var toItem = pinnedSectionRoot.pinnedItems[pinnedSectionRoot.dropTargetIndex]
                                                if (fromItem && toItem) pinnedSectionRoot.reorderRequested(fromItem.uuid, toItem.uuid)
                                            }
                                        }
                                        pinnedSectionRoot.draggedIndex = -1
                                        pinnedSectionRoot.dropTargetIndex = -1
                                        if (tileContent) {
                                            tileContent.x = 0
                                            tileContent.y = 0
                                        }
                                    }

                                    onPositionChanged: (mouse) => {
                                        if (drag.active) {
                                            // Calculate drop target based on mouse position
                                            var globalPos = mapToItem(tileFlow, mouse.x, mouse.y)
                                            var cellWidth = tileFlow.cellWidth
                                            var cellHeight = tileFlow.cellHeight
                                            var columns = tileFlow.columnCount
                                            var column = Math.max(0, Math.floor(globalPos.x / cellWidth))
                                            var row = Math.max(0, Math.floor(globalPos.y / cellHeight))
                                            var targetIndex = row * columns + column
                                            targetIndex = Math.max(0, Math.min(targetIndex, pinnedSectionRoot.pinnedItems.length - 1))
                                            pinnedSectionRoot.dropTargetIndex = targetIndex
                                        }
                                    }

                                    onClicked: (mouse) => {
                                        if (mouse.button === Qt.RightButton) {
                                            pinnedContextMenu.currentItem = modelData
                                            pinnedContextMenu.selectedIndex = index
                                            pinnedContextMenu.popup(tileMouse, mouse.x, mouse.y)
                                        } else if (!drag.active) {
                                            pinnedSectionRoot.itemClicked(modelData)
                                        }
                                    }
                                }

                                PlasmaComponents.ToolTip {
                                    visible: tileMouse.containsMouse && !tileMouse.drag.active
                                    text: modelData.display + "\n" + i18nd("plasma_applet_com.mcc45tr.filesearch", "Drag to reorder")
                                }
                        }
                    }
                }
            }
        }
    }

    // Context Menu for pinned items
    NativeContextMenu {
        id: pinnedContextMenu

        property var currentItem: null
        property int selectedIndex: -1

        readonly property string itemPath: currentItem && currentItem.filePath ? currentItem.filePath.toString() : ""
        readonly property bool isWebLink: Utils.isHttpUrl(itemPath)
        readonly property bool isLocalFile: Utils.decodeLocalPath(itemPath).indexOf("/") === 0
        readonly property bool isFolder: currentItem && Utils.isFolderCategory(currentItem.category || "", itemPath, currentItem.decoration || "")

        function moveCurrentTo(index) {
            var items = pinnedSectionRoot.pinnedItems || []
            if (!currentItem || index < 0 || index >= items.length || index === selectedIndex)
                return
            var target = items[index]
            if (target && target.uuid)
                pinnedSectionRoot.reorderRequested(currentItem.uuid, target.uuid)
        }

        NativeContextMenuItem {
            text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Open")
            icon: "document-open"
            onTriggered: {
                if (pinnedContextMenu.currentItem) {
                    pinnedSectionRoot.itemClicked(pinnedContextMenu.currentItem)
                }
            }
        }

        NativeContextMenuItem {
            text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Copy File Name")
            icon: "edit-copy"
            visible: pinnedContextMenu.isLocalFile
            onTriggered: {
                var path = Utils.decodeLocalPath(pinnedContextMenu.itemPath).replace(/\/+$/, "")
                pinnedSectionRoot.logic.copyToClipboard(path.substring(path.lastIndexOf("/") + 1))
            }
        }

        NativeContextMenuItem {
            text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Copy Link")
            icon: "edit-copy"
            visible: pinnedContextMenu.isWebLink
            onTriggered: pinnedSectionRoot.logic.copyToClipboard(pinnedContextMenu.itemPath)
        }

        NativeContextMenuItem {
            text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Copy Folder Path")
            icon: "edit-copy"
            visible: pinnedContextMenu.isLocalFile
            onTriggered: {
                var path = Utils.decodeLocalPath(pinnedContextMenu.itemPath).replace(/\/+$/, "")
                pinnedSectionRoot.logic.copyToClipboard(pinnedContextMenu.isFolder ? path : Utils.getParentFolder(path))
            }
        }

        NativeContextMenuItem {
            text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Copy Path")
            icon: "edit-copy"
            visible: pinnedContextMenu.currentItem && pinnedContextMenu.currentItem.filePath
            onTriggered: {
                if (pinnedContextMenu.currentItem) {
                    pinnedSectionRoot.copyPathRequested(pinnedContextMenu.currentItem)
                }
            }
        }

        NativeContextMenuItem {
            text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Open Containing Folder")
            icon: "folder-open"
            visible: pinnedContextMenu.currentItem && pinnedContextMenu.currentItem.filePath && !pinnedContextMenu.isFolder
            onTriggered: pinnedSectionRoot.logic.openFolder(pinnedContextMenu.itemPath)
        }

        NativeContextMenuItem {
            text: pinnedContextMenu.isFolder ? i18nd("plasma_applet_com.mcc45tr.filesearch", "Open Terminal Here") : i18nd("plasma_applet_com.mcc45tr.filesearch", "Open Terminal in Containing Folder")
            icon: "utilities-terminal"
            visible: pinnedContextMenu.isLocalFile
            onTriggered: pinnedSectionRoot.logic.openTerminal(pinnedContextMenu.itemPath)
        }

        NativeContextMenuItem {
            text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Rename")
            icon: "edit-rename"
            visible: pinnedContextMenu.isLocalFile
            onTriggered: pinnedSectionRoot.logic.renameLocalFile(pinnedContextMenu.itemPath)
        }

        NativeContextMenuItem {
            text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Create Copy")
            icon: "edit-copy"
            visible: pinnedContextMenu.isLocalFile
            onTriggered: pinnedSectionRoot.logic.duplicateLocalFile(pinnedContextMenu.itemPath)
        }

        NativeContextMenuItem {
            text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Share / Send via KDE Connect...")
            icon: "document-share"
            visible: pinnedContextMenu.isLocalFile || pinnedContextMenu.isWebLink
            onTriggered: pinnedSectionRoot.logic.shareItem(pinnedContextMenu.itemPath)
        }

        NativeContextMenuSeparator { visible: pinnedContextMenu.selectedIndex >= 0 }

        NativeContextMenuItem {
            text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Move to Top")
            icon: "go-top"
            visible: pinnedContextMenu.selectedIndex > 0
            onTriggered: pinnedContextMenu.moveCurrentTo(0)
        }

        NativeContextMenuItem {
            text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Move Left")
            icon: "go-previous"
            visible: pinnedContextMenu.selectedIndex > 0
            onTriggered: pinnedContextMenu.moveCurrentTo(pinnedContextMenu.selectedIndex - 1)
        }

        NativeContextMenuItem {
            text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Move Right")
            icon: "go-next"
            visible: pinnedContextMenu.selectedIndex >= 0 && pinnedContextMenu.selectedIndex < pinnedSectionRoot.pinnedItems.length - 1
            onTriggered: pinnedContextMenu.moveCurrentTo(pinnedContextMenu.selectedIndex + 1)
        }

        NativeContextMenuSeparator {}

        NativeContextMenuItem {
            text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Unpin")
            icon: "window-unpin"
            onTriggered: {
                if (pinnedContextMenu.currentItem) {
                    pinnedSectionRoot.unpinClicked(pinnedContextMenu.currentItem.matchId)
                }
            }
        }
    }
}
