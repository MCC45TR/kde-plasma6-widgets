import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

Item {
    id: smallLayout

    required property var weatherRoot
    readonly property var currentWeather: weatherRoot.currentWeather

    Timer {
        id: autoReturnTimer
        interval: 6500
        onTriggered: pages.currentIndex = 0
    }

    PlasmaComponents.SwipeView {
        id: pages
        anchors.fill: parent
        clip: true

        onCurrentIndexChanged: {
            if (currentIndex === 0) autoReturnTimer.stop()
            else autoReturnTimer.restart()
        }

        Item {
            RowLayout {
                anchors.fill: parent
                anchors.margins: Kirigami.Units.largeSpacing
                spacing: Kirigami.Units.smallSpacing

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 0

                    Kirigami.Heading {
                        Layout.fillWidth: true
                        level: 4
                        text: smallLayout.currentWeather ? smallLayout.currentWeather.location : smallLayout.weatherRoot.location
                        elide: Text.ElideRight
                    }

                    PlasmaComponents.Label {
                        Layout.fillWidth: true
                        text: smallLayout.currentWeather ? i18n(smallLayout.currentWeather.condition) : ""
                        wrapMode: Text.WordWrap
                        maximumLineCount: 2
                        elide: Text.ElideRight
                        opacity: 0.7
                    }

                    Item { Layout.fillHeight: true }

                    Kirigami.Heading {
                        level: 1
                        text: smallLayout.currentWeather
                              ? Math.round(smallLayout.currentWeather.temp) + (smallLayout.weatherRoot.units === "imperial" ? "°F" : "°C")
                              : "--"
                        font.family: smallLayout.weatherRoot.activeFont.family
                    }

                    PlasmaComponents.Label {
                        text: smallLayout.currentWeather
                              ? i18n("High %1 · Low %2",
                                     Math.round(smallLayout.currentWeather.temp_max) + "°",
                                     Math.round(smallLayout.currentWeather.temp_min) + "°")
                              : ""
                        opacity: 0.7
                        font: Kirigami.Theme.smallFont
                    }
                }

                ColumnLayout {
                    Layout.fillHeight: true
                    Layout.preferredWidth: Math.min(smallLayout.width * 0.42, smallLayout.height * 0.55)

                    Kirigami.Icon {
                        source: smallLayout.weatherRoot.getWeatherIcon(smallLayout.currentWeather)
                        Layout.fillWidth: true
                        Layout.preferredHeight: width
                        isMask: false
                    }

                    Item { Layout.fillHeight: true }

                    PlasmaComponents.ToolButton {
                        Layout.alignment: Qt.AlignRight
                        icon.name: "go-next-symbolic"
                        display: PlasmaComponents.ToolButton.IconOnly
                        onClicked: pages.currentIndex = 1
                        PlasmaComponents.ToolTip { text: i18n("Show forecast") }
                    }
                }
            }
        }

        Item {
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Kirigami.Units.smallSpacing
                spacing: Kirigami.Units.smallSpacing

                RowLayout {
                    Layout.fillWidth: true

                    Kirigami.Heading {
                        Layout.fillWidth: true
                        level: 4
                        text: i18n("Daily Forecast")
                    }

                    PlasmaComponents.ToolButton {
                        icon.name: "go-previous-symbolic"
                        display: PlasmaComponents.ToolButton.IconOnly
                        onClicked: pages.currentIndex = 0
                        PlasmaComponents.ToolTip { text: i18n("Back to current weather") }
                    }
                }

                DailyForecastView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    weatherRoot: smallLayout.weatherRoot
                    cellWidth: width
                    cellHeight: Math.max(Kirigami.Units.gridUnit * 3.5, height / 2)
                    isHorizontalLayout: true
                    isHourly: false
                    showUnits: false
                    showBackground: true
                    itemSpacing: Kirigami.Units.smallSpacing
                    flow: GridView.FlowLeftToRight

                    onMovementStarted: autoReturnTimer.stop()
                    onMovementEnded: autoReturnTimer.restart()
                }
            }
        }
    }
}
