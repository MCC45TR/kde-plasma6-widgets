import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

Item {
    id: wideLayout

    required property var weatherRoot
    readonly property var currentWeather: weatherRoot.currentWeather
    readonly property bool showingDetails: weatherRoot.largeDetailsOpen || weatherRoot.showForecastDetails

    RowLayout {
        anchors.fill: parent
        spacing: Kirigami.Units.smallSpacing
        visible: !wideLayout.showingDetails

        PlasmaComponents.ItemDelegate {
            Layout.fillHeight: true
            Layout.preferredWidth: Math.max(Kirigami.Units.gridUnit * 7.5, wideLayout.width * 0.29)
            hoverEnabled: true
            Accessible.name: i18n("Current weather details")
            onClicked: wideLayout.weatherRoot.largeDetailsOpen = true

            contentItem: ColumnLayout {
                spacing: 0

                Kirigami.Icon {
                    source: wideLayout.weatherRoot.getWeatherIcon(wideLayout.currentWeather)
                    Layout.preferredWidth: Kirigami.Units.iconSizes.large
                    Layout.preferredHeight: Kirigami.Units.iconSizes.large
                    Layout.alignment: Qt.AlignHCenter
                    isMask: false
                }

                PlasmaComponents.Label {
                    Layout.fillWidth: true
                    text: wideLayout.currentWeather ? i18n(wideLayout.currentWeather.condition) : ""
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    opacity: 0.7
                    font: Kirigami.Theme.smallFont
                }

                Kirigami.Heading {
                    Layout.fillWidth: true
                    level: 1
                    text: wideLayout.currentWeather
                          ? Math.round(wideLayout.currentWeather.temp) + (wideLayout.weatherRoot.units === "imperial" ? "°F" : "°C")
                          : "--"
                    horizontalAlignment: Text.AlignHCenter
                    font.family: wideLayout.weatherRoot.activeFont.family
                }

                PlasmaComponents.Label {
                    Layout.fillWidth: true
                    text: wideLayout.currentWeather
                          ? i18n("High %1 · Low %2",
                                 Math.round(wideLayout.currentWeather.temp_max) + "°",
                                 Math.round(wideLayout.currentWeather.temp_min) + "°")
                          : ""
                    horizontalAlignment: Text.AlignHCenter
                    opacity: 0.7
                    font: Kirigami.Theme.smallFont
                }

                Item { Layout.fillHeight: true }

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: Kirigami.Units.smallSpacing

                    Kirigami.Icon {
                        source: "humidity-symbolic"
                        Layout.preferredWidth: Kirigami.Units.iconSizes.small
                        Layout.preferredHeight: Kirigami.Units.iconSizes.small
                    }
                    PlasmaComponents.Label {
                        text: wideLayout.currentWeather && wideLayout.currentWeather.humidity !== undefined
                              ? wideLayout.currentWeather.humidity + "%" : "--"
                        font: Kirigami.Theme.smallFont
                    }
                    Kirigami.Icon {
                        source: "weather-wind"
                        Layout.preferredWidth: Kirigami.Units.iconSizes.small
                        Layout.preferredHeight: Kirigami.Units.iconSizes.small
                    }
                    PlasmaComponents.Label {
                        text: wideLayout.currentWeather && wideLayout.currentWeather.wind_speed !== undefined
                              ? wideLayout.currentWeather.wind_speed : "--"
                        font: Kirigami.Theme.smallFont
                    }
                }
            }
        }

        Kirigami.Separator {
            Layout.fillHeight: true
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Kirigami.Units.smallSpacing

            RowLayout {
                Layout.fillWidth: true

                Kirigami.Heading {
                    Layout.fillWidth: true
                    level: 4
                    text: wideLayout.currentWeather ? wideLayout.currentWeather.location : wideLayout.weatherRoot.location
                    elide: Text.ElideRight
                }

                PlasmaComponents.TabBar {
                    Layout.maximumWidth: wideLayout.width * 0.5
                    currentIndex: wideLayout.weatherRoot.forecastMode ? 1 : 0
                    onCurrentIndexChanged: wideLayout.weatherRoot.forecastMode = currentIndex === 1

                    PlasmaComponents.TabButton {
                        text: i18n("Daily")
                    }
                    PlasmaComponents.TabButton {
                        text: i18n("Hourly")
                    }
                }
            }

            DailyForecastView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                weatherRoot: wideLayout.weatherRoot
                isHourly: wideLayout.weatherRoot.forecastMode
                useTodayLabel: true
                showUnits: wideLayout.weatherRoot.showForecastUnits
                showBackground: true
                itemSpacing: Kirigami.Units.smallSpacing
                cellWidth: Math.max(Kirigami.Units.gridUnit * 4.5,
                                    width / Math.max(1, Math.min(count, 5)))
                cellHeight: height
                flow: GridView.FlowTopToBottom

                onItemClicked: function(data, index, cardRect) {
                    if (wideLayout.weatherRoot.forecastMode || !data.hasDetails) return
                    wideLayout.weatherRoot.selectedForecast = data
                    wideLayout.weatherRoot.showForecastDetails = true
                }
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        visible: wideLayout.weatherRoot.largeDetailsOpen
        spacing: Kirigami.Units.smallSpacing

        RowLayout {
            Layout.fillWidth: true

            Kirigami.Heading {
                Layout.fillWidth: true
                level: 4
                text: i18n("Current Weather")
            }

            PlasmaComponents.ToolButton {
                icon.name: "window-close-symbolic"
                display: PlasmaComponents.ToolButton.IconOnly
                onClicked: wideLayout.weatherRoot.largeDetailsOpen = false
                PlasmaComponents.ToolTip { text: i18n("Close") }
            }
        }

        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: width
            contentHeight: currentDetails.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            PlasmaComponents.ScrollBar.vertical: PlasmaComponents.ScrollBar { }

            WeatherDetailsView {
                id: currentDetails
                width: parent.width
                weatherRoot: wideLayout.weatherRoot
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        visible: wideLayout.weatherRoot.showForecastDetails
        spacing: Kirigami.Units.smallSpacing

        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: width
            contentHeight: forecastDetails.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            PlasmaComponents.ScrollBar.vertical: PlasmaComponents.ScrollBar { }

            ForecastDetailsView {
                id: forecastDetails
                width: parent.width
                weatherRoot: wideLayout.weatherRoot
                forecastData: wideLayout.weatherRoot.selectedForecast
            }
        }
    }
}
