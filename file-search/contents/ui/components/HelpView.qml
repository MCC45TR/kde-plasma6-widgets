import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.kirigami as Kirigami

Item {
    id: root
    
    required property color textColor
    required property color accentColor
    
    // Signal when a help item is clicked
    signal aidSelected(string prefix)
    
    readonly property var helpItems: [
        { prefix: "timeline:/", desc: i18n("Timeline View"), icon: "view-calendar", example: "timeline:/today -> 📅", key: "timeline" },
        { prefix: "app:", desc: i18n("Applications"), icon: "applications-all", example: "app:Code -> VS Code", localeBase: "app" },
        { prefix: "file:/", desc: i18n("File Path Search"), icon: "folder", example: "file:/home -> 📂", localeBase: "file" },
        { prefix: "gg:", desc: i18n("Google Search"), icon: "google", example: "gg:kde -> 🔍 Google", localeBase: "google" },
        { prefix: "dd:", desc: i18n("DuckDuckGo Search"), icon: "internet-web-browser", example: "dd:linux -> 🦆 DuckDuckGo", localeBase: "ddg" },
        { prefix: "wp:", desc: i18n("Wikipedia Search"), icon: "wikipedia", example: "wp:plasma -> 📖 Wikipedia", localeBase: "wikipedia" },
        { prefix: "b:", desc: i18n("Bookmarks"), icon: "bookmarks", example: "b:kde -> 🔖 KDE.org", localeBase: "bookmarks" },
        { prefix: "man:/", desc: i18n("Man Pages"), icon: "help-contents", example: "man:ls -> 📄 ls(1)", localeBase: "man" },
        { prefix: "kill ", desc: i18n("Kill Process"), icon: "process-stop", example: "kill firefox -> 🚫 Stop Process", key: "kill", localeBase: "kill" },
        { prefix: "spell ", desc: i18n("Spell Check"), icon: "tools-check-spelling", example: "spell hello -> ✅ Correct", key: "spell", localeBase: "spell" },
        { prefix: "define:", desc: i18n("Dictionary Definition"), icon: "accessories-dictionary", example: "define:kernel -> 📕 Definition", localeBase: "define" },
        { prefix: "unit:", desc: i18n("Unit Converter"), icon: "accessories-calculator", example: "10m to cm -> 1000 cm", key: "unit", localeBase: "unit" },
        { prefix: "shell:", desc: i18n("Shell Commands"), icon: "utilities-terminal", example: "echo hi -> hi", key: "shell", localeBase: "shell" },
        { prefix: "power:", desc: i18n("Power Management"), icon: "system-shutdown", key: "power", localeBase: "power" },
        { prefix: "services:", desc: i18n("System Services"), icon: "preferences-system", key: "services", localeBase: "services" },
        { prefix: "#", desc: i18n("Unicode Characters"), icon: "character-set", example: "#happy -> 😀", localeBase: "unicode" },
        { prefix: "date", desc: i18n("Date and Time"), icon: "alarm-clock", example: "date -> 18.01.2026", key: "date", localeBase: "date" },
        { prefix: "help:", desc: i18n("Help & Shortcuts"), icon: "help-about", key: "help", localeBase: "help" }
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
            
            ScrollBar.vertical: ScrollBar {
                active: helpList.moving || helpList.contentHeight > helpList.height
            }
            
            delegate: Rectangle {
                width: ListView.view.width
                height: 36
                color: model.index % 2 === 0 ? "transparent" : Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.03)
                radius: 6
                
                property string displayPrefix: {
                    if (modelData.localeBase) {
                        var loc = i18n(modelData.localeBase)
                        if (loc && loc !== modelData.localeBase) {
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
                        font.pixelSize: 14
                        font.family: "Barlow Condensed" 
                        color: root.textColor
                    }
                    
                    Text {
                        text: "(" + modelData.desc + ")"
                        font.pixelSize: 13
                        font.italic: true
                        font.family: "Barlow Condensed"
                        color: Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.6)
                        elide: Text.ElideRight
                        // Explicitly set alignment and width behavior if needed, 
                        // but with Spacer below, it should stick to left.
                    }
                    
                    // Spacer to push example to right
                    Item { 
                        Layout.fillWidth: true 
                    }
                    
                    Text {
                        text: modelData.example ? i18n(modelData.example) : ""
                        visible: !!modelData.example
                        font.pixelSize: 13
                        font.family: "Barlow Condensed"
                        color: Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.4)
                        horizontalAlignment: Text.AlignRight
                        elide: Text.ElideRight
                    }
                }
                
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onEntered: parent.color = Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.1)
                    onExited: parent.color = model.index % 2 === 0 ? "transparent" : Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.03)
                    onClicked: root.aidSelected(displayPrefix)
                }
            }
        }
    }
}
