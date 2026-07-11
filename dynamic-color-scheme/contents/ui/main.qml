import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.plasma5support as Plasma5Support
import "logic.js" as Logic

PlasmoidItem {
    id: root
    
    Layout.preferredWidth: Kirigami.Units.gridUnit * 12
    Layout.preferredHeight: Kirigami.Units.gridUnit * 8

    property string currentPhase: ""
    property var sunTimes: ({})
    property date lastUpdate: new Date(0)

    function update() {
        const now = new Date();
        const currentTime = now.getHours() + now.getMinutes() / 60;
        
        let phase = "";
        
        if (plasmoid.configuration.trigger === 2) { // Sun Position
            if (now.getDate() !== lastUpdate.getDate()) {
                sunTimes = Logic.getSunTimes(now, plasmoid.configuration.latitude, plasmoid.configuration.longitude);
                lastUpdate = now;
            }
            
            const sunrise = sunTimes.sunrise || 6;
            const sunset = sunTimes.sunset || 18;
            const noon = sunTimes.noon || 12;
            
            if (plasmoid.configuration.mode === 0) { // 2-Mode
                if (currentTime >= sunrise && currentTime < sunset) {
                    phase = "light";
                } else {
                    phase = "dark";
                }
            } else { // 4-Mode
                if (currentTime >= sunrise && currentTime < noon) {
                    phase = "morning";
                } else if (currentTime >= noon && currentTime < sunset) {
                    phase = "noon";
                } else if (currentTime >= sunset && currentTime < sunset + 2) {
                    phase = "evening";
                } else {
                    phase = "night";
                }
            }
        } else if (plasmoid.configuration.trigger === 1) { // Time Based
            const tMorning = Logic.parseManualTime(plasmoid.configuration.timeMorning);
            const tNoon = Logic.parseManualTime(plasmoid.configuration.timeNoon);
            const tEvening = Logic.parseManualTime(plasmoid.configuration.timeEvening);
            const tNight = Logic.parseManualTime(plasmoid.configuration.timeNight);
            
            if (plasmoid.configuration.mode === 0) { // 2-Mode
                if (currentTime >= tMorning && currentTime < tEvening) {
                    phase = "light";
                } else {
                    phase = "dark";
                }
            } else { // 4-Mode
                if (currentTime >= tMorning && currentTime < tNoon) {
                    phase = "morning";
                } else if (currentTime >= tNoon && currentTime < tEvening) {
                    phase = "noon";
                } else if (currentTime >= tEvening && currentTime < tNight) {
                    phase = "evening";
                } else {
                    phase = "night";
                }
            }
        }
        
        if (phase !== "" && phase !== currentPhase) {
            applyPhase(phase);
        }
    }

    function applyPhase(phase) {
        currentPhase = phase;
        let scheme = "";
        let konsole = "";
        
        if (plasmoid.configuration.mode === 0) { // 2-Mode
            if (phase === "light") {
                scheme = plasmoid.configuration.schemeLight;
                konsole = plasmoid.configuration.konsoleLight;
            } else {
                scheme = plasmoid.configuration.schemeDark;
                konsole = plasmoid.configuration.konsoleDark;
            }
        } else { // 4-Mode
            if (phase === "morning") {
                scheme = plasmoid.configuration.schemeMorning;
                konsole = plasmoid.configuration.konsoleMorning;
            } else if (phase === "noon") {
                scheme = plasmoid.configuration.schemeNoon;
                konsole = plasmoid.configuration.konsoleNoon;
            } else if (phase === "evening") {
                scheme = plasmoid.configuration.schemeEvening;
                konsole = plasmoid.configuration.konsoleEvening;
            } else {
                scheme = plasmoid.configuration.schemeNight;
                konsole = plasmoid.configuration.konsoleNight;
            }
        }
        
        if (scheme !== "") {
            runCommand("plasma-apply-colorscheme " + scheme);
        }
        
        if (konsole !== "") {
            // Set default profile
            runCommand("kwriteconfig6 --file konsolerc --group 'Desktop Entry' --key DefaultProfile " + konsole + ".profile");
            // Try to update open sessions (best effort)
            runCommand("for i in $(qdbus | grep org.kde.konsole- | cut -d' ' -f1); do for s in $(qdbus $i | grep /Sessions/); do qdbus $i $s setProfile " + konsole + "; done; done");
        }
    }

    Plasma5Support.DataSource {
        id: executable
        engine: "executable"
        connectedSources: []
        onNewData: function(source, data) {
            disconnectSource(source)
        }
    }

    function runCommand(cmd) {
        executable.connectSource(cmd);
    }

    Timer {
        id: updateTimer
        interval: 60000 
        running: plasmoid.configuration.trigger !== 0
        repeat: true
        triggeredOnStart: true
        onTriggered: root.update()
    }

    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: i18n("Light")
            icon.name: "weather-clear"
            checkable: true
            checked: currentPhase === "light"
            visible: plasmoid.configuration.mode === 0
            onTriggered: applyPhase("light")
        },
        PlasmaCore.Action {
            text: i18n("Dark")
            icon.name: "weather-clear-night"
            checkable: true
            checked: currentPhase === "dark"
            visible: plasmoid.configuration.mode === 0
            onTriggered: applyPhase("dark")
        },
        // 4-Mode Actions
        PlasmaCore.Action {
            text: i18n("Morning")
            icon.name: "weather-sunset-up"
            checkable: true
            checked: currentPhase === "morning"
            visible: plasmoid.configuration.mode === 1
            onTriggered: applyPhase("morning")
        },
        PlasmaCore.Action {
            text: i18n("Noon")
            icon.name: "weather-clear"
            checkable: true
            checked: currentPhase === "noon"
            visible: plasmoid.configuration.mode === 1
            onTriggered: applyPhase("noon")
        },
        PlasmaCore.Action {
            text: i18n("Evening")
            icon.name: "weather-sunset-down"
            checkable: true
            checked: currentPhase === "evening"
            visible: plasmoid.configuration.mode === 1
            onTriggered: applyPhase("evening")
        },
        PlasmaCore.Action {
            text: i18n("Night")
            icon.name: "weather-clear-night"
            checkable: true
            checked: currentPhase === "night"
            visible: plasmoid.configuration.mode === 1
            onTriggered: applyPhase("night")
        },
        PlasmaCore.Action {
            text: i18n("Auto Update")
            icon.name: "view-refresh"
            checkable: true
            checked: plasmoid.configuration.trigger !== 0
            onTriggered: {
                plasmoid.configuration.trigger = checked ? 1 : 0;
            }
        }
    ]

    Component.onCompleted: {
        if (plasmoid.configuration.trigger !== 0) {
            update();
        }
    }
    
    function action_toggle() {
        if (plasmoid.configuration.mode === 0) {
            applyPhase(currentPhase === "light" ? "dark" : "light");
        } else {
            const phases = ["morning", "noon", "evening", "night"];
            let idx = phases.indexOf(currentPhase);
            if (idx === -1) idx = 3;
            applyPhase(phases[(idx + 1) % 4]);
        }
    }

    compactRepresentation: Kirigami.Icon {
        source: "preferences-desktop-color"
        width: 32
        height: 32
        
        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            onClicked: root.action_toggle()
        }
        
        PlasmaComponents.ToolTip {
            text: i18n("Dynamic Color Scheme\nCurrent: %1", currentPhase || "Manual")
        }
    }

    fullRepresentation: Item {
        Layout.preferredWidth: Kirigami.Units.gridUnit * 12
        Layout.preferredHeight: Kirigami.Units.gridUnit * 8
        
        ColumnLayout {
            anchors.centerIn: parent
            spacing: Kirigami.Units.smallSpacing
            
            PlasmaComponents.Label {
                text: i18n("Phase: %1", currentPhase.toUpperCase() || i18n("MANUAL"))
                font.bold: true
                Layout.alignment: Qt.AlignHCenter
            }
            
            RowLayout {
                spacing: Kirigami.Units.largeSpacing
                
                PlasmaComponents.Button {
                    icon.name: "arrow-left"
                    onClicked: {
                         const phases = ["morning", "noon", "evening", "night"];
                         let idx = phases.indexOf(currentPhase);
                         if (idx === -1) idx = 0;
                         applyPhase(phases[(idx + 3) % 4]);
                    }
                }
                
                PlasmaComponents.Button {
                    text: i18n("Switch")
                    onClicked: root.action_toggle()
                }
                
                PlasmaComponents.Button {
                    icon.name: "arrow-right"
                    onClicked: {
                         const phases = ["morning", "noon", "evening", "night"];
                         let idx = phases.indexOf(currentPhase);
                         if (idx === -1) idx = 0;
                         applyPhase(phases[(idx + 1) % 4]);
                    }
                }
            }
            
            PlasmaComponents.Label {
                text: i18n("Trigger: %1", ["Manual", "Time", "Sun"][plasmoid.configuration.trigger])
                font.pixelSize: Kirigami.Units.gridUnit * 0.7
                opacity: 0.6
                Layout.alignment: Qt.AlignHCenter
            }
        }
    }
}
