import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import "WeatherService.js" as WeatherService
import "IconMapper.js" as IconMapper

PlasmoidItem {
    id: root

    // Localization with inline fallbacks (in case JSON loading fails)
    property var locales: ({
        "en": {
            "loading": "Loading weather data...",
            "error_network": "Network error. Check your internet connection.",
            "error_no_api_key": "No API key configured.",
            "error_invalid_location": "Location not found.",
            "refresh": "Refresh",
            "daily_forecast": "Daily",
            "hourly_forecast": "Hourly",
            "details": "Details",
            "feels_like": "Feels Like",
            "humidity": "Humidity",
            "wind": "Wind",
            "pressure": "Pressure",
            "clouds": "Clouds",
            "uv_index": "UV",
            "visibility": "Visibility",
            "wind_direction": "Direction",
            "close_hint": "Click to close",
            "mon": "MON", "tue": "TUE", "wed": "WED", "thu": "THU", "fri": "FRI", "sat": "SAT", "sun": "SUN",
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
            "error_no_api_key": "API anahtarı ayarlanmadı.",
            "error_invalid_location": "Konum bulunamadı.",
            "refresh": "Yenile",
            "daily_forecast": "Günlük",
            "hourly_forecast": "Saatlik",
            "details": "Detay",
            "feels_like": "Hissedilen",
            "humidity": "Nem",
            "wind": "Rüzgar",
            "pressure": "Basınç",
            "clouds": "Bulut",
            "uv_index": "UV",
            "visibility": "Görüş",
            "wind_direction": "Yön",
            "close_hint": "Kapatmak için tıklayın",
            "mon": "PZT", "tue": "SAL", "wed": "ÇAR", "thu": "PER", "fri": "CUM", "sat": "CMT", "sun": "PAZ",
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
    })
    property string currentLocale: Qt.locale().name.substring(0, 2)
    property bool localesLoaded: false

    // Localization function with English fallback for unsupported languages
    function tr(key) {
        // First try current system locale
        if (locales[currentLocale] && locales[currentLocale][key]) {
            return locales[currentLocale][key]
        }
        // Fallback to English for unsupported languages
        if (locales["en"] && locales["en"][key]) {
            return locales["en"][key]
        }
        // Return key as last resort
        return key
    }

    // Widget Size Constraints
    Layout.preferredWidth: 400
    Layout.preferredHeight: 200
    Layout.minimumWidth: 200
    Layout.minimumHeight: 200

    // Configuration Properties
    readonly property string apiKey: Plasmoid.configuration.apiKey || ""
    readonly property string apiKey2: Plasmoid.configuration.apiKey2 || ""
    readonly property string locationMode: Plasmoid.configuration.locationMode || "auto"
    readonly property string location: Plasmoid.configuration.location || ""
    readonly property string location2: Plasmoid.configuration.location2 || ""
    readonly property string location3: Plasmoid.configuration.location3 || ""
    readonly property bool useSystemUnits: Plasmoid.configuration.useSystemUnits || false
    readonly property string configuredUnits: Plasmoid.configuration.units || "metric"
    readonly property string units: useSystemUnits ? detectSystemUnits() : configuredUnits
    readonly property string weatherProvider: Plasmoid.configuration.weatherProvider || "openmeteo"
    readonly property string iconPack: Plasmoid.configuration.iconPack || "default"
    readonly property int updateInterval: Plasmoid.configuration.updateInterval || 30

    // Layout Mode Detection
    readonly property bool isWideMode: root.width > 350 && root.height <= 350
    readonly property bool isLargeMode: root.width > 350 && root.height > 350
    readonly property bool isSmallMode: !isWideMode && !isLargeMode

    // Weather Data State
    property var currentWeather: null
    property var forecastDaily: []
    property var forecastHourly: []
    property string apiProvider: ""
    property bool isLoading: true
    property string errorMessage: ""
    property bool forecastMode: false
    property bool largeDetailsOpen: false
    property int lastFetchMinute: -1

    // Context Menu Actions
    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: root.tr("refresh")
            icon.name: "view-refresh"
            onTriggered: root.fetchWeatherData()
        },
        PlasmaCore.Action {
            text: root.forecastMode ? root.tr("daily_forecast") : root.tr("hourly_forecast")
            icon.name: root.forecastMode ? "view-calendar-month" : "view-calendar-day"
            onTriggered: root.forecastMode = !root.forecastMode
        }
    ]
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    // Auto-refresh Timer
    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: {
            var min = new Date().getMinutes()
            if ((min === 0 || min === 30) && lastFetchMinute !== min) {
                fetchWeatherData()
                lastFetchMinute = min
            }
        }
    }

    Component.onCompleted: {
        loadLocales()
        var cached = Plasmoid.configuration.cachedWeather
        if (cached && cached.length > 0) {
            try {
                processWeatherData(JSON.parse(cached))
                isLoading = false
            } catch (e) {
                fetchWeatherData()
            }
        } else {
            fetchWeatherData()
        }
    }

    function detectSystemUnits() {
        var imperialLocales = ["en_US", "en_LR", "en_MM"]
        return imperialLocales.indexOf(Qt.locale().name) >= 0 ? "imperial" : "metric"
    }

    function getActiveLocation() {
        if (locationMode === "auto") return ""
        return location || location2 || location3 || ""
    }

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

    function loadLocales() {
        var xhr = new XMLHttpRequest()
        xhr.open("GET", Qt.resolvedUrl("localization.json"))
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE && xhr.status === 200) {
                try {
                    var json = JSON.parse(xhr.responseText)
                    // Start with existing inline locales as base
                    var mergedLocales = JSON.parse(JSON.stringify(locales))
                    // Merge JSON data into existing locales
                    for (var key in json) {
                        var translations = json[key]
                        for (var lang in translations) {
                            if (!mergedLocales[lang]) mergedLocales[lang] = {}
                            mergedLocales[lang][key] = translations[lang]
                        }
                    }
                    locales = mergedLocales
                    localesLoaded = true
                    console.log("Localization loaded and merged successfully")
                } catch (e) {
                    console.log("Failed to parse localization.json: " + e + " - using inline fallbacks")
                }
            } else if (xhr.readyState === XMLHttpRequest.DONE) {
                console.log("Localization JSON not available (status: " + xhr.status + ") - using inline fallbacks")
            }
        }
        xhr.send()
    }

    function fetchWeatherData() {
        isLoading = true
        WeatherService.fetchWeather({
            apiKey: apiKey,
            apiKey2: apiKey2,
            location: getActiveLocation(),
            units: units,
            provider: weatherProvider,
            autoDetect: locationMode === "auto"
        }, function(result) {
            isLoading = false
            if (result.success) {
                processWeatherData(result)
                Plasmoid.configuration.cachedWeather = JSON.stringify(result)
                Plasmoid.configuration.lastUpdate = new Date().getTime()
            } else {
                errorMessage = result.error || "Unknown error"
            }
        })
    }

    function getWeatherIcon(item) {
        if (!item) return "../images/clear_day.svg"
        var isDark = ((Kirigami.Theme.backgroundColor.r + Kirigami.Theme.backgroundColor.g + Kirigami.Theme.backgroundColor.b) / 3) < 0.5
        return IconMapper.getIconPath(item.code, item.icon, weatherProvider, isDark, iconPack)
    }

    function getLocalizedDay(dayKey) {
        if (!dayKey) return ""
        return tr(dayKey.toLowerCase()).toUpperCase()
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
                BusyIndicator { running: root.isLoading; Layout.alignment: Qt.AlignHCenter }
                Text { text: root.tr("loading"); color: Kirigami.Theme.textColor; font.pixelSize: 14; Layout.alignment: Qt.AlignHCenter }
            }

            // Error State
            ColumnLayout {
                anchors.centerIn: parent
                visible: !root.isLoading && root.errorMessage !== ""
                spacing: 10
                width: parent.width * 0.8
                Kirigami.Icon { source: "dialog-error"; Layout.preferredWidth: 48; Layout.preferredHeight: 48; Layout.alignment: Qt.AlignHCenter }
                Text { text: root.errorMessage; color: Kirigami.Theme.textColor; font.pixelSize: 13; Layout.alignment: Qt.AlignHCenter; horizontalAlignment: Text.AlignHCenter; wrapMode: Text.Wrap; Layout.fillWidth: true }
                Button { text: root.tr("refresh"); Layout.alignment: Qt.AlignHCenter; onClicked: root.fetchWeatherData() }
            }

            // Lazy-loaded Mode Layouts
            Loader {
                anchors.fill: parent
                anchors.margins: 8
                active: !root.isLoading && root.errorMessage === "" && root.currentWeather && root.isWideMode
                sourceComponent: WideModeLayout { weatherRoot: root }
            }

            Loader {
                anchors.fill: parent
                anchors.margins: 10
                active: !root.isLoading && root.errorMessage === "" && root.currentWeather && root.isSmallMode
                sourceComponent: SmallModeLayout { weatherRoot: root }
            }

            Loader {
                anchors.fill: parent
                anchors.margins: 20
                active: !root.isLoading && root.errorMessage === "" && root.currentWeather && root.isLargeMode
                sourceComponent: LargeModeLayout { weatherRoot: root }
            }

            // Middle-click Refresh
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.MiddleButton
                onClicked: (mouse) => { if (mouse.button === Qt.MiddleButton) root.fetchWeatherData() }
            }
        }
    }
}
