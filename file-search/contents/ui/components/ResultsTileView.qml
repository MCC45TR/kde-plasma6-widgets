import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

// Results Tile View - Displays search results in tile/grid format
ScrollView {
    id: resultsTileRoot
    
    // Required properties
    required property var categorizedData
    required property int iconSize
    required property color textColor
    required property color accentColor
    
    // Signals
    signal itemClicked(int index, string display, string decoration, string category, string matchId, string filePath)
    
    // Localization
    property var trFunc: function(key) { return key }
    property string searchText: ""
    
    clip: true
    ScrollBar.vertical.policy: ScrollBar.AlwaysOff
    
    ListView {
        id: tileCategoryList
        width: parent.width
        model: resultsTileRoot.categorizedData
        spacing: 16
        interactive: false // Let ScrollView handle scrolling
        
        delegate: Column {
            width: parent.width
            spacing: 8
            
            // Category Header
            RowLayout {
                width: parent.width
                spacing: 8
                
                Text {
                    text: modelData.categoryName
                    font.pixelSize: 13
                    font.bold: true
                    color: Qt.rgba(resultsTileRoot.textColor.r, resultsTileRoot.textColor.g, resultsTileRoot.textColor.b, 0.6)
                }
                
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: Qt.rgba(resultsTileRoot.textColor.r, resultsTileRoot.textColor.g, resultsTileRoot.textColor.b, 0.2)
                }
            }
            
            // Grid Flow
            Flow {
                width: parent.width
                spacing: 8
                
                Repeater {
                    model: modelData.items
                    
                    delegate: Item {
                        width: resultsTileRoot.iconSize + 40
                        height: resultsTileRoot.iconSize + 50
                        
                        Rectangle {
                            id: tileBg
                            anchors.fill: parent
                            radius: 8
                            color: tileMouseArea.containsMouse ? Qt.rgba(resultsTileRoot.accentColor.r, resultsTileRoot.accentColor.g, resultsTileRoot.accentColor.b, 0.15) : "transparent"
                            
                            Column {
                                anchors.centerIn: parent
                                spacing: 6
                                
                                // Icon with configurable size
                                Kirigami.Icon {
                                    width: resultsTileRoot.iconSize
                                    height: resultsTileRoot.iconSize
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    source: modelData.decoration || "application-x-executable"
                                    color: resultsTileRoot.textColor
                                }
                                
                                // Text below icon
                                Text {
                                    width: parent.width - 8
                                    text: modelData.display || ""
                                    color: resultsTileRoot.textColor
                                    font.pixelSize: resultsTileRoot.iconSize > 32 ? 11 : 9
                                    horizontalAlignment: Text.AlignHCenter
                                    elide: Text.ElideMiddle
                                    maximumLineCount: 2
                                    wrapMode: Text.Wrap
                                }
                            }
                            
                            MouseArea {
                                id: tileMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                
                                onClicked: {
                                    var matchId = modelData.duplicateId || modelData.display || ""
                                    var filePath = modelData.url || ""
                                    resultsTileRoot.itemClicked(modelData.index, modelData.display || "", modelData.decoration || "application-x-executable", modelData.category || "Diğer", matchId, filePath)
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
        text: resultsTileRoot.searchText.length > 0 ? "Sonuç bulunamadı" : "Aramak için yazmaya başlayın"
        color: Qt.rgba(resultsTileRoot.textColor.r, resultsTileRoot.textColor.g, resultsTileRoot.textColor.b, 0.5)
        font.pixelSize: 12
        visible: resultsTileRoot.categorizedData.length === 0
    }
}
