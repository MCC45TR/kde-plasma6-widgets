import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid

Item {
    id: root
    
    required property var rootModel
    
    // Style settings
    property real iconSize: Plasmoid.configuration.iconSize || 48
    property real cardSize: ((iconSize + 34) * 2) + 10
    property real smallIconSize: Math.max(16, iconSize / 2)
    
    Flickable {
        id: flickable
        anchors.fill: parent
        anchors.topMargin: 0
        anchors.leftMargin: Kirigami.Units.smallSpacing
        anchors.rightMargin: Kirigami.Units.smallSpacing
        anchors.bottomMargin: Kirigami.Units.smallSpacing
        contentWidth: width
        contentHeight: flowLayout.implicitHeight + 20
        
        focus: true
        clip: true
        
        ScrollBar.vertical: ScrollBar {
            active: true
        }

        property real minSpacing: Kirigami.Units.largeSpacing
        property int columns: Math.max(1, Math.floor((width) / (root.cardSize + minSpacing)))
        property real cellWidth: Math.floor(width / columns)
        property real cellHeight: root.cardSize + 40
        
        GridLayout {
            id: flowLayout
            columns: flickable.columns
            rowSpacing: 0
            columnSpacing: 0
            width: flickable.width
            
            property int expandedIndex: -1
            
            Repeater {
                model: root.rootModel
                
                delegate: Item {
                    id: delegateRoot
                    required property int index
                    required property string display
                    
                    property bool isExpanded: flowLayout.expandedIndex === index
                    
                    property int slotStart: {
                        let expIdx = flowLayout.expandedIndex;
                        if (expIdx === -1) return index;
                        let cols = flickable.columns;
                        let expRow = Math.floor(expIdx / cols);
                        let baseRow = Math.floor(index / cols);
                        let startOfExpRow = expRow * cols;
                        
                        if (baseRow < expRow) {
                            return index;
                        } else if (baseRow > expRow) {
                            return index + cols - 1;
                        } else {
                            if (index === expIdx) {
                                return startOfExpRow;
                            } else if (index < expIdx) {
                                return startOfExpRow + cols + (index % cols);
                            } else {
                                return startOfExpRow + cols + (index % cols) - 1;
                            }
                        }
                    }
                    
                    Layout.row: Math.floor(slotStart / flickable.columns)
                    Layout.column: slotStart % flickable.columns
                    Layout.columnSpan: isExpanded ? flickable.columns : 1
                    
                    Layout.preferredWidth: isExpanded ? flowLayout.width : flickable.cellWidth
                    Layout.preferredHeight: isExpanded ? folderCard.expandedHeight : flickable.cellHeight
                    
                    Behavior on Layout.preferredWidth { NumberAnimation { duration: Kirigami.Units.shortDuration; easing.type: Easing.OutCubic } }
                    Behavior on Layout.preferredHeight { NumberAnimation { duration: Kirigami.Units.shortDuration; easing.type: Easing.OutCubic } }
                    
                    // Preserve row separation when GridLayout spacing is disabled.
                    
                    AppFolderCard {
                        id: folderCard
                        
                        // Centering logic inside cell:
                        // When collapsed, center the card normally inside the virtual cell
                        // When expanded, the width is full width, so x is 0. y is 0.
                        x: isExpanded ? 0 : (parent.width - width) / 2
                        y: isExpanded ? 0 : (parent.height - height) / 2
                        
                        isExpanded: delegateRoot.isExpanded
                        parentWidth: flowLayout.width
                        
                        categoryModel: root.rootModel.modelForRow(index)
                        title: display
                        iconSize: root.iconSize
                        smallIconSize: root.smallIconSize
                        cardSize: root.cardSize
                        categoryIndex: index
                        
                        onToggleExpand: {
                            if (flowLayout.expandedIndex === index) {
                                flowLayout.expandedIndex = -1 // Close
                            } else {
                                flowLayout.expandedIndex = index // Open
                            }
                        }
                    }
                }
            }
        }
    }
}
