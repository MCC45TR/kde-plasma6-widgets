import QtQuick
import QtQuick.Layouts 1.1
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore

Loader {
    TapHandler {
        property bool wasExpanded: false

        acceptedButtons: Qt.LeftButton

        onPressedChanged: if (pressed) {
            wasExpanded = Plasmoid.expanded;
        }
        onTapped: Plasmoid.expanded = !wasExpanded
    }

    Kirigami.Icon {
        anchors.fill: parent
        source: Qt.resolvedUrl(getIcon())
    }

    function getIcon() {
        // Use the custom Gemini-Kchat icon or user selection
        if (Plasmoid.configuration.panelIcon) {
            return Plasmoid.configuration.panelIcon
        }
        return "internet-chat";
    }
}