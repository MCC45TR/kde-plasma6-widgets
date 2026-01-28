import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Item {
    id: configAppearance
    
    property string title: i18n("Appearance")
    
    // Config binding
    property int cfg_edgeMargin
    
    // Default values
    property int cfg_edgeMarginDefault: 10
    
    implicitHeight: layout.implicitHeight
    
    ColumnLayout {
        id: layout
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 15
        
        GroupBox {
            title: i18n("Appearance")
            Layout.fillWidth: true
            
            ColumnLayout {
                width: parent.width
                spacing: 10
                
                Label {
                    text: i18n("Widget Margin:")
                    font.bold: true
                }
                
                ComboBox {
                    id: edgeMarginCombo
                    Layout.fillWidth: true
                    model: [i18n("Normal (10px)"), i18n("Less (5px)"), i18n("None (0px)")]
                    
                    onCurrentIndexChanged: {
                        if (currentIndex === 0) configAppearance.cfg_edgeMargin = 10
                        else if (currentIndex === 1) configAppearance.cfg_edgeMargin = 5
                        else if (currentIndex === 2) configAppearance.cfg_edgeMargin = 0
                    }
                }
            }
        }
    }
    
    Component.onCompleted: {
         // Initialize Edge Margin
         var margin = cfg_edgeMargin
         if (margin === 10) edgeMarginCombo.currentIndex = 0
         else if (margin === 5) edgeMarginCombo.currentIndex = 1
         else if (margin === 0) edgeMarginCombo.currentIndex = 2
         else edgeMarginCombo.currentIndex = 0
    }
}
