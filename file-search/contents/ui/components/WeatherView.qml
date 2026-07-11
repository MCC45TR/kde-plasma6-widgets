import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasma5support as Plasma5Support
import "WeatherService.js" as WeatherService
import "WeatherIconMapper.js" as WeatherIcons
import "../js/utils.js" as Utils

// LogicController must be injected or accessible
Item {
    id: weatherView
    
    // Properties
    property var plasmoidConfig: null // injected from SearchPopup
    property string queryCity: ""
    property var currentWeather: null
    
    onQueryCityChanged: {
        loadCachedWeatherOrFetch()
    }
    property var forecastDaily: []
    property var forecastHourly: []
    property bool isLoading: true
    property string errorMessage: ""
    property string location: ""
    property bool isFetching: false
    property bool secretsLoaded: false
    property bool secretsLoading: false
    property string secureApiKey: ""
    property string secureApiKey2: ""
    property var secretWaiters: []

    Plasma5Support.DataSource {
        id: secretProcess
        engine: "executable"
        connectedSources: []
        property var callbacks: ({})
        onNewData: (source, data) => {
            if (data["exit code"] === undefined) return
            var callback = callbacks[source]
            if (callback) callback(data["exit code"] === 0, (data["stdout"] || "").replace(/\n$/, ""))
            delete callbacks[source]
            disconnectSource(source)
        }
    }

    function readSecret(entry, callback) {
        var scriptPath = Utils.decodeLocalPath(Qt.resolvedUrl("../../tools/secret_store.sh"))
        var command = "sh " + Utils.shellEscape(scriptPath) + " 'read' " + Utils.shellEscape(entry)
                + " #secret_" + Date.now() + "_" + Math.floor(Math.random() * 1000000)
        secretProcess.callbacks[command] = callback
        secretProcess.connectSource(command)
    }

    function loadWeatherSecrets(callback) {
        if (secretsLoaded) {
            callback()
            return
        }
        secretWaiters.push(callback)
        if (secretsLoading) return
        secretsLoading = true
        var remaining = 2
        function completed() {
            remaining--
            if (remaining > 0) return
            secretsLoaded = true
            secretsLoading = false
            var waiters = secretWaiters.slice()
            secretWaiters = []
            for (var i = 0; i < waiters.length; i++) waiters[i]()
        }
        readSecret("weatherApiKey", function(ok, value) {
            if (ok) secureApiKey = value
            completed()
        })
        readSecret("weatherApiKey2", function(ok, value) {
            if (ok) secureApiKey2 = value
            completed()
        })
    }
    
    // UI Layout Properties expected by mweather sub-components
    property bool forecastMode: false
    property bool largeDetailsOpen: false
    property var selectedForecast: null
    property bool showForecastDetails: false
    
    readonly property font activeFont: Kirigami.Theme.defaultFont
    readonly property real radiusMultiplier: 1.0
    readonly property bool showInnerBackgrounds: true
    readonly property double backgroundOpacity: 0.9
    readonly property bool showForecastUnits: true
    
    readonly property string weatherProvider: plasmoidConfig ? (plasmoidConfig.weatherProvider || "openmeteo") : "openmeteo"
    readonly property string iconPack: plasmoidConfig ? (plasmoidConfig.weatherIconPack || "default") : "default"
    readonly property string units: {
        if (!plasmoidConfig) return "metric";
        if (plasmoidConfig.weatherUseSystemUnits) {
            return Qt.locale().measurementSystem === Locale.MetricSystem ? "metric" : "imperial";
        }
        return plasmoidConfig.weatherUnits || "metric";
    }
    
    readonly property string layoutMode: plasmoidConfig ? (plasmoidConfig.weatherViewMode || "large") : "large"
    readonly property bool isWideMode: layoutMode === "wide"
    readonly property bool isLargeMode: layoutMode === "large"
    readonly property bool isSmallMode: layoutMode === "small"
    
    // Auto-fetch on visible
    onVisibleChanged: {
        if (visible && !currentWeather) {
            loadCachedWeatherOrFetch()
        }
    }

    Component.onCompleted: {
        loadCachedWeatherOrFetch()
    }

    function loadCachedWeatherOrFetch() {
        if (queryCity !== "") {
            fetchWeatherData()
            return
        }
        var cached = (plasmoidConfig && plasmoidConfig.weatherCache) ? plasmoidConfig.weatherCache : ""
        if (cached && cached !== "{}" && cached !== "") {
            try {
                var result = JSON.parse(cached)
                if (result && result.current) {
                    currentWeather = result.current
                    forecastDaily = result.forecast ? result.forecast.daily : []
                    forecastHourly = (result.forecast && result.forecast.hourly) ? result.forecast.hourly : []
                    location = result.current.location
                    isLoading = false
                    errorMessage = ""
                    
                    // Check if stale
                    var lastUpdate = (plasmoidConfig && plasmoidConfig.weatherLastUpdate) ? plasmoidConfig.weatherLastUpdate : 0
                    var refreshInterval = (plasmoidConfig && plasmoidConfig.weatherRefreshInterval !== undefined) ? plasmoidConfig.weatherRefreshInterval : 15
                    var ageMs = Date.now() - lastUpdate
                    if (ageMs > refreshInterval * 60 * 1000 || ageMs < 0) {
                        fetchWeatherData()
                    }
                    return
                }
            } catch (e) {
                console.warn("WeatherView: Failed to parse cached weather:", e)
            }
        }
        fetchWeatherData()
    }
    
    function fetchWeatherData() {
        if (isFetching) return
        isFetching = true
        isLoading = true
        errorMessage = ""
        
        var units = "metric"
        var refreshInterval = 15
        var provider = "openmeteo"
        var locationMode = "auto"
        var loc = ""
        var apiKey = ""
        var apiKey2 = ""
        
        if (plasmoidConfig) {
             if (plasmoidConfig.weatherUseSystemUnits) {
                  units = Qt.locale().measurementSystem === Locale.MetricSystem ? "metric" : "imperial"
             } else {
                  units = plasmoidConfig.weatherUnits || "metric"
             }
             refreshInterval = plasmoidConfig.weatherRefreshInterval !== undefined ? plasmoidConfig.weatherRefreshInterval : 15
             provider = plasmoidConfig.weatherProvider || "openmeteo"
             locationMode = plasmoidConfig.weatherLocationMode || "auto"
             loc = plasmoidConfig.weatherLocation || ""
        }
        
        if (queryCity !== "") {
            locationMode = "manual"
            loc = queryCity
        }
        
        function issueRequest() {
            if (secretsLoaded) {
                apiKey = secureApiKey
                apiKey2 = secureApiKey2
            }
            WeatherService.fetchWeather({
                location: locationMode === "auto" ? "" : loc,
                autoDetect: locationMode === "auto",
                units: units,
                provider: provider,
                apiKey: apiKey,
                apiKey2: apiKey2,
                refreshInterval: refreshInterval
            }, function(result) {
                isFetching = false
                isLoading = false
                if (result.success) {
                    currentWeather = result.current
                    forecastDaily = result.forecast.daily
                    forecastHourly = result.forecast.hourly || []
                    location = result.current.location
                    // Only save cache if this is not a temporary query city search
                    if (plasmoidConfig && queryCity === "") {
                        plasmoidConfig.weatherCache = JSON.stringify(result)
                        if (!result.fromCache) plasmoidConfig.weatherLastUpdate = Date.now()
                    }
                } else {
                    var err = result.error || "Unknown error";
                    if (err === "Location not found" || result.code === 404 || err.indexOf("404") !== -1) {
                        errorMessage = i18nd("plasma_applet_com.mcc45tr.filesearch", "City not found")
                    } else {
                        errorMessage = i18nd("plasma_applet_com.mcc45tr.filesearch", err)
                    }
                }
            })
        }

        if ((provider === "openweathermap" || provider === "weatherapi") && !secretsLoaded) {
            loadWeatherSecrets(issueRequest)
        } else {
            issueRequest()
        }
    }

    Connections {
        target: weatherView.plasmoidConfig
        ignoreUnknownSignals: true
        function onWeatherUpdateTriggerChanged() {
            weatherView.fetchWeatherData()
        }
    }
    
    function calculateIsNight(item) {
        if (!item) return false

        // Determine the reference for sunrise/sunset
        var referenceItem = (item.sunrise && item.sunset) ? item : weatherView.currentWeather

        if (!referenceItem || !referenceItem.sunrise || !referenceItem.sunset) {
            // Fallback: no sunrise/sunset data at all, use simple hour range
            var fallbackHour = item.timestamp ? new Date(item.timestamp).getHours() : new Date().getHours()
            return fallbackHour < 6 || fallbackHour >= 20
        }

        // Determine the hour to compare
        var compareDate
        if (item.timestamp) {
            compareDate = new Date(item.timestamp)
        } else if (item.date) {
            // Daily forecast item with a date string but no timestamp — show as daytime
            return false
        } else {
            compareDate = new Date()
        }

        // Parse sunrise/sunset to extract hours and minutes in local time
        var sunriseDate = new Date(referenceItem.sunrise)
        var sunsetDate = new Date(referenceItem.sunset)

        // Convert everything to minutes-since-midnight for clean comparison
        var compareMinutes = compareDate.getHours() * 60 + compareDate.getMinutes()
        var sunriseMinutes = sunriseDate.getHours() * 60 + sunriseDate.getMinutes()
        var sunsetMinutes = sunsetDate.getHours() * 60 + sunsetDate.getMinutes()

        // It's night if current time is before sunrise or after sunset
        return compareMinutes < sunriseMinutes || compareMinutes >= sunsetMinutes
    }

    function getWeatherIcon(item) {
        if (!item) return Qt.resolvedUrl("../../images/clear_day.svg")
        var isNight = calculateIsNight(item)
        var provider = (plasmoidConfig && plasmoidConfig.weatherProvider) ? plasmoidConfig.weatherProvider : "openmeteo"
        var pack = (plasmoidConfig && plasmoidConfig.weatherIconPack) ? plasmoidConfig.weatherIconPack : "default"
        var path = WeatherIcons.getIconPath(item.code, provider, isNight, pack)
        if (path.indexOf("/") !== -1) {
            return Qt.resolvedUrl(path)
        }
        return path
    }

    function getLocalizedDay(dayIndex) {
        if (dayIndex === undefined) return ""
        return Qt.locale().dayName(dayIndex, Locale.ShortFormat)
    }

    // Main Layout
    Rectangle {
        anchors.fill: parent
        color: "transparent" // Parent usually provides background or it's transparent in popup

        // Loading State
        ColumnLayout {
            anchors.centerIn: parent
            visible: weatherView.isLoading
            spacing: 10
            BusyIndicator { running: weatherView.isLoading; Layout.alignment: Qt.AlignHCenter }
            Label { text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Loading weather data..."); color: Kirigami.Theme.textColor; font.pixelSize: 14; Layout.alignment: Qt.AlignHCenter }
        }

        // Error State
        ColumnLayout {
            anchors.centerIn: parent
            visible: !weatherView.isLoading && weatherView.errorMessage !== ""
            spacing: 10
            width: parent.width * 0.8
            Kirigami.Icon { source: "dialog-error"; Layout.preferredWidth: 32; Layout.preferredHeight: 32; Layout.alignment: Qt.AlignHCenter }
            Label { text: weatherView.errorMessage; color: Kirigami.Theme.textColor; font.pixelSize: 13; Layout.alignment: Qt.AlignHCenter; horizontalAlignment: Text.AlignHCenter; wrapMode: Text.Wrap; Layout.fillWidth: true }
            Button { text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Refresh"); Layout.alignment: Qt.AlignHCenter; onClicked: weatherView.fetchWeatherData() }
        }

        // Content State - Dynamic loaders for different view modes
        Loader {
            anchors.fill: parent
            anchors.margins: 8
            active: !weatherView.isLoading && weatherView.errorMessage === "" && weatherView.currentWeather !== null && weatherView.isWideMode
            sourceComponent: WideModeLayout { weatherRoot: weatherView }
        }

        Loader {
            anchors.fill: parent
            anchors.margins: 0
            active: !weatherView.isLoading && weatherView.errorMessage === "" && weatherView.currentWeather !== null && weatherView.isSmallMode
            sourceComponent: SmallModeLayout { weatherRoot: weatherView }
        }

        Loader {
            anchors.fill: parent
            anchors.margins: 10
            active: !weatherView.isLoading && weatherView.errorMessage === "" && weatherView.currentWeather !== null && weatherView.isLargeMode
            sourceComponent: LargeModeLayout { weatherRoot: weatherView }
        }
    }

    // Keep translated condition strings discoverable by xgettext.
    function dummyTranslations() {
        i18nd("plasma_applet_com.mcc45tr.filesearch", "Clear")
        i18nd("plasma_applet_com.mcc45tr.filesearch", "Mainly Clear")
        i18nd("plasma_applet_com.mcc45tr.filesearch", "Partly Cloudy")
        i18nd("plasma_applet_com.mcc45tr.filesearch", "Overcast")
        i18nd("plasma_applet_com.mcc45tr.filesearch", "Fog")
        i18nd("plasma_applet_com.mcc45tr.filesearch", "Drizzle")
        i18nd("plasma_applet_com.mcc45tr.filesearch", "Freezing Drizzle")
        i18nd("plasma_applet_com.mcc45tr.filesearch", "Rain")
        i18nd("plasma_applet_com.mcc45tr.filesearch", "Freezing Rain")
        i18nd("plasma_applet_com.mcc45tr.filesearch", "Snow")
        i18nd("plasma_applet_com.mcc45tr.filesearch", "Snow Grains")
        i18nd("plasma_applet_com.mcc45tr.filesearch", "Rain Showers")
        i18nd("plasma_applet_com.mcc45tr.filesearch", "Snow Showers")
        i18nd("plasma_applet_com.mcc45tr.filesearch", "Thunderstorm")
        i18nd("plasma_applet_com.mcc45tr.filesearch", "Thunderstorm with Hail")
        i18nd("plasma_applet_com.mcc45tr.filesearch", "Unknown")
        i18nd("plasma_applet_com.mcc45tr.filesearch", "Cloudy")
        i18nd("plasma_applet_com.mcc45tr.filesearch", "Mist")
        i18nd("plasma_applet_com.mcc45tr.filesearch", "Smoke")
        i18nd("plasma_applet_com.mcc45tr.filesearch", "Haze")
        i18nd("plasma_applet_com.mcc45tr.filesearch", "Dust")
        i18nd("plasma_applet_com.mcc45tr.filesearch", "Sand")
        i18nd("plasma_applet_com.mcc45tr.filesearch", "Ash")
        i18nd("plasma_applet_com.mcc45tr.filesearch", "Squall")
        i18nd("plasma_applet_com.mcc45tr.filesearch", "Tornado")
    }
}
