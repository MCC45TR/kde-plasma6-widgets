import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

// Shared Plasma-native heading used by pinned, history and result categories.
Rectangle {
    id: root

    required property string categoryName
    property color textColor: Kirigami.Theme.textColor
    property color accentColor: Kirigami.Theme.highlightColor
    property int itemCount: -1
    property bool collapsible: true
    property bool collapsed: false
    property bool showSeparator: true
    property string actionIcon: ""
    property string actionText: ""

    signal toggleRequested()
    signal actionTriggered()

    implicitHeight: Kirigami.Units.gridUnit + Kirigami.Units.smallSpacing
    color: headerMouse.containsMouse && root.collapsible
        ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.1)
        : "transparent"
    radius: Kirigami.Units.cornerRadius

    MouseArea {
        id: headerMouse
        anchors.fill: parent
        anchors.rightMargin: actionButton.visible ? actionButton.width : 0
        enabled: root.collapsible
        hoverEnabled: enabled
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: root.toggleRequested()
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Kirigami.Units.smallSpacing
        anchors.rightMargin: Kirigami.Units.smallSpacing
        spacing: Kirigami.Units.smallSpacing

        Kirigami.Icon {
            visible: root.collapsible
            source: root.collapsed ? "arrow-right" : "arrow-down"
            Layout.preferredWidth: Kirigami.Units.iconSizes.small
            Layout.preferredHeight: Kirigami.Units.iconSizes.small
            color: root.textColor
            opacity: 0.7
        }

        PlasmaComponents.Label {
            text: root.categoryName + (root.itemCount >= 0 ? " (" + root.itemCount + ")" : "")
            font.family: Kirigami.Theme.defaultFont.family
            font.pixelSize: Kirigami.Theme.defaultFont.pixelSize
            font.bold: true
            color: Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.75)
            elide: Text.ElideRight
        }

        Rectangle {
            visible: root.showSeparator
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.2)
        }

        PlasmaComponents.ToolButton {
            id: actionButton
            visible: root.actionIcon.length > 0
            icon.name: root.actionIcon
            text: root.actionText
            display: PlasmaComponents.ToolButton.IconOnly
            Accessible.name: root.actionText
            Layout.preferredWidth: Kirigami.Units.gridUnit + Kirigami.Units.smallSpacing
            Layout.preferredHeight: Layout.preferredWidth
            onClicked: root.actionTriggered()

            PlasmaComponents.ToolTip {
                text: root.actionText
            }
        }
    }
}
