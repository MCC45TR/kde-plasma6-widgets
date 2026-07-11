import QtQuick
import org.kde.kirigami as Kirigami

Item {
    id: root

    property int cpuTemp: 0
    property int gpuTemp: 0
    property bool isAvailable: false

    implicitWidth: Kirigami.Units.iconSizes.medium
    implicitHeight: Kirigami.Units.iconSizes.medium

    Kirigami.Icon {
        anchors.fill: parent
        source: "laptop-symbolic"
    }
}
