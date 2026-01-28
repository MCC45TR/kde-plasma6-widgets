import QtQuick
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import QtQuick.Layouts

PlasmoidItem {
    id: root

    // Use full representation for the popup
    fullRepresentation: FullRepresentation {}

    // propertity for configured icon
    readonly property string icon: Plasmoid.configuration.icon || "start-here-kde"

    // Use a simple icon for the panel (compact) representation
    compactRepresentation: MouseArea {
        id: compactRoot
        Layout.minimumWidth: Kirigami.Units.iconSizes.small
        Layout.minimumHeight: Kirigami.Units.iconSizes.small
        Layout.preferredWidth: Layout.minimumWidth
        Layout.preferredHeight: Layout.minimumHeight
        
        property bool expanded: root.expanded

        onClicked: root.expanded = !root.expanded

        Kirigami.Icon {
            anchors.fill: parent
            source: root.icon
            active: compactRoot.containsMouse
        }
    }
    
    // Default to compact representation (panel button)
    preferredRepresentation: compactRepresentation
    
    Plasmoid.icon: root.icon
}
