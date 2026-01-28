import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid

Item {
    id: root
    
    required property var rootModel
    
    signal requestCategoryPage(int index)
    
    // Style settings
    property real iconSize: Plasmoid.configuration.iconSize || 48
    property real cardSize: ((iconSize + 34) * 2) + 10
    property real smallIconSize: Math.max(16, iconSize / 2)
    
    // We forward width/height to GridView but logic is encapsulated here.
    
    GridView {
        id: grid
        anchors.fill: parent
        anchors.margins: 10
        
        focus: true
        clip: true
        
        ScrollBar.vertical: ScrollBar {
            active: true
        }

        // Layout Calculation
        property real minSpacing: 10
        // Use grid.width because anchors.fill makes grid size match parent (Item)
        property int columns: Math.max(1, Math.floor((width - 20) / (root.cardSize + minSpacing)))
        
        cellWidth: Math.floor(width / columns)
        cellHeight: root.cardSize + 20 + 20 
        
        model: root.rootModel
        
        delegate: Item {
            width: grid.cellWidth
            height: grid.cellHeight
            
            property var categoryModel: grid.model.modelForRow(index)
            
            // Centered Card
            Item {
                width: root.cardSize
                height: root.cardSize + 20
                anchors.centerIn: parent
                
                // Card Background
                Rectangle {
                    id: bg
                    width: parent.width
                    height: parent.width // Square
                    anchors.top: parent.top
                    color: Kirigami.Theme.backgroundColor
                    radius: 10
                    border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.1)
                
                    // Title
                    Text {
                        id: title
                        text: model.display
                        anchors.top: bg.bottom
                        anchors.topMargin: 5
                        anchors.horizontalCenter: parent.horizontalCenter
                        font.bold: true
                        color: Kirigami.Theme.textColor
                        font.pixelSize: Kirigami.Theme.defaultFont.pixelSize
                        elide: Text.ElideRight
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                    }
                    
                    // 2x2 Grid for items
                    Grid {
                        anchors.centerIn: parent
                        columns: 2
                        spacing: 10
                        
                        // Item 0
                        Item {
                            width: (bg.width - 30) / 2
                            height: width
                            visible: categoryModel?.count > 0
                            
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    if (categoryModel) {
                                         categoryModel.trigger(0, "", null);
                                    }
                                }
                            }

                            Column {
                                anchors.centerIn: parent
                                spacing: 2
                                width: parent.width
                                
                                Kirigami.Icon {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    source: (categoryModel?.count > 0) ? categoryModel.data(categoryModel.index(0, 0), Qt.DecorationRole) : ""
                                    width: root.iconSize
                                    height: root.iconSize
                                }

                                Text {
                                    text: (categoryModel?.count > 0) ? categoryModel.data(categoryModel.index(0, 0), Qt.DisplayRole) : ""
                                    width: parent.width
                                    horizontalAlignment: Text.AlignHCenter
                                    elide: Text.ElideRight
                                    font.pixelSize: Kirigami.Theme.smallFont.pixelSize * 0.8
                                    color: Kirigami.Theme.textColor
                                    maximumLineCount: 1
                                    visible: text !== "" && Plasmoid.configuration.showLabelsInTiles
                                }
                            }
                        }
                        
                        // Item 1
                        Item {
                            width: (bg.width - 30) / 2
                            height: width
                            visible: categoryModel?.count > 1
                            
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    if (categoryModel) {
                                         categoryModel.trigger(1, "", null);
                                    }
                                }
                            }

                            Column {
                                anchors.centerIn: parent
                                spacing: 2
                                width: parent.width

                                Kirigami.Icon {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    source: (categoryModel?.count > 1) ? categoryModel.data(categoryModel.index(1, 0), Qt.DecorationRole) : ""
                                    width: root.iconSize
                                    height: root.iconSize
                                }

                                Text {
                                    text: (categoryModel?.count > 1) ? categoryModel.data(categoryModel.index(1, 0), Qt.DisplayRole) : ""
                                    width: parent.width
                                    horizontalAlignment: Text.AlignHCenter
                                    elide: Text.ElideRight
                                    font.pixelSize: Kirigami.Theme.smallFont.pixelSize * 0.8
                                    color: Kirigami.Theme.textColor
                                    maximumLineCount: 1
                                    visible: text !== "" && Plasmoid.configuration.showLabelsInTiles
                                }
                            }
                        }
                        
                        // Item 2
                        Item {
                            width: (bg.width - 30) / 2
                            height: width
                            visible: categoryModel?.count > 2
                            
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    if (categoryModel) {
                                         categoryModel.trigger(2, "", null);
                                    }
                                }
                            }

                            Column {
                                anchors.centerIn: parent
                                spacing: 2
                                width: parent.width

                                Kirigami.Icon {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    source: (categoryModel?.count > 2) ? categoryModel.data(categoryModel.index(2, 0), Qt.DecorationRole) : ""
                                    width: root.iconSize
                                    height: root.iconSize
                                }

                                Text {
                                    text: (categoryModel?.count > 2) ? categoryModel.data(categoryModel.index(2, 0), Qt.DisplayRole) : ""
                                    width: parent.width
                                    horizontalAlignment: Text.AlignHCenter
                                    elide: Text.ElideRight
                                    font.pixelSize: Kirigami.Theme.smallFont.pixelSize * 0.8
                                    color: Kirigami.Theme.textColor
                                    maximumLineCount: 1
                                    visible: text !== "" && Plasmoid.configuration.showLabelsInTiles
                                }
                            }
                        }
                        
                        // Item 3 (or Cluster)
                        Item {
                            width: (bg.width - 30) / 2
                            height: width
                            visible: categoryModel?.count > 3
                            
                            // Case A: <= 4 items total -> Just show Item 3
                            
                             MouseArea {
                                anchors.fill: parent
                                enabled: categoryModel?.count <= 4
                                onClicked: {
                                    if (categoryModel) {
                                         categoryModel.trigger(3, "", null);
                                    }
                                }
                            }

                            Column {
                                anchors.centerIn: parent
                                spacing: 2
                                width: parent.width
                                visible: categoryModel?.count <= 4 && categoryModel?.count > 3

                                Kirigami.Icon {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    source: parent.visible ? categoryModel.data(categoryModel.index(3, 0), Qt.DecorationRole) : ""
                                    width: root.iconSize
                                    height: root.iconSize
                                }
                                
                                Text {
                                    text: parent.visible ? categoryModel.data(categoryModel.index(3, 0), Qt.DisplayRole) : ""
                                    width: parent.width
                                    horizontalAlignment: Text.AlignHCenter
                                    elide: Text.ElideRight
                                    font.pixelSize: Kirigami.Theme.smallFont.pixelSize * 0.8
                                    color: Kirigami.Theme.textColor
                                    maximumLineCount: 1
                                    visible: text !== "" && Plasmoid.configuration.showLabelsInTiles
                                }
                            }
                            
                            // Case B: > 4 items -> Show Cluster of 4 small icons
                            Grid {
                                anchors.centerIn: parent
                                visible: categoryModel?.count > 4
                                columns: 2
                                spacing: 2
                                
                                Repeater {
                                    model: 4
                                    delegate: Kirigami.Icon {
                                        property int itemIndex: 3 + index
                                        visible: categoryModel?.count > itemIndex
                                        source: visible ? categoryModel.data(categoryModel.index(itemIndex, 0), Qt.DecorationRole) : ""
                                        width: root.smallIconSize
                                        height: root.smallIconSize
                                    }
                                }
                            }
                            
                            // Click handler for Case B -> triggers category view
                            MouseArea {
                                anchors.fill: parent
                                enabled: categoryModel?.count > 4
                                onClicked: {
                                    // Navigate to category page
                                    root.requestCategoryPage(index)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
