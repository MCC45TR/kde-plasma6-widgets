import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.kirigami as Kirigami

ColumnLayout {
    id: forecastDetailsView
    property var weatherRoot
    property var forecastData: null

    spacing: 5

    // --- Row 1: Header ---
    RowLayout {
        Layout.fillWidth: true
        spacing: 10

        Kirigami.Icon {
            source: weatherRoot.getWeatherIcon(forecastData)
            Layout.preferredHeight: 50
            Layout.preferredWidth: 50
            smooth: true
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            Text {
                text: forecastDetailsView.getSmartDateText(forecastData)
                color: Kirigami.Theme.textColor
                font.family: weatherRoot.activeFont.family
                font.bold: true
                font.pixelSize: 16
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Text {
                text: forecastData ? i18n(forecastData.condition) : ""
                color: Kirigami.Theme.textColor
                opacity: 0.7
                font.pixelSize: 12
            }
        }

        ColumnLayout {
            spacing: 0

            RowLayout {
                spacing: 0
                Text {
                    text: forecastData ? forecastData.temp : "--"
                    color: Kirigami.Theme.textColor
                    font.family: weatherRoot.activeFont.family
                    font.bold: true
                    font.pixelSize: 36
                }
                Text {
                    text: weatherRoot.units === "imperial" ? "°F" : "°C"
                    color: Kirigami.Theme.textColor
                    font.family: weatherRoot.activeFont.family
                    font.bold: true
                    font.pixelSize: 36
                    Layout.alignment: Qt.AlignTop
                }
            }

            RowLayout {
                spacing: 8
                Layout.alignment: Qt.AlignHCenter
                RowLayout {
                    spacing: 2
                    Text { text: "▲"; color: Kirigami.Theme.positiveTextColor; font.pixelSize: 11 }
                    Text { text: forecastData ? forecastData.temp_max + (weatherRoot.units === "imperial" ? "°F" : "°C") : "--"; color: Kirigami.Theme.textColor; font.pixelSize: 11 }
                }
                RowLayout {
                    spacing: 2
                    Text { text: "▼"; color: Kirigami.Theme.negativeTextColor; font.pixelSize: 11 }
                    Text { text: forecastData ? forecastData.temp_min + (weatherRoot.units === "imperial" ? "°F" : "°C") : "--"; color: Kirigami.Theme.textColor; font.pixelSize: 11 }
                }
            }
        }
    }

    // --- Row 2: Feels Like, Humidity, Wind, Rain Chance ---
    RowLayout {
        Layout.fillWidth: true
        spacing: 6

        // Feels Like
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 45
            radius: 8 * weatherRoot.radiusMultiplier
            color: weatherRoot.showInnerBackgrounds ? Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.05) : "transparent"
            visible: forecastData && forecastData.feels_like !== undefined

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 1
                Text { text: i18n("Feels like"); color: Kirigami.Theme.textColor; opacity: 0.6; font.pixelSize: 9; Layout.alignment: Qt.AlignHCenter }
                Text {
                    text: (forecastData && forecastData.feels_like !== undefined) ? forecastData.feels_like + "°" : "--"
                    color: Kirigami.Theme.textColor; font.pixelSize: 15; font.bold: true; Layout.alignment: Qt.AlignHCenter
                }
            }
        }

        // Humidity
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 45
            radius: 8 * weatherRoot.radiusMultiplier
            color: weatherRoot.showInnerBackgrounds ? Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.05) : "transparent"
            visible: forecastData && forecastData.humidity !== undefined

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 1
                Text { text: "💧 " + i18n("Humidity"); color: Kirigami.Theme.textColor; opacity: 0.6; font.pixelSize: 9; Layout.alignment: Qt.AlignHCenter }
                Text {
                    text: (forecastData && forecastData.humidity !== undefined) ? forecastData.humidity + "%" : "--"
                    color: Kirigami.Theme.textColor; font.pixelSize: 15; font.bold: true; Layout.alignment: Qt.AlignHCenter
                }
            }
        }

        // Wind Speed
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 45
            radius: 8 * weatherRoot.radiusMultiplier
            color: weatherRoot.showInnerBackgrounds ? Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.05) : "transparent"
            visible: forecastData && forecastData.wind_speed !== undefined

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 1
                Text { text: "💨 " + i18n("Wind"); color: Kirigami.Theme.textColor; opacity: 0.6; font.pixelSize: 9; Layout.alignment: Qt.AlignHCenter }
                Text {
                    text: (forecastData && forecastData.wind_speed !== undefined) ? forecastData.wind_speed + " km/h" : "--"
                    color: Kirigami.Theme.textColor; font.pixelSize: 13; font.bold: true; Layout.alignment: Qt.AlignHCenter
                }
            }
        }

        // Rain Chance
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 45
            radius: 8 * weatherRoot.radiusMultiplier
            color: weatherRoot.showInnerBackgrounds ? Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.05) : "transparent"
            visible: forecastData && forecastData.precipitation_probability !== undefined

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 1
                Text { text: "🌧️ " + i18n("Rain Chance"); color: Kirigami.Theme.textColor; opacity: 0.6; font.pixelSize: 9; Layout.alignment: Qt.AlignHCenter }
                Text {
                    text: (forecastData && forecastData.precipitation_probability !== undefined) ? forecastData.precipitation_probability + "%" : "--"
                    color: Kirigami.Theme.textColor; font.pixelSize: 15; font.bold: true; Layout.alignment: Qt.AlignHCenter
                }
            }
        }
    }

    // --- Row 3: Precipitation, UV Index, Wind Direction, Sunrise/Sunset ---
    RowLayout {
        Layout.fillWidth: true
        spacing: 6
        visible: forecastData

        // Precipitation (mm)
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 45
            radius: 8 * weatherRoot.radiusMultiplier
            color: weatherRoot.showInnerBackgrounds ? Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.05) : "transparent"
            visible: forecastData && forecastData.precipitation !== undefined

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 1
                Text { text: i18n("Precipitation"); color: Kirigami.Theme.textColor; opacity: 0.6; font.pixelSize: 9; Layout.alignment: Qt.AlignHCenter }
                Text {
                    text: (forecastData && forecastData.precipitation !== undefined) ? forecastData.precipitation + " mm" : "--"
                    color: Kirigami.Theme.textColor; font.pixelSize: 13; font.bold: true; Layout.alignment: Qt.AlignHCenter
                }
            }
        }

        // UV Index
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 45
            radius: 8 * weatherRoot.radiusMultiplier
            color: weatherRoot.showInnerBackgrounds ? Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.05) : "transparent"
            visible: forecastData && forecastData.uv_index !== undefined

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 1
                Text { text: "☀️ " + i18n("UV Index"); color: Kirigami.Theme.textColor; opacity: 0.6; font.pixelSize: 9; Layout.alignment: Qt.AlignHCenter }
                Text {
                    text: (forecastData && forecastData.uv_index !== undefined) ? forecastData.uv_index : "--"
                    color: {
                        var uv = (forecastData && forecastData.uv_index !== undefined) ? forecastData.uv_index : 0
                        if (uv >= 11) return "#8B3FC7"
                        if (uv >= 8) return "#D90011"
                        if (uv >= 6) return "#F95901"
                        if (uv >= 3) return "#F7E400"
                        return Kirigami.Theme.textColor
                    }
                    font.pixelSize: 15; font.bold: true; Layout.alignment: Qt.AlignHCenter
                }
            }
        }

        // Wind Direction
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 45
            radius: 8 * weatherRoot.radiusMultiplier
            color: weatherRoot.showInnerBackgrounds ? Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.05) : "transparent"
            visible: forecastData && forecastData.wind_deg !== undefined

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 1
                Text { text: "🧭 " + i18n("Wind Direction"); color: Kirigami.Theme.textColor; opacity: 0.6; font.pixelSize: 9; Layout.alignment: Qt.AlignHCenter }
                Text {
                    id: windDirText
                    text: {
                        if (!forecastData || forecastData.wind_deg === undefined) return "--"
                        var deg = forecastData.wind_deg
                        var idx = Math.round(deg / 45) % 8
                        var fullDirs = [i18n("North"), i18n("North East"), i18n("East"), i18n("South East"), i18n("South"), i18n("South West"), i18n("West"), i18n("North West")]
                        return fullDirs[idx]
                    }
                    color: Kirigami.Theme.textColor; font.pixelSize: 13; font.bold: true; Layout.alignment: Qt.AlignHCenter
                    
                    onContentWidthChanged: {
                        if (forecastData && forecastData.wind_deg !== undefined && parent && windDirText.contentWidth > parent.width - 15) {
                            var deg = forecastData.wind_deg
                            var idx = Math.round(deg / 45) % 8
                            var shortDirs = [i18n("N"), i18n("NE"), i18n("E"), i18n("SE"), i18n("S"), i18n("SW"), i18n("W"), i18n("NW")]
                            text = shortDirs[idx]
                        }
                    }
                }
            }
        }

        // Sun Times (Dynamic)
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 45
            radius: 8 * weatherRoot.radiusMultiplier
            color: weatherRoot.showInnerBackgrounds ? Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.05) : "transparent"
            visible: forecastData && (forecastData.sunrise || forecastData.sunset)

            property bool showSunset: {
                if (!forecastData || !forecastData.sunrise || !forecastData.sunset) return false
                var d = new Date()
                var srVal = forecastData.sunrise
                var ssVal = forecastData.sunset
                var sr = (typeof srVal === "number") ? new Date(srVal * 1000) : new Date(srVal)
                var ss = (typeof ssVal === "number") ? new Date(ssVal * 1000) : new Date(ssVal)

                // If it's today, check time ranges
                if (d.toDateString() === sr.toDateString()) {
                    // Logic: If Sunrise < Now < Sunset -> Show Sunset (Next event is Sunset)
                    // If Now > Sunset -> Sunset passed, show Sunrise (Loop)
                    // If Now < Sunrise -> Sunrise hasn't happened, show Sunrise
                    if (d > sr && d < ss) return true 
                    return false
                }
                return false
            }

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 1
                Text { 
                    text: parent.parent.showSunset ? "🌇 " + i18n("Sunset") : "🌅 " + i18n("Sunrise")
                    color: Kirigami.Theme.textColor; opacity: 0.6; font.pixelSize: 9; Layout.alignment: Qt.AlignHCenter 
                }
                Text {
                    text: {
                        if (!forecastData) return "--"
                        var val = parent.parent.showSunset ? forecastData.sunset : forecastData.sunrise
                        if (!val) return "--"
                        
                        var dt = (typeof val === "number") ? new Date(val * 1000) : new Date(val)
                        return Qt.formatTime(dt, "hh:mm")
                    }
                    color: Kirigami.Theme.textColor; font.pixelSize: 15; font.bold: true; Layout.alignment: Qt.AlignHCenter
                }
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.topMargin: 0
        Layout.preferredHeight: 32
        radius: 8 * weatherRoot.radiusMultiplier
        color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.08)
        
        Text {
            anchors.centerIn: parent
            text: i18n("Tap to close")
            color: Kirigami.Theme.textColor
            opacity: 0.7
            font.pixelSize: 11
        }
        
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onClicked: weatherRoot.showForecastDetails = false
            onPressed: parent.opacity = 0.7
            onReleased: parent.opacity = 1.0
            onEntered: parent.color = Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.12)
            onExited: parent.color = Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.08)
        }
    }
    
    function getSmartDateText(data) {
        if (!data) return "--"
        
        var date
        if (data.timestamp) {
            date = new Date(data.timestamp * 1000)
        } else if (data.date) {
            date = new Date(data.date)
        } else {
            return data.day 
        }
        
        var today = new Date()
        var targetDate = new Date(date)
        
        if (isNaN(targetDate.getTime())) return data.day

        today.setHours(0,0,0,0)
        targetDate.setHours(0,0,0,0)
        
        function getMonday(d) {
            var d = new Date(d);
            var day = d.getDay();
            var diff = d.getDate() - day + (day == 0 ? -6 : 1); 
            return new Date(d.setDate(diff));
        }

        var currentMonday = getMonday(today)
        var targetMonday = getMonday(targetDate)
        
        var diffTime = targetMonday.getTime() - currentMonday.getTime()
        var diffWeeks = Math.round(diffTime / (1000 * 60 * 60 * 24 * 7))
        
        var longDayName = Qt.locale().dayName(targetDate.getDay(), Locale.LongFormat)
        
        if (diffWeeks <= 0) {
            return longDayName
        } else if (diffWeeks === 1) {
            return i18n("Next week %1", longDayName)
        } else {
            return i18n("2 weeks later %1", longDayName)
        }
    }
}
