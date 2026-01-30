import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.kirigami as Kirigami

ColumnLayout {
    id: forecastDetailsView
    property var weatherRoot
    property var forecastData: null

    spacing: 8

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
                    text: "°"
                    color: Kirigami.Theme.textColor
                    font.family: weatherRoot.activeFont.family
                    font.bold: true
                    font.pixelSize: 22
                    Layout.alignment: Qt.AlignTop
                }
            }

            RowLayout {
                spacing: 8
                Layout.alignment: Qt.AlignHCenter
                RowLayout {
                    spacing: 2
                    Text { text: "▲"; color: Kirigami.Theme.positiveTextColor; font.pixelSize: 11 }
                    Text { text: forecastData ? forecastData.temp_max + "°" : "--"; color: Kirigami.Theme.textColor; font.pixelSize: 11 }
                }
                RowLayout {
                    spacing: 2
                    Text { text: "▼"; color: Kirigami.Theme.negativeTextColor; font.pixelSize: 11 }
                    Text { text: forecastData ? forecastData.temp_min + "°" : "--"; color: Kirigami.Theme.textColor; font.pixelSize: 11 }
                }
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 6

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 45
            radius: 8 * weatherRoot.radiusMultiplier
            color: weatherRoot.showInnerBackgrounds ? Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.05) : "transparent"
            visible: forecastData && forecastData.feels_like !== undefined && forecastData.feels_like !== null

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

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 45
            radius: 8 * weatherRoot.radiusMultiplier
            color: weatherRoot.showInnerBackgrounds ? Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.05) : "transparent"
            visible: forecastData && forecastData.precipitation_probability !== undefined && forecastData.precipitation_probability !== null

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

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 45
            radius: 8 * weatherRoot.radiusMultiplier
            color: weatherRoot.showInnerBackgrounds ? Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.05) : "transparent"
            visible: forecastData && forecastData.wind_speed !== undefined && forecastData.wind_speed !== null

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

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 45
            radius: 8 * weatherRoot.radiusMultiplier
            color: weatherRoot.showInnerBackgrounds ? Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.05) : "transparent"
            visible: forecastData && forecastData.uv_index !== undefined && forecastData.uv_index !== null

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 1
                Text { text: "☀️ " + i18n("UV Index"); color: Kirigami.Theme.textColor; opacity: 0.6; font.pixelSize: 9; Layout.alignment: Qt.AlignHCenter }
                Text {
                    text: (forecastData && forecastData.uv_index !== undefined) ? forecastData.uv_index : "--"
                    color: Kirigami.Theme.textColor; font.pixelSize: 15; font.bold: true; Layout.alignment: Qt.AlignHCenter
                }
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 6
        visible: forecastData && (forecastData.precipitation !== undefined || forecastData.wind_deg !== undefined || forecastData.sunrise !== undefined)

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 45
            radius: 8 * weatherRoot.radiusMultiplier
            color: weatherRoot.showInnerBackgrounds ? Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.05) : "transparent"
            visible: forecastData && forecastData.precipitation !== undefined && forecastData.precipitation !== null

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

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 45
            radius: 8 * weatherRoot.radiusMultiplier
            color: weatherRoot.showInnerBackgrounds ? Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.05) : "transparent"
            visible: forecastData && forecastData.wind_deg !== undefined && forecastData.wind_deg !== null

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 1
                Text { text: i18n("Wind Direction"); color: Kirigami.Theme.textColor; opacity: 0.6; font.pixelSize: 9; Layout.alignment: Qt.AlignHCenter }
                Text {
                    text: {
                        if (!forecastData || forecastData.wind_deg === undefined) return "--"
                        var deg = forecastData.wind_deg
                        if (deg >= 337.5 || deg < 22.5) return "N"
                        if (deg >= 22.5 && deg < 67.5) return "NE"
                        if (deg >= 67.5 && deg < 112.5) return "E"
                        if (deg >= 112.5 && deg < 157.5) return "SE"
                        if (deg >= 157.5 && deg < 202.5) return "S"
                        if (deg >= 202.5 && deg < 247.5) return "SW"
                        if (deg >= 247.5 && deg < 292.5) return "W"
                        return "NW"
                    }
                    color: Kirigami.Theme.textColor; font.pixelSize: 15; font.bold: true; Layout.alignment: Qt.AlignHCenter
                }
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignHCenter
        spacing: 20
        visible: forecastData && (forecastData.sunrise || forecastData.sunset)

        RowLayout {
            spacing: 4
            visible: forecastData && forecastData.sunrise
            Text { text: "🌅"; font.pixelSize: 16 }
            Text {
                text: {
                    if (!forecastData || !forecastData.sunrise) return "--"
                    var d = new Date(forecastData.sunrise)
                    return Qt.formatTime(d, "hh:mm")
                }
                color: Kirigami.Theme.textColor
                font.pixelSize: 12
                font.bold: true
            }
        }

        RowLayout {
            spacing: 4
            visible: forecastData && forecastData.sunset
            Text { text: "🌇"; font.pixelSize: 16 }
            Text {
                text: {
                    if (!forecastData || !forecastData.sunset) return "--"
                    var d = new Date(forecastData.sunset)
                    return Qt.formatTime(d, "hh:mm")
                }
                color: Kirigami.Theme.textColor
                font.pixelSize: 12
                font.bold: true
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.topMargin: 5
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
        
        // Helper to get start of week (Monday)
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
        
        var longDayName = i18n(Qt.formatDate(targetDate, "dddd"))
        
        if (diffWeeks <= 0) {
            return longDayName
        } else if (diffWeeks === 1) {
            return i18n("Next week %1", longDayName)
        } else {
            return i18n("2 weeks later %1", longDayName)
        }
    }
}
