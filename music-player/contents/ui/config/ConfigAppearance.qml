import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Item {
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
    property int cfg_popupLayoutMode
    
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
    property int cfg_popupLayoutModeDefault: 0
    
    // General config (to silence property warnings - handled by ConfigGeneral)
    property string cfg_preferredPlayer
    property string cfg_preferredPlayerDefault: ""
    property bool cfg_showPlayerBadge
    property bool cfg_showPlayerBadgeDefault: false
    
    // Title for tab
    property string title: i18n("Appearance")
    
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
                    

                    onActivated: {
                        if (currentIndex === 0) configAppearance.cfg_edgeMargin = 10
                        else if (currentIndex === 1) configAppearance.cfg_edgeMargin = 5
                        else if (currentIndex === 2) configAppearance.cfg_edgeMargin = 0
                    }

                Label {
                    text: i18n("Background Opacity:")
                    font.bold: true
                }

                ComboBox {
                    id: opacityCombo
                    Layout.fillWidth: true
                    model: ["100%", "90%", "80%", "75%", "50%", "25%", "10%", "5%", "0%"]
                    
                    // Maps index to opacity value
                    property var opacityValues: [1.0, 0.9, 0.8, 0.75, 0.5, 0.25, 0.1, 0.05, 0.0]

                    onActivated: {
                         configAppearance.cfg_backgroundOpacity = opacityValues[currentIndex]
                    }
                }
                }
                
                CheckBox {
                    text: i18n("Show Controls in Panel")
                    checked: configAppearance.cfg_showPanelControls
                    onCheckedChanged: configAppearance.cfg_showPanelControls = checked
                }
            }
        }
        
        GroupBox {
            title: i18n("Panel Settings")
            Layout.fillWidth: true
            
            ColumnLayout {
                width: parent.width
                spacing: 10
                
                Label {
                    text: i18n("Layout Mode:")
                    font.bold: true
                }
                
                ComboBox {
                    id: panelLayoutCombo
                    Layout.fillWidth: true
                    model: [i18n("Left Aligned"), i18n("Right Aligned"), i18n("Centered")]
                    
                    onActivated: configAppearance.cfg_panelLayoutMode = currentIndex
                }
                
                CheckBox {
                    text: i18n("Scroll Text if truncated")
                    checked: configAppearance.cfg_panelScrollingText
                    onCheckedChanged: configAppearance.cfg_panelScrollingText = checked
                }
                
                CheckBox {
                    text: i18n("Dynamic Width (auto-expand to fit text)")
                    checked: configAppearance.cfg_panelDynamicWidth
                    onCheckedChanged: configAppearance.cfg_panelDynamicWidth = checked
                }

                RowLayout {
                    enabled: !configAppearance.cfg_panelDynamicWidth
                    opacity: enabled ? 1.0 : 0.5
                    Label { text: i18n("Max Width (px):") }
                    SpinBox {
                        from: 50
                        to: 1500
                        stepSize: 10
                        value: configAppearance.cfg_panelMaxWidth
                        onValueModified: configAppearance.cfg_panelMaxWidth = value
                    }
                }
                
                RowLayout {
                    enabled: configAppearance.cfg_panelScrollingText
                    Label { text: i18n("Speed:") }
                    ComboBox {
                        id: scrollSpeedCombo
                        Layout.fillWidth: true
                        model: [i18n("Fast"), i18n("Medium"), i18n("Slow")]
                        onActivated: configAppearance.cfg_panelScrollingSpeed = currentIndex
                    }
                }
                
                Label {
                    text: i18n("Displayed Information:")
                    font.bold: true
                }
                
                RowLayout {
                    CheckBox {
                        text: i18n("Show Title")
                        checked: configAppearance.cfg_panelShowTitle
                        onCheckedChanged: configAppearance.cfg_panelShowTitle = checked
                    }
                    CheckBox {
                        text: i18n("Show Artist")
                        checked: configAppearance.cfg_panelShowArtist
                        onCheckedChanged: configAppearance.cfg_panelShowArtist = checked
                    }
                }
                
                Label {
                    text: i18n("Font Size:")
                    font.bold: true
                }
                
                CheckBox {
                    text: i18n("Auto Size based on Panel Height")
                    checked: configAppearance.cfg_panelAutoFontSize
                    onCheckedChanged: configAppearance.cfg_panelAutoFontSize = checked
                }
                
                RowLayout {
                    enabled: !configAppearance.cfg_panelAutoFontSize
                    Label { text: i18n("Size (px):") }
                    SpinBox {
                        from: 12
                        to: 72
                        value: configAppearance.cfg_panelFontSize
                        onValueModified: configAppearance.cfg_panelFontSize = value
                    }
                }
            }
        }
        
        GroupBox {
            title: i18n("View Settings")
            Layout.fillWidth: true
            
            ColumnLayout {
                width: parent.width
                spacing: 10
                
                Label {
                    text: i18n("View Mode:")
                    font.bold: true
                }
                
                ComboBox {
                    id: popupLayoutCombo
                    Layout.fillWidth: true
                    
                    // Check if in panel (2=Horizontal, 3=Vertical)
                    readonly property bool isInPanel: (plasmoid.formFactor === 2 || plasmoid.formFactor === 3)
                    
                    model: isInPanel
                           ? [i18n("Automatic"), i18n("Wide"), i18n("Large")]
                           : [i18n("Automatic"), i18n("Small"), i18n("Wide"), i18n("Large")]
                    
                    onActivated: {
                         // Mapping:
                         // Internal Config: 0=Auto, 1=Small, 2=Wide, 3=Large
                         if (isInPanel) {
                             // Panel Model: 0=Auto, 1=Wide, 2=Large
                             if (currentIndex === 0) configAppearance.cfg_popupLayoutMode = 0
                             else if (currentIndex === 1) configAppearance.cfg_popupLayoutMode = 2
                             else if (currentIndex === 2) configAppearance.cfg_popupLayoutMode = 3
                         } else {
                             // Desktop Model: 0=Auto, 1=Small, 2=Wide, 3=Large
                             configAppearance.cfg_popupLayoutMode = currentIndex
                         }
                    }
                }
            }
        }
    }
    
    function syncSettings() {
         var margin = cfg_edgeMargin
         if (margin === 10) edgeMarginCombo.currentIndex = 0
         else if (margin === 5) edgeMarginCombo.currentIndex = 1
         else if (margin === 0) edgeMarginCombo.currentIndex = 2
         else edgeMarginCombo.currentIndex = 0
         
         panelLayoutCombo.currentIndex = cfg_panelLayoutMode
         
         // Sync Layout Mode
         // Config: 0=Auto, 1=Small, 2=Wide, 3=Large
         var mode = cfg_popupLayoutMode
         var pCombo = popupLayoutCombo
         
         if (pCombo.isInPanel) {
             // Model: 0=Auto, 1=Wide, 2=Large
             if (mode === 2) pCombo.currentIndex = 1 // Wide
             else if (mode === 3) pCombo.currentIndex = 2 // Large
             else pCombo.currentIndex = 0 // Auto (or fallback if Small is set but hidden)
         } else {
             // Model: 0=Auto, 1=Small, 2=Wide, 3=Large
             // Safe guard if mode is out of bounds (though unlikely with int)
             if (mode >= 0 && mode <= 3) pCombo.currentIndex = mode
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
