import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    id: configAppearance
    
    // Config binding
    property int cfg_edgeMargin
    property double cfg_backgroundOpacity
    property bool cfg_showPanelControls
    property bool cfg_panelShowTitle
    property bool cfg_panelShowArtist
    property bool cfg_panelAutoFontSize
    property bool cfg_panelScrollingText
    property int cfg_panelMaxWidth
    property int cfg_panelScrollingSpeed
    property int cfg_panelFontSize
    property int cfg_panelLayoutMode
    property bool cfg_panelDynamicWidth
    property bool cfg_panelAutoButtonSize
    property int cfg_panelButtonSize
    property int cfg_popupLayoutMode
    property bool cfg_showShuffleButton
    property bool cfg_showLoopButton
    property bool cfg_showSeekButtons
    
    // Default values (required for Defaults button)
    property int cfg_edgeMarginDefault: 10
    property double cfg_backgroundOpacityDefault: 1.0
    property bool cfg_showPanelControlsDefault: true
    property bool cfg_panelShowTitleDefault: true
    property bool cfg_panelShowArtistDefault: true
    property bool cfg_panelAutoFontSizeDefault: true
    property bool cfg_panelScrollingTextDefault: true
    property int cfg_panelMaxWidthDefault: 350
    property int cfg_panelScrollingSpeedDefault: 0
    property int cfg_panelFontSizeDefault: 12
    property int cfg_panelLayoutModeDefault: 0
    property bool cfg_panelDynamicWidthDefault: true
    property bool cfg_panelAutoButtonSizeDefault: true
    property int cfg_panelButtonSizeDefault: 32
    property int cfg_popupLayoutModeDefault: 0
    property bool cfg_showShuffleButtonDefault: false
    property bool cfg_showLoopButtonDefault: false
    property bool cfg_showSeekButtonsDefault: true
    
    // General config (to silence property warnings - handled by ConfigGeneral)
    property string cfg_preferredPlayer
    property string cfg_preferredPlayerDefault: ""
    property bool cfg_showPlayerBadge
    property bool cfg_showPlayerBadgeDefault: false
    
    // Title for tab
    property string title: i18n("Appearance")
    
    // Appearance Section
    Kirigami.Separator {
        Kirigami.FormData.isSection: true
        Kirigami.FormData.label: i18n("Appearance")
    }
    
    ComboBox {
        id: edgeMarginCombo
        Kirigami.FormData.label: i18n("Widget Margin") + ":"
        Layout.fillWidth: true
        model: [i18n("Normal (10px)"), i18n("Less (5px)"), i18n("None (0px)")]
        
        onActivated: {
            if (currentIndex === 0) configAppearance.cfg_edgeMargin = 10
            else if (currentIndex === 1) configAppearance.cfg_edgeMargin = 5
            else if (currentIndex === 2) configAppearance.cfg_edgeMargin = 0
        }
    }

    ComboBox {
        id: opacityCombo
        Kirigami.FormData.label: i18n("Background Opacity") + ":"
        Layout.fillWidth: true
        model: ["100%", "90%", "80%", "75%", "50%", "25%", "10%", "5%", "0%"]
        
        property var opacityValues: [1.0, 0.9, 0.8, 0.75, 0.5, 0.25, 0.1, 0.05, 0.0]

        onActivated: {
             configAppearance.cfg_backgroundOpacity = opacityValues[currentIndex]
        }
    }
    
    CheckBox {
        Kirigami.FormData.label: i18n("Controls") + ":"
        text: i18n("Show Controls in Panel")
        checked: configAppearance.cfg_showPanelControls
        onCheckedChanged: configAppearance.cfg_showPanelControls = checked
    }
    
    // Panel Settings Section
    Kirigami.Separator {
        Kirigami.FormData.isSection: true
        Kirigami.FormData.label: i18n("Panel Settings")
    }
    
    ComboBox {
        id: panelLayoutCombo
        Kirigami.FormData.label: i18n("Layout Mode") + ":"
        Layout.fillWidth: true
        model: [i18n("Left Aligned"), i18n("Right Aligned"), i18n("Centered")]
        
        onActivated: configAppearance.cfg_panelLayoutMode = currentIndex
    }
    
    CheckBox {
        Kirigami.FormData.label: i18n("Button Size") + ":"
        text: i18n("Auto Size based on Panel Height")
        checked: configAppearance.cfg_panelAutoButtonSize
        onCheckedChanged: configAppearance.cfg_panelAutoButtonSize = checked
    }
    
    SpinBox {
        Kirigami.FormData.label: i18n("Button Size (px)") + ":"
        enabled: !configAppearance.cfg_panelAutoButtonSize
        from: 16
        to: 128
        value: configAppearance.cfg_panelButtonSize
        onValueModified: configAppearance.cfg_panelButtonSize = value
    }
    
    CheckBox {
        Kirigami.FormData.label: i18n("Text") + ":"
        text: i18n("Scroll Text if truncated")
        checked: configAppearance.cfg_panelScrollingText
        onCheckedChanged: configAppearance.cfg_panelScrollingText = checked
    }
    
    CheckBox {
        text: i18n("Dynamic Width (auto-expand to fit text)")
        checked: configAppearance.cfg_panelDynamicWidth
        onCheckedChanged: configAppearance.cfg_panelDynamicWidth = checked
    }

    SpinBox {
        Kirigami.FormData.label: i18n("Max Width (px)") + ":"
        enabled: !configAppearance.cfg_panelDynamicWidth
        from: 50
        to: 1500
        stepSize: 10
        value: configAppearance.cfg_panelMaxWidth
        onValueModified: configAppearance.cfg_panelMaxWidth = value
    }
    
    ComboBox {
        id: scrollSpeedCombo
        Kirigami.FormData.label: i18n("Scroll Speed") + ":"
        enabled: configAppearance.cfg_panelScrollingText
        Layout.fillWidth: true
        model: [i18n("Fast"), i18n("Medium"), i18n("Slow")]
        onActivated: configAppearance.cfg_panelScrollingSpeed = currentIndex
    }
    
    CheckBox {
        Kirigami.FormData.label: i18n("Displayed Info") + ":"
        text: i18n("Show Title")
        checked: configAppearance.cfg_panelShowTitle
        onCheckedChanged: configAppearance.cfg_panelShowTitle = checked
    }
    
    CheckBox {
        text: i18n("Show Artist")
        checked: configAppearance.cfg_panelShowArtist
        onCheckedChanged: configAppearance.cfg_panelShowArtist = checked
    }
    
    CheckBox {
        Kirigami.FormData.label: i18n("Font Size") + ":"
        text: i18n("Auto Size based on Panel Height")
        checked: configAppearance.cfg_panelAutoFontSize
        onCheckedChanged: configAppearance.cfg_panelAutoFontSize = checked
    }
    
    SpinBox {
        Kirigami.FormData.label: i18n("Font Size (px)") + ":"
        enabled: !configAppearance.cfg_panelAutoFontSize
        from: 12
        to: 72
        value: configAppearance.cfg_panelFontSize
        onValueModified: configAppearance.cfg_panelFontSize = value
    }
    
    // View Settings Section
    Kirigami.Separator {
        Kirigami.FormData.isSection: true
        Kirigami.FormData.label: i18n("View Settings")
    }
    
    ComboBox {
        id: popupLayoutCombo
        Kirigami.FormData.label: i18n("View Mode") + ":"
        Layout.fillWidth: true
        
        // Check if in panel (2=Horizontal, 3=Vertical)
        readonly property bool isInPanel: (plasmoid.formFactor === 2 || plasmoid.formFactor === 3)
        
        model: isInPanel
               ? [i18n("Automatic"), i18n("Wide"), i18n("Large"), i18n("Extra Large")]
               : [i18n("Automatic"), i18n("Small"), i18n("Wide"), i18n("Large"), i18n("Extra Large")]
        
        onActivated: {
             // Mapping:
             // Internal Config: 0=Auto, 1=Small, 2=Wide, 3=Large, 4=ExtraLarge
             if (isInPanel) {
                 // Panel Model: 0=Auto, 1=Wide, 2=Large, 3=ExtraLarge
                 if (currentIndex === 0) configAppearance.cfg_popupLayoutMode = 0
                 else if (currentIndex === 1) configAppearance.cfg_popupLayoutMode = 2
                 else if (currentIndex === 2) configAppearance.cfg_popupLayoutMode = 3
                 else if (currentIndex === 3) configAppearance.cfg_popupLayoutMode = 4
             } else {
                 // Desktop Model: 0=Auto, 1=Small, 2=Wide, 3=Large, 4=ExtraLarge
                 configAppearance.cfg_popupLayoutMode = currentIndex
             }
        }
    }
    
    // Extra Large Mode specific settings
    Label {
        text: i18n("Extra Large Mode Buttons:")
        opacity: isExtraLargeMode ? 1.0 : 0.5
        
        // Check if Extra Large mode is selected (4) or Auto mode on panel (0 with panel)
        readonly property bool isExtraLargeMode: {
            var mode = configAppearance.cfg_popupLayoutMode
            if (mode === 4) return true
            if (mode === 0 && popupLayoutCombo.isInPanel) return true
            return false
        }
    }
    
    CheckBox {
        text: i18n("Shuffle Button") + " (" + i18n("not working") + ")"
        checked: configAppearance.cfg_showShuffleButton
        onCheckedChanged: configAppearance.cfg_showShuffleButton = checked
        enabled: {
            var mode = configAppearance.cfg_popupLayoutMode
            if (mode === 4) return true
            if (mode === 0 && popupLayoutCombo.isInPanel) return true
            return false
        }
        opacity: enabled ? 1.0 : 0.5
    }
    
    CheckBox {
        text: i18n("Loop/Repeat Button") + " (" + i18n("not working") + ")"
        checked: configAppearance.cfg_showLoopButton
        onCheckedChanged: configAppearance.cfg_showLoopButton = checked
        enabled: {
            var mode = configAppearance.cfg_popupLayoutMode
            if (mode === 4) return true
            if (mode === 0 && popupLayoutCombo.isInPanel) return true
            return false
        }
        opacity: enabled ? 1.0 : 0.5
    }
    
    CheckBox {
        text: i18n("10-Second Seek Buttons")
        checked: configAppearance.cfg_showSeekButtons
        onCheckedChanged: configAppearance.cfg_showSeekButtons = checked
        enabled: {
            var mode = configAppearance.cfg_popupLayoutMode
            if (mode === 4) return true
            if (mode === 0 && popupLayoutCombo.isInPanel) return true
            return false
        }
        opacity: enabled ? 1.0 : 0.5
    }
    
    function syncSettings() {
         var margin = cfg_edgeMargin
         if (margin === 10) edgeMarginCombo.currentIndex = 0
         else if (margin === 5) edgeMarginCombo.currentIndex = 1
         else if (margin === 0) edgeMarginCombo.currentIndex = 2
         else edgeMarginCombo.currentIndex = 0
         
         panelLayoutCombo.currentIndex = cfg_panelLayoutMode
         
         // Sync Layout Mode
         var mode = cfg_popupLayoutMode
         var pCombo = popupLayoutCombo
         
         if (pCombo.isInPanel) {
             if (mode === 2) pCombo.currentIndex = 1 // Wide
             else if (mode === 3) pCombo.currentIndex = 2 // Large
             else if (mode === 4) pCombo.currentIndex = 3 // ExtraLarge
             else pCombo.currentIndex = 0 // Auto
         } else {
             if (mode >= 0 && mode <= 4) pCombo.currentIndex = mode
             else pCombo.currentIndex = 0
         }

         // Sync Opacity
         var currentOp = cfg_backgroundOpacity
         var closestIdx = 0
         var minDiff = 100
         for (var i = 0; i < opacityCombo.opacityValues.length; i++) {
             var diff = Math.abs(currentOp - opacityCombo.opacityValues[i])
             if (diff < minDiff) {
                 minDiff = diff
                 closestIdx = i
             }
         }
         opacityCombo.currentIndex = closestIdx
         
         scrollSpeedCombo.currentIndex = cfg_panelScrollingSpeed
    }

    onCfg_edgeMarginChanged: syncSettings()
    onCfg_backgroundOpacityChanged: syncSettings()
    Component.onCompleted: syncSettings()
}
