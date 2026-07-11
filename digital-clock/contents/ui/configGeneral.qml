import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Item {
    id: page
    width: parent.width
    height: parent.height

    // The property name must match 'cfg_' + the entry name in main.xml
    property alias cfg_customFont: fontCombo.currentText
    property alias cfg_use24HourFormat: formatCheckBox.checked

    ColumnLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 10
        spacing: 10
        
        Label {
            text: "Appearance"
            font.bold: true
        }

        CheckBox {
            id: formatCheckBox
            text: "Use 24-Hour Format"
        }
        
        Label {
            text: "Font Selection"
            font.bold: true
        }
        
        RowLayout {
            spacing: 10
            Label {
                text: "Font Family:"
            }
            
            ComboBox {
                id: fontCombo
                Layout.fillWidth: true
                model: Qt.fontFamilies()
                
            }
        }
    }
}
