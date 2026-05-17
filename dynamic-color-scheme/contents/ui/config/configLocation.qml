import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.20 as Kirigami

Item {
    id: page
    
    property alias cfg_latitude: latitudeSpin.value
    property alias cfg_longitude: longitudeSpin.value
    
    property alias cfg_timeMorning: timeMorning.text
    property alias cfg_timeNoon: timeNoon.text
    property alias cfg_timeEvening: timeEvening.text
    property alias cfg_timeNight: timeNight.text

    Kirigami.FormLayout {
        anchors.fill: parent

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            label: i18n("Location (for Sun Position)")
        }

        SpinBox {
            id: latitudeSpin
            Kirigami.FormData.label: i18n("Latitude:")
            from: -9000
            to: 9000
            stepSize: 1
            editable: true
            property real realValue: value / 100
            validator: DoubleValidator { bottom: -90; top: 90 }
            textFromValue: function(value, locale) { return (value / 100).toLocaleString(locale, 'f', 2) }
            valueFromText: function(text, locale) { return Number.fromLocaleString(locale, text) * 100 }
        }

        SpinBox {
            id: longitudeSpin
            Kirigami.FormData.label: i18n("Longitude:")
            from: -18000
            to: 18000
            stepSize: 1
            editable: true
            property real realValue: value / 100
            validator: DoubleValidator { bottom: -180; top: 180 }
            textFromValue: function(value, locale) { return (value / 100).toLocaleString(locale, 'f', 2) }
            valueFromText: function(text, locale) { return Number.fromLocaleString(locale, text) * 100 }
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            label: i18n("Manual Time Thresholds (HH:mm)")
        }

        TextField {
            id: timeMorning
            Kirigami.FormData.label: i18n("Morning Start:")
            placeholderText: "06:00"
        }
        TextField {
            id: timeNoon
            Kirigami.FormData.label: i18n("Noon Start:")
            placeholderText: "12:00"
        }
        TextField {
            id: timeEvening
            Kirigami.FormData.label: i18n("Evening Start:")
            placeholderText: "18:00"
        }
        TextField {
            id: timeNight
            Kirigami.FormData.label: i18n("Night Start:")
            placeholderText: "22:00"
        }
    }
}
