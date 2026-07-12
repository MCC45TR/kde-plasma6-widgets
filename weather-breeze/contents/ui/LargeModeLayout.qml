import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import "WeatherService.js" as WeatherService

Item {
    id: largeLayout

    required property var weatherRoot
    readonly property var currentWeather: weatherRoot.currentWeather
    readonly property bool showingDetails: weatherRoot.largeDetailsOpen || weatherRoot.showForecastDetails
    readonly property string degreeUnit: weatherRoot.units === "imperial" ? "°F" : "°C"
    readonly property string speedUnit: weatherRoot.units === "imperial" ? " mph" : " km/h"

    ColumnLayout {
        anchors.fill: parent
        spacing: Kirigami.Units.smallSpacing
        visible: !largeLayout.showingDetails

        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.largeSpacing

            PlasmaComponents.ItemDelegate {
                Layout.fillWidth: true
                Layout.preferredHeight: Kirigami.Units.gridUnit * 6
                hoverEnabled: true
                onClicked: largeLayout.weatherRoot.largeDetailsOpen = true

                contentItem: RowLayout {
                    spacing: Kirigami.Units.largeSpacing

                    Kirigami.Icon {
                        source: largeLayout.weatherRoot.getWeatherIcon(largeLayout.currentWeather)
                        Layout.preferredWidth: Kirigami.Units.iconSizes.huge
                        Layout.preferredHeight: Kirigami.Units.iconSizes.huge
                        isMask: false
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        Kirigami.Heading {
                            Layout.fillWidth: true
                            level: 2
                            text: largeLayout.currentWeather ? largeLayout.currentWeather.location : largeLayout.weatherRoot.location
                            elide: Text.ElideRight
                        }

                        PlasmaComponents.Label {
                            Layout.fillWidth: true
                            text: largeLayout.currentWeather ? i18n(largeLayout.currentWeather.condition) : ""
                            elide: Text.ElideRight
                            opacity: 0.7
                        }

                        PlasmaComponents.Label {
                            Layout.fillWidth: true
                            text: largeLayout.currentWeather
                                  ? i18n("High %1 · Low %2",
                                         Math.round(largeLayout.currentWeather.temp_max) + "°",
                                         Math.round(largeLayout.currentWeather.temp_min) + "°")
                                  : ""
                            opacity: 0.65
                            font: Kirigami.Theme.smallFont
                        }
                    }

                    Kirigami.Heading {
                        level: 1
                        text: largeLayout.currentWeather
                              ? Math.round(largeLayout.currentWeather.temp) + largeLayout.degreeUnit
                              : "--"
                        font.family: largeLayout.weatherRoot.activeFont.family
                    }

                    Kirigami.Icon {
                        source: "go-next-symbolic"
                        Layout.preferredWidth: Kirigami.Units.iconSizes.small
                        Layout.preferredHeight: Kirigami.Units.iconSizes.small
                    }
                }
            }

            PlasmaComponents.ToolButton {
                icon.name: "view-refresh"
                display: PlasmaComponents.ToolButton.IconOnly
                enabled: !largeLayout.weatherRoot.isLoading
                onClicked: largeLayout.weatherRoot.fetchWeatherData()
                PlasmaComponents.ToolTip { text: i18n("Refresh") }
            }
        }

        GridLayout {
            Layout.fillWidth: true
            columns: largeLayout.width >= Kirigami.Units.gridUnit * 24 ? 4 : 2
            columnSpacing: Kirigami.Units.smallSpacing
            rowSpacing: Kirigami.Units.smallSpacing

            WeatherStatsCard {
                label: i18n("Feels like")
                value: largeLayout.currentWeather && largeLayout.currentWeather.feels_like !== undefined
                       ? Math.round(largeLayout.currentWeather.feels_like) + largeLayout.degreeUnit : "--"
                iconName: "temperature-symbolic"
                hasData: largeLayout.currentWeather && largeLayout.currentWeather.feels_like !== undefined
            }
            WeatherStatsCard {
                label: i18n("Humidity")
                value: largeLayout.currentWeather && largeLayout.currentWeather.humidity !== undefined
                       ? Math.round(largeLayout.currentWeather.humidity) + "%" : "--"
                iconName: "humidity-symbolic"
                hasData: largeLayout.currentWeather && largeLayout.currentWeather.humidity !== undefined
            }
            WeatherStatsCard {
                label: i18n("Wind")
                value: largeLayout.currentWeather && largeLayout.currentWeather.wind_speed !== undefined
                       ? largeLayout.currentWeather.wind_speed + largeLayout.speedUnit : "--"
                iconName: "weather-wind"
                hasData: largeLayout.currentWeather && largeLayout.currentWeather.wind_speed !== undefined
            }
            WeatherStatsCard {
                label: i18n("Pressure")
                value: largeLayout.currentWeather && largeLayout.currentWeather.pressure !== undefined
                       ? Math.round(largeLayout.currentWeather.pressure) + " hPa" : "--"
                iconName: "speedometer"
                hasData: largeLayout.currentWeather && largeLayout.currentWeather.pressure !== undefined
            }
        }

        Kirigami.InlineMessage {
            Layout.fillWidth: true
            visible: largeLayout.currentWeather && largeLayout.currentWeather.aqi !== undefined
            type: Kirigami.MessageType.Information
            text: {
                if (!visible) return ""
                var info = WeatherService.getAQIDescription(largeLayout.currentWeather.aqi,
                                                            largeLayout.currentWeather.pm25,
                                                            largeLayout.currentWeather.pm10)
                return info ? i18n("Air quality: %1 (AQI %2)", i18n(info.level), info.aqi) : ""
            }
        }

        RowLayout {
            Layout.fillWidth: true

            Kirigami.Heading {
                Layout.fillWidth: true
                level: 4
                text: largeLayout.weatherRoot.forecastMode ? i18n("Hourly Forecast") : i18n("Daily Forecast")
            }

            PlasmaComponents.TabBar {
                currentIndex: largeLayout.weatherRoot.forecastMode ? 1 : 0
                onCurrentIndexChanged: largeLayout.weatherRoot.forecastMode = currentIndex === 1

                PlasmaComponents.TabButton { text: i18n("Daily") }
                PlasmaComponents.TabButton { text: i18n("Hourly") }
            }
        }

        DailyForecastView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            weatherRoot: largeLayout.weatherRoot
            isHourly: largeLayout.weatherRoot.forecastMode
            useTodayLabel: true
            showUnits: largeLayout.weatherRoot.showForecastUnits
            showBackground: true
            itemSpacing: Kirigami.Units.smallSpacing
            cellWidth: Math.max(Kirigami.Units.gridUnit * 5,
                                width / Math.max(1, Math.min(count, 7)))
            cellHeight: height
            flow: GridView.FlowTopToBottom

            onItemClicked: function(data, index, cardRect) {
                if (largeLayout.weatherRoot.forecastMode || !data.hasDetails) return
                largeLayout.weatherRoot.selectedForecast = data
                largeLayout.weatherRoot.showForecastDetails = true
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        visible: largeLayout.weatherRoot.largeDetailsOpen
        spacing: Kirigami.Units.smallSpacing

        RowLayout {
            Layout.fillWidth: true

            Kirigami.Heading {
                Layout.fillWidth: true
                level: 3
                text: i18n("Current Weather")
            }

            PlasmaComponents.ToolButton {
                icon.name: "window-close-symbolic"
                display: PlasmaComponents.ToolButton.IconOnly
                onClicked: largeLayout.weatherRoot.largeDetailsOpen = false
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
                weatherRoot: largeLayout.weatherRoot
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        visible: largeLayout.weatherRoot.showForecastDetails

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
                weatherRoot: largeLayout.weatherRoot
                forecastData: largeLayout.weatherRoot.selectedForecast
            }
        }
    }
}
