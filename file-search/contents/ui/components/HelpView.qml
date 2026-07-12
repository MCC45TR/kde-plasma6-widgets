import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

Item {
    id: root

    required property color textColor
    required property color accentColor

    // Signal when a help item is clicked
    signal aidSelected(string prefix)

    readonly property var helpItems: [
        { prefix: "timeline:/", desc: i18nd("plasma_applet_com.mcc45tr.filesearch", "Timeline View"), icon: "view-calendar", example: "timeline:/today -> 📅", key: "timeline" },
        { prefix: "app:", desc: i18nd("plasma_applet_com.mcc45tr.filesearch", "Applications"), icon: "applications-all", example: "app:Code -> VS Code", localeBase: "app" },
        { prefix: "file:/", desc: i18nd("plasma_applet_com.mcc45tr.filesearch", "File Path Search"), icon: "folder", example: "file:/home -> 📂", localeBase: "file" },
        { prefix: "gg:", desc: i18nd("plasma_applet_com.mcc45tr.filesearch", "Google Search"), icon: "google", example: "gg:kde -> 🔍 Google", localeBase: "google" },
        { prefix: "dd:", desc: i18nd("plasma_applet_com.mcc45tr.filesearch", "DuckDuckGo Search"), icon: "internet-web-browser", example: "dd:linux -> 🦆 DuckDuckGo", localeBase: "ddg" },
        { prefix: "wp:", desc: i18nd("plasma_applet_com.mcc45tr.filesearch", "Wikipedia Search"), icon: "wikipedia", example: "wp:plasma -> 📖 Wikipedia", localeBase: "wikipedia" },
        { prefix: "b:", desc: i18nd("plasma_applet_com.mcc45tr.filesearch", "Bookmarks"), icon: "bookmarks", example: "b:kde -> 🔖 KDE.org", localeBase: "bookmarks" },
        { prefix: "man:/", desc: i18nd("plasma_applet_com.mcc45tr.filesearch", "Man Pages"), icon: "help-contents", example: "man:ls -> 📄 ls(1)", localeBase: "man" },
        { prefix: "kill ", desc: i18nd("plasma_applet_com.mcc45tr.filesearch", "Kill Process"), icon: "process-stop", example: "kill firefox -> 🚫 Stop Process", key: "kill", runnerDomain: "plasma_runner_kill", runnerKey: "kill" },
        { prefix: "spell ", desc: i18nd("plasma_applet_com.mcc45tr.filesearch", "Spell Check"), icon: "tools-check-spelling", example: "spell hello -> ✅ Correct", key: "spell", runnerDomain: "plasma_runner_spellcheckrunner", runnerKey: "spell" },
        { prefix: "define:", desc: i18nd("plasma_applet_com.mcc45tr.filesearch", "Dictionary Definition"), icon: "accessories-dictionary", example: "define:kernel -> 📕 Definition", runnerDomain: "plasma_runner_krunner_dictionary", runnerKey: "define" },
        { prefix: "unit:", desc: i18nd("plasma_applet_com.mcc45tr.filesearch", "Unit Converter"), icon: "accessories-calculator", example: "10m to cm -> 1000 cm", key: "unit", localeBase: "unit" },
        { prefix: "shell:", desc: i18nd("plasma_applet_com.mcc45tr.filesearch", "Shell Commands"), icon: "utilities-terminal", example: "echo hi -> hi", key: "shell", localeBase: "shell" },
        { prefix: "power:", desc: i18nd("plasma_applet_com.mcc45tr.filesearch", "Power Management"), icon: "system-shutdown", key: "power", localeBase: "power" },
        { prefix: "services:", desc: i18nd("plasma_applet_com.mcc45tr.filesearch", "System Services"), icon: "preferences-system", key: "services", localeBase: "services" },
        { prefix: "#", desc: i18nd("plasma_applet_com.mcc45tr.filesearch", "Unicode Characters"), icon: "character-set", example: "#happy -> 😀", localeBase: "unicode" },
        { prefix: "date:", desc: i18nd("plasma_applet_com.mcc45tr.filesearch", "Date and Time"), icon: "alarm-clock", example: "date: -> 18.01.2026", key: "date", localeBase: "date" },
        { prefix: "rss:", desc: i18nd("plasma_applet_com.mcc45tr.filesearch", "RSS Feeds"), icon: "news-subscribe", example: "rss:kde -> 📰 RSS", localeBase: "rss" },
        { prefix: "weather:", desc: i18nd("plasma_applet_com.mcc45tr.filesearch", "Show current weather"), icon: "weather-many-clouds", example: "weather: -> ⛅ Weather", localeBase: "weather" },
        { prefix: "calendar:", desc: i18nd("plasma_applet_com.mcc45tr.filesearch", "Show calendar"), icon: "view-calendar", example: "calendar: -> 📅 Calendar", localeBase: "Calendar" },
        { prefix: "clock:", desc: i18nd("plasma_applet_com.mcc45tr.filesearch", "Show large clock"), icon: "preferences-system-time", example: "clock: -> ⏰ Clock", localeBase: "clock" },
        { prefix: "help:", desc: i18nd("plasma_applet_com.mcc45tr.filesearch", "Help & Shortcuts"), icon: "help-about", key: "help", localeBase: "help" }
    ]

    Rectangle {
        anchors.fill: parent
        anchors.margins: 0
        color: Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.05)
        radius: 12
        clip: true

        ListView {
            id: helpList
            anchors.fill: parent
            anchors.margins: 8
            model: root.helpItems
            spacing: 4
            boundsBehavior: Flickable.StopAtBounds

            PlasmaComponents.ScrollBar.vertical: PlasmaComponents.ScrollBar {
                active: helpList.moving || helpList.contentHeight > helpList.height
            }

            delegate: Rectangle {
                width: ListView.view.width
                height: 36
                color: helpMouse.containsMouse
                    ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.1)
                    : (model.index % 2 === 0 ? "transparent" : Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.03))
                radius: Kirigami.Units.cornerRadius

                property string displayPrefix: {
                    if (modelData.runnerDomain) {
                        var runnerTrigger = i18nd(modelData.runnerDomain, modelData.runnerKey)
                        return runnerTrigger.toLowerCase() + " "
                    }
                    if (modelData.localeBase) {
                        var loc = i18nd("plasma_applet_com.mcc45tr.filesearch", modelData.localeBase)
                        if (loc) {
                            var suffix = ""
                            if (modelData.prefix.endsWith(":")) suffix = ":"
                            if (modelData.prefix.endsWith(" ")) suffix = " "
                            if (modelData.prefix.endsWith(":/")) suffix = ":/"

                            return (loc + suffix).toLowerCase()
                        }
                    }
                    return modelData.prefix
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 12

                    Kirigami.Icon {
                        source: modelData.icon
                        Layout.preferredWidth: 20
                        Layout.preferredHeight: 20
                        color: root.accentColor
                    }

                    Text {
                        text: displayPrefix
                        font.bold: true
                        font.family: Kirigami.Theme.defaultFont.family
                        font.pixelSize: Kirigami.Theme.defaultFont.pixelSize
                        color: root.textColor
                    }

                    Text {
                        text: "(" + modelData.desc + ")"
                        font.family: Kirigami.Theme.defaultFont.family
                        font.pixelSize: Kirigami.Theme.defaultFont.pixelSize
                        font.italic: true
                        color: Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.6)
                        elide: Text.ElideRight
                    }

                    // Spacer to push example to right
                    Item {
                        Layout.fillWidth: true
                    }

                    Text {
                        text: modelData.example ? i18nd("plasma_applet_com.mcc45tr.filesearch", modelData.example) : ""
                        visible: !!modelData.example
                        font.family: Kirigami.Theme.defaultFont.family
                        font.pixelSize: Kirigami.Theme.defaultFont.pixelSize
                        color: Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.4)
                        horizontalAlignment: Text.AlignRight
                        elide: Text.ElideRight
                    }
                }

                MouseArea {
                    id: helpMouse
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: root.aidSelected(displayPrefix)
                }
            }
        }
    }
}
