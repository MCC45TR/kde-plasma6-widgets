import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCore
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import "WeatherService.js" as WeatherService
import "IconMapper.js" as IconMapper

PlasmoidItem {
    id: root

    Layout.preferredWidth: 400
    Layout.preferredHeight: 200
    Layout.minimumWidth: 200
    Layout.minimumHeight: 200

    readonly property string apiKey: Plasmoid.configuration.apiKey || ""
    readonly property string apiKey2: Plasmoid.configuration.apiKey2 || ""
    readonly property string locationMode: Plasmoid.configuration.locationMode || "manual"
    readonly property string location: Plasmoid.configuration.location || ""
    readonly property string location2: Plasmoid.configuration.location2 || ""
    readonly property string location3: Plasmoid.configuration.location3 || ""
    readonly property bool useSystemUnits: Plasmoid.configuration.useSystemUnits || false
    readonly property string configuredUnits: Plasmoid.configuration.units || "metric"
    readonly property string units: useSystemUnits ? detectSystemUnits() : configuredUnits
    readonly property string weatherProvider: Plasmoid.configuration.weatherProvider || "openmeteo"
    readonly property string iconPack: Plasmoid.configuration.iconPack || "default"
    readonly property int updateInterval: Plasmoid.configuration.updateInterval || 30
    readonly property double backgroundOpacity: {
        if (isPanel) return 0.0
        var op = Plasmoid.configuration.backgroundOpacity
        if (op === -1.0) return 0.0 // Full transparent mode
        return (op !== undefined) ? op : 0.9
    }
    
    // New property to control inner elements transparency
    readonly property bool showInnerBackgrounds: (Plasmoid.configuration.backgroundOpacity !== -1.0)
    readonly property string panelMode: Plasmoid.configuration.panelMode || "simple"
    readonly property int panelFontSize: Plasmoid.configuration.panelFontSize || 0
    readonly property int panelIconSize: Plasmoid.configuration.panelIconSize || 0
    readonly property string layoutMode: Plasmoid.configuration.layoutMode || "auto"
    readonly property int forecastDays: Plasmoid.configuration.forecastDays || 5
    readonly property int edgeMargin: Plasmoid.configuration.edgeMargin !== undefined ? Plasmoid.configuration.edgeMargin : 10
    readonly property bool showForecastUnits: Plasmoid.configuration.showForecastUnits !== undefined ? Plasmoid.configuration.showForecastUnits : true
    
    readonly property string cornerRadiusMode: Plasmoid.configuration.cornerRadius || "normal"
    
    // Notification settings
    readonly property bool notifyEnabled: Plasmoid.configuration.notifyEnabled || false
    readonly property bool notifyRoutineEnabled: Plasmoid.configuration.notifyRoutineEnabled || false
    readonly property int notifyRoutineTime1: Plasmoid.configuration.notifyRoutineTime1 !== undefined ? Plasmoid.configuration.notifyRoutineTime1 : 480
    readonly property int notifyRoutineTime2: Plasmoid.configuration.notifyRoutineTime2 !== undefined ? Plasmoid.configuration.notifyRoutineTime2 : 1140
    readonly property bool notifyRoutineTime2Enabled: Plasmoid.configuration.notifyRoutineTime2Enabled || false
    readonly property string notifyRoutineType: Plasmoid.configuration.notifyRoutineType || "forecast_3day"
    readonly property bool notifySevereWeather: Plasmoid.configuration.notifySevereWeather !== undefined ? Plasmoid.configuration.notifySevereWeather : true
    readonly property bool notifyRain: Plasmoid.configuration.notifyRain !== undefined ? Plasmoid.configuration.notifyRain : true
    readonly property bool notifyTemperatureDrop: Plasmoid.configuration.notifyTemperatureDrop || false
    readonly property int notifyTemperatureThreshold: Plasmoid.configuration.notifyTemperatureThreshold || 0
    readonly property bool notifyHighTemp: Plasmoid.configuration.notifyHighTemp !== undefined ? Plasmoid.configuration.notifyHighTemp : false
    readonly property int notifyHighTempThreshold: Plasmoid.configuration.notifyHighTempThreshold !== undefined ? Plasmoid.configuration.notifyHighTempThreshold : 30
    readonly property bool notifyUvIndex: Plasmoid.configuration.notifyUvIndex !== undefined ? Plasmoid.configuration.notifyUvIndex : true
    readonly property int notifyUvThreshold: Plasmoid.configuration.notifyUvThreshold !== undefined ? Plasmoid.configuration.notifyUvThreshold : 6
    readonly property bool notifyWind: Plasmoid.configuration.notifyWind !== undefined ? Plasmoid.configuration.notifyWind : true
    readonly property int notifyWindThreshold: Plasmoid.configuration.notifyWindThreshold !== undefined ? Plasmoid.configuration.notifyWindThreshold : 50
    readonly property real radiusMultiplier: {
        if (cornerRadiusMode === "small") return 0.5
        if (cornerRadiusMode === "square") return 0.0
        return 1.0
    }

    readonly property bool isPanel: Plasmoid.formFactor === PlasmaCore.Types.Horizontal || Plasmoid.formFactor === PlasmaCore.Types.Vertical
    readonly property int refreshIntervalMs: Math.max(1, updateInterval) * 60 * 1000
    readonly property string weatherRequestKey: WeatherService.cacheKeyForConfig({
        provider: weatherProvider,
        units: units,
        location: getActiveLocation(),
        autoDetect: locationMode === "auto",
        forecastDays: forecastDays
    })

    Settings {
        id: runtimeState
        location: StandardPaths.writableLocation(StandardPaths.GenericConfigLocation) + "/mweather-runtime.ini"
        category: "Applet-" + Plasmoid.id

        property string cachedWeather: ""
        property string cacheKey: ""
        property double lastUpdate: 0
        property string lastRoutineDate1: ""
        property string lastRoutineDate2: ""
        property double lastSevereNotify: 0
        property double lastRainNotify: 0
        property double lastTempNotify: 0
        property double lastHighTempNotify: 0
        property double lastUvNotify: 0
        property double lastWindNotify: 0
    }
    
    // Notification Manager
    Loader {
        id: notificationManagerLoader
        active: root.notifyEnabled
        sourceComponent: NotificationManager {
            currentWeather: root.currentWeather
            forecastHourly: root.forecastHourly
            forecastDaily: root.forecastDaily
            units: root.units
            enabled: root.notifyEnabled
            routineEnabled: root.notifyRoutineEnabled
            routineTime1: root.notifyRoutineTime1
            routineTime2: root.notifyRoutineTime2
            routineTime2Enabled: root.notifyRoutineTime2Enabled
            routineType: root.notifyRoutineType
            severeWeatherEnabled: root.notifySevereWeather
            rainEnabled: root.notifyRain
            temperatureDropEnabled: root.notifyTemperatureDrop
            temperatureThreshold: root.notifyTemperatureThreshold
            notifyHighTemp: root.notifyHighTemp
            notifyHighTempThreshold: root.notifyHighTempThreshold
            notifyUvIndex: root.notifyUvIndex
            notifyUvThreshold: root.notifyUvThreshold
            notifyWind: root.notifyWind
            notifyWindThreshold: root.notifyWindThreshold
            stateStore: runtimeState
        }
    }
    readonly property bool isWideMode: layoutMode === "wide" || (layoutMode === "auto" && root.width > 350 && root.height <= 350)
    readonly property bool isLargeMode: layoutMode === "large" || (layoutMode === "auto" && root.width > 350 && root.height > 350)
    readonly property bool isSmallMode: layoutMode === "small" || (layoutMode === "auto" && !isWideMode && !isLargeMode)

    property var currentWeather: null
    property var forecastDaily: []
    property var forecastHourly: []
    property string apiProvider: ""
    property bool isLoading: true
    property string errorMessage: ""
    property bool forecastMode: false
    property bool largeDetailsOpen: false
    property double lastSuccessfulFetch: 0
    property double lastFetchAttempt: 0
    property int fetchGeneration: 0
    property bool componentReady: false
    
    property var selectedForecast: null
    property bool showForecastDetails: false
    property rect clickedCardRect: Qt.rect(0, 0, 0, 0)

    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: i18n("Refresh")
            icon.name: "view-refresh"
            onTriggered: root.fetchWeatherData(true, true)
        },
        PlasmaCore.Action {
            text: root.forecastMode ? i18n("Daily Forecast") : i18n("Hourly Forecast")
            icon.name: root.forecastMode ? "view-calendar-month" : "view-calendar-day"
            onTriggered: root.forecastMode = !root.forecastMode
        }
    ]
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: {
            var now = Date.now()
            if (!root.isLoading && now - root.lastSuccessfulFetch >= root.refreshIntervalMs && now - root.lastFetchAttempt >= 60000) {
                root.fetchWeatherData(root.currentWeather === null, false)
            }
        }
    }

    Timer {
        id: requestWatchdog
        interval: 45000
        repeat: false
        property int generation: 0
        property bool foreground: false
        onTriggered: {
            if (generation !== root.fetchGeneration) return
            root.fetchGeneration++
            WeatherService.cancelRequest({
                provider: root.weatherProvider,
                units: root.units,
                location: root.getActiveLocation(),
                autoDetect: root.locationMode === "auto",
                forecastDays: root.forecastDays,
                clientId: String(Plasmoid.id)
            })
            root.isLoading = false
            if (foreground || !root.currentWeather) root.errorMessage = i18n("Weather request timed out. Please check your connection and try again.")
        }
    }

    onWeatherRequestKeyChanged: {
        if (componentReady) {
            lastSuccessfulFetch = 0
            fetchWeatherData(true, true)
        }
    }

    function detectSystemUnits() {
        var measurementSystem = Qt.locale().measurementSystem
        return measurementSystem === 0 ? "metric" : "imperial"
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
        componentReady = true
        var cached = runtimeState.cacheKey === weatherRequestKey ? runtimeState.cachedWeather : ""
        if (cached.length > 0) {
            try {
                processWeatherData(JSON.parse(cached))
                isLoading = false
                lastSuccessfulFetch = runtimeState.lastUpdate || 0
                if (Date.now() - lastSuccessfulFetch >= refreshIntervalMs) fetchWeatherData(false, false)
            } catch (e) {
                console.warn("MWeather: failed to read runtime cache:", e)
                fetchWeatherData(true, false)
            }
        } else {
            fetchWeatherData(true, false)
        }
    }

    function fetchWeatherData(showLoading, forceRefresh) {
        var requestGeneration = ++fetchGeneration
        lastFetchAttempt = Date.now()
        if (showLoading === undefined || showLoading) isLoading = true
        requestWatchdog.generation = requestGeneration
        requestWatchdog.foreground = showLoading === undefined || showLoading
        requestWatchdog.restart()
        WeatherService.fetchWeather({
            apiKey: apiKey,
            apiKey2: apiKey2,
            location: getActiveLocation(),
            units: units,
            provider: weatherProvider,
            autoDetect: locationMode === "auto",
            forecastDays: forecastDays,
            forceRefresh: forceRefresh === true,
            clientId: String(Plasmoid.id)
        }, function(result) {
            if (requestGeneration !== fetchGeneration) return
            requestWatchdog.stop()
            isLoading = false
            if (result.success) {
                processWeatherData(result)
                lastSuccessfulFetch = result.fetchedAt || Date.now()
                runtimeState.cachedWeather = JSON.stringify(result)
                runtimeState.cacheKey = weatherRequestKey
                runtimeState.lastUpdate = lastSuccessfulFetch
                runtimeState.sync()
                
                // Check notifications after successful fetch
                if (notificationManagerLoader.item) {
                    notificationManagerLoader.item.checkNotifications()
                }
            } else {
                errorMessage = result.error || "Unknown error"
            }
        })
    }

    function calculateIsNight(item) {
        if (!item) return false

        // Determine the reference for sunrise/sunset
        var referenceItem = (item.sunrise && item.sunset) ? item : root.currentWeather

        if (!referenceItem || !referenceItem.sunrise || !referenceItem.sunset) {
            // Fallback: no sunrise/sunset data at all, use simple hour range
            var fallbackHour = new Date().getHours()
            return fallbackHour < 6 || fallbackHour >= 20
        }

        // Determine the hour to compare
        var compareDate
        if (item.timestamp && item !== root.currentWeather) {
            compareDate = item.timestamp
        } else if (item.date) {
            // Daily forecast item with a date string but no timestamp — show as daytime
            return false
        } else {
            compareDate = Date.now()
        }

        var offset = referenceItem.timezone_offset || 0
        var compareMinutes = minutesAtLocation(compareDate, offset)
        var sunriseMinutes = minutesAtLocation(referenceItem.sunrise, offset)
        var sunsetMinutes = minutesAtLocation(referenceItem.sunset, offset)

        // It's night if current time is before sunrise or after sunset
        return compareMinutes < sunriseMinutes || compareMinutes >= sunsetMinutes
    }

    function getWeatherIcon(item) {
        if (!item) return Qt.resolvedUrl("../images/clear_day.svg")
        
        var isNight = calculateIsNight(item)
        var iconPath = IconMapper.getIconPath(item.code, item.icon, apiProvider || weatherProvider, isNight, iconPack)

        if (iconPath.indexOf("/") !== -1) {
            return Qt.resolvedUrl(iconPath)
        }

        return iconPath
    }

    function minutesAtLocation(epochMs, utcOffsetSeconds) {
        var shifted = new Date(epochMs + utcOffsetSeconds * 1000)
        return shifted.getUTCHours() * 60 + shifted.getUTCMinutes()
    }

    function formatWeatherTime(epochMs, utcOffsetSeconds) {
        if (epochMs === undefined || epochMs === null) return "--"
        var shifted = new Date(epochMs + (utcOffsetSeconds || 0) * 1000)
        return shifted.getUTCHours().toString().padStart(2, "0") + ":" + shifted.getUTCMinutes().toString().padStart(2, "0")
    }

    function displayWindSpeed(speedKmh) {
        if (speedKmh === undefined || speedKmh === null) return "--"
        return units === "imperial" ? Math.round(speedKmh * 0.621371) + " mph" : Math.round(speedKmh) + " km/h"
    }

    function displayVisibility(distanceKm) {
        if (distanceKm === undefined || distanceKm === null) return "--"
        return units === "imperial" ? Math.round(distanceKm * 0.621371 * 10) / 10 + " mi" : distanceKm + " km"
    }

    function getLocalizedDay(dayIndex) {
        if (dayIndex === undefined) return ""
        return Qt.locale().dayName(dayIndex, Locale.ShortFormat)
    }

    compactRepresentation: Item {
        id: compactRep
        readonly property bool detailed: root.panelMode === "detailed"

        Layout.minimumWidth: detailed ? detailedLayout.implicitWidth : simpleLayout.implicitWidth
        Layout.preferredWidth: detailed ? detailedLayout.implicitWidth : simpleLayout.implicitWidth

        MouseArea {
            anchors.fill: parent
            onClicked: root.expanded = !root.expanded
        }

        RowLayout {
            id: simpleLayout
            anchors.centerIn: parent
            spacing: 0
            visible: !compactRep.detailed

            Kirigami.Icon {
                source: root.getWeatherIcon(root.currentWeather)
                Layout.preferredHeight: root.panelIconSize > 0 ? root.panelIconSize : compactRep.height * 0.8
                Layout.preferredWidth: height
                isMask: false
                smooth: true
                Layout.alignment: Qt.AlignVCenter
            }
                Text {
                    text: root.currentWeather ? Math.round(root.currentWeather.temp) + "°" : "--"
                    color: Kirigami.Theme.textColor
                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: root.panelFontSize > 0 ? root.panelFontSize : compactRep.height * 0.5
                    font.family: root.activeFont.family
                    font.bold: true
                    Layout.alignment: Qt.AlignVCenter
                    leftPadding: 4
                }
            }

            RowLayout {
                id: detailedLayout
                anchors.centerIn: parent
                spacing: 6
                visible: compactRep.detailed

                Kirigami.Icon {
                    source: root.getWeatherIcon(root.currentWeather)
                    Layout.preferredHeight: root.panelIconSize > 0 ? root.panelIconSize : compactRep.height * 0.8
                    Layout.preferredWidth: height
                    isMask: false
                    smooth: true
                    Layout.alignment: Qt.AlignVCenter
                }

                ColumnLayout {
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 0

                    Text {
                        text: root.currentWeather ? Math.round(root.currentWeather.temp) + (root.units === "metric" ? "°C" : "°F") : "--"
                        color: Kirigami.Theme.textColor
                        font.pixelSize: root.panelFontSize > 0 ? root.panelFontSize : compactRep.height * 0.4
                        font.family: root.activeFont.family
                        font.bold: true
                        lineHeight: 0.8
                    }

                    Text {
                        text: root.currentWeather ? i18n(root.currentWeather.condition) : ""
                        color: Kirigami.Theme.textColor
                        font.pixelSize: root.panelFontSize > 0 ? root.panelFontSize * 0.6 : compactRep.height * 0.25
                        font.family: root.activeFont.family
                        opacity: 0.8
                        elide: Text.ElideRight
                        lineHeight: 0.8
                    }
            }
        }
    }

    preferredRepresentation: (Plasmoid.formFactor === PlasmaCore.Types.Horizontal || Plasmoid.formFactor === PlasmaCore.Types.Vertical) ? compactRepresentation : fullRepresentation

    readonly property bool useCustomFont: Plasmoid.configuration.useCustomFont || false
    readonly property string customFontFamily: Plasmoid.configuration.customFontFamily || ""
    readonly property font activeFont: useCustomFont && customFontFamily !== "" ? Qt.font({ family: customFontFamily }) : Kirigami.Theme.defaultFont

    fullRepresentation: Item {
        id: fullRep
        anchors.fill: parent

        Rectangle {
            id: mainRect
            anchors.fill: parent
            anchors.margins: (Plasmoid.formFactor === PlasmaCore.Types.Horizontal || Plasmoid.formFactor === PlasmaCore.Types.Vertical) ? 0 : root.edgeMargin
            color: Qt.rgba(Kirigami.Theme.backgroundColor.r, Kirigami.Theme.backgroundColor.g, Kirigami.Theme.backgroundColor.b, root.backgroundOpacity)
            radius: 20 * root.radiusMultiplier
            clip: true

            property font font: root.activeFont

            ColumnLayout {
                anchors.centerIn: parent
                visible: root.isLoading
                spacing: 10
                BusyIndicator { running: root.isLoading; Layout.alignment: Qt.AlignHCenter }
                Text { text: i18n("Loading weather data..."); color: Kirigami.Theme.textColor; font.pixelSize: 14; Layout.alignment: Qt.AlignHCenter }
            }

            ColumnLayout {
                anchors.centerIn: parent
                visible: !root.isLoading && root.errorMessage !== ""
                spacing: 10
                width: parent.width * 0.8
                Kirigami.Icon { source: "dialog-error"; Layout.preferredWidth: 48; Layout.preferredHeight: 48; Layout.alignment: Qt.AlignHCenter }
                Text { text: root.errorMessage; color: Kirigami.Theme.textColor; font.pixelSize: 13; Layout.alignment: Qt.AlignHCenter; horizontalAlignment: Text.AlignHCenter; wrapMode: Text.Wrap; Layout.fillWidth: true }
                Button { text: i18n("Refresh"); Layout.alignment: Qt.AlignHCenter; onClicked: root.fetchWeatherData(true, true) }
            }

            Loader {
                anchors.fill: parent
                anchors.margins: 8
                active: !root.isLoading && root.errorMessage === "" && root.currentWeather && root.isWideMode
                sourceComponent: WideModeLayout { weatherRoot: root }
            }

            Loader {
                anchors.fill: parent
                anchors.margins: 0
                active: !root.isLoading && root.errorMessage === "" && root.currentWeather && root.isSmallMode
                sourceComponent: SmallModeLayout { weatherRoot: root }
            }

            Loader {
                anchors.fill: parent
                anchors.margins: 10
                active: !root.isLoading && root.errorMessage === "" && root.currentWeather && root.isLargeMode
                sourceComponent: LargeModeLayout { weatherRoot: root }
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.MiddleButton
                onClicked: (mouse) => { if (mouse.button === Qt.MiddleButton) root.fetchWeatherData(true, true) }
            }
        }
    // Keep translated condition strings discoverable by xgettext.
    function translationDummy() {
        i18n("Clear")
        i18n("Mainly Clear")
        i18n("Partly Cloudy")
        i18n("Overcast")
        i18n("Fog")
        i18n("Drizzle")
        i18n("Freezing Drizzle")
        i18n("Rain")
        i18n("Freezing Rain")
        i18n("Snow")
        i18n("Snow Grains")
        i18n("Rain Showers")
        i18n("Snow Showers")
        i18n("Thunderstorm")
        i18n("Thunderstorm with Hail")
        i18n("Unknown")
        i18n("Cloudy")
        i18n("Mist")
        i18n("Smoke")
        i18n("Haze")
        i18n("Dust")
        i18n("Sand")
        i18n("Ash")
        i18n("Squall")
        i18n("Tornado")
    }
}
}
