import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
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

    signal clearClicked()
    
    // Localization removed
    // Use standard i18nd("plasma_applet_com.mcc45tr.filesearch", )
    
    // Header with title and clear button
    RowLayout {
        id: historyHeader
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 24
        
        Text {
            text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Recent Searches")
            font.pixelSize: 13
            font.bold: true
            color: Qt.rgba(historyList.textColor.r, historyList.textColor.g, historyList.textColor.b, 0.7)
            Layout.fillWidth: true
        }
        
        // Clear History Button
        Rectangle {
            id: clearHistoryBtn
            Layout.preferredWidth: clearBtnText.implicitWidth + 16
            Layout.preferredHeight: 26
            radius: 4
            color: clearHistoryMouseArea.containsMouse ? Qt.rgba(historyList.accentColor.r, historyList.accentColor.g, historyList.accentColor.b, 0.2) : "transparent"
            border.width: 1
            border.color: Qt.rgba(historyList.textColor.r, historyList.textColor.g, historyList.textColor.b, 0.2)
            
            Text {
                id: clearBtnText
                anchors.centerIn: parent
                text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Clear History")
                font.pixelSize: 11
                color: historyList.textColor
            }
            
            MouseArea {
                id: clearHistoryMouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: historyList.clearClicked()
            }
        }
    }
    
    // Context Menu
    HistoryContextMenu {
        id: contextMenu
        logic: historyList.logic
    }

    // History List
    ScrollView {
        visible: historyList.categorizedHistory.length > 0
        anchors.top: historyHeader.bottom
        anchors.topMargin: 4
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        clip: true
        ScrollBar.vertical.policy: ScrollBar.AlwaysOff
        
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
                
                // Category Header (Clickable - matches tile view style)
                Rectangle {
                    width: parent.width
                    height: 28
                    color: histListCategoryMouse.containsMouse ? Qt.rgba(historyList.accentColor.r, historyList.accentColor.g, historyList.accentColor.b, 0.1) : "transparent"
                    radius: 4
                    
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 4
                        anchors.rightMargin: 4
                        spacing: 8
                        
                        Kirigami.Icon {
                            source: histListCategoryDelegate.isCollapsed ? "arrow-right" : "arrow-down"
                            Layout.preferredWidth: 16
                            Layout.preferredHeight: 16
                            color: historyList.textColor
                            opacity: 0.6
                        }
                        
                        Text {
                            text: modelData.categoryName + " (" + modelData.items.length + ")"
                            font.pixelSize: 13
                            font.bold: true
                            color: Qt.rgba(historyList.textColor.r, historyList.textColor.g, historyList.textColor.b, 0.6)
                        }
                        
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 1
                            color: Qt.rgba(historyList.textColor.r, historyList.textColor.g, historyList.textColor.b, 0.2)
                        }
                    }
                    
                    MouseArea {
                        id: histListCategoryMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: histListCategoryDelegate.isCollapsed = !histListCategoryDelegate.isCollapsed
                    }
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
                        model: modelData.items
                        
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
                            readonly property string previewSource: previewActive ? PreviewUtils.getPreviewSource((modelData.filePath || modelData.url || "").toString(), historyList.previewEnabled, historyList.previewSettings) : ""
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
                                if (!previewPath) return false;
                                var ext = previewPath.split('.').pop().toLowerCase();
                                var txtExts = ['txt', 'js', 'py', 'qml', 'html', 'css', 'json', 'md', 'sh', 'c', 'cpp', 'h', 'hpp', 'rs', 'go', 'java', 'xml', 'yml', 'yaml', 'ini', 'conf', 'log'];
                                return txtExts.indexOf(ext) !== -1;
                            }

                            function loadTextSnippet() {
                                if (!previewPath) return;
                                var xhr = new XMLHttpRequest();
                                xhr.onreadystatechange = function() {
                                    if (xhr.readyState === XMLHttpRequest.DONE) {
                                        if (xhr.status === 200 || xhr.status === 0) {
                                            var lines = xhr.responseText.split('\n').slice(0, 5).join('\n');
                                            textSnippet.text = lines;
                                            
                                            var bytes = xhr.responseText.length;
                                            var sizeStr = "";
                                            if (bytes < 1024) sizeStr = bytes + " B";
                                            else if (bytes < 1048576) sizeStr = (bytes / 1024).toFixed(1) + " KB";
                                            else sizeStr = (bytes / 1048576).toFixed(1) + " MB";
                                            fileSizeText.text = "<b>" + i18nd("plasma_applet_com.mcc45tr.filesearch", "Size") + ":</b> " + sizeStr;
                                        }
                                    }
                                }
                                xhr.open("GET", (modelData.filePath || modelData.url || "").toString());
                                xhr.send();
                            }

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
                                            visible: previewImageHistory.status !== Image.Ready
                                        }
                                        
                                        Image {
                                            id: previewImageHistory
                                            anchors.fill: parent
                                            asynchronous: true
                                            fillMode: Image.PreserveAspectCrop
                                            sourceSize.width: historyList.listIconSize
                                            sourceSize.height: historyList.listIconSize
                                            cache: true
                                            source: historyList.listIconSize > 22
                                                ? PreviewUtils.getPreviewSource((modelData.filePath || modelData.url || "").toString(), historyList.previewEnabled, historyList.previewSettings)
                                                : ""
                                            visible: source.length > 0 && status === Image.Ready
                                        }
                                    }
                                    
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 2
                                        
                                        Text {
                                            text: modelData.display || ""
                                            color: historyList.textColor
                                            font.pixelSize: 14
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
                                            font.pixelSize: 11
                                            elide: Text.ElideMiddle
                                            Layout.fillWidth: true
                                        }
                                    }
                                    
                                    Text {
                                        text: historyList.formatTimeFunc(modelData.timestamp)
                                        color: Qt.rgba(historyList.textColor.r, historyList.textColor.g, historyList.textColor.b, 0.5)
                                        font.pixelSize: 11
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
                                                font.pixelSize: 12
                                                elide: Text.ElideRight
                                                Layout.fillWidth: true
                                            }

                                            Text {
                                                text: "<b>" + i18nd("plasma_applet_com.mcc45tr.filesearch", "Category") + ":</b> " + (modelData.category || "Other")
                                                color: Qt.rgba(historyList.textColor.r, historyList.textColor.g, historyList.textColor.b, 0.7)
                                                font.pixelSize: 10
                                                textFormat: Text.StyledText
                                            }

                                            Text {
                                                text: "<b>" + i18nd("plasma_applet_com.mcc45tr.filesearch", "File Type") + ":</b> " + historyItemDelegate.previewFileType
                                                color: Qt.rgba(historyList.textColor.r, historyList.textColor.g, historyList.textColor.b, 0.7)
                                                font.pixelSize: 10
                                                visible: historyItemDelegate.previewFileType.length > 0
                                                textFormat: Text.StyledText
                                            }

                                            Text {
                                                id: fileSizeText
                                                text: ""
                                                color: Qt.rgba(historyList.textColor.r, historyList.textColor.g, historyList.textColor.b, 0.7)
                                                font.pixelSize: 10
                                                visible: text.length > 0
                                                textFormat: Text.StyledText
                                            }

                                            Text {
                                                text: "<b>" + i18nd("plasma_applet_com.mcc45tr.filesearch", "Path") + ":</b> " + historyItemDelegate.previewPath
                                                color: Qt.rgba(historyList.textColor.r, historyList.textColor.g, historyList.textColor.b, 0.5)
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
                                        border.color: Qt.rgba(historyList.textColor.r, historyList.textColor.g, historyList.textColor.b, 0.1)
                                        visible: historyItemDelegate.isTextFile && textSnippet.text.length > 0

                                        Text {
                                            id: textSnippet
                                            anchors.fill: parent
                                            anchors.margins: 6
                                            text: ""
                                            color: historyList.textColor
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
                                            onClicked: if (historyList.logic) historyList.logic.copyToClipboard(historyItemDelegate.previewPath)
                                        }

                                        Button {
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
                                        contextMenu.popup()
                                    } else {
                                        historyList.itemClicked(modelData)
                                    }
                                }
                            }

                            ToolTip {
                                visible: historyList.previewInlineMode === 0 && historyItemDelegate.previewSource.length > 0
                                delay: 400
                                timeout: 10000
                                x: historyItemDelegate.width + 4
                                y: 0

                                contentItem: Column {
                                    spacing: 6

                                    Text {
                                        text: modelData.display || ""
                                        font.bold: true
                                        font.pixelSize: 12
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
                                        font.pixelSize: 10
                                        color: Qt.rgba(historyList.textColor.r, historyList.textColor.g, historyList.textColor.b, 0.7)
                                        visible: (modelData.category || "").length > 0
                                    }

                                    Text {
                                        text: i18nd("plasma_applet_com.mcc45tr.filesearch", "File Type") + ": " + historyItemDelegate.previewFileType
                                        font.pixelSize: 10
                                        color: Qt.rgba(historyList.textColor.r, historyList.textColor.g, historyList.textColor.b, 0.7)
                                        visible: historyItemDelegate.previewFileType.length > 0
                                    }

                                    Text {
                                        text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Path") + ": " + historyItemDelegate.previewPath
                                        font.pixelSize: 10
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
            font.pixelSize: 16
            Layout.alignment: Qt.AlignHCenter
        }
    }
}
