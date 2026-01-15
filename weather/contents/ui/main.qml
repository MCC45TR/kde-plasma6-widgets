import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import Qt5Compat.GraphicalEffects
import "WeatherService.js" as WeatherService
import "IconMapper.js" as IconMapper

PlasmoidItem {
    id: root

    // --- Localization Logic ---
    // Inline fallback for instant display
    property var locales: {
        "en": { 
            "loading": "Loading...", 
            "error_network": "Network error",
            "error_no_api_key": "No API key configured",
            "refresh": "Refresh",
            "change_location": "Change Location",
            "daily_forecast": "Daily Forecast",
            "hourly_forecast": "Hourly Forecast"
        },
        "tr": { 
            "loading": "Yükleniyor...", 
            "error_network": "Ağ hatası",
            "error_no_api_key": "API anahtarı ayarlanmadı",
            "refresh": "Yenile",
            "change_location": "Konum Değiştir",
            "daily_forecast": "Günlük Tahmin",
            "hourly_forecast": "Saatlik Tahmin"
        }
    }
    property string currentLocale: Qt.locale().name.substring(0, 2)
    
    function loadLocales() {
        var xhr = new XMLHttpRequest()
        xhr.open("GET", "localization.json")
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200 || xhr.status === 0) {
                    try {
                        var loaded = JSON.parse(xhr.responseText)
                        // Merge with inline fallback
                        for (var locale in loaded) {
                            if (!locales[locale]) locales[locale] = {}
                            for (var key in loaded[locale]) {
                                locales[locale][key] = loaded[locale][key]
                            }
                        }
                    } catch (e) {
                        console.log("Error parsing localization.json: " + e)
                    }
                }
            }
        }
        xhr.send()
    }
    
   Component.onCompleted: {
        loadLocales()
        fetchWeatherData()
    }
    
    function tr(key) {
        if (locales[currentLocale] && locales[currentLocale][key]) {
            return locales[currentLocale][key]
        }
        if (locales["en"] && locales["en"][key]) {
            return locales["en"][key]
        }
        return key
    }

    // Widget Size Constraints
    Layout.preferredWidth: 400
    Layout.preferredHeight: 200
    Layout.minimumWidth: 250
    Layout.minimumHeight: 150
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    // Configuration
    readonly property string apiKey: Plasmoid.configuration.apiKey || ""
    readonly property string apiKey2: Plasmoid.configuration.apiKey2 || ""
    readonly property string location: Plasmoid.configuration.location || "Ankara"
    readonly property string units: Plasmoid.configuration.units || "metric"
    readonly property int updateInterval: Plasmoid.configuration.updateInterval || 30 // minutes

    // Weather Data
    property var currentWeather: null
    property var forecastDaily: []
    property var forecastHourly: []
    property string apiProvider: ""
    property bool isLoading: true
    property string errorMessage: ""
    property bool forecastMode: false // false = daily, true = hourly

    // Fetch weather data
    function fetchWeatherData() {
        isLoading = true
        errorMessage = ""
        
        WeatherService.fetchWeather({
            apiKey: apiKey,
            apiKey2: apiKey2,
            location: location,
            units: units
        }, function(result) {
            isLoading = false
            if (result.success) {
                currentWeather = result.current
                forecastDaily = result.forecast.daily
                forecastHourly = result.forecast.hourly
                apiProvider = result.provider || "openweathermap"
            } else {
                errorMessage = result.error || "Unknown error"
                console.log("Weather fetch error: " + errorMessage)
            }
        })
    }

    // Auto-refresh timer
    Timer {
        interval: updateInterval * 60 * 1000
        running: true
        repeat: true
        onTriggered: root.fetchWeatherData()
    }

    // Helper functions
    function getWeatherIcon(item) {
        if (!item) return "../images/clear_day.svg"
        return IconMapper.getIconPath(item.code, item.icon, apiProvider)
    }

    preferredRepresentation: fullRepresentation
    
    fullRepresentation: Item {
        id: fullRep
        anchors.fill: parent

        Rectangle {
            id: mainRect
            anchors.fill: parent
            anchors.margins: 10
            color: Kirigami.Theme.backgroundColor
            radius: 20
            clip: true

            // Loading State
            ColumnLayout {
                anchors.centerIn: parent
                visible: root.isLoading
                spacing: 10

                BusyIndicator {
                    running: root.isLoading
                    Layout.alignment: Qt.AlignHCenter
                }
                Text {
                    text: root.tr("loading")
                    color: Kirigami.Theme.textColor
                    font.pixelSize: 14
                    Layout.alignment: Qt.AlignHCenter
                }
            }

            // Error State
            ColumnLayout {
                anchors.centerIn: parent
                visible: !root.isLoading && root.errorMessage !== ""
                spacing: 10
                width: parent.width * 0.8

                Kirigami.Icon {
                    source: "dialog-error"
                    Layout.preferredWidth: 48
                    Layout.preferredHeight: 48
                    Layout.alignment: Qt.AlignHCenter
                }
                Text {
                    text: root.errorMessage
                    color: Kirigami.Theme.textColor
                    font.pixelSize: 13
                    Layout.alignment: Qt.AlignHCenter
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                    Layout.fillWidth: true
                }
                Button {
                    text: root.tr("refresh")
                    Layout.alignment: Qt.AlignHCenter
                    onClicked: root.fetchWeatherData()
                }
            }

            // Main Weather Display
            RowLayout {
                id: mainLayout
                anchors.fill: parent
                anchors.margins: 15
                spacing: 15
                visible: !root.isLoading && root.errorMessage === "" && root.currentWeather

                // Left Section: Current Weather
                ColumnLayout {
                    id: currentSection
                    Layout.preferredWidth: Math.min(150, parent.width * 0.35)
                    Layout.fillHeight: true
                    spacing: 5

                    // Current Weather Icon (Large)
                    Image {
                        id: currentIcon
                        source: root.getWeatherIcon(root.currentWeather)
                        Layout.preferredWidth: Math.min(100, currentSection.width * 0.9)
                        Layout.preferredHeight: Layout.preferredWidth
                        Layout.alignment: Qt.AlignHCenter
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                    }

                    // Current Temperature (Large)
                    Text {
                        id: currentTemp
                        text: root.currentWeather ? root.currentWeather.temp + "°" : "--"
                        color: Kirigami.Theme.textColor
                        font.family: "Roboto Condensed"
                        font.bold: true
                        font.pixelSize: Math.min(48, currentSection.width * 0.35)
                        Layout.alignment: Qt.AlignHCenter
                    }

                    // High/Low Temperatures
                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 10

                        RowLayout {
                            spacing: 2
                            Text {
                                text: "↑"
                                color: Kirigami.Theme.positiveTextColor
                                font.pixelSize: 14
                                font.bold: true
                            }
                            Text {
                                text: root.currentWeather ? root.currentWeather.temp_max + "°" : "--"
                                color: Kirigami.Theme.textColor
                                font.pixelSize: 13
                            }
                        }

                        RowLayout {
                            spacing: 2
                            Text {
                                text: "↓"
                                color: Kirigami.Theme.neutralTextColor
                                font.pixelSize: 14
                                font.bold: true
                            }
                            Text {
                                text: root.currentWeather ? root.currentWeather.temp_min + "°" : "--"
                                color: Kirigami.Theme.textColor
                                font.pixelSize: 13
                            }
                        }
                    }

                    Item { Layout.fillHeight: true } // Spacer
                }

                // Right Section: Location, Condition, Forecast
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 8

                    // Location Text
                    Text {
                        id: locationText
                        text: root.currentWeather ? root.currentWeather.location : root.location
                        color: Kirigami.Theme.textColor
                        font.family: "Roboto Condensed"
                        font.bold: true
                        font.pixelSize: Math.min(20, parent.width * 0.08)
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    // Condition Text
                    Text {
                        text: root.currentWeather ? root.currentWeather.condition : ""
                        color: Kirigami.Theme.textColor
                        opacity: 0.8
                        font.pixelSize: 14
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }

                    // Forecast Mode Toggle Button
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 5

                        Rectangle {
                            Layout.preferredWidth: toggleButton.implicitWidth + 16
                            Layout.preferredHeight: toggleButton.implicitHeight + 8
                            radius: 5
                            color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.1)

                            Text {
                                id: toggleButton
                                anchors.centerIn: parent
                                text: root.forecastMode ? root.tr("hourly_forecast") : root.tr("daily_forecast")
                                color: Kirigami.Theme.textColor
                                font.pixelSize: 11
                                font.bold: true
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.forecastMode = !root.forecastMode
                            }
                        }

                        Item { Layout.fillWidth: true }
                    }

                    // Forecast ListView (Horizontal Scroll)
                    ListView {
                        id: forecastList
                        Layout.fillWidth: true
                        Layout.preferredHeight: 90
                        orientation: ListView.Horizontal
                        spacing: 8
                        clip: true
                        
                        model: root.forecastMode ? root.forecastHourly : root.forecastDaily

                        delegate: ForecastItem {
                            required property var modelData
                            
                            label: root.forecastMode ? modelData.time : modelData.day
                            iconPath: root.getWeatherIcon(modelData)
                            temp: modelData.temp
                            isHourly: root.forecastMode
                        }

                        // Scroll indicator (optional subtle hint)
                        Rectangle {
                            anchors.bottom: parent.bottom
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: parent.width * 0.8
                            height: 2
                            color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.1)
                            visible: forecastList.contentWidth > forecastList.width

                            Rectangle {
                                height: parent.height
                                width: parent.width * (forecastList.width / forecastList.contentWidth)
                                x: parent.width * (forecastList.contentX / forecastList.contentWidth)
                                color: Kirigami.Theme.highlightColor
                                radius: 1
                            }
                        }
                    }

                    Item { Layout.fillHeight: true } // Spacer
                }
            }

            // Click to Refresh (subtle)
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.MiddleButton | Qt.RightButton
                onClicked: (mouse) => {
                    if (mouse.button === Qt.MiddleButton || mouse.button === Qt.RightButton) {
                        root.fetchWeatherData()
                    }
                }
            }
        }
    }
}
