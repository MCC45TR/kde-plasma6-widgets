import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

Item {
    id: configRoot

    property real cfg_minMagnitude
    property alias cfg_timeRange: timeRangeCombo.currentValue
    property alias cfg_limit: limitSpin.value
    property alias cfg_updateInterval: intervalSpin.value

    onCfg_minMagnitudeChanged: {
        if (minMagSpin.value !== Math.round(cfg_minMagnitude * 10)) {
            minMagSpin.value = Math.round(cfg_minMagnitude * 10)
        }
    }

    ScrollView {
        id: scrollView
        anchors.fill: parent
        clip: true

        Kirigami.FormLayout {
            width: scrollView.availableWidth

            PlasmaComponents.SpinBox {
                id: minMagSpin
                Kirigami.FormData.label: i18n("Minimum Magnitude:")
                from: 0
                to: 90
                stepSize: 1
                editable: true
                
                onValueModified: {
                    configRoot.cfg_minMagnitude = value / 10.0
                }
                
                textFromValue: function(value, locale) {
                    return Number(value / 10.0).toLocaleString(locale, 'f', 1);
                }
                
                valueFromText: function(text, locale) {
                    return Math.round(Number.fromLocaleString(locale, text) * 10.0);
                }
            }

            PlasmaComponents.ComboBox {
                id: timeRangeCombo
                Kirigami.FormData.label: i18n("Time Range:")
                model: [
                    { text: i18n("Last 6 Hours"), value: 6 },
                    { text: i18n("Last 12 Hours"), value: 12 },
                    { text: i18n("Last 18 Hours"), value: 18 },
                    { text: i18n("Last 24 Hours"), value: 24 },
                    { text: i18n("Last 36 Hours"), value: 36 },
                    { text: i18n("Last 48 Hours"), value: 48 },
                    { text: i18n("Last 72 Hours"), value: 72 }
                ]
                textRole: "text"
                valueRole: "value"
            }

            PlasmaComponents.SpinBox {
                id: limitSpin
                Kirigami.FormData.label: i18n("Max Reports:")
                from: 10
                to: 500
                stepSize: 10
                editable: true
            }

            PlasmaComponents.SpinBox {
                id: intervalSpin
                Kirigami.FormData.label: i18n("Update Interval (min):")
                from: 1
                to: 120
                stepSize: 1
                editable: true
            }
        }
    }
}
