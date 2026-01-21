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
    readonly property double backgroundOpacity: isPanel ? 0.0 : ((Plasmoid.configuration.backgroundOpacity !== undefined) ? Plasmoid.configuration.backgroundOpacity : 0.9)
    readonly property string panelMode: Plasmoid.configuration.panelMode || "simple"
    readonly property int panelFontSize: Plasmoid.configuration.panelFontSize || 0
    readonly property int panelIconSize: Plasmoid.configuration.panelIconSize || 0
    readonly property string layoutMode: Plasmoid.configuration.layoutMode || "auto"
    readonly property int forecastDays: Plasmoid.configuration.forecastDays || 5

    // Layout Mode Detection
    readonly property bool isPanel: Plasmoid.formFactor === PlasmaCore.Types.Horizontal || Plasmoid.formFactor === PlasmaCore.Types.Vertical
    readonly property bool isWideMode: layoutMode === "wide" || (layoutMode === "auto" && root.width > 350 && root.height <= 350)
    readonly property bool isLargeMode: layoutMode === "large" || (layoutMode === "auto" && root.width > 350 && root.height > 350)
    readonly property bool isSmallMode: layoutMode === "small" || (layoutMode === "auto" && !isWideMode && !isLargeMode)

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
            } else {
                errorMessage = result.error || "Unknown error"
            }
        })
    }

    function getWeatherIcon(item) {
        if (!item) return Qt.resolvedUrl("../images/clear_day.svg")
        var isDark = ((Kirigami.Theme.backgroundColor.r + Kirigami.Theme.backgroundColor.g + Kirigami.Theme.backgroundColor.b) / 3) < 0.5
        var iconPath = IconMapper.getIconPath(item.code, item.icon, weatherProvider, isDark, iconPack)
        
        // If it is a relative path (local file), resolve it to a full URL
        if (iconPath.indexOf("/") !== -1) {
            return Qt.resolvedUrl(iconPath)
        }
        
        // Otherwise, return as is (system icon name)
        return iconPath
    }

    function getLocalizedDay(dayKey) {
        if (!dayKey) return ""
        return i18n(dayKey)
    }

    compactRepresentation: Item {
        id: compactRep
        // Determine layout based on panelMode
        readonly property bool detailed: root.panelMode === "detailed"
        
        Layout.minimumWidth: detailed ? detailedLayout.implicitWidth : simpleLayout.implicitWidth
        Layout.preferredWidth: detailed ? detailedLayout.implicitWidth : simpleLayout.implicitWidth
        
        MouseArea {
            anchors.fill: parent
            onClicked: root.expanded = !root.expanded
        }

        // Simple View (Icon + Temp)
        RowLayout {
            id: simpleLayout
            anchors.centerIn: parent
            spacing: 0
            visible: !compactRep.detailed
            
            // Removed spacers to allow auto-sizing
            
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
                font.bold: true
                Layout.alignment: Qt.AlignVCenter
                leftPadding: 4
            }
        }

        // Detailed View (Icon + Temp + Condition)
        RowLayout {
            id: detailedLayout
            anchors.centerIn: parent
            spacing: 6
            visible: compactRep.detailed
            
            // Removed spacers
            
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
                    text: root.currentWeather ? Math.round(root.currentWeather.temp) + "°C" : "--"
                    color: Kirigami.Theme.textColor
                    font.pixelSize: root.panelFontSize > 0 ? root.panelFontSize : compactRep.height * 0.4
                    font.bold: true
                    lineHeight: 0.8
                }
                
                Text {
                    text: root.currentWeather ? i18n(root.currentWeather.condition) : ""
                    color: Kirigami.Theme.textColor
                    font.pixelSize: root.panelFontSize > 0 ? root.panelFontSize * 0.6 : compactRep.height * 0.25
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
            anchors.margins: (Plasmoid.formFactor === PlasmaCore.Types.Horizontal || Plasmoid.formFactor === PlasmaCore.Types.Vertical) ? 0 : 5
            color: Qt.rgba(Kirigami.Theme.backgroundColor.r, Kirigami.Theme.backgroundColor.g, Kirigami.Theme.backgroundColor.b, root.backgroundOpacity)
            radius: 20
            clip: true
            
            // Set default font for all children
            // Note: Some complex children might override this if they don't inherit explicitly
            // But usually this works for standard QtQuick types
            property font font: root.activeFont
            // Force application to children text items that inherit
            // Not standard prop in Rectangle but we can alias or use it as attached if needed, 
            // but for QML inheritance, just having it here might not be enough if children bind to theme.
            // Let's bind 'Font.family' to it for the context of this Rect.
            
            // Actually, best way is to set it on the specific Text elements or override the system font locally.
            // But since this is a widget, we can't easily globally override.
            // We'll pass 'activeFont' down to the Loaders as a property.


            // Loading State
            ColumnLayout {
                anchors.centerIn: parent
                visible: root.isLoading
                spacing: 10
                BusyIndicator { running: root.isLoading; Layout.alignment: Qt.AlignHCenter }
                Text { text: i18n("Loading weather data..."); color: Kirigami.Theme.textColor; font.pixelSize: 14; Layout.alignment: Qt.AlignHCenter }
            }

            // Error State
            ColumnLayout {
                anchors.centerIn: parent
                visible: !root.isLoading && root.errorMessage !== ""
                spacing: 10
                width: parent.width * 0.8
                Kirigami.Icon { source: "dialog-error"; Layout.preferredWidth: 48; Layout.preferredHeight: 48; Layout.alignment: Qt.AlignHCenter }
                Text { text: root.errorMessage; color: Kirigami.Theme.textColor; font.pixelSize: 13; Layout.alignment: Qt.AlignHCenter; horizontalAlignment: Text.AlignHCenter; wrapMode: Text.Wrap; Layout.fillWidth: true }
                Button { text: i18n("Refresh"); Layout.alignment: Qt.AlignHCenter; onClicked: root.fetchWeatherData() }
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
