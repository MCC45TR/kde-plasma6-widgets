import QtQuick
import QtQuick.Layouts 1.1
import org.kde.kirigami 2.20 as Kirigami
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore

Loader {
    TapHandler {
        property bool wasExpanded: false

        acceptedButtons: Qt.LeftButton

        onPressedChanged: if (pressed) {
            wasExpanded = root.expanded;
        }
        onTapped: root.expanded = !wasExpanded
    }

    Kirigami.Icon {
        anchors.fill: parent
        source: Qt.resolvedUrl(getIcon())
    }

    function getIcon() {
        // Use the custom Gemini-Kchat icon
        return "assets/gemini-kchat-icon.svg";
    }
}