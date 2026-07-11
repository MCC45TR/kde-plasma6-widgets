import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Item {
    id: configAppearance

    property string title: i18n("Appearance")

    // Config bindings
    property int cfg_edgeMargin
    property int cfg_widgetRadius
    property string cfg_cornerRadius
    property double cfg_backgroundOpacity
    property double cfg_widgetScale
    property int cfg_contentPadding
    property bool cfg_showSeconds
    property int cfg_timeFormat
    property int cfg_dateFormat

    // Default values
    property int cfg_edgeMarginDefault: 10
    property int cfg_widgetRadiusDefault: 20
    property string cfg_cornerRadiusDefault: "normal"
    property double cfg_backgroundOpacityDefault: 1.0
    property double cfg_widgetScaleDefault: 1.0
    property int cfg_contentPaddingDefault: 10

    function getOpacityIndex(val) {
        var bestIdx = 0
        var minDiff = 100
        for (var i = 0; i < opacityCombo.opacityValues.length; i++) {
            var diff = Math.abs(val - opacityCombo.opacityValues[i])
            if (diff < minDiff) {
                minDiff = diff
                bestIdx = i
            }
        }
        return bestIdx
    }

    implicitHeight: mainLayout.implicitHeight

    ColumnLayout {
        id: mainLayout
        anchors.fill: parent
        spacing: Kirigami.Units.largeSpacing

        Kirigami.FormLayout {
            Layout.fillWidth: true

            ComboBox {
                id: edgeMarginCombo
                Kirigami.FormData.label: i18n("Widget Margin:")
                Layout.fillWidth: true
                model: [i18n("Normal (10px)"), i18n("Less (5px)"), i18n("None (0px)")]

                onCurrentIndexChanged: {
                    if (currentIndex === 0) configAppearance.cfg_edgeMargin = 10
                    else if (currentIndex === 1) configAppearance.cfg_edgeMargin = 5
                    else if (currentIndex === 2) configAppearance.cfg_edgeMargin = 0
                }
            }

            ComboBox {
                id: contentPaddingCombo
                Kirigami.FormData.label: i18n("Content Padding:")
                Layout.fillWidth: true
                model: [i18n("None (0px)"), i18n("Less (5px)"), i18n("Medium (10px)"), i18n("More (15px)"), i18n("Most (20px)")]

                property var paddingValues: [0, 5, 10, 15, 20]

                onCurrentIndexChanged: {
                    configAppearance.cfg_contentPadding = paddingValues[currentIndex]
                }
            }

            ComboBox {
                id: cornerRadiusCombo
                Kirigami.FormData.label: i18n("Corner Radius:")
                Layout.fillWidth: true
                model: [i18n("Normal"), i18n("Small"), i18n("Square")]

                onCurrentIndexChanged: {
                    if (currentIndex === 0) configAppearance.cfg_cornerRadius = "normal"
                    else if (currentIndex === 1) configAppearance.cfg_cornerRadius = "small"
                    else if (currentIndex === 2) configAppearance.cfg_cornerRadius = "square"
                }
            }

            ComboBox {
                id: widgetScaleCombo
                Kirigami.FormData.label: i18n("Widget Size:")
                Layout.fillWidth: true
                model: ["1.0x", "1.25x", "1.5x", "1.75x", "2.0x", "2.25x", "2.5x"]

                property var scaleValues: [1.0, 1.25, 1.5, 1.75, 2.0, 2.25, 2.5]

                onCurrentIndexChanged: {
                    configAppearance.cfg_widgetScale = scaleValues[currentIndex]
                }
            }

            Label {
                Layout.fillWidth: true
                text: i18n("Larger sizes help readability on 2K/4K displays.")
                font.pixelSize: Kirigami.Units.gridUnit
                opacity: 0.7
                wrapMode: Text.WordWrap
            }
        }

        Kirigami.Separator {
            Layout.fillWidth: true
        }

        Kirigami.FormLayout {
            Layout.fillWidth: true

            ComboBox {
                id: opacityCombo
                Kirigami.FormData.label: i18n("Background Opacity:")
                Layout.fillWidth: true
                model: ["100%", "75%", "50%", "25%", "10%", "5%", "0%", i18n("0% (No Backgrounds)")]

                property var opacityValues: [1.0, 0.75, 0.5, 0.25, 0.1, 0.05, 0.0, -1.0]

                onCurrentIndexChanged: {
                    configAppearance.cfg_backgroundOpacity = opacityValues[currentIndex]
                }
            }
        }

        Kirigami.Separator {
            Layout.fillWidth: true
        }

        Kirigami.FormLayout {
            Layout.fillWidth: true
            enabled: (plasmoid.formFactor === 2 || plasmoid.formFactor === 3) // 2=Horizontal, 3=Vertical

            Kirigami.Separator {
                Kirigami.FormData.isSection: true
                Kirigami.FormData.label: i18n("Panel Clock Settings")
            }

            CheckBox {
                id: showSecondsCheckbox
                Kirigami.FormData.label: i18n("Seconds:")
                text: i18n("Show seconds")
                checked: configAppearance.cfg_showSeconds
                onCheckedChanged: configAppearance.cfg_showSeconds = checked
            }

            ComboBox {
                id: timeFormatCombo
                Kirigami.FormData.label: i18n("Time Format:")
                Layout.fillWidth: true
                model: [i18n("System Default"), i18n("12-Hour"), i18n("24-Hour")]
                onCurrentIndexChanged: configAppearance.cfg_timeFormat = currentIndex
            }

            ComboBox {
                id: dateFormatCombo
                Kirigami.FormData.label: i18n("Date Format:")
                Layout.fillWidth: true
                model: [i18n("System Default"), "DD.MM.YYYY", "DD/MM/YYYY", "YYYY-MM-DD"]
                onCurrentIndexChanged: configAppearance.cfg_dateFormat = currentIndex
            }
            
            Label {
                visible: !parent.enabled
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                font.pixelSize: Kirigami.Units.smallFont.pixelSize
                opacity: 0.6
                text: i18n("These settings only apply when the widget is placed in a panel.")
            }
        }
    }

    Component.onCompleted: {
        // Initialize Edge Margin
        var margin = cfg_edgeMargin
        if (margin === 10) edgeMarginCombo.currentIndex = 0
        else if (margin === 5) edgeMarginCombo.currentIndex = 1
        else if (margin === 0) edgeMarginCombo.currentIndex = 2
        else edgeMarginCombo.currentIndex = 0

        // Initialize Content Padding
        var padding = (cfg_contentPadding !== undefined) ? cfg_contentPadding : 10
        var paddingIdx = contentPaddingCombo.paddingValues.indexOf(padding)
        contentPaddingCombo.currentIndex = paddingIdx >= 0 ? paddingIdx : 2

        // Initialize Corner Radius
        var radiusMode = cfg_cornerRadius || "normal"
        if (radiusMode === "normal") cornerRadiusCombo.currentIndex = 0
        else if (radiusMode === "small") cornerRadiusCombo.currentIndex = 1
        else if (radiusMode === "square") cornerRadiusCombo.currentIndex = 2
        else cornerRadiusCombo.currentIndex = 0

        // Initialize Widget Scale
        var scale = cfg_widgetScale || 1.0
        var scaleIdx = widgetScaleCombo.scaleValues.indexOf(scale)
        widgetScaleCombo.currentIndex = scaleIdx >= 0 ? scaleIdx : 0

        // Initialize Background Opacity
        var currentOp = (cfg_backgroundOpacity !== undefined) ? cfg_backgroundOpacity : 1.0
        opacityCombo.currentIndex = getOpacityIndex(currentOp)

        // Initialize Clock Settings
        showSecondsCheckbox.checked = cfg_showSeconds || false
        timeFormatCombo.currentIndex = cfg_timeFormat || 0
        dateFormatCombo.currentIndex = cfg_dateFormat || 0
    }
}
