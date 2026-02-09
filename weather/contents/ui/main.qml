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

    Layout.preferredWidth: 400
    Layout.preferredHeight: 200
    Layout.minimumWidth: 200
    Layout.minimumHeight: 200

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
    readonly property real radiusMultiplier: {
        if (cornerRadiusMode === "small") return 0.5
        if (cornerRadiusMode === "square") return 0.0
        return 1.0
    }

    readonly property bool isPanel: Plasmoid.formFactor === PlasmaCore.Types.Horizontal || Plasmoid.formFactor === PlasmaCore.Types.Vertical
    readonly property double triggerTestNotification: Plasmoid.configuration.triggerTestNotification || 0
    
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
            testNotificationTrigger: root.triggerTestNotification
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
    property int lastFetchMinute: -1
    
    property var selectedForecast: null
    property bool showForecastDetails: false
    property rect clickedCardRect: Qt.rect(0, 0, 0, 0)

    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: i18n("Refresh")
            icon.name: "view-refresh"
            onTriggered: root.fetchWeatherData()
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
            var min = new Date().getMinutes()
            if ((min === 0 || min === 30) && lastFetchMinute !== min) {
                fetchWeatherData()
                lastFetchMinute = min
            }
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
            autoDetect: locationMode === "auto",
            forecastDays: forecastDays
        }, function(result) {
            isLoading = false
            if (result.success) {
                processWeatherData(result)
                Plasmoid.configuration.cachedWeather = JSON.stringify(result)
                Plasmoid.configuration.lastUpdate = new Date().getTime()
                
                // Check notifications after successful fetch
                if (notificationManagerLoader.item) {
                    notificationManagerLoader.item.checkNotifications()
                }
            } else {
                errorMessage = result.error || "Unknown error"
            }
        })
    }

    function getWeatherIcon(item) {
        if (!item) return Qt.resolvedUrl("../images/clear_day.svg")
        var isDark = ((Kirigami.Theme.backgroundColor.r + Kirigami.Theme.backgroundColor.g + Kirigami.Theme.backgroundColor.b) / 3) < 0.5
        var iconPath = IconMapper.getIconPath(item.code, item.icon, weatherProvider, isDark, iconPack)

        if (iconPath.indexOf("/") !== -1) {
            return Qt.resolvedUrl(iconPath)
        }

        return iconPath
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
                Button { text: i18n("Refresh"); Layout.alignment: Qt.AlignHCenter; onClicked: root.fetchWeatherData() }
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
                onClicked: (mouse) => { if (mouse.button === Qt.MiddleButton) root.fetchWeatherData() }
            }
        }
    // Dummy function to provide strings for xgettext
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
