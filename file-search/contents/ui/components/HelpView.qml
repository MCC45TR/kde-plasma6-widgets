import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.kirigami as Kirigami

Item {
    id: root
    
    required property color textColor
    required property color accentColor
    
    // Localization function stub - passed from parent usually, but we might need to rely on system tr or pass it in
    property var trFunc: function(key) { return key }
    
    // Signal when a help item is clicked (optional - maybe to auto-fill search?)
    signal aidSelected(string prefix)
    
    readonly property var helpItems: [
        { prefix: "timeline:/", desc: "hint_timeline", icon: "view-calendar" },
        { prefix: "app:", desc: "hint_applications", icon: "applications-all" },
        { prefix: "file:/", desc: "hint_file_path", icon: "folder" },
        { prefix: "gg:", desc: "hint_google", icon: "google" },
        { prefix: "dd:", desc: "hint_duckduckgo", icon: "internet-web-browser" },
        { prefix: "wp:", desc: "hint_wikipedia", icon: "wikipedia" },
        { prefix: "b:", desc: "hint_bookmarks", icon: "bookmarks" },
        { prefix: "man:/", desc: "hint_man_page", icon: "help-contents" },
        { prefix: "kill ", desc: "hint_kill", icon: "process-stop" },
        { prefix: "spell ", desc: "hint_spell", icon: "tools-check-spelling" },
        { prefix: "define:", desc: "hint_define", icon: "accessories-dictionary" },
        { prefix: "unit:", desc: "hint_unit", icon: "accessories-calculator" },
        { prefix: "shell:", desc: "hint_shell", icon: "utilities-terminal" },
        { prefix: "power:", desc: "hint_power", icon: "system-shutdown" },
        { prefix: "services:", desc: "hint_services", icon: "preferences-system" },
        { prefix: "#", desc: "hint_unicode", icon: "character-set" },
        { prefix: "date", desc: "hint_datetime", icon: "alarm-clock" },
        { prefix: "help:", desc: "hint_help", icon: "help-about" }
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
                        text: modelData.prefix
                        font.bold: true
                        font.pixelSize: 14
                        font.family: "Barlow Condensed" // Consistent with DateView
                        color: root.textColor
                    }
                    
                    Text {
                        text: "(" + (root.trFunc(modelData.desc) || modelData.desc) + ")"
                        font.pixelSize: 13
                        font.italic: true
                        font.family: "Barlow Condensed"
                        color: Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.6)
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }
                }
                
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onEntered: parent.color = Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.1)
                    onExited: parent.color = model.index % 2 === 0 ? "transparent" : Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.03)
                    onClicked: root.aidSelected(modelData.prefix)
                }
            }
        }
    }
}
