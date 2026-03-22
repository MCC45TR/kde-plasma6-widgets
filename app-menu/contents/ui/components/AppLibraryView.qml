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
        
        Flow {
            id: flowLayout
            width: flickable.width
            spacing: 0
            
            property int expandedIndex: -1
            
            Repeater {
                model: root.rootModel
                
                delegate: Item {
                    id: delegateRoot
                    required property int index
                    required property string display
                    
                    property bool isExpanded: flowLayout.expandedIndex === index
                    
                    width: isExpanded ? flowLayout.width : flickable.cellWidth
                    height: isExpanded ? folderCard.expandedHeight : flickable.cellHeight
                    
                    Behavior on width { NumberAnimation { duration: Kirigami.Units.shortDuration; easing.type: Easing.OutCubic } }
                    Behavior on height { NumberAnimation { duration: Kirigami.Units.shortDuration; easing.type: Easing.OutCubic } }
                    
                    // We need a slight bottom padding to space out the rows properly. Flow does it if siblings adjust height.
                    
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
                                // Scroll to ensure it's visible?
                                // Not strictly required but nice.
                            }
                        }
                    }
                }
            }
        }
    }
}
