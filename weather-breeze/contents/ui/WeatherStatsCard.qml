import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

Kirigami.AbstractCard {
    id: card

    property string label: ""
    property string value: "--"
    property string iconName: ""
    property bool hasData: true
    property color valueColor: Kirigami.Theme.textColor
    property int valueFontSize: Kirigami.Theme.defaultFont.pixelSize + 2

    visible: hasData
    Layout.fillWidth: true
    Layout.minimumWidth: Kirigami.Units.gridUnit * 5
    Layout.preferredHeight: Kirigami.Units.gridUnit * 3.2
    padding: Kirigami.Units.smallSpacing

    contentItem: RowLayout {
        spacing: Kirigami.Units.smallSpacing

        Kirigami.Icon {
            visible: card.iconName.length > 0
            source: card.iconName
            Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
            Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
            color: Kirigami.Theme.textColor
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            PlasmaComponents.Label {
                Layout.fillWidth: true
                text: card.label
                elide: Text.ElideRight
                opacity: 0.7
                font: Kirigami.Theme.smallFont
            }

            PlasmaComponents.Label {
                Layout.fillWidth: true
                text: card.value
                color: card.valueColor
                elide: Text.ElideRight
                font.family: Kirigami.Theme.defaultFont.family
                font.pixelSize: card.valueFontSize
                font.weight: Font.DemiBold
            }
        }
    }
}
