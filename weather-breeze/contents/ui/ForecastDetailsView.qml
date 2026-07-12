import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

ColumnLayout {
    id: view

    property var weatherRoot
    property var forecastData: null
    readonly property string degreeUnit: weatherRoot && weatherRoot.units === "imperial" ? "°F" : "°C"
    readonly property string speedUnit: weatherRoot && weatherRoot.units === "imperial" ? " mph" : " km/h"

    spacing: Kirigami.Units.smallSpacing

    function has(key) {
        return forecastData && forecastData[key] !== undefined && forecastData[key] !== null
    }

    function dateText(data) {
        if (!data) return "--"
        var date = data.timestamp ? new Date(data.timestamp * 1000)
                                  : (data.date ? new Date(data.date) : null)
        if (!date || isNaN(date.getTime())) return data.day || "--"
        var today = new Date()
        today.setHours(0, 0, 0, 0)
        var target = new Date(date)
        target.setHours(0, 0, 0, 0)
        if (target.getTime() === today.getTime()) return i18n("Today")
        return Qt.formatDate(target, Qt.locale().dateFormat(Locale.LongFormat))
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
            source: view.weatherRoot.getWeatherIcon(view.forecastData)
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
                text: view.dateText(view.forecastData)
                elide: Text.ElideRight
            }

            PlasmaComponents.Label {
                Layout.fillWidth: true
                text: view.forecastData ? i18n(view.forecastData.condition) : ""
                opacity: 0.7
                elide: Text.ElideRight
            }
        }

        ColumnLayout {
            spacing: 0

            Kirigami.Heading {
                Layout.alignment: Qt.AlignRight
                level: 1
                text: view.forecastData ? Math.round(view.forecastData.temp) + view.degreeUnit : "--"
            }

            PlasmaComponents.Label {
                Layout.alignment: Qt.AlignRight
                text: view.forecastData
                      ? i18n("High %1 · Low %2",
                             Math.round(view.forecastData.temp_max) + "°",
                             Math.round(view.forecastData.temp_min) + "°")
                      : ""
                opacity: 0.7
                font: Kirigami.Theme.smallFont
            }
        }
    }

    Kirigami.Separator { Layout.fillWidth: true }

    GridLayout {
        Layout.fillWidth: true
        columns: view.width >= Kirigami.Units.gridUnit * 28 ? 4 : 2
        columnSpacing: Kirigami.Units.smallSpacing
        rowSpacing: Kirigami.Units.smallSpacing

        WeatherStatsCard {
            label: i18n("Feels like")
            value: view.has("feels_like") ? Math.round(view.forecastData.feels_like) + view.degreeUnit : "--"
            iconName: "temperature-symbolic"
            hasData: view.has("feels_like")
        }
        WeatherStatsCard {
            label: i18n("Humidity")
            value: view.has("humidity") ? Math.round(view.forecastData.humidity) + "%" : "--"
            iconName: "humidity-symbolic"
            hasData: view.has("humidity")
        }
        WeatherStatsCard {
            label: i18n("Wind")
            value: view.has("wind_speed") ? view.forecastData.wind_speed + view.speedUnit : "--"
            iconName: "weather-wind"
            hasData: view.has("wind_speed")
        }
        WeatherStatsCard {
            label: i18n("Rain chance")
            value: view.has("precipitation_probability") ? Math.round(view.forecastData.precipitation_probability) + "%" : "--"
            iconName: "weather-showers"
            hasData: view.has("precipitation_probability")
        }
        WeatherStatsCard {
            label: i18n("Precipitation")
            value: view.has("precipitation") ? view.forecastData.precipitation + " mm" : "--"
            iconName: "weather-showers-scattered"
            hasData: view.has("precipitation")
        }
        WeatherStatsCard {
            label: i18n("UV index")
            value: view.has("uv_index") ? view.forecastData.uv_index.toString() : "--"
            iconName: "weather-clear"
            hasData: view.has("uv_index")
            valueColor: view.has("uv_index") && view.forecastData.uv_index >= 6
                        ? Kirigami.Theme.negativeTextColor : Kirigami.Theme.textColor
        }
        WeatherStatsCard {
            label: i18n("Wind direction")
            value: view.windDirection(view.forecastData ? view.forecastData.wind_deg : undefined)
            iconName: "compass"
            hasData: view.has("wind_deg")
        }
        WeatherStatsCard {
            label: i18n("Sunrise")
            value: view.timeText(view.forecastData ? view.forecastData.sunrise : null)
            iconName: "weather-clear-symbolic"
            hasData: view.has("sunrise")
        }
        WeatherStatsCard {
            label: i18n("Sunset")
            value: view.timeText(view.forecastData ? view.forecastData.sunset : null)
            iconName: "weather-clear-night-symbolic"
            hasData: view.has("sunset")
        }
    }

    PlasmaComponents.Button {
        Layout.fillWidth: true
        icon.name: "go-previous-symbolic"
        text: i18n("Back to forecast")
        onClicked: view.weatherRoot.showForecastDetails = false
    }
}
