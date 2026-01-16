import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: configAppearance
    
    // Config binding
    property string cfg_iconPack
    
    // Model for icon packs
    property var iconPacksModel: ["default", "flat", "realistic"]
    property var iconPacksLabels: ["Default (Colorful)", "Flat", "Realistic"]
    
    // Load config
    onCfg_iconPackChanged: {
        var idx = iconPacksModel.indexOf(cfg_iconPack)
        if (idx >= 0 && idx !== iconPackCombo.currentIndex) {
            iconPackCombo.currentIndex = idx
        }
    }
    
    ColumnLayout {
        anchors.fill: parent
        spacing: 15
        
        GroupBox {
            title: "Görünüm (Appearance)"
            Layout.fillWidth: true
            
            ColumnLayout {
                anchors.fill: parent
                spacing: 10
                
                Label {
                    text: "İkon Paketi (Icon Pack):"
                    font.bold: true
                }
                
                ComboBox {
                    id: iconPackCombo
                    Layout.fillWidth: true
                    model: iconPacksLabels
                    
                    onCurrentIndexChanged: {
                        configAppearance.cfg_iconPack = iconPacksModel[currentIndex]
                    }
                }
                
                Label {
                    text: "Select the visual style for weather icons."
                    font.pixelSize: 10
                    opacity: 0.7
                }
            }
        }
        
        Item { Layout.fillHeight: true }
    }
    
    Component.onCompleted: {
         // Initial load
         var savedPack = plasmoid.configuration.iconPack || "default"
         var idx = iconPacksModel.indexOf(savedPack)
         if (idx >= 0) iconPackCombo.currentIndex = idx
    }
}
