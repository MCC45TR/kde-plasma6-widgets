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
    // Inline fallback for instant display and XHR failure
    property var locales: {
        "en": {
            "loading": "Loading weather data...",
            "error_network": "Network error. Check your internet connection.",
            "error_no_api_key": "No API key configured. Please add one in settings.",
            "error_invalid_location": "Location not found. Please check the city name.",
            "refresh": "Refresh Weather",
            "change_location": "Change Location",
            "daily_forecast": "Daily Forecast",
            "hourly_forecast": "Hourly Forecast",
            "feels_like": "Feels like",
            "humidity": "Humidity",
            "wind": "Wind",
            "condition_clear": "Clear",
            "condition_clouds": "Cloudy",
            "condition_rain": "Rain",
            "condition_drizzle": "Drizzle",
            "condition_thunderstorm": "Thunderstorm",
            "condition_snow": "Snow",
            "condition_mist": "Mist",
            "condition_fog": "Fog",
            "condition_haze": "Haze",
            "condition_overcast": "Overcast",
            "condition_mainly_clear": "Mainly Clear",
            "condition_partly_cloudy": "Partly Cloudy",
            "condition_freezing_drizzle": "Freezing Drizzle",
            "condition_freezing_rain": "Freezing Rain",
            "condition_snow_grains": "Snow Grains",
            "condition_rain_showers": "Rain Showers",
            "condition_snow_showers": "Snow Showers",
            "condition_thunderstorm_with_hail": "Thunderstorm with Hail",
            "condition_unknown": "Unknown"
        },
        "tr": {
            "loading": "Hava durumu yükleniyor...",
            "error_network": "Ağ hatası. İnternet bağlantınızı kontrol edin.",
            "error_no_api_key": "API anahtarı ayarlanmadı. Lütfen ayarlarda ekleyin.",
            "error_invalid_location": "Konum bulunamadı. Şehir adını kontrol edin.",
            "refresh": "Hava Durumunu Yenile",
            "change_location": "Konumu Değiştir",
            "daily_forecast": "Günlük Tahmin",
            "hourly_forecast": "Saatlik Tahmin",
            "feels_like": "Hissedilen",
            "humidity": "Nem",
            "wind": "Rüzgar",
            "condition_clear": "Açık",
            "condition_clouds": "Bulutlu",
            "condition_rain": "Yağmurlu",
            "condition_drizzle": "Çiseliyor",
            "condition_thunderstorm": "Gök Gürültülü Fırtına",
            "condition_snow": "Karlı",
            "condition_mist": "Sisli",
            "condition_fog": "Sisli",
            "condition_haze": "Puslu",
            "condition_overcast": "Kapalı",
            "condition_mainly_clear": "Genelde Açık",
            "condition_partly_cloudy": "Parçalı Bulutlu",
            "condition_freezing_drizzle": "Dondurucu Çisinti",
            "condition_freezing_rain": "Dondurucu Yağmur",
            "condition_snow_grains": "Kar Taneleri",
            "condition_rain_showers": "Sağanak Yağmur",
            "condition_snow_showers": "Sağanak Kar",
            "condition_thunderstorm_with_hail": "Dolu ile Fırtına",
            "condition_unknown": "Bilinmeyen"
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
        
        // Try to load from cache first
        var cached = Plasmoid.configuration.cachedWeather
        if (cached && cached.length > 0) {
            try {
                var data = JSON.parse(cached)
                // Check if cache is recent (e.g., less than 40 minutes old)
                // Actually user requested persistence, so load it regardless of age on startup, 
                // but let the timer update it if needed.
                console.log("Loading weather from cache...")
                processWeatherData(data)
                isLoading = false
            } catch (e) {
                console.log("Cache parse error, fetching new data")
                fetchWeatherData()
            }
        } else {
            fetchWeatherData()
        }
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
    property int lastFetchMinute: -1

    // Timer for Auto-Refresh (Every 00 and 30 minutes)
    Timer {
        interval: 10000 // Check every 10 seconds
        running: true
        repeat: true
        onTriggered: {
            var now = new Date()
            var min = now.getMinutes()
            // Fetch if minutes is 0 or 30, and we haven't fetched in this minute yet
            if ((min === 0 || min === 30) && lastFetchMinute !== min) {
                console.log("Auto-refresh triggered at " + now)
                fetchWeatherData()
                lastFetchMinute = min
            }
        }
    }

    // Weather Data
    property var currentWeather: null
    property var forecastDaily: []
    property var forecastHourly: []
    property string apiProvider: ""
    property bool isLoading: true
    property string errorMessage: ""
    property bool forecastMode: false // false = daily, true = hourly

    // Process data helper
    function processWeatherData(result) {
        if (result.success) {
            currentWeather = result.current
            forecastDaily = result.forecast.daily
            forecastHourly = result.forecast.hourly
            apiProvider = result.provider || "openweathermap"
            errorMessage = ""
        } else {
            errorMessage = result.error || "Unknown error"
        }
    }

    // Fetch weather data
    function fetchWeatherData() {
        isLoading = true 
        // Don't clear errorMessage immediately to keep UI stable if cache exists
        
        WeatherService.fetchWeather({
            apiKey: apiKey,
            apiKey2: apiKey2,
            location: location,
            units: units
        }, function(result) {
            isLoading = false
            if (result.success) {
                processWeatherData(result)
                // Save to cache
                Plasmoid.configuration.cachedWeather = JSON.stringify(result)
                Plasmoid.configuration.lastUpdate = new Date().getTime()
                console.log("Weather data cached")
            } else {
                errorMessage = result.error || "Unknown error"
                console.log("Weather fetch error: " + errorMessage)
            }
        })
    }



    // Helper functions
    function getWeatherIcon(item) {
        if (!item) return "../images/clear_day.svg"
        // Detect dark theme by background luminance (dark < 0.5)
        var isDarkTheme = ((Kirigami.Theme.backgroundColor.r + Kirigami.Theme.backgroundColor.g + Kirigami.Theme.backgroundColor.b) / 3) < 0.5
        return IconMapper.getIconPath(item.code, item.icon, apiProvider, isDarkTheme)
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
            // Main Weather Display
            RowLayout {
                id: mainLayout
                anchors.fill: parent
                anchors.margins: 15
                spacing: 8
                visible: !root.isLoading && root.errorMessage === "" && root.currentWeather
                
                // Left Section: Current Weather
                Rectangle {
                    id: currentSection
                    Layout.fillHeight: true
                    Layout.preferredWidth: contentLayout.implicitWidth + 40 // Increased Padding
                    
                    radius: 20
                    color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.1)

                    ColumnLayout {
                        id: contentLayout
                        anchors.fill: parent
                        spacing: 0 // Tighter spacing for card look

                        Item { Layout.fillHeight: true } // Top Spacer

                        // Current Weather Icon
                        Image {
                            id: currentIcon
                            source: root.getWeatherIcon(root.currentWeather)
                            Layout.preferredHeight: root.height * 0.375
                            Layout.preferredWidth: Layout.preferredHeight
                            
                            Layout.alignment: Qt.AlignHCenter
                            
                            sourceSize.width: Layout.preferredWidth * 2
                            sourceSize.height: Layout.preferredHeight * 2
                            fillMode: Image.PreserveAspectFit
                            smooth: true
                            antialiasing: true
                        }

                        // Current Temperature
                        Text {
                            id: currentTemp
                            text: root.currentWeather ? root.currentWeather.temp + "°" : "--"
                            color: Kirigami.Theme.textColor
                            font.family: "Roboto Condensed"
                            font.bold: true
                            font.pixelSize: root.height * 0.25
                            Layout.alignment: Qt.AlignHCenter
                            Layout.topMargin: -5
                        }

                        // High/Low Temperatures
                        RowLayout {
                            Layout.alignment: Qt.AlignHCenter
                            spacing: 12

                            RowLayout {
                                spacing: 2
                                Text {
                                    text: "▲"
                                    color: Kirigami.Theme.positiveTextColor
                                    font.pixelSize: 16
                                    font.bold: true
                                }
                                Text {
                                    text: root.currentWeather ? root.currentWeather.temp_max + "°" : "--"
                                    color: Kirigami.Theme.textColor
                                    font.pixelSize: 16
                                    font.bold: true
                                }
                            }

                            RowLayout {
                                spacing: 2
                                Text {
                                    text: "▼"
                                    // Use negative text color (Red) as requested in image
                                    color: Kirigami.Theme.negativeTextColor
                                    font.pixelSize: 16
                                    font.bold: true
                                }
                                Text {
                                    text: root.currentWeather ? root.currentWeather.temp_min + "°" : "--"
                                    color: Kirigami.Theme.textColor
                                    font.pixelSize: 16
                                    font.bold: true
                                }
                            }
                        }

                        Item { Layout.fillHeight: true } // Bottom Spacer
                    }
                }



                // Right Section: Location, Condition, Forecast
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredWidth: root.width * 0.55 // Ensure it takes up space
                    Layout.minimumWidth: 150
                    // Removed maximumWidth constraint to allow full expansion
                    spacing: 4
                    clip: true

                    // Location Text and Toggle Button Row
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Text {
                            id: locationText
                            text: root.currentWeather ? root.currentWeather.location : root.location
                            color: Kirigami.Theme.textColor
                            font.family: "Roboto Condensed"
                            font.bold: true
                            font.pixelSize: Math.min(22, root.width * 0.09)
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        // Toggle Button (Integrated into header)
                        Rectangle {
                            Layout.alignment: Qt.AlignRight | Qt.AlignTop
                            Layout.preferredWidth: toggleText.implicitWidth + 24
                            Layout.preferredHeight: 28
                            radius: 14
                            color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.1)

                            Text {
                                id: toggleText
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
                            
                            // Hover effect
                            Rectangle {
                                anchors.fill: parent
                                color: Kirigami.Theme.highlightColor
                                opacity: parent.children[2].containsMouse ? 0.1 : 0
                                radius: parent.radius
                                Behavior on opacity { NumberAnimation { duration: 150 } }
                            }
                        }
                    }

                    // Condition Text (localized)
                    Text {
                        text: root.currentWeather ? root.tr("condition_" + root.currentWeather.condition.toLowerCase().replace(/ /g, "_")) : ""
                        color: Kirigami.Theme.textColor
                        opacity: 0.7
                        font.pixelSize: 14
                        Layout.fillWidth: true
                        Layout.maximumWidth: parent.width
                        elide: Text.ElideRight
                    }

                    // Forecast Grid (fixed card width, wraps to multiple rows)
                    GridView {
                        id: forecastGrid
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.minimumHeight: 80
                        clip: true
                        
                        // Fixed card width, dynamic rows
                        readonly property real cardWidth: 70
                        readonly property int cardsPerRow: Math.max(1, Math.floor(width / cardWidth))
                        readonly property int rowCount: Math.ceil(count / cardsPerRow)
                        
                        cellWidth: cardWidth
                        cellHeight: 100  // Fixed card height
                        
                        // Center the content by adding left margin equal to half the remaining space
                        leftMargin: Math.max(0, (width - (cardsPerRow * cardWidth)) / 2)
                        
                        flow: GridView.FlowLeftToRight
                        
                        model: root.forecastMode ? root.forecastHourly : root.forecastDaily

                        delegate: ForecastItem {
                            required property var modelData
                            required property int index
                            
                            width: forecastGrid.cellWidth - 4
                            height: forecastGrid.cellHeight - 4
                            
                            // Pass responsive sizing info
                            availableWidth: forecastGrid.width
                            cardCount: forecastGrid.count
                            cardSpacing: 4
                            
                            label: root.forecastMode ? modelData.time : modelData.day
                            iconPath: root.getWeatherIcon(modelData)
                            temp: modelData.temp
                            isHourly: root.forecastMode
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
