import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    Plasmoid.icon: "laptop-symbolic"
    toolTipMainText: ""
    toolTipSubText: ""

    MsiEcModel {
        id: msiModel
    }

    // Helper maps (shared with FullRepresentation)
    readonly property var shiftModeInfo: ({
        "eco":     { label: i18n("Eco"),     desc: i18n("Power Saving") },
        "comfort": { label: i18n("Comfort"), desc: i18n("Balanced") },
        "sport":   { label: i18n("Sport"),   desc: i18n("High Performance") },
        "turbo":   { label: i18n("Turbo"),   desc: i18n("Overclocking") }
    })

    readonly property var fanModeInfo: ({
        "auto":     { label: i18n("Auto"),     desc: i18n("Adaptive") },
        "silent":   { label: i18n("Silent"),   desc: i18n("Fan Disabled") },
        "basic":    { label: i18n("Basic"),    desc: i18n("Fixed Speed") },
        "advanced": { label: i18n("Advanced"), desc: i18n("Custom Curve") }
    })

    readonly property var kbdBacklightLabels: [
        i18n("Off"), i18n("Low"), i18n("Mid"), i18n("Full")
    ]

    // ─── Compact: Tray Icon ───
    compactRepresentation: CompactRepresentation {
        cpuTemp: msiModel.cpuTemp
        gpuTemp: msiModel.gpuTemp
        isAvailable: msiModel.isAvailable
        MouseArea {
            anchors.fill: parent
            onClicked: root.expanded = !root.expanded
        }
    }

    // ─── Full: Popup ───
    fullRepresentation: Loader {
        source: "FullRepresentation.qml"
        onLoaded: {
            item.msiModel = Qt.binding(function() { return msiModel })
            item.shiftModeInfo = Qt.binding(function() { return root.shiftModeInfo })
            item.fanModeInfo = Qt.binding(function() { return root.fanModeInfo })
            item.kbdBacklightLabels = Qt.binding(function() { return root.kbdBacklightLabels })
        }
    }
}
