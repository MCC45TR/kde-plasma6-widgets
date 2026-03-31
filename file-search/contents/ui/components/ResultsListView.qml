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
    property var previewSettings: ({"images": true, "videos": false, "text": false, "documents": false})
    
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
                text: section === "RSS" ? i18nd("plasma_applet_com.mcc45tr.filesearch", "Haberler") : section
                font.pixelSize: 11
                font.bold: true
                color: Qt.rgba(resultsListRoot.textColor.r, resultsListRoot.textColor.g, resultsListRoot.textColor.b, 0.6)
            }
        }
        
        delegate: Item {
            id: delegateRoot
            width: resultsList.width
            
            // Reliable RSS detection: check category OR the unique ID prefix
            readonly property bool isRSS: modelData.category === "RSS" || 
                                          modelData.category === i18nd("plasma_applet_com.mcc45tr.filesearch", "Haberler") || 
                                          (modelData.duplicateId && modelData.duplicateId.toString().startsWith("rss:"))
                                          
            property bool previewActive: resultsListRoot.previewEnabled && !isRSS && resultMouseArea.containsMouse
            property string previewPath: previewActive ? PreviewUtils.getLocalPreviewPath(modelData.url || "") : ""
            property string previewSource: previewActive ? PreviewUtils.getPreviewSource(modelData.url || "", resultsListRoot.previewEnabled, resultsListRoot.previewSettings) : ""
            property string previewFileType: PreviewUtils.getFileTypeLabel(modelData.url || "")
            
            // Use implicitHeight of layout instead of anchors.fill to avoid circular dependency
            height: isRSS ? (rssCardLayout.implicitHeight + 20) : Math.max(44, resultsListRoot.listIconSize + 18)
            
            // Background Container
            Rectangle {
                anchors.fill: parent
                anchors.margins: isRSS ? 2 : 0
                color: resultMouseArea.containsMouse ? Qt.rgba(resultsListRoot.accentColor.r, resultsListRoot.accentColor.g, resultsListRoot.accentColor.b, 0.15) : 
                       (isRSS ? Qt.rgba(resultsListRoot.accentColor.r, resultsListRoot.accentColor.g, resultsListRoot.accentColor.b, 0.05) : "transparent")
                radius: isRSS ? 10 : 4
                border.width: (isRSS || resultsList.currentIndex === index) ? 1 : 0
                border.color: (isRSS || resultsList.currentIndex === index) ? Qt.rgba(resultsListRoot.accentColor.r, resultsListRoot.accentColor.g, resultsListRoot.accentColor.b, 0.3) : "transparent"
                
                ColumnLayout {
                    id: rssCardLayout
                    // Use anchors for positioning, but the parent's height is derived from this layout's implicitHeight
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 10
                    spacing: 8
                    
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12
                        
                        // Icon Container
                        Item {
                            Layout.preferredWidth: isRSS ? 36 : resultsListRoot.listIconSize
                            Layout.preferredHeight: isRSS ? 36 : resultsListRoot.listIconSize
                            
                            Kirigami.Icon {
                                anchors.fill: parent
                                source: modelData.decoration || (isRSS ? "news-subscribe" : "application-x-executable")
                                color: resultsListRoot.textColor
                            }
                        }
                        
                        // Text Content
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1
                            
                            Text {
                                text: modelData.display || ""
                                color: resultsListRoot.textColor
                                font.pixelSize: isRSS ? 15 : 14
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
                                font.pixelSize: 11
                                elide: Text.ElideMiddle
                                Layout.fillWidth: true
                            }
                        }

                        // Right side icons
                        RowLayout {
                            spacing: 4
                            
                            // Pin Indicator/Button
                            Kirigami.Icon {
                                source: "pin"
                                implicitWidth: 14
                                implicitHeight: 14
                                visible: resultsListRoot.isPinnedFunc(modelData.duplicateId || modelData.display)
                                color: resultsListRoot.accentColor
                            }
                        }
                    }
                    
                    ColumnLayout {
                        Layout.fillWidth: true
                        visible: isRSS
                        spacing: 8
                        
                        Rectangle {
                            Layout.fillWidth: true
                            height: 1
                            color: Qt.rgba(resultsListRoot.textColor.r, resultsListRoot.textColor.g, resultsListRoot.textColor.b, 0.1)
                        }
                        
                        Text {
                            id: descriptionLabel
                            text: modelData.description || ""
                            color: resultsListRoot.textColor
                            font.pixelSize: 13
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                            maximumLineCount: 8
                            elide: Text.ElideRight
                            opacity: 0.85
                            lineHeight: 1.2
                        }

                        Text {
                            text: resultsListRoot.rssMetaLine(modelData)
                            color: Qt.rgba(resultsListRoot.textColor.r, resultsListRoot.textColor.g, resultsListRoot.textColor.b, 0.62)
                            font.pixelSize: 11
                            wrapMode: Text.WrapAnywhere
                            Layout.fillWidth: true
                            visible: text.length > 0
                        }
                        
                        RowLayout {
                            spacing: 12
                            Button {
                                text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Haberi Oku")
                                icon.name: "internet-services"
                                onClicked: if (modelData.url) Qt.openUrlExternally(modelData.url)
                            }
                            
                            Button {
                                text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Paylaş")
                                icon.name: "mail-send"
                                flat: true
                                onClicked: logic.copyToClipboard(modelData.url)
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
                    var matchId = modelData.duplicateId || modelData.display || ""
                    var filePath = (modelData.url || "").toString()
                    
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
                        if (isRSS && filePath.length > 0) {
                            Qt.openUrlExternally(filePath)
                        } else {
                            resultsListRoot.itemClicked(index, modelData.display || "", modelData.decoration || "application-x-executable", modelData.category || "Other", matchId, filePath)
                        }
                    }
                }
            }

            ToolTip {
                visible: delegateRoot.previewSource.length > 0
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
                        text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Category") + ": " + (modelData.category || "")
                        font.pixelSize: 10
                        color: Qt.rgba(resultsListRoot.textColor.r, resultsListRoot.textColor.g, resultsListRoot.textColor.b, 0.7)
                        visible: (modelData.category || "").length > 0
                    }

                    Text {
                        text: i18nd("plasma_applet_com.mcc45tr.filesearch", "File Type") + ": " + delegateRoot.previewFileType
                        font.pixelSize: 10
                        color: Qt.rgba(resultsListRoot.textColor.r, resultsListRoot.textColor.g, resultsListRoot.textColor.b, 0.7)
                        visible: delegateRoot.previewFileType.length > 0
                    }

                    Text {
                        text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Path") + ": " + delegateRoot.previewPath
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
            visible: resultsList.count === 0 && resultsListRoot.searchText.length > 0

            BusyIndicator {
                anchors.horizontalCenter: parent.horizontalCenter
                running: resultsListRoot.isLoading
                visible: resultsListRoot.isLoading
            }

            Text {
                text: resultsListRoot.isLoading
                    ? i18nd("plasma_applet_com.mcc45tr.filesearch", "Searching...")
                    : i18nd("plasma_applet_com.mcc45tr.filesearch", "No results found")
                color: Qt.rgba(resultsListRoot.textColor.r, resultsListRoot.textColor.g, resultsListRoot.textColor.b, 0.5)
                font.pixelSize: 12
            }
        }
    }
    
    property int count: resultsList.count
    
    function moveUp() {
        if (currentIndex > 0) currentIndex--
    }
    
    function moveDown() {
        if (currentIndex < resultsList.count - 1) currentIndex++
    }
}
