import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: configAppearance
    
    // Config binding
    property string cfg_iconPack
    
    // Model for icon packs
    property var iconPacksModel: ["default", "google_v3", "google_v2", "google_v1"]
    property var iconPacksLabels: ["Default (Colorful SVG)", "Google Weather v3 (Flat SVG)", "Google Weather v2 (Realistic PNG)", "Google Weather v1 (Classic PNG)"]
    
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
            title: i18n("Appearance")
            Layout.fillWidth: true
            
            ColumnLayout {
                anchors.fill: parent
                spacing: 10
                
                Label {
                    text: i18n("Icon Pack:")
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
                    text: iconPackCombo.currentIndex > 1 ? 
                          i18n("Select the visual style for weather icons. (Note: older packs like v1/v2 may have missing icons for some conditions)") : 
                          i18n("Select the visual style for weather icons.")
                    font.pixelSize: 10
                    opacity: 0.7
                    wrapMode: Text.WordWrap // Enable multiline
                    Layout.fillWidth: true
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
