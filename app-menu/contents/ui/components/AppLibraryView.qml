import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore

ScrollView {
    id: root
    
    required property var rootModel
    
    // Style settings
    property real cardSize: Kirigami.Units.gridUnit * 8
    property real iconSize: Kirigami.Units.iconSizes.large // 32px or 48px usually
    property real smallIconSize: Kirigami.Units.iconSizes.small // 16px or 22px
    
    // contentWidth: availableWidth
    
    Flow {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 15
        
        Repeater {
            model: rootModel
            
            delegate: Item {
                // Category Card
                width: root.cardSize
                height: root.cardSize + 20 // Extra for title
                
                property var categoryModel: rootModel.modelForRow(index)
                
                // Title
                Text {
                    id: title
                    text: model.display
                    anchors.bottom: bg.top
                    anchors.bottomMargin: 5
                    anchors.horizontalCenter: parent.horizontalCenter
                    font.bold: true
                    color: Kirigami.Theme.textColor
                    font.pixelSize: Kirigami.Theme.defaultFont.pixelSize
                    elide: Text.ElideRight
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                }
                
                // Card Background
                Rectangle {
                    id: bg
                    width: parent.width
                    height: parent.width // Square
                    anchors.bottom: parent.bottom
                    color: Kirigami.Theme.backgroundColor
                    radius: 10
                    border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.1)
                    
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
                            
                            Kirigami.Icon {
                                anchors.centerIn: parent
                                source: (categoryModel?.count > 0) ? categoryModel.data(categoryModel.index(0, 0), Qt.DecorationRole) : ""
                                width: root.iconSize
                                height: root.iconSize
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    if (categoryModel) {
                                        root.launchApp(categoryModel.index(0, 0))
                                    }
                                }
                            }
                        }
                        
                        // Item 1
                        Item {
                            width: (bg.width - 30) / 2
                            height: width
                            visible: categoryModel?.count > 1
                            
                            Kirigami.Icon {
                                anchors.centerIn: parent
                                source: (categoryModel?.count > 1) ? categoryModel.data(categoryModel.index(1, 0), Qt.DecorationRole) : ""
                                width: root.iconSize
                                height: root.iconSize
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    if (categoryModel) {
                                        root.launchApp(categoryModel.index(1, 0))
                                    }
                                }
                            }
                        }
                        
                        // Item 2
                        Item {
                            width: (bg.width - 30) / 2
                            height: width
                            visible: categoryModel?.count > 2
                            
                            Kirigami.Icon {
                                anchors.centerIn: parent
                                source: (categoryModel?.count > 2) ? categoryModel.data(categoryModel.index(2, 0), Qt.DecorationRole) : ""
                                width: root.iconSize
                                height: root.iconSize
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    if (categoryModel) {
                                        root.launchApp(categoryModel.index(2, 0))
                                    }
                                }
                            }
                        }
                        
                        // Item 3 (or Cluster)
                        Item {
                            width: (bg.width - 30) / 2
                            height: width
                            visible: categoryModel?.count > 3
                            
                            // Case A: <= 4 items total -> Just show Item 3
                            Kirigami.Icon {
                                anchors.centerIn: parent
                                visible: categoryModel?.count <= 4 && categoryModel?.count > 3
                                source: visible ? categoryModel.data(categoryModel.index(3, 0), Qt.DecorationRole) : ""
                                width: root.iconSize
                                height: root.iconSize
                            }
                            
                             MouseArea {
                                anchors.fill: parent
                                enabled: categoryModel?.count <= 4
                                onClicked: {
                                    if (categoryModel) {
                                        root.launchApp(categoryModel.index(3, 0))
                                    }
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
                                    // Find index in parent swipe view?
                                    // index in repeater corresponds to rootModel index
                                    // SwipeView has AppLibrary at 0, then Categories at 1..N
                                    // So target index is index + 1
                                    
                                    // We need to signal the parent
                                    // quick hack: access global logic or emit signal
                                    root.requestCategoryPage(index + 1)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    signal requestCategoryPage(int index)
    
    function launchApp(modelIndex) {
        // Kicker types trigger
        // modelIndex.model.trigger(modelIndex.row, "", null)
        // Or if it's a proxy model, we might need to map it.
        // But here categoryModel is a Kicker.AppsModel (or similar)
        // trigger() should work.
        // Wait, Kicker models usually have a 'trigger' method on the model itself?
        // Or use `model.trigger(index, "", null)`?
        // Checking Kicker docs/usage:
        // `kickoff.rootModel.trigger(index, "", null)`
        
        // categoryModel is a recursive model.
        // It should have a trigger method.
        if (categoryModel && categoryModel.trigger) {
             categoryModel.trigger(modelIndex.row, "", null);
        }
    }
}
