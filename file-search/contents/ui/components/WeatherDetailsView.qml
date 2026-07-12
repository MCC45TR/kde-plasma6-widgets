import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

ColumnLayout {
    id: detailsView
    property var weatherRoot
    property string weatherProvider: ""

    spacing: 8

    // --- Header: Icon, Location, Temp ---
    RowLayout {
        Layout.fillWidth: true
        spacing: 10

        Kirigami.Icon {
            source: weatherRoot.getWeatherIcon(weatherRoot.currentWeather)
            Layout.preferredHeight: 50
            Layout.preferredWidth: 50
            smooth: true
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            Text {
                text: weatherRoot.currentWeather ? weatherRoot.currentWeather.location : weatherRoot.location
                color: Kirigami.Theme.textColor
                font.family: weatherRoot.activeFont.family
                font.bold: true
                font.pixelSize: Math.round(Kirigami.Theme.defaultFont.pixelSize * 1.25)
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Text {
                text: weatherRoot.currentWeather ? i18n(weatherRoot.currentWeather.condition) : ""
                textFormat: Text.PlainText
                color: Kirigami.Theme.textColor
                opacity: 0.7
                font.family: Kirigami.Theme.defaultFont.family
                font.pixelSize: Kirigami.Theme.defaultFont.pixelSize
            }
        }

        ColumnLayout {
            spacing: 0

            RowLayout {
                spacing: 0
                Text {
                    text: weatherRoot.currentWeather ? weatherRoot.currentWeather.temp : "--"
                    color: Kirigami.Theme.textColor
                    font.family: weatherRoot.activeFont.family
                    font.bold: true
                    font.pixelSize: Math.round(Kirigami.Theme.defaultFont.pixelSize * 3)
                }
                Text {
                    text: weatherRoot.units === "imperial" ? "°F" : "°C"
                    color: Kirigami.Theme.textColor
                    font.family: weatherRoot.activeFont.family
                    font.bold: true
                    font.pixelSize: Math.round(Kirigami.Theme.defaultFont.pixelSize * 3)
                    Layout.alignment: Qt.AlignTop
                }
            }

            RowLayout {
                spacing: 8
                Layout.alignment: Qt.AlignHCenter
                RowLayout {
                    spacing: 2
                    Text { text: "▲"; color: Kirigami.Theme.positiveTextColor; font: Kirigami.Theme.smallFont }
                    Text { text: weatherRoot.currentWeather ? weatherRoot.currentWeather.temp_max + (weatherRoot.units === "imperial" ? "°F" : "°C") : "--"; color: Kirigami.Theme.textColor; font: Kirigami.Theme.smallFont }
                }
                RowLayout {
                    spacing: 2
                    Text { text: "▼"; color: Kirigami.Theme.negativeTextColor; font: Kirigami.Theme.smallFont }
                    Text { text: weatherRoot.currentWeather ? weatherRoot.currentWeather.temp_min + (weatherRoot.units === "imperial" ? "°F" : "°C") : "--"; color: Kirigami.Theme.textColor; font: Kirigami.Theme.smallFont }
                }
            }
        }
    }

    // --- Row 2: Feels Like, Humidity, Wind Speed, Pressure ---
    RowLayout {
        Layout.fillWidth: true
        spacing: 6

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 45
            radius: 8 * weatherRoot.radiusMultiplier
            color: weatherRoot.showInnerBackgrounds ? Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.05) : "transparent"
            visible: weatherRoot.currentWeather && weatherRoot.currentWeather.feels_like !== undefined

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 1
                Text { text: i18n("Feels like"); color: Kirigami.Theme.textColor; opacity: 0.6; font: Kirigami.Theme.smallFont; Layout.alignment: Qt.AlignHCenter }
                Text {
                    text: (weatherRoot.currentWeather && weatherRoot.currentWeather.feels_like !== undefined) ? weatherRoot.currentWeather.feels_like + "°" : "--"
                    color: Kirigami.Theme.textColor; font.pixelSize: Math.round(Kirigami.Theme.defaultFont.pixelSize * 1.25); font.bold: true; Layout.alignment: Qt.AlignHCenter
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 45
            radius: 8 * weatherRoot.radiusMultiplier
            color: weatherRoot.showInnerBackgrounds ? Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.05) : "transparent"
            visible: weatherRoot.currentWeather && weatherRoot.currentWeather.humidity !== undefined

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 1
                Text { text: "💧 " + i18n("Humidity"); color: Kirigami.Theme.textColor; opacity: 0.6; font: Kirigami.Theme.smallFont; Layout.alignment: Qt.AlignHCenter }
                Text {
                    text: (weatherRoot.currentWeather && weatherRoot.currentWeather.humidity !== undefined) ? weatherRoot.currentWeather.humidity + "%" : "--"
                    color: Kirigami.Theme.textColor; font.pixelSize: Math.round(Kirigami.Theme.defaultFont.pixelSize * 1.25); font.bold: true; Layout.alignment: Qt.AlignHCenter
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 45
            radius: 8 * weatherRoot.radiusMultiplier
            color: weatherRoot.showInnerBackgrounds ? Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.05) : "transparent"
            visible: weatherRoot.currentWeather && weatherRoot.currentWeather.wind_speed !== undefined

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 1
                Text { text: "💨 " + i18n("Wind"); color: Kirigami.Theme.textColor; opacity: 0.6; font: Kirigami.Theme.smallFont; Layout.alignment: Qt.AlignHCenter }
                Text {
                    text: (weatherRoot.currentWeather && weatherRoot.currentWeather.wind_speed !== undefined) ? weatherRoot.currentWeather.wind_speed + (weatherRoot.units === "imperial" ? " mph" : " km/h") : "--"
                    color: Kirigami.Theme.textColor; font.family: Kirigami.Theme.defaultFont.family; font.pixelSize: Kirigami.Theme.defaultFont.pixelSize; font.bold: true; Layout.alignment: Qt.AlignHCenter
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 45
            radius: 8 * weatherRoot.radiusMultiplier
            color: weatherRoot.showInnerBackgrounds ? Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.05) : "transparent"
            visible: weatherRoot.currentWeather && weatherRoot.currentWeather.pressure !== undefined && weatherRoot.currentWeather.pressure !== null

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 1
                Text { text: i18n("Pressure"); color: Kirigami.Theme.textColor; opacity: 0.6; font: Kirigami.Theme.smallFont; Layout.alignment: Qt.AlignHCenter }
                Text {
                    text: (weatherRoot.currentWeather && weatherRoot.currentWeather.pressure !== undefined && weatherRoot.currentWeather.pressure !== null) ? weatherRoot.currentWeather.pressure + " hPa" : "--"
                    color: Kirigami.Theme.textColor; font.family: Kirigami.Theme.smallFont.family; font.pixelSize: Kirigami.Theme.smallFont.pixelSize; font.bold: true; Layout.alignment: Qt.AlignHCenter
                }
            }
        }
    }

    // --- Row 3: Clouds, UV, Visibility, Dew Point ---
    RowLayout {
        Layout.fillWidth: true
        spacing: 6
        visible: {
            var hasData = weatherRoot.currentWeather && (
                weatherRoot.currentWeather.clouds !== undefined ||
                weatherRoot.currentWeather.uv_index !== undefined ||
                weatherRoot.currentWeather.visibility !== undefined ||
                weatherRoot.currentWeather.dew_point !== undefined
            )
            return hasData
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 45
            radius: 8 * weatherRoot.radiusMultiplier
            color: weatherRoot.showInnerBackgrounds ? Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.05) : "transparent"
            visible: weatherRoot.currentWeather && weatherRoot.currentWeather.clouds !== undefined

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 1
                Text { text: "☁️ " + i18n("Cloud Cover"); color: Kirigami.Theme.textColor; opacity: 0.6; font: Kirigami.Theme.smallFont; Layout.alignment: Qt.AlignHCenter }
                Text {
                    text: (weatherRoot.currentWeather && weatherRoot.currentWeather.clouds !== undefined) ? weatherRoot.currentWeather.clouds + "%" : "--"
                    color: Kirigami.Theme.textColor; font.pixelSize: Math.round(Kirigami.Theme.defaultFont.pixelSize * 1.25); font.bold: true; Layout.alignment: Qt.AlignHCenter
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 45
            radius: 8 * weatherRoot.radiusMultiplier
            color: weatherRoot.showInnerBackgrounds ? Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.05) : "transparent"
            visible: weatherRoot.currentWeather && weatherRoot.currentWeather.uv_index !== undefined

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 1
                Text { text: "☀️ " + i18n("UV"); color: Kirigami.Theme.textColor; opacity: 0.6; font: Kirigami.Theme.smallFont; Layout.alignment: Qt.AlignHCenter }
                Text {
                    text: (weatherRoot.currentWeather && weatherRoot.currentWeather.uv_index !== undefined && weatherRoot.currentWeather.uv_index !== null) ? weatherRoot.currentWeather.uv_index.toString() : "--"
                    color: {
                        var uv = (weatherRoot.currentWeather && weatherRoot.currentWeather.uv_index !== undefined) ? weatherRoot.currentWeather.uv_index : 0
                        if (uv >= 11) return "#8B3FC7"
                        if (uv >= 8) return "#D90011"
                        if (uv >= 6) return "#F95901"
                        if (uv >= 3) return "#F7E400"
                        return Kirigami.Theme.textColor
                    }
                    font.pixelSize: Math.round(Kirigami.Theme.defaultFont.pixelSize * 1.25); font.bold: true; Layout.alignment: Qt.AlignHCenter
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 45
            radius: 8 * weatherRoot.radiusMultiplier
            color: weatherRoot.showInnerBackgrounds ? Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.05) : "transparent"
            visible: weatherRoot.currentWeather && weatherRoot.currentWeather.visibility !== undefined && weatherRoot.currentWeather.visibility !== null

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 1
                Text { text: "👁️ " + i18n("Visibility"); color: Kirigami.Theme.textColor; opacity: 0.6; font: Kirigami.Theme.smallFont; Layout.alignment: Qt.AlignHCenter }
                Text {
                    text: (weatherRoot.currentWeather && weatherRoot.currentWeather.visibility !== undefined && weatherRoot.currentWeather.visibility !== null) ? weatherRoot.currentWeather.visibility + (weatherRoot.units === "imperial" ? " mi" : " km") : "--"
                    color: Kirigami.Theme.textColor; font.family: Kirigami.Theme.defaultFont.family; font.pixelSize: Kirigami.Theme.defaultFont.pixelSize; font.bold: true; Layout.alignment: Qt.AlignHCenter
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 45
            radius: 8 * weatherRoot.radiusMultiplier
            color: weatherRoot.showInnerBackgrounds ? Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.05) : "transparent"
            visible: weatherRoot.currentWeather && weatherRoot.currentWeather.dew_point !== undefined

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 1
                Text { text: "💧 " + i18n("Dew Point"); color: Kirigami.Theme.textColor; opacity: 0.6; font: Kirigami.Theme.smallFont; Layout.alignment: Qt.AlignHCenter }
                Text {
                    text: (weatherRoot.currentWeather && weatherRoot.currentWeather.dew_point !== undefined) ? weatherRoot.currentWeather.dew_point + "°" : "--"
                    color: Kirigami.Theme.textColor; font.family: Kirigami.Theme.defaultFont.family; font.pixelSize: Kirigami.Theme.defaultFont.pixelSize; font.bold: true; Layout.alignment: Qt.AlignHCenter
                }
            }
        }
    }

    // --- Row 4: Wind Direction (Full Width Logic) ---
    // --- Row 4: Wind Direction & Sun Times (Side by Side) ---
    RowLayout {
        Layout.fillWidth: true
        spacing: 6
        visible: weatherRoot.currentWeather && (
            weatherRoot.currentWeather.wind_deg !== undefined ||
            weatherRoot.currentWeather.sunrise !== undefined ||
            weatherRoot.currentWeather.sunset !== undefined
        )

        // Wind Direction Card
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 45
            radius: 8 * weatherRoot.radiusMultiplier
            color: weatherRoot.showInnerBackgrounds ? Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.05) : "transparent"
            visible: weatherRoot.currentWeather && weatherRoot.currentWeather.wind_deg !== undefined

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 1
                Text { text: "🧭 " + i18n("Wind Direction"); color: Kirigami.Theme.textColor; opacity: 0.6; font: Kirigami.Theme.smallFont; Layout.alignment: Qt.AlignHCenter }
                Text {
                    id: windDirText
                    text: {
                        if (!weatherRoot.currentWeather || weatherRoot.currentWeather.wind_deg === undefined) return "--"
                        var deg = weatherRoot.currentWeather.wind_deg
                        var idx = Math.round(deg / 45) % 8
                        var fullDirs = [i18n("North"), i18n("North East"), i18n("East"), i18n("South East"), i18n("South"), i18n("South West"), i18n("West"), i18n("North West")]
                        return fullDirs[idx]
                    }
                    color: Kirigami.Theme.textColor; font.family: Kirigami.Theme.defaultFont.family; font.pixelSize: Kirigami.Theme.defaultFont.pixelSize; font.bold: true; Layout.alignment: Qt.AlignHCenter

                    onContentWidthChanged: {
                        if (weatherRoot.currentWeather && weatherRoot.currentWeather.wind_deg !== undefined && parent && windDirText.contentWidth > parent.width - 20) {
                            var deg = weatherRoot.currentWeather.wind_deg
                            var idx = Math.round(deg / 45) % 8
                            var shortDirs = [i18n("N"), i18n("NE"), i18n("E"), i18n("SE"), i18n("S"), i18n("SW"), i18n("W"), i18n("NW")]
                            text = shortDirs[idx]
                        }
                    }
                }
            }
        }

        // Sun Times Card
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 45
            radius: 8 * weatherRoot.radiusMultiplier
            color: weatherRoot.showInnerBackgrounds ? Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.05) : "transparent"
            visible: weatherRoot.currentWeather && (weatherRoot.currentWeather.sunrise !== undefined || weatherRoot.currentWeather.sunset !== undefined)

            RowLayout {
                anchors.centerIn: parent
                spacing: 15

                RowLayout {
                    spacing: 4
                    Text { text: "🌅"; font: Kirigami.Theme.defaultFont }
                    Text {
                        text: {
                            if (!weatherRoot.currentWeather || !weatherRoot.currentWeather.sunrise) return "--"
                            var sr = weatherRoot.currentWeather.sunrise
                            if (typeof sr === "number") {
                                var d = new Date(sr)
                                return d.getHours().toString().padStart(2, '0') + ":" + d.getMinutes().toString().padStart(2, '0')
                            } else if (typeof sr === "string") {
                                var d2 = new Date(sr)
                                return d2.getHours().toString().padStart(2, '0') + ":" + d2.getMinutes().toString().padStart(2, '0')
                            }
                            return "--"
                        }
                        color: Kirigami.Theme.textColor; font.family: Kirigami.Theme.defaultFont.family; font.pixelSize: Kirigami.Theme.defaultFont.pixelSize; font.bold: true
                    }
                }

                RowLayout {
                    spacing: 4
                    Text { text: "🌇"; font: Kirigami.Theme.defaultFont }
                    Text {
                        text: {
                            if (!weatherRoot.currentWeather || !weatherRoot.currentWeather.sunset) return "--"
                            var ss = weatherRoot.currentWeather.sunset
                            if (typeof ss === "number") {
                                var d = new Date(ss)
                                return d.getHours().toString().padStart(2, '0') + ":" + d.getMinutes().toString().padStart(2, '0')
                            } else if (typeof ss === "string") {
                                var d2 = new Date(ss)
                                return d2.getHours().toString().padStart(2, '0') + ":" + d2.getMinutes().toString().padStart(2, '0')
                            }
                            return "--"
                        }
                        color: Kirigami.Theme.textColor; font.family: Kirigami.Theme.defaultFont.family; font.pixelSize: Kirigami.Theme.defaultFont.pixelSize; font.bold: true
                    }
                }
            }
        }
    }

    Text {
        text: i18n("Click to close")
        color: Kirigami.Theme.textColor
        opacity: 0.4
        font.family: Kirigami.Theme.smallFont.family
        font.pixelSize: Kirigami.Theme.smallFont.pixelSize
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: 5
    }
}
