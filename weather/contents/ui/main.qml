import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import "WeatherService.js" as WeatherService
import "IconMapper.js" as IconMapper
import "localization.js" as LocalizationData

PlasmoidItem {
    id: root

    // Localization (loaded from JSON at runtime)
    property var locales: ({})
    property string currentLocale: Qt.locale().name.substring(0, 2)
    property bool localesLoaded: false

    // Localization function
    function tr(key) {
        if (locales[currentLocale] && locales[currentLocale][key]) return locales[currentLocale][key]
        if (locales["en"] && locales["en"][key]) return locales["en"][key]
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



    Component.onCompleted: {
        // Load and transform localization data synchronously
        try {
            var json = LocalizationData.data
            var newLocales = {}
            for (var key in json) {
                var translations = json[key]
                for (var lang in translations) {
                    if (!newLocales[lang]) newLocales[lang] = {}
                    newLocales[lang][key] = translations[lang]
                }
            }
            locales = newLocales
            console.log("Localization loaded via JS import")
        } catch(e) {
            console.log("Error processing localization data: " + e)
        }

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
