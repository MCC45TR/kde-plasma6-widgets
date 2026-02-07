import QtQuick
import QtQuick.Layouts
import QtQuick.Controls 2.15
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    
    // Required by Plasma config system - suppress warnings
    property string title: ""
    property bool cfg_useCustomIconsDefault: false
    property string cfg_iconShapeDefault: "square"
    property string cfg_iconVersionDefault: "v1"
    property int cfg_edgeMarginDefault: 10
    property string cfg_laptopIconDefault: "computer-laptop"
    property string cfg_deviceTypeDefault: "laptop"
    property bool cfg_showChargingIconDefault: true
    property string cfg_backgroundOpacityDefault: "full"
    property string cfg_cornerRadiusDefault: "normal"
    
    // Alias to "useCustomIcons" entry in main.xml
    property alias cfg_useCustomIcons: useCustomIcons.checked
    // Config Property (Not alias, because ComboBox.currentValue is usually read-only or tricky to alias directly for writing)
    property string cfg_iconShape: "square"
    property string cfg_iconVersion: "v1"

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

    // Laptop Icon Config
    property string cfg_laptopIcon: "computer-laptop"

    ComboBox {
        id: laptopIconCombo
        Kirigami.FormData.label: i18n("Laptop Icon:")
        textRole: "text"
        valueRole: "value"
        model: [
           { text: "computer-laptop (Default)", value: "computer-laptop" },
           { text: "laptoptrusted (Trusted)", value: "laptoptrusted" }
        ]
        
        onActivated: {
             if (currentIndex >= 0) cfg_laptopIcon = model[currentIndex].value
        }
    }
    
    onCfg_laptopIconChanged: {
        for(var i=0; i<laptopIconCombo.model.length; i++) {
             if(laptopIconCombo.model[i].value === cfg_laptopIcon) {
                 if(laptopIconCombo.currentIndex !== i) laptopIconCombo.currentIndex = i;
                 break;
             }
        }
    }

    // Device Type Config
    property string cfg_deviceType: "laptop"
    
    ComboBox {
        id: deviceTypeCombo
        Kirigami.FormData.label: i18n("Device Type:")
        textRole: "text"
        valueRole: "value"
        model: [
           { text: i18n("Laptop"), value: "laptop" },
           { text: i18n("Desktop"), value: "desktop" }
        ]
        
        onActivated: {
             if (currentIndex >= 0) cfg_deviceType = model[currentIndex].value
        }
    }
    
    onCfg_deviceTypeChanged: {
        for(var i=0; i<deviceTypeCombo.model.length; i++) {
             if(deviceTypeCombo.model[i].value === cfg_deviceType) {
                 if(deviceTypeCombo.currentIndex !== i) deviceTypeCombo.currentIndex = i;
                 break;
             }
        }
    }

    // Charging Icon Config
    property alias cfg_showChargingIcon: showChargingIconCheck.checked
    
    CheckBox {
        id: showChargingIconCheck
        Kirigami.FormData.label: i18n("Display:")
        text: i18n("Show charging indicator icon")
    }
    
    // Background Opacity
    property string cfg_backgroundOpacity: "full"
    
    ComboBox {
        id: opacityCombo
        Kirigami.FormData.label: i18n("Background Opacity:")
        textRole: "text"
        valueRole: "value"
        model: [
           { text: i18n("Full (100%)"), value: "full" },
           { text: i18n("High (75%)"), value: "high" },
           { text: i18n("Medium (50%)"), value: "medium" },
           { text: i18n("Low (25%)"), value: "low" },
           { text: i18n("None (0%)"), value: "none" }
        ]
        
        onActivated: {
             if (currentIndex >= 0) cfg_backgroundOpacity = model[currentIndex].value
        }
    }
    
    onCfg_backgroundOpacityChanged: {
        for(var i=0; i<opacityCombo.model.length; i++) {
             if(opacityCombo.model[i].value === cfg_backgroundOpacity) {
                 if(opacityCombo.currentIndex !== i) opacityCombo.currentIndex = i;
                 break;
             }
        }
    }
    
    // Corner Radius Config
    property string cfg_cornerRadius: "normal"
    
    ComboBox {
        id: cornerRadiusCombo
        Kirigami.FormData.label: i18n("Corner Radius:")
        textRole: "text"
        valueRole: "value"
        model: [
           { text: i18n("Normal (20px)"), value: "normal" },
           { text: i18n("Small (10px)"), value: "small" },
           { text: i18n("Square (0px)"), value: "square" }
        ]
        
        onActivated: {
             if (currentIndex >= 0) cfg_cornerRadius = model[currentIndex].value
        }
    }
    
    onCfg_cornerRadiusChanged: {
        for(var i=0; i<cornerRadiusCombo.model.length; i++) {
             if(cornerRadiusCombo.model[i].value === cfg_cornerRadius) {
                 if(cornerRadiusCombo.currentIndex !== i) cornerRadiusCombo.currentIndex = i;
                 break;
             }
        }
    }
    
    // Pill Geometry
    property alias cfg_pillGeometry: pillGeometryCheck.checked
    property bool cfg_pillGeometryDefault: false
    
    CheckBox {
        id: pillGeometryCheck
        Kirigami.FormData.label: i18n("Battery Bars:")
        text: i18n("Pill geometry mode (radius = height/2)")
    }
}
