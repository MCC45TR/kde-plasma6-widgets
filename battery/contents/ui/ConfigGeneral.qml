import QtQuick
import QtQuick.Layouts
import QtQuick.Controls 2.15
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    
    // Alias to "useCustomIcons" entry in main.xml
    property alias cfg_useCustomIcons: useCustomIcons.checked
    // Config Property (Not alias, because ComboBox.currentValue is usually read-only or tricky to alias directly for writing)
    property string cfg_iconShape: "square"

    CheckBox {
        id: useCustomIcons
        Kirigami.FormData.label: i18n("Behavior:")
        text: i18n("Use custom battery icons")
    }
    
    ComboBox {
        id: shapeCombo
        Kirigami.FormData.label: i18n("Icon Card Shape:")
        
        textRole: "text"
        valueRole: "value"
        
        model: [
            { text: i18n("Adaptive Square (Matches Parent)"), value: "square" },
            { text: i18n("Rounded Square (Fixed 20px)"), value: "rounded" },
            { text: i18n("Circle"), value: "circle" }
        ]
        
        // When user selects a new item, update the config property
        onActivated: {
            if (currentIndex >= 0) {
                cfg_iconShape = model[currentIndex].value
            }
        }
        
        // When binding sets the index, Qt handling ensures sync, but we need initial load logic
    }
    
    // Config -> UI Sync
    // When the config loader sets 'cfg_iconShape', we must update the ComboBox selection
    onCfg_iconShapeChanged: {
        for (var i = 0; i < shapeCombo.model.length; i++) {
            if (shapeCombo.model[i].value === cfg_iconShape) {
                if (shapeCombo.currentIndex !== i) {
                    shapeCombo.currentIndex = i;
                }
                break;
            }
        }
    }
    
    // Edge Margin Config
    property int cfg_edgeMargin: 10
    
    ComboBox {
        id: edgeMarginCombo
        Kirigami.FormData.label: i18n("Widget Margin:")
        textRole: "text"
        valueRole: "value"
        model: [
           { text: i18n("Normal (10px)"), value: 10 },
           { text: i18n("Less (5px)"), value: 5 },
           { text: i18n("None (0px)"), value: 0 }
        ]
        
        onActivated: {
             if (currentIndex >= 0) cfg_edgeMargin = model[currentIndex].value
        }
    }
    
    onCfg_edgeMarginChanged: {
        for(var i=0; i<edgeMarginCombo.model.length; i++) {
             if(edgeMarginCombo.model[i].value === cfg_edgeMargin) {
                 if(edgeMarginCombo.currentIndex !== i) edgeMarginCombo.currentIndex = i;
                 break;
             }
        }
    }
}
