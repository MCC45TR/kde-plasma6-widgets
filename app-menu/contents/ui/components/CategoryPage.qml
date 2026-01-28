import QtQuick
import QtQuick.Controls
import org.kde.kirigami as Kirigami

ScrollView {
    id: root
    
    required property var categoryModel
    
    // contentWidth: availableWidth
    width: availableWidth
    
    GridView {
        anchors.fill: parent
        anchors.margins: 10
        cellWidth: Kirigami.Units.gridUnit * 6
        cellHeight: cellWidth + 30
        
        model: categoryModel
        
        delegate: Item {
            width: GridView.view.cellWidth
            height: GridView.view.cellHeight
            
            Column {
                anchors.centerIn: parent
                spacing: 5
                
                Kirigami.Icon {
                    source: model.decoration
                    width: Kirigami.Units.iconSizes.medium
                    height: Kirigami.Units.iconSizes.medium
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                
                Text {
                    text: model.display
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                    color: Kirigami.Theme.textColor
                    font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                }
            }
            
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    if (categoryModel && categoryModel.trigger) {
                        categoryModel.trigger(index, "", null)
                    }
                }
            }
        }
    }
}
