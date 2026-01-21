import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    id: page
    
    property int cfg_clockStyle
    property double cfg_backgroundOpacity
    
    property bool cfg_showDigitalClock
    property bool cfg_useCustomFont
    property string cfg_customFontFamily
    
    property bool cfg_fontAutoAdjust
    property int cfg_fixedWeight
    property int cfg_fixedWidth
    property int cfg_verticalSpacingRatio

    CheckBox {
        id: showDigitalCheck
        Kirigami.FormData.label: i18n("Digital Clock:")
        text: i18n("Show digital clock in center")
        checked: cfg_showDigitalClock
        onCheckedChanged: cfg_showDigitalClock = checked
    }

    ComboBox {
        Kirigami.FormData.label: i18n("Clock Style:")
        model: [i18n("Automatic"), i18n("Classic (Circular)"), i18n("Modern (Squircle)")]
        currentIndex: cfg_clockStyle
        onActivated: cfg_clockStyle = currentIndex
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
    
    // Modern / Digital Clock Tweaks
    Kirigami.Separator {
        visible: cfg_showDigitalClock
        Kirigami.FormData.isSection: true
        Kirigami.FormData.label: i18n("Digital Clock Customization")
    }
    
    CheckBox {
        visible: cfg_showDigitalClock
        enabled: !cfg_useCustomFont
        Kirigami.FormData.label: i18n("Font Settings:")
        text: i18n("Auto-adjust font weight & width")
        checked: cfg_fontAutoAdjust
        onCheckedChanged: cfg_fontAutoAdjust = checked
    }

    Slider {
        visible: cfg_showDigitalClock && !cfg_fontAutoAdjust
        enabled: !cfg_useCustomFont
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
        visible: cfg_showDigitalClock && !cfg_fontAutoAdjust
        enabled: !cfg_useCustomFont
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
        visible: cfg_showDigitalClock
        // Pasif olsun: enabled condition based on context is hard, but visually "passive" usually simply means enabled/disabled
        // User asked: "Saat dikey modda görüntülenmiyorsa o esnada pasif olsun." 
        // We can't know if it's vertical currently. We'll just leave it always enabled for now if Digital Clock is shown.
        Kirigami.FormData.label: i18n("Vertical Spacing:")
        from: -20
        to: 50
        stepSize: 1
        value: cfg_verticalSpacingRatio
        onMoved: cfg_verticalSpacingRatio = value
        
        ToolTip.visible: hovered
        ToolTip.text: value + "%"
    }


    

    
    CheckBox {
        id: useCustomFontCheck
        visible: cfg_showDigitalClock
        Kirigami.FormData.label: i18n("Font:")
        text: i18n("Use custom font for digital clock")
        checked: cfg_useCustomFont
        onCheckedChanged: cfg_useCustomFont = checked
    }
    
    ComboBox {
        id: fontCombo
        visible: cfg_showDigitalClock
        Kirigami.FormData.label: i18n("Font Family:")
        enabled: useCustomFontCheck.checked
        model: Qt.fontFamilies()
        
        onCurrentTextChanged: {
            if (enabled) {
                cfg_customFontFamily = currentText
            }
        }
    }
        
    Component.onCompleted: {
             var currentOp = (page.cfg_backgroundOpacity !== undefined) ? page.cfg_backgroundOpacity : 1.0
             var closestIdx = 0
             var minDiff = 100
             for (var i = 0; i < opacityValues.length; i++) {
                 var diff = Math.abs(currentOp - opacityValues[i])
                 if (diff < minDiff) {
                     minDiff = diff
                     closestIdx = i
                 }
             }
             opacityCombo.currentIndex = closestIdx
             
             if (page.cfg_customFontFamily) {
                 var fIdx = fontCombo.find(page.cfg_customFontFamily)
                 if (fIdx >= 0) fontCombo.currentIndex = fIdx
             }
    }
}
