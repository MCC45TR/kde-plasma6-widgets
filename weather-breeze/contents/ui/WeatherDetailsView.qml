import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

ColumnLayout {
    id: detailsView

    property var weatherRoot
    property string weatherProvider: ""
    readonly property var weatherData: weatherRoot ? weatherRoot.currentWeather : null
    readonly property string degreeUnit: weatherRoot && weatherRoot.units === "imperial" ? "°F" : "°C"
    readonly property string speedUnit: weatherRoot && weatherRoot.units === "imperial" ? " mph" : " km/h"

    spacing: Kirigami.Units.smallSpacing

    function has(key) {
        return weatherData && weatherData[key] !== undefined && weatherData[key] !== null
    }

    function timeText(value) {
        if (!value) return "--"
        var date = typeof value === "number" ? new Date(value * 1000) : new Date(value)
        return isNaN(date.getTime()) ? "--" : Qt.formatTime(date, Qt.locale().timeFormat(Locale.ShortFormat))
    }

    function windDirection(degrees) {
        if (degrees === undefined || degrees === null) return "--"
        var names = [i18n("N"), i18n("NE"), i18n("E"), i18n("SE"),
                     i18n("S"), i18n("SW"), i18n("W"), i18n("NW")]
        return names[Math.round(degrees / 45) % 8] + " · " + Math.round(degrees) + "°"
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Kirigami.Units.largeSpacing

        Kirigami.Icon {
            source: detailsView.weatherRoot.getWeatherIcon(detailsView.weatherData)
            Layout.preferredWidth: Kirigami.Units.iconSizes.huge
            Layout.preferredHeight: Kirigami.Units.iconSizes.huge
            isMask: false
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            Kirigami.Heading {
                Layout.fillWidth: true
                level: 3
                text: detailsView.weatherData ? detailsView.weatherData.location : detailsView.weatherRoot.location
                elide: Text.ElideRight
            }

            PlasmaComponents.Label {
                Layout.fillWidth: true
                text: detailsView.weatherData ? i18n(detailsView.weatherData.condition) : ""
                opacity: 0.7
                elide: Text.ElideRight
            }
        }

        ColumnLayout {
            spacing: 0

            Kirigami.Heading {
                Layout.alignment: Qt.AlignRight
                level: 1
                text: detailsView.weatherData ? Math.round(detailsView.weatherData.temp) + detailsView.degreeUnit : "--"
            }

            PlasmaComponents.Label {
                Layout.alignment: Qt.AlignRight
                text: detailsView.weatherData
                      ? i18n("High %1 · Low %2",
                             Math.round(detailsView.weatherData.temp_max) + "°",
                             Math.round(detailsView.weatherData.temp_min) + "°")
                      : ""
                opacity: 0.7
                font: Kirigami.Theme.smallFont
            }
        }
    }

    Kirigami.Separator { Layout.fillWidth: true }

    GridLayout {
        Layout.fillWidth: true
        columns: detailsView.width >= Kirigami.Units.gridUnit * 28 ? 4 : 2
        columnSpacing: Kirigami.Units.smallSpacing
        rowSpacing: Kirigami.Units.smallSpacing

        WeatherStatsCard {
            label: i18n("Feels like")
            value: detailsView.has("feels_like") ? Math.round(detailsView.weatherData.feels_like) + detailsView.degreeUnit : "--"
            iconName: "temperature-symbolic"
            hasData: detailsView.has("feels_like")
        }
        WeatherStatsCard {
            label: i18n("Humidity")
            value: detailsView.has("humidity") ? Math.round(detailsView.weatherData.humidity) + "%" : "--"
            iconName: "humidity-symbolic"
            hasData: detailsView.has("humidity")
        }
        WeatherStatsCard {
            label: i18n("Wind")
            value: detailsView.has("wind_speed") ? detailsView.weatherData.wind_speed + detailsView.speedUnit : "--"
            iconName: "weather-wind"
            hasData: detailsView.has("wind_speed")
        }
        WeatherStatsCard {
            label: i18n("Pressure")
            value: detailsView.has("pressure") ? Math.round(detailsView.weatherData.pressure) + " hPa" : "--"
            iconName: "speedometer"
            hasData: detailsView.has("pressure")
        }
        WeatherStatsCard {
            label: i18n("Cloud cover")
            value: detailsView.has("clouds") ? Math.round(detailsView.weatherData.clouds) + "%" : "--"
            iconName: "weather-clouds"
            hasData: detailsView.has("clouds")
        }
        WeatherStatsCard {
            label: i18n("UV index")
            value: detailsView.has("uv_index") ? detailsView.weatherData.uv_index.toString() : "--"
            iconName: "weather-clear"
            hasData: detailsView.has("uv_index")
            valueColor: detailsView.has("uv_index") && detailsView.weatherData.uv_index >= 6
                        ? Kirigami.Theme.negativeTextColor : Kirigami.Theme.textColor
        }
        WeatherStatsCard {
            label: i18n("Visibility")
            value: detailsView.has("visibility") ? detailsView.weatherData.visibility + " km" : "--"
            iconName: "visibility"
            hasData: detailsView.has("visibility")
        }
        WeatherStatsCard {
            label: i18n("Dew point")
            value: detailsView.has("dew_point") ? Math.round(detailsView.weatherData.dew_point) + detailsView.degreeUnit : "--"
            iconName: "weather-freezing-rain"
            hasData: detailsView.has("dew_point")
        }
        WeatherStatsCard {
            label: i18n("Wind direction")
            value: detailsView.windDirection(detailsView.weatherData ? detailsView.weatherData.wind_deg : undefined)
            iconName: "compass"
            hasData: detailsView.has("wind_deg")
        }
        WeatherStatsCard {
            label: i18n("Sunrise")
            value: detailsView.timeText(detailsView.weatherData ? detailsView.weatherData.sunrise : null)
            iconName: "weather-clear-symbolic"
            hasData: detailsView.has("sunrise")
        }
        WeatherStatsCard {
            label: i18n("Sunset")
            value: detailsView.timeText(detailsView.weatherData ? detailsView.weatherData.sunset : null)
            iconName: "weather-clear-night-symbolic"
            hasData: detailsView.has("sunset")
        }
    }

    PlasmaComponents.Label {
        Layout.alignment: Qt.AlignHCenter
        text: i18n("Click outside to close")
        opacity: 0.55
        font: Kirigami.Theme.smallFont
    }
}
