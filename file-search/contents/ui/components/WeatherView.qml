import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.kirigami as Kirigami
import "WeatherService.js" as WeatherService
import "IconMapper.js" as IconMapper

// LogicController must be injected or accessible
Item {
    id: weatherView
    
    // Properties
    property var plasmoidConfig: null // injected from SearchPopup
    property var currentWeather: null
    property var forecastDaily: []
    property bool isLoading: true
    property string errorMessage: ""
    property string location: ""
    
    // Auto-fetch on visible
    onVisibleChanged: {
        if (visible && !currentWeather) {
            fetchWeatherData()
        }
    }
    
    function fetchWeatherData() {
        isLoading = true
        errorMessage = ""
        
        // Local logic: get settings from Plasmoid configuration
        var units = "metric"
        var refreshInterval = 15
        
        if (plasmoidConfig) {
             if (plasmoidConfig.weatherUseSystemUnits) {
                  units = Qt.locale().measurementSystem === Locale.MetricSystem ? "metric" : "imperial"
             } else {
                  units = plasmoidConfig.weatherUnits || "metric"
             }
             refreshInterval = plasmoidConfig.weatherRefreshInterval !== undefined ? plasmoidConfig.weatherRefreshInterval : 15
        }
        
        WeatherService.fetchWeather({
            location: "", // Force auto-detect
            autoDetect: true,
            units: units,
            provider: "openmeteo",
            refreshInterval: refreshInterval
        }, function(result) {
            isLoading = false
            if (result.success) {
                currentWeather = result.current
                forecastDaily = result.forecast.daily
                location = result.current.location
            } else {
                errorMessage = result.error || i18nd("plasma_applet_com.mcc45tr.filesearch", "Unknown error")
            }
        })
    }
    
    function getWeatherIcon(item) {
        if (!item) return "weather-clear" // Default fallback
        var isDark = ((Kirigami.Theme.backgroundColor.r + Kirigami.Theme.backgroundColor.g + Kirigami.Theme.backgroundColor.b) / 3) < 0.5
        // Use default system icons
        return IconMapper.getIconPath(item.code, item.icon, "openmeteo", isDark, "default")
    }

    // Main Layout (based on SmallModeLayout from reference)
    Rectangle {
        anchors.fill: parent
        color: "transparent" // Parent usually provides background or it's transparent in popup

        // Loading State
        ColumnLayout {
            anchors.centerIn: parent
            visible: weatherView.isLoading
            spacing: 10
            BusyIndicator { running: weatherView.isLoading; Layout.alignment: Qt.AlignHCenter }
            Label { text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Loading Weather..."); color: Kirigami.Theme.textColor; font.pixelSize: 14; Layout.alignment: Qt.AlignHCenter }
        }

        // Error State
        ColumnLayout {
            anchors.centerIn: parent
            visible: !weatherView.isLoading && weatherView.errorMessage !== ""
            spacing: 10
            width: parent.width * 0.8
            Kirigami.Icon { source: "dialog-error"; Layout.preferredWidth: 32; Layout.preferredHeight: 32; Layout.alignment: Qt.AlignHCenter }
            Label { text: weatherView.errorMessage; color: Kirigami.Theme.textColor; font.pixelSize: 13; Layout.alignment: Qt.AlignHCenter; horizontalAlignment: Text.AlignHCenter; wrapMode: Text.Wrap; Layout.fillWidth: true }
            Button { text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Retry"); Layout.alignment: Qt.AlignHCenter; onClicked: weatherView.fetchWeatherData() }
        }

        // Content State
        Item {
            anchors.fill: parent
            visible: !weatherView.isLoading && weatherView.errorMessage === "" && weatherView.currentWeather !== null
            
            // 1. Top Left: Condition & Location
            ColumnLayout {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.margins: 15
                spacing: 0
                width: parent.width * 0.6

                Label {
                    id: conditionLabel
                    // Use localization for condition text if possible, reference used tr("condition_" + ...)
                    // Here we will try to just show what API gives or a simple mapping if needed.
                    text: currentWeather ? currentWeather.condition : "" 
                    color: Kirigami.Theme.textColor
                    font.family: "Roboto Condensed"
                    font.pixelSize: 22
                    wrapMode: Text.WordWrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
                Label {
                    text: location
                    color: Kirigami.Theme.textColor
                    font.family: "Roboto Condensed"
                    font.pixelSize: 16
                    font.bold: true
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                    opacity: 0.7
                }
            }

            // 2. Top Right: Big Icon
            Kirigami.Icon {
                source: getWeatherIcon(currentWeather)
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 10
                width: parent.height * 0.5
                height: width
            }

            // 3. Bottom Left: Big Temperature
            Text {
                id: mainTemp
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                anchors.margins: 15
                text: currentWeather ? currentWeather.temp + "°" : "--"
                color: Kirigami.Theme.textColor
                font.family: "Roboto Condensed"
                font.pixelSize: weatherView.height * 0.4
                font.bold: true
                // verticalAlignment: Text.AlignBottom
            }

            // 4. Bottom Middle: High/Low Stats (Next to Temp)
            ColumnLayout {
                anchors.left: mainTemp.right
                anchors.leftMargin: 10
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 25
                spacing: 2

                RowLayout {
                    spacing: 4
                    Label { text: "▲"; color: Kirigami.Theme.positiveTextColor; font.pixelSize: 14; font.bold: true }
                    Label { text: currentWeather ? currentWeather.temp_max + "°" : "--"; color: Kirigami.Theme.textColor; font.pixelSize: 14; font.bold: true }
                }

                RowLayout {
                    spacing: 4
                    Label { text: "▼"; color: Kirigami.Theme.negativeTextColor; font.pixelSize: 14; font.bold: true }
                    Label { text: currentWeather ? currentWeather.temp_min + "°" : "--"; color: Kirigami.Theme.textColor; font.pixelSize: 14; font.bold: true }
                }
            }
        }
    }
}
