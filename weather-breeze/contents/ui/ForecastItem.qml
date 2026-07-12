import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

PlasmaComponents.ItemDelegate {
    id: itemRoot

    required property string label
    required property string iconPath
    required property int temp
    required property bool isHourly
    property bool isHorizontalLayout: false
    property bool showBackground: true
    property string units: "metric"
    property bool showUnits: true
    property string fontFamily: Kirigami.Theme.defaultFont.family
    property var forecastData: null
    property int itemIndex: 0
    property bool hasDetails: forecastData && forecastData.hasDetails === true

    signal forecastClicked(var data, int index, rect cardRect)

    hoverEnabled: true
    enabled: true
    padding: Kirigami.Units.smallSpacing
    background.visible: showBackground || highlighted || hovered
    Accessible.name: label + ", " + temperatureText()
    Accessible.description: hasDetails ? i18n("Open forecast details") : ""

    function temperatureText() {
        return temp + "°" + (showUnits ? (units === "imperial" ? "F" : "C") : "")
    }

    onClicked: {
        if (!hasDetails || !forecastData) return
        var globalPos = mapToGlobal(0, 0)
        forecastClicked(forecastData, itemIndex,
                        Qt.rect(globalPos.x, globalPos.y, width, height))
    }

    contentItem: Loader {
        sourceComponent: itemRoot.isHorizontalLayout ? horizontalContent : verticalContent
    }

    Component {
        id: verticalContent

        ColumnLayout {
            spacing: Kirigami.Units.smallSpacing

            PlasmaComponents.Label {
                Layout.fillWidth: true
                text: itemRoot.label
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                font.weight: Font.DemiBold
            }

            Kirigami.Icon {
                source: itemRoot.iconPath
                Layout.preferredWidth: Kirigami.Units.iconSizes.large
                Layout.preferredHeight: Kirigami.Units.iconSizes.large
                Layout.alignment: Qt.AlignHCenter
                isMask: false
            }

            PlasmaComponents.Label {
                Layout.fillWidth: true
                text: itemRoot.temperatureText()
                horizontalAlignment: Text.AlignHCenter
                font.family: itemRoot.fontFamily
                font.pixelSize: Kirigami.Theme.defaultFont.pixelSize + 3
                font.weight: Font.DemiBold
            }
        }
    }

    Component {
        id: horizontalContent

        RowLayout {
            spacing: Kirigami.Units.smallSpacing

            Kirigami.Icon {
                source: itemRoot.iconPath
                Layout.preferredWidth: Math.min(parent.height, Kirigami.Units.iconSizes.large)
                Layout.preferredHeight: Layout.preferredWidth
                isMask: false
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                PlasmaComponents.Label {
                    Layout.fillWidth: true
                    text: itemRoot.label
                    elide: Text.ElideRight
                    font.weight: Font.DemiBold
                }

                PlasmaComponents.Label {
                    Layout.fillWidth: true
                    text: itemRoot.temperatureText()
                    elide: Text.ElideRight
                    font.family: itemRoot.fontFamily
                    font.pixelSize: Kirigami.Theme.defaultFont.pixelSize + 2
                }
            }

            Kirigami.Icon {
                visible: itemRoot.hasDetails
                source: "go-next-symbolic"
                Layout.preferredWidth: Kirigami.Units.iconSizes.small
                Layout.preferredHeight: Kirigami.Units.iconSizes.small
            }
        }
    }
}
