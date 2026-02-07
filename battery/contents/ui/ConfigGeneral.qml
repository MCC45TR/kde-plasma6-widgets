import QtQuick
import QtQuick.Layouts
import QtQuick.Controls 2.15
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasma5support as P5Support

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
    
    // Icon Card Shape - REMOVED (no longer used)
    
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

    // Device Icons Config (combines laptop icon and alternative icons)
    property string cfg_deviceIcons: "default"
    property string cfg_deviceIconsDefault: "default"
    // Keep old properties for backward compatibility
    property string cfg_laptopIcon: cfg_deviceIcons === "alternative" ? "laptoptrusted" : "computer-laptop"
    property bool cfg_useAlternativeIcons: cfg_deviceIcons === "alternative"

    ComboBox {
        id: deviceIconsCombo
        Kirigami.FormData.label: i18n("Device Icons:")
        textRole: "text"
        valueRole: "value"
        model: [
           { text: i18n("Default"), value: "default" },
           { text: i18n("Alternative (Trusted)"), value: "alternative" }
        ]
        
        onActivated: {
             if (currentIndex >= 0) cfg_deviceIcons = model[currentIndex].value
        }
    }
    
    onCfg_deviceIconsChanged: {
        for(var i=0; i<deviceIconsCombo.model.length; i++) {
             if(deviceIconsCombo.model[i].value === cfg_deviceIcons) {
                 if(deviceIconsCombo.currentIndex !== i) deviceIconsCombo.currentIndex = i;
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
           { text: i18n("%1%", 100), value: "full" },
           { text: i18n("%1%", 75), value: "high" },
           { text: i18n("%1%", 50), value: "medium" },
           { text: i18n("%1%", 25), value: "low" },
           { text: i18n("%1%", 0), value: "none" }
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
    
    // Battery Bars Style Config
    property string cfg_batteryBarsStyle: "default"
    property string cfg_batteryBarsStyleDefault: "default"
    // Keep old property for backward compatibility
    property bool cfg_pillGeometry: cfg_batteryBarsStyle === "pill"

    ComboBox {
        id: batteryBarsCombo
        Kirigami.FormData.label: i18n("Battery Bars:")
        textRole: "text"
        valueRole: "value"
        model: [
           { text: i18n("Default (radius based)"), value: "default" },
           { text: i18n("Pill geometry"), value: "pill" }
        ]
        
        onActivated: {
             if (currentIndex >= 0) cfg_batteryBarsStyle = model[currentIndex].value
        }
    }
    
    onCfg_batteryBarsStyleChanged: {
        for(var i=0; i<batteryBarsCombo.model.length; i++) {
             if(batteryBarsCombo.model[i].value === cfg_batteryBarsStyle) {
                 if(batteryBarsCombo.currentIndex !== i) batteryBarsCombo.currentIndex = i;
                 break;
             }
        }
    }
    
    // Power Profile Detection
    property bool hasPowerProfiles: false
    property bool detectionComplete: false
    property int checksCompleted: 0
    
    // P5Support DataSource for executable check
    Loader {
        id: powerProfileCheckLoader
        active: true
        sourceComponent: Component {
            Item {
                id: checker
                
                // Import P5Support via alias
                property var dataSource: P5Support.DataSource {
                    id: checkDataSource
                    engine: "executable"
                    connectedSources: []
                    
                    onNewData: (source, data) => {
                        if (data["exit code"] === 0) {
                            hasPowerProfiles = true
                        }
                        checksCompleted++
                        if (checksCompleted >= 2) {
                            detectionComplete = true
                        }
                        disconnectSource(source)
                    }
                }
                
                Component.onCompleted: {
                    checkDataSource.connectSource("which powerprofilesctl")
                    checkDataSource.connectSource("which tuned-adm")
                }
            }
        }
    }
    
    // Power Profile Warning
    Kirigami.InlineMessage {
        Kirigami.FormData.isSection: true
        Layout.fillWidth: true
        type: Kirigami.MessageType.Warning
        visible: detectionComplete && !hasPowerProfiles
        text: i18n("No power profile management found. Install one of the following packages:\n\n" +
                   "• power-profiles-daemon (Fedora, Ubuntu, Debian, Arch)\n" +
                   "• tuned (Fedora, RHEL, CentOS)\n" +
                   "• tuned-ppd (openSUSE)\n" +
                   "• tlp (All distros - alternative)\n\n" +
                   "Install commands:\n" +
                   "Fedora/RHEL: sudo dnf install power-profiles-daemon\n" +
                   "Ubuntu/Debian: sudo apt install power-profiles-daemon\n" +
                   "Arch: sudo pacman -S power-profiles-daemon\n" +
                   "openSUSE: sudo zypper install tuned-ppd")
    }
}
