import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.20 as Kirigami
import org.kde.plasma.plasma5support as Plasma5Support

Item {
    id: page
    width: Kirigami.Units.gridUnit * 30
    height: Kirigami.Units.gridUnit * 25

    property alias cfg_mode: modeCombo.currentIndex
    property alias cfg_trigger: triggerCombo.currentIndex

    property alias cfg_schemeLight: schemeLight.currentText
    property alias cfg_schemeDark: schemeDark.currentText
    
    property alias cfg_schemeNight: schemeNight.currentText
    property alias cfg_schemeMorning: schemeMorning.currentText
    property alias cfg_schemeNoon: schemeNoon.currentText
    property alias cfg_schemeEvening: schemeEvening.currentText

    property alias cfg_konsoleLight: konsoleLight.currentText
    property alias cfg_konsoleDark: konsoleDark.currentText

    property alias cfg_konsoleNight: konsoleNight.currentText
    property alias cfg_konsoleMorning: konsoleMorning.currentText
    property alias cfg_konsoleNoon: konsoleNoon.currentText
    property alias cfg_konsoleEvening: konsoleEvening.currentText

    ListModel { id: colorSchemesModel }
    ListModel { id: konsoleProfilesModel }

    Plasma5Support.DataSource {
        id: executable
        engine: "executable"
        connectedSources: []
        onNewData: function(source, data) {
            var stdout = data["stdout"] || ""
            if (source === "plasma-apply-colorscheme -l") {
                colorSchemesModel.clear()
                var lines = stdout.split("\n")
                for (var i = 0; i < lines.length; i++) {
                    var name = lines[i].replace(/^\* /, "").trim()
                    if (name) colorSchemesModel.append({text: name})
                }
            } else if (source === "konsole --list-profiles") {
                konsoleProfilesModel.clear()
                var lines = stdout.split("\n")
                for (var i = 0; i < lines.length; i++) {
                    var name = lines[i].trim()
                    if (name) konsoleProfilesModel.append({text: name})
                }
            }
            disconnectSource(source)
        }
    }

    Component.onCompleted: {
        executable.connectSource("plasma-apply-colorscheme -l")
        executable.connectSource("konsole --list-profiles")
    }

    Kirigami.FormLayout {
        anchors.fill: parent

        ComboBox {
            id: modeCombo
            Kirigami.FormData.label: i18n("Operation Mode:")
            model: [i18n("2-Mode (Light/Dark)"), i18n("4-Mode (Night/Morning/Noon/Evening)")]
        }

        ComboBox {
            id: triggerCombo
            Kirigami.FormData.label: i18n("Trigger Type:")
            model: [i18n("Manual (Click)"), i18n("Time Based"), i18n("Sun Position")]
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            label: i18n("2-Mode Configuration")
            visible: modeCombo.currentIndex === 0
        }

        ComboBox {
            id: schemeLight
            Kirigami.FormData.label: i18n("Light Color Scheme:")
            model: colorSchemesModel
            textRole: "text"
            visible: modeCombo.currentIndex === 0
            editable: true
        }
        ComboBox {
            id: konsoleLight
            Kirigami.FormData.label: i18n("Light Konsole Profile:")
            model: konsoleProfilesModel
            textRole: "text"
            visible: modeCombo.currentIndex === 0
            editable: true
        }

        ComboBox {
            id: schemeDark
            Kirigami.FormData.label: i18n("Dark Color Scheme:")
            model: colorSchemesModel
            textRole: "text"
            visible: modeCombo.currentIndex === 0
            editable: true
        }
        ComboBox {
            id: konsoleDark
            Kirigami.FormData.label: i18n("Dark Konsole Profile:")
            model: konsoleProfilesModel
            textRole: "text"
            visible: modeCombo.currentIndex === 0
            editable: true
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            label: i18n("4-Mode Configuration")
            visible: modeCombo.currentIndex === 1
        }

        ComboBox {
            id: schemeMorning
            Kirigami.FormData.label: i18n("Morning Scheme:")
            model: colorSchemesModel
            textRole: "text"
            visible: modeCombo.currentIndex === 1
            editable: true
        }
        ComboBox {
            id: konsoleMorning
            Kirigami.FormData.label: i18n("Morning Konsole:")
            model: konsoleProfilesModel
            textRole: "text"
            visible: modeCombo.currentIndex === 1
            editable: true
        }

        ComboBox {
            id: schemeNoon
            Kirigami.FormData.label: i18n("Noon Scheme:")
            model: colorSchemesModel
            textRole: "text"
            visible: modeCombo.currentIndex === 1
            editable: true
        }
        ComboBox {
            id: konsoleNoon
            Kirigami.FormData.label: i18n("Noon Konsole:")
            model: konsoleProfilesModel
            textRole: "text"
            visible: modeCombo.currentIndex === 1
            editable: true
        }

        ComboBox {
            id: schemeEvening
            Kirigami.FormData.label: i18n("Evening Scheme:")
            model: colorSchemesModel
            textRole: "text"
            visible: modeCombo.currentIndex === 1
            editable: true
        }
        ComboBox {
            id: konsoleEvening
            Kirigami.FormData.label: i18n("Evening Konsole:")
            model: konsoleProfilesModel
            textRole: "text"
            visible: modeCombo.currentIndex === 1
            editable: true
        }

        ComboBox {
            id: schemeNight
            Kirigami.FormData.label: i18n("Night Scheme:")
            model: colorSchemesModel
            textRole: "text"
            visible: modeCombo.currentIndex === 1
            editable: true
        }
        ComboBox {
            id: konsoleNight
            Kirigami.FormData.label: i18n("Night Konsole:")
            model: konsoleProfilesModel
            textRole: "text"
            visible: modeCombo.currentIndex === 1
            editable: true
        }
    }
}
