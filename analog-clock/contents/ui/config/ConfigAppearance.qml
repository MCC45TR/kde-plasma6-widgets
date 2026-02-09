import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.ScrollablePage {
    id: page
    title: i18n("Appearance")
    
    property int cfg_clockStyle
    property double cfg_backgroundOpacity
    
    property bool cfg_showDigitalClock
    property bool cfg_useCustomFont
    property string cfg_customFontFamily
    
    property bool cfg_fontAutoAdjust
    property int cfg_fixedWeight
    property int cfg_fixedWidth
    property int cfg_verticalSpacingRatio
    property int cfg_edgeMargin
    property int cfg_widgetRadius
    property int cfg_modernDisplayMode
    
    // Default Values (Requested by Environment)
    readonly property int cfg_clockStyleDefault: 2
    readonly property double cfg_backgroundOpacityDefault: 1.0
    readonly property bool cfg_showDigitalClockDefault: false
    readonly property bool cfg_useCustomFontDefault: false
    readonly property string cfg_customFontFamilyDefault: ""
    readonly property bool cfg_fontAutoAdjustDefault: true
    readonly property int cfg_fixedWeightDefault: 400
    readonly property int cfg_fixedWidthDefault: 100
    readonly property int cfg_verticalSpacingRatioDefault: 10
    readonly property int cfg_edgeMarginDefault: 10
    readonly property int cfg_widgetRadiusDefault: 20
    readonly property int cfg_hourMarkerRatioDefault: 0
    readonly property bool cfg_boldHourMarkersDefault: false
    readonly property int cfg_modernDisplayModeDefault: 0
    readonly property double cfg_fontSizeRatioDefault: 1.0
    readonly property double cfg_letterSpacingRatioDefault: 0.0
    
    property int cfg_hourMarkerRatio
    property bool cfg_boldHourMarkers
    property double cfg_fontSizeRatio
    property double cfg_letterSpacingRatio

    Kirigami.FormLayout {
        ComboBox {
            Kirigami.FormData.label: i18n("Clock Style:")
            model: [i18n("Automatic"), i18n("Classic (Circular)"), i18n("Modern (Squircle)")]
            currentIndex: cfg_clockStyle
            onActivated: cfg_clockStyle = currentIndex
        }

        ComboBox {
            visible: cfg_clockStyle === 2
            Kirigami.FormData.label: i18n("Display Mode:")
            model: [i18n("Analog"), i18n("Hybrid"), i18n("Digital")]
            currentIndex: cfg_modernDisplayMode
            onActivated: {
                cfg_modernDisplayMode = currentIndex
                // Keep showDigitalClock sync'd for internal usage if needed/migration
                cfg_showDigitalClock = (currentIndex !== 0)
            }
        }

        ComboBox {
            Kirigami.FormData.label: i18n("Hour Line Length:")
            model: [i18n("1.0x (Default)"), i18n("1.25x"), i18n("1.5x"), i18n("1.75x"), i18n("2.0x")]
            currentIndex: cfg_hourMarkerRatio
            onActivated: cfg_hourMarkerRatio = currentIndex
        }

        CheckBox {
            Kirigami.FormData.label: i18n("Hour Line Thickness:")
            text: i18n("Bold hour markers")
            checked: cfg_boldHourMarkers
            onCheckedChanged: cfg_boldHourMarkers = checked
        }

        ComboBox {
            id: opacityCombo
            Kirigami.FormData.label: i18n("Background Opacity:")
            
            model: ["100%", "75%", "50%", "25%", "10%", "5%", "0%"]
            property var opacityValues: [1.0, 0.75, 0.5, 0.25, 0.1, 0.05, 0.0]
            
            onCurrentIndexChanged: {
                if (currentIndex >= 0 && currentIndex < opacityValues.length) {
                    page.cfg_backgroundOpacity = opacityValues[currentIndex]
                }
            }
        }

        ComboBox {
            id: edgeMarginCombo
            Kirigami.FormData.label: i18n("Widget Margin:")
            model: [i18n("Normal (10px)"), i18n("Less (5px)"), i18n("None (0px)")]
            
            onActivated: {
                if (currentIndex === 0) page.cfg_edgeMargin = 10
                else if (currentIndex === 1) page.cfg_edgeMargin = 5
                else if (currentIndex === 2) page.cfg_edgeMargin = 0
            }
        }

        ComboBox {
            id: widgetRadiusCombo
            Kirigami.FormData.label: i18n("Widget Radius:")
            model: [i18n("Square (0px)"), i18n("10px"), i18n("20px"), i18n("30px"), i18n("40px"), i18n("50px"), i18n("Full")]
            
            onActivated: {
                if (currentIndex === 0) page.cfg_widgetRadius = 0
                else if (currentIndex === 1) page.cfg_widgetRadius = 10
                else if (currentIndex === 2) page.cfg_widgetRadius = 20
                else if (currentIndex === 3) page.cfg_widgetRadius = 30
                else if (currentIndex === 4) page.cfg_widgetRadius = 40
                else if (currentIndex === 5) page.cfg_widgetRadius = 50
                else if (currentIndex === 6) page.cfg_widgetRadius = -1
            }
        }
        
        // Modern / Digital Clock Tweaks
        Kirigami.Separator {
            visible: cfg_clockStyle === 2 && cfg_modernDisplayMode !== 0
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Digital Clock Customization")
        }
        
        CheckBox {
            visible: cfg_clockStyle === 2 && cfg_modernDisplayMode !== 0
            enabled: !cfg_useCustomFont
            Kirigami.FormData.label: i18n("Font Settings:")
            text: i18n("Auto-adjust font weight & width")
            checked: cfg_fontAutoAdjust
            onCheckedChanged: cfg_fontAutoAdjust = checked
        }

        Slider {
            visible: cfg_clockStyle === 2 && cfg_modernDisplayMode !== 0
            enabled: !cfg_useCustomFont && !cfg_fontAutoAdjust
            Kirigami.FormData.label: i18n("Weight:")
            from: 100
            to: 1000
            stepSize: 10
            value: cfg_fixedWeight
            onMoved: cfg_fixedWeight = value
            
            ToolTip.visible: hovered
            ToolTip.text: value
        }
        
        Slider {
            visible: cfg_clockStyle === 2 && cfg_modernDisplayMode !== 0
            enabled: !cfg_useCustomFont && !cfg_fontAutoAdjust
            Kirigami.FormData.label: i18n("Width:")
            from: 25
            to: 151
            stepSize: 1
            value: cfg_fixedWidth
            onMoved: cfg_fixedWidth = value
            
            ToolTip.visible: hovered
            ToolTip.text: value
        }
        
        Slider {
            visible: cfg_clockStyle === 2 && cfg_modernDisplayMode !== 0
            enabled: !cfg_fontAutoAdjust
            Kirigami.FormData.label: i18n("Vertical Spacing:")
            from: -20
            to: 50
            stepSize: 1
            value: cfg_verticalSpacingRatio
            onMoved: cfg_verticalSpacingRatio = value
            
            ToolTip.visible: hovered
            ToolTip.text: value + "%"
        }

        Slider {
            visible: cfg_clockStyle === 2 && cfg_modernDisplayMode !== 0
            enabled: !cfg_fontAutoAdjust
            Kirigami.FormData.label: i18n("Font Size Scale:")
            from: 0.5
            to: 2.0
            stepSize: 0.1
            value: cfg_fontSizeRatio
            onMoved: cfg_fontSizeRatio = value
            
            ToolTip.visible: hovered
            ToolTip.text: value.toFixed(1) + "x"
        }

        Slider {
            visible: cfg_clockStyle === 2 && cfg_modernDisplayMode !== 0
            enabled: !cfg_fontAutoAdjust
            Kirigami.FormData.label: i18n("Letter Spacing:")
            from: -5.0
            to: 20.0
            stepSize: 0.5
            value: cfg_letterSpacingRatio
            onMoved: cfg_letterSpacingRatio = value
            
            ToolTip.visible: hovered
            ToolTip.text: value + "%"
        }

        CheckBox {
            id: useCustomFontCheck
            visible: cfg_clockStyle === 2 && cfg_modernDisplayMode !== 0
            Kirigami.FormData.label: i18n("Font:")
            text: i18n("Use custom font for digital clock")
            checked: cfg_useCustomFont
            onCheckedChanged: cfg_useCustomFont = checked
        }
        
        ComboBox {
            id: fontCombo
            visible: cfg_clockStyle === 2 && cfg_modernDisplayMode !== 0
            Kirigami.FormData.label: i18n("Font Family:")
            enabled: useCustomFontCheck.checked
            model: Qt.fontFamilies()
            
            onCurrentTextChanged: {
                if (enabled) {
                    cfg_customFontFamily = currentText
                }
            }
        }
    }

    Component.onCompleted: {
          var currentOp = (page.cfg_backgroundOpacity !== undefined) ? page.cfg_backgroundOpacity : 1.0
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
         
         // Initialize Edge Margin
         var margin = page.cfg_edgeMargin !== undefined ? page.cfg_edgeMargin : 10
         if (margin === 10) edgeMarginCombo.currentIndex = 0
         else if (margin === 5) edgeMarginCombo.currentIndex = 1
         else if (margin === 0) edgeMarginCombo.currentIndex = 2
         else edgeMarginCombo.currentIndex = 0
         
         // Initialize Widget Radius
         var radius = page.cfg_widgetRadius !== undefined ? page.cfg_widgetRadius : 20
         if (radius === 0) widgetRadiusCombo.currentIndex = 0
         else if (radius === 10) widgetRadiusCombo.currentIndex = 1
         else if (radius === 20) widgetRadiusCombo.currentIndex = 2
         else if (radius === 30) widgetRadiusCombo.currentIndex = 3
         else if (radius === 40) widgetRadiusCombo.currentIndex = 4
         else if (radius === 50) widgetRadiusCombo.currentIndex = 5
         else if (radius === -1) widgetRadiusCombo.currentIndex = 6
         else widgetRadiusCombo.currentIndex = 2 // Default to 20 if unknown
         
         if (page.cfg_customFontFamily) {
             var fIdx = fontCombo.find(page.cfg_customFontFamily)
             if (fIdx >= 0) fontCombo.currentIndex = fIdx
         }
    }
}
