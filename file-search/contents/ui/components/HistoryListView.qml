import QtQuick
import QtQuick.Layouts
import QtCore
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
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
    property bool previewShowHistory: true
    property int previewInlineMode: 1
    property int previewSize: 1
    // Logic controller for context menu actions
    required property var logic

    property int currentIndex: -1
    property var flatItems: []
    readonly property string thumbnailCacheBase: StandardPaths.writableLocation(StandardPaths.HomeLocation).toString().replace(/^file:\/\/\/?/, "/") + "/.cache/thumbnails"

    onCategorizedHistoryChanged: {
        var list = [];
        if (categorizedHistory) {
            for (var i = 0; i < categorizedHistory.length; i++) {
                var cat = categorizedHistory[i];
                if (cat && cat.items) {
                    for (var j = 0; j < cat.items.length; j++) {
                        list.push({
                            catIdx: i,
                            itemIdx: j,
                            modelData: cat.items[j]
                        });
                    }
                }
            }
        }
        flatItems = list;
        if (currentIndex >= flatItems.length) {
            currentIndex = flatItems.length - 1;
        }
    }

    function isItemSelected(catIdx, itemIdx) {
        if (currentIndex < 0 || currentIndex >= flatItems.length) return false;
        var current = flatItems[currentIndex];
        return current.catIdx === catIdx && current.itemIdx === itemIdx;
    }

    function moveUp() {
        if (currentIndex > 0) {
            currentIndex--;
        }
    }

    function moveDown() {
        if (currentIndex > -1 ? (currentIndex < flatItems.length - 1) : (flatItems.length > 0)) {
            currentIndex++;
        }
    }

    function activateCurrentItem() {
        if (currentIndex >= 0 && currentIndex < flatItems.length) {
            var item = flatItems[currentIndex].modelData;
            itemClicked(item);
        }
    }

    // Signals
    signal itemClicked(var item)

    signal searchAgainRequested(var item)

    signal clearClicked()

    // Localization removed
    // Use standard i18nd("plasma_applet_com.mcc45tr.filesearch", )

    // Context Menu
    HistoryContextMenu {
        id: contextMenu
        logic: historyList.logic
        onSearchAgainRequested: (item) => historyList.searchAgainRequested(item)
    }

    // History List
    PlasmaComponents.ScrollView {
        visible: historyList.categorizedHistory.length > 0
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        clip: true
        PlasmaComponents.ScrollBar.vertical.policy: PlasmaComponents.ScrollBar.AlwaysOff

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

                CategoryHeader {
                    width: parent.width
                    categoryName: modelData.categoryName
                    itemCount: modelData.items.length
                    collapsed: histListCategoryDelegate.isCollapsed
                    textColor: historyList.textColor
                    accentColor: historyList.accentColor
                    actionIcon: index === 0 ? "edit-clear-history" : ""
                    actionText: i18nd("plasma_applet_com.mcc45tr.filesearch", "Clear History")
                    onToggleRequested: histListCategoryDelegate.isCollapsed = !histListCategoryDelegate.isCollapsed
                    onActionTriggered: historyList.clearClicked()
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
                        // Destroy delegates for collapsed categories instead of merely clipping them.
                        model: histListCategoryDelegate.isCollapsed ? [] : modelData.items

                        Rectangle {
                            id: historyItemDelegate
                            width: listView.width
                            height: mainLayout.implicitHeight + 12
                            color: itemMouseArea.containsMouse || historyItemDelegate.isSelected || (contextMenu.visible && contextMenu.historyItem === modelData) ? Qt.rgba(historyList.accentColor.r, historyList.accentColor.g, historyList.accentColor.b, 0.15) : "transparent"
                            radius: 4
                            clip: true

                            property bool animateHeight: false
                            property bool isSelected: historyList.isItemSelected(catIdx, index)

                            Behavior on height {
                                enabled: historyItemDelegate.animateHeight
                                NumberAnimation {
                                    duration: 250;
                                    easing.type: Easing.InOutQuad
                                    onFinished: historyItemDelegate.animateHeight = false
                                }
                            }

                            readonly property bool isPreviewAvailable: PreviewUtils.isPreviewAvailable(modelData.filePath || modelData.url || "", modelData.category || "", historyList.previewSettings)
                            readonly property bool previewActive: historyList.previewEnabled && isPreviewAvailable && (historyList.previewInlineMode === 0 ? itemMouseArea.containsMouse : historyItemDelegate.isSelected)
                            readonly property bool showInlinePreview: historyList.previewEnabled && historyList.previewShowHistory && historyList.previewInlineMode === 1 && isPreviewAvailable && historyItemDelegate.isSelected
                            readonly property string previewPath: previewActive ? PreviewUtils.getLocalPreviewPath(modelData.filePath || modelData.url || "") : ""
                            readonly property string previewSource: previewResolver.source
                            readonly property string previewFileType: previewActive ? PreviewUtils.getFileTypeLabel(modelData.filePath || modelData.url || "") : ""

                            onShowInlinePreviewChanged: {
                                historyItemDelegate.animateHeight = true;
                                if (showInlinePreview) {
                                    if (isTextFile) {
                                        loadTextSnippet();
                                    }
                                }
                            }

                            readonly property bool isTextFile: {
                                return PreviewUtils.isTextExtension(PreviewUtils.getExtension(previewPath));
                            }

                            FilePreviewSource {
                                id: previewResolver
                                logic: historyList.logic
                                fileUrl: (modelData.filePath || modelData.url || "").toString()
                                category: (modelData.category || "").toString()
                                active: historyItemDelegate.previewActive
                                settings: historyList.previewSettings
                                freedesktopThumbnailBase: historyList.thumbnailCacheBase
                            }
                            property int snippetRequestToken: 0

                            function loadTextSnippet() {
                                if (!previewPath || !historyList.logic) return;
                                var token = ++snippetRequestToken
                                historyList.logic.readLocalTextSnippet(previewPath, function(content, bytes) {
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

                            ColumnLayout {
                                id: mainLayout
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.margins: 6
                                spacing: 4

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 10

                                    Item {
                                        Layout.preferredWidth: historyList.listIconSize
                                        Layout.preferredHeight: historyList.listIconSize

                                        Kirigami.Icon {
                                            anchors.fill: parent
                                            source: modelData.decoration || "application-x-executable"
                                            color: historyList.textColor
                                            visible: !previewImageHistory.item || previewImageHistory.item.status !== Image.Ready
                                        }

                                        Loader {
                                            id: previewImageHistory
                                            anchors.fill: parent
                                            active: historyList.listIconSize > 22 && historyItemDelegate.previewActive
                                            sourceComponent: Image {
                                                asynchronous: true
                                                fillMode: Image.PreserveAspectCrop
                                                sourceSize.width: historyList.listIconSize
                                                sourceSize.height: historyList.listIconSize
                                                cache: true
                                                source: historyItemDelegate.previewSource
                                                visible: source.length > 0 && status === Image.Ready
                                            }
                                        }
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 2

                                        Text {
                                            text: modelData.display || ""
                                            color: historyList.textColor
                                            font.family: Kirigami.Theme.defaultFont.family
                                            font.pixelSize: Kirigami.Theme.defaultFont.pixelSize
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
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
                                            font.family: Kirigami.Theme.defaultFont.family
                                            font.pixelSize: Kirigami.Theme.defaultFont.pixelSize
                                            elide: Text.ElideMiddle
                                            Layout.fillWidth: true
                                        }
                                    }

                                    Text {
                                        text: historyList.formatTimeFunc(modelData.timestamp)
                                        color: Qt.rgba(historyList.textColor.r, historyList.textColor.g, historyList.textColor.b, 0.5)
                                        font.family: Kirigami.Theme.defaultFont.family
                                        font.pixelSize: Kirigami.Theme.defaultFont.pixelSize
                                        Layout.alignment: Qt.AlignVCenter
                                    }
                                }

                                // Native Inline Preview Card
                                ColumnLayout {
                                    id: inlinePreviewCard
                                    Layout.fillWidth: true
                                    visible: historyItemDelegate.showInlinePreview
                                    spacing: 8
                                    Layout.topMargin: 8

                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 1
                                        color: Qt.rgba(historyList.textColor.r, historyList.textColor.g, historyList.textColor.b, 0.15)
                                    }

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 12
                                        Layout.leftMargin: 4
                                        Layout.rightMargin: 4

                                        // Left Column: Thumbnail or large icon
                                        Item {
                                            id: thumbContainer
                                            Layout.preferredWidth: historyList.previewSize === 0 ? 64 : (historyList.previewSize === 1 ? 120 : 200)
                                            Layout.preferredHeight: historyList.previewSize === 0 ? 48 : (historyList.previewSize === 1 ? 90 : 150)
                                            visible: historyItemDelegate.previewSource.length > 0 || historyItemDelegate.previewFileType.length > 0

                                            // Background fallback placeholder
                                            Rectangle {
                                                anchors.fill: parent
                                                color: Qt.rgba(historyList.textColor.r, historyList.textColor.g, historyList.textColor.b, 0.05)
                                                radius: 4
                                            }

                                            Kirigami.Icon {
                                                anchors.centerIn: parent
                                                implicitWidth: 32
                                                implicitHeight: 32
                                                source: modelData.decoration || "application-x-executable"
                                                color: historyList.textColor
                                                opacity: 0.3
                                                visible: imgPreview.status !== Image.Ready
                                            }

                                            Image {
                                                id: imgPreview
                                                anchors.fill: parent
                                                source: historyItemDelegate.previewSource
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
                                                color: historyList.textColor
                                                font.bold: true
                                                font.family: Kirigami.Theme.defaultFont.family
                                                font.pixelSize: Kirigami.Theme.defaultFont.pixelSize
                                                elide: Text.ElideRight
                                                Layout.fillWidth: true
                                            }

                                            Text {
                                                text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Category") + ": " + (modelData.category || "Other")
                                                color: Qt.rgba(historyList.textColor.r, historyList.textColor.g, historyList.textColor.b, 0.7)
                                                font.family: Kirigami.Theme.defaultFont.family
                                                font.pixelSize: Kirigami.Theme.defaultFont.pixelSize
                                                textFormat: Text.PlainText
                                            }

                                            Text {
                                                text: i18nd("plasma_applet_com.mcc45tr.filesearch", "File Type") + ": " + historyItemDelegate.previewFileType
                                                color: Qt.rgba(historyList.textColor.r, historyList.textColor.g, historyList.textColor.b, 0.7)
                                                font.family: Kirigami.Theme.defaultFont.family
                                                font.pixelSize: Kirigami.Theme.defaultFont.pixelSize
                                                visible: historyItemDelegate.previewFileType.length > 0
                                                textFormat: Text.PlainText
                                            }

                                            Text {
                                                id: fileSizeText
                                                text: ""
                                                color: Qt.rgba(historyList.textColor.r, historyList.textColor.g, historyList.textColor.b, 0.7)
                                                font.family: Kirigami.Theme.defaultFont.family
                                                font.pixelSize: Kirigami.Theme.defaultFont.pixelSize
                                                visible: text.length > 0
                                                textFormat: Text.PlainText
                                            }

                                            Text {
                                                text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Path") + ": " + historyItemDelegate.previewPath
                                                color: Qt.rgba(historyList.textColor.r, historyList.textColor.g, historyList.textColor.b, 0.5)
                                                font.family: Kirigami.Theme.defaultFont.family
                                                font.pixelSize: Kirigami.Theme.defaultFont.pixelSize
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
                                        border.color: Qt.rgba(historyList.textColor.r, historyList.textColor.g, historyList.textColor.b, 0.1)
                                        visible: historyItemDelegate.isTextFile && textSnippet.text.length > 0

                                        Text {
                                            id: textSnippet
                                            anchors.fill: parent
                                            anchors.margins: 6
                                            text: ""
                                            color: historyList.textColor
                                            font.family: "Monospace"
                                            font.pixelSize: Kirigami.Theme.defaultFont.pixelSize
                                            wrapMode: Text.Wrap
                                        }
                                    }

                                    // Quick Actions
                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 10

                                        PlasmaComponents.Button {
                                            text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Copy Path")
                                            icon.name: "edit-copy"
                                            flat: true
                                            Layout.preferredHeight: 28
                                            onClicked: if (historyList.logic) historyList.logic.copyToClipboard(historyItemDelegate.previewPath)
                                        }

                                        PlasmaComponents.Button {
                                            text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Open Folder")
                                            icon.name: "folder-open"
                                            flat: true
                                            Layout.preferredHeight: 28
                                            visible: historyItemDelegate.previewPath.length > 0 && historyItemDelegate.previewPath.includes("/")
                                            onClicked: {
                                                if (historyList.logic && historyItemDelegate.previewPath) {
                                                    historyList.logic.openContainingFolder(historyItemDelegate.previewPath)
                                                }
                                            }
                                        }
                                    }
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
                                        contextMenu.popup(itemMouseArea, mouse.x, mouse.y)
                                    } else {
                                        historyList.itemClicked(modelData)
                                    }
                                }
                            }

                            Loader {
                                active: historyList.previewInlineMode === 0
                                        && itemMouseArea.containsMouse
                                        && historyItemDelegate.previewSource.length > 0
                                sourceComponent: PlasmaComponents.ToolTip {
                                    visible: true
                                    delay: 400
                                    timeout: 10000
                                    x: historyItemDelegate.width + 4
                                    y: 0

                                    contentItem: Column {
                                    spacing: 6

                                    Text {
                                        text: modelData.display || ""
                                        font.bold: true
                                        font.family: Kirigami.Theme.defaultFont.family
                                        font.pixelSize: Kirigami.Theme.defaultFont.pixelSize
                                        color: historyList.textColor
                                    }

                                    Image {
                                        source: historyItemDelegate.previewSource
                                        width: source.length > 0 ? 150 : 0
                                        height: source.length > 0 ? 100 : 0
                                        fillMode: Image.PreserveAspectFit
                                        visible: source.length > 0
                                        cache: true
                                        asynchronous: true
                                    }

                                    Text {
                                        text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Category") + ": " + (modelData.category || "")
                                        font.family: Kirigami.Theme.defaultFont.family
                                        font.pixelSize: Kirigami.Theme.defaultFont.pixelSize
                                        color: Qt.rgba(historyList.textColor.r, historyList.textColor.g, historyList.textColor.b, 0.7)
                                        visible: (modelData.category || "").length > 0
                                    }

                                    Text {
                                        text: i18nd("plasma_applet_com.mcc45tr.filesearch", "File Type") + ": " + historyItemDelegate.previewFileType
                                        font.family: Kirigami.Theme.defaultFont.family
                                        font.pixelSize: Kirigami.Theme.defaultFont.pixelSize
                                        color: Qt.rgba(historyList.textColor.r, historyList.textColor.g, historyList.textColor.b, 0.7)
                                        visible: historyItemDelegate.previewFileType.length > 0
                                    }

                                    Text {
                                        text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Path") + ": " + historyItemDelegate.previewPath
                                        font.family: Kirigami.Theme.defaultFont.family
                                        font.pixelSize: Kirigami.Theme.defaultFont.pixelSize
                                        color: Qt.rgba(historyList.textColor.r, historyList.textColor.g, historyList.textColor.b, 0.7)
                                        wrapMode: Text.WrapAnywhere
                                        width: 300
                                        visible: historyItemDelegate.previewPath.length > 0
                                    }
                                    }

                                    background: Rectangle {
                                        color: Kirigami.Theme.backgroundColor
                                        border.color: historyList.accentColor
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
            font.pixelSize: Math.round(Kirigami.Theme.defaultFont.pixelSize * 1.25)
            Layout.alignment: Qt.AlignHCenter
        }
    }
}
