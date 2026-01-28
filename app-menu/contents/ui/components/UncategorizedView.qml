import QtQuick
import QtQuick.Controls
import org.kde.kirigami as Kirigami

ScrollView {
    id: root
    
    // Logic to find the specific category model will be outside or passed in.
    // For now, let's accept a model.
    property var categoryModel: null
    
    // If no model is provided (e.g. we couldn't find "Uncategorized"), show placeholder
    
    // width: availableWidth
    contentWidth: availableWidth
    
    GridView {
        anchors.fill: parent
        anchors.margins: 10
        cellWidth: Kirigami.Units.gridUnit * 6
        cellHeight: cellWidth + 30
        visible: !!categoryModel
        
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
    
    // Fallback if empty/null
    Column {
        anchors.centerIn: parent
        spacing: 10
        visible: !categoryModel
        
        Kirigami.Icon {
            source: "applications-other"
            width: 64
            height: 64
            anchors.horizontalCenter: parent.horizontalCenter
        }
        
        Text {
            text: i18n("No Uncategorized Items")
            font.bold: true
            anchors.horizontalCenter: parent.horizontalCenter
            color: Kirigami.Theme.textColor
        }
    }
}
