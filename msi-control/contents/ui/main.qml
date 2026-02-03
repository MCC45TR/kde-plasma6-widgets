import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root
    
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    // preferredRepresentation: compactRepresentation
    // preferredRepresentation: compactRepresentation
    
    // Tooltip for the plasmoid
    // Plasmoid.toolTipMainText: i18n("MSI Control Center")
    // Plasmoid.toolTipSubText: msiModel.isAvailable ? 
    //    i18n("CPU: %1°C | GPU: %2°C", msiModel.cpuTemp, msiModel.gpuTemp) : 
    //    i18n("msi-ec driver not available")
    
    // Data model
    MsiEcModel {
        id: msiModel
        Component.onCompleted: console.log("MsiEcModel loaded in main.qml with id:", msiModel)
    }
    
    // Compact representation (system tray icon)
    compactRepresentation: TrayIcon {
        cpuTemp: msiModel.cpuTemp
        gpuTemp: msiModel.gpuTemp
        isAvailable: msiModel.isAvailable
        
        MouseArea {
            anchors.fill: parent
            onClicked: root.expanded = !root.expanded
        }
    }
    
    // Full representation (popup)
    fullRepresentation: ControlPanel {
        msiModel: msiModel
        Component.onCompleted: console.log("ControlPanel loaded. msiModel is:", msiModel)
        
        Layout.preferredWidth: Kirigami.Units.gridUnit * 22
        Layout.preferredHeight: Kirigami.Units.gridUnit * 28
        Layout.minimumWidth: Kirigami.Units.gridUnit * 18
        Layout.minimumHeight: Kirigami.Units.gridUnit * 24
    }
}
