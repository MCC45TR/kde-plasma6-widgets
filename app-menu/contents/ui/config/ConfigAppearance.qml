import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    property int cfg_iconSize
    property bool cfg_showLabelsInTiles
    
    Layout.fillWidth: true
    
    Kirigami.FormLayout {
        ComboBox {
            id: iconSizeBox
            Kirigami.FormData.label: i18n("Icon Size:")
            model: [22, 32, 48, 64, 128]
            
            // Map configuration value to ComboBox index
            currentIndex: {
                let idx = model.indexOf(cfg_iconSize)
                return idx >= 0 ? idx : 2 // Default to 48 (index 2)
            }
            
            // Update configuration value when user selects an option
            onActivated: {
                cfg_iconSize = model[index]
            }
        }
        
        CheckBox {
            id: showLabels
            Kirigami.FormData.label: i18n("Show Text Labels:")
            text: i18n("Show application names inside tiles")
            checked: cfg_showLabelsInTiles
            onToggled: cfg_showLabelsInTiles = checked
        }
    }
}
