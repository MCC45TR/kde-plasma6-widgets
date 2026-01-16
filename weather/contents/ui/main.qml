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

    // Localization - inline for reliability (XHR local file access is disabled)
    property var locales: ({
        "en": {
            "loading": "Loading weather data...",
            "error_network": "Network error. Check your internet connection.",
            "error_no_api_key": "No API key configured.",
            "error_invalid_location": "Location not found.",
            "refresh": "Refresh Weather",
            "daily_forecast": "Daily Forecast",
            "hourly_forecast": "Hourly Forecast",
            "feels_like": "Feels Like",
            "humidity": "Humidity",
            "wind": "Wind",
            "pressure": "Pressure",
            "clouds": "Clouds",
            "uv_index": "UV",
            "visibility": "Visibility",
            "wind_direction": "Direction",
            "close_hint": "Click to close",
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
            "refresh": "Hava Durumunu Yenile",
            "daily_forecast": "Günlük Tahmin",
            "hourly_forecast": "Saatlik Tahmin",
            "feels_like": "Hissedilen",
            "humidity": "Nem",
            "wind": "Rüzgar",
            "pressure": "Basınç",
            "clouds": "Bulut",
            "uv_index": "UV",
            "visibility": "Görüş",
            "wind_direction": "Yön",
            "close_hint": "Kapatmak için tıklayın",
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
    Layout.minimumWidth: 200
    Layout.minimumHeight: 200

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

    // Configuration
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
    property int lastFetchMinute: -1
    
    // Detect system units based on locale
    function detectSystemUnits() {
        var locale = Qt.locale().name // e.g., "en_US", "tr_TR"
        var imperialLocales = ["en_US", "en_LR", "en_MM"] // US, Liberia, Myanmar use imperial
        return imperialLocales.indexOf(locale) >= 0 ? "imperial" : "metric"
    }
    
    // Get the location to use for weather fetching
    function getActiveLocation() {
        if (locationMode === "auto") return "" // WeatherService handles IP detection
        return location || location2 || location3 || ""
    }

    // Timer for Auto-Refresh (Every 00 and 30 minutes)
    
    // Layout Logic - Threshold Based
    // Wide Mode: Width > 350 AND Height <= 350
    readonly property bool isWideMode: root.width > 350 && root.height <= 350
    
    // Large Mode: Width > 350 AND Height > 350
    readonly property bool isLargeMode: root.width > 350 && root.height > 350
    
    // Small Mode: Everything else (Width <= 350 OR Height <= 350, assuming fallback for vertical strips)
    // User definition: "Küçük Mod = Genişlik ve Yükseklik 350 den küçük" implies W<=350 AND H<=350.
    // We treat anything NOT Large and NOT Wide as Small (includes narrow-tall strips).
    readonly property bool isSmallMode: !isWideMode && !isLargeMode
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
    property bool largeDetailsOpen: false // State for Large Mode details overlay

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

    // Load localization from JSON file
    function loadLocales() {
        var xhr = new XMLHttpRequest()
        xhr.open("GET", Qt.resolvedUrl("localization.json"))
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        var json = JSON.parse(xhr.responseText)
                        var newLocales = locales
                        // Pivot data: JSON is {key: {lang: val}} -> Locales is {lang: {key: val}}
                        for (var tokenKey in json) {
                            var translations = json[tokenKey]
                            for (var langCode in translations) {
                                if (!newLocales[langCode]) newLocales[langCode] = {}
                                newLocales[langCode][tokenKey] = translations[langCode]
                            }
                        }
                        locales = newLocales
                        console.log("Localization loaded successfully")
                    } catch (e) {
                        console.log("Failed to parse localization.json: " + e)
                    }
                } else {
                    console.log("Failed to load localization.json (Status: " + xhr.status + ") - using built-in defaults")
                }
            }
        }
        xhr.send()
    }

    // Fetch weather data
    function fetchWeatherData() {
        isLoading = true 
        // Don't clear errorMessage immediately to keep UI stable if cache exists
        
        var activeLocation = getActiveLocation()
        WeatherService.fetchWeather({
            apiKey: apiKey,
            apiKey2: apiKey2,
            location: activeLocation,
            units: units,
            provider: weatherProvider,
            autoDetect: locationMode === "auto"
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
        return IconMapper.getIconPath(item.code, item.icon, weatherProvider, isDarkTheme, iconPack)
    }
    
    // Localized day names helper
    function getLocalizedDay(dayKey) {
        if (!dayKey) return ""
        // dayKey is like "fri", tr() returns specialized string or key if missing
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
                anchors.margins: 8
                spacing: 8
                visible: !root.isLoading && root.errorMessage === "" && root.currentWeather && root.isWideMode
                
                // Left Section: Current Weather (Expandable)
                Rectangle {
                    id: currentSection
                    
                    // Expansion state
                    property bool isExpanded: false
                    
                    // Normal state values
                    readonly property real normalWidth: contentLayout.implicitWidth + 20
                    readonly property real normalHeight: mainLayout.height
                    readonly property real normalRadius: 10
                    
                    // Expanded state values (fill parent mainRect)
                    readonly property real expandedWidth: mainRect.width - 16
                    readonly property real expandedHeight: mainRect.height - 16
                    readonly property real expandedRadius: 15
                    
                    Layout.fillHeight: !isExpanded
                    Layout.preferredWidth: isExpanded ? expandedWidth : normalWidth
                    Layout.preferredHeight: isExpanded ? expandedHeight : -1
                    
                    // Z-index to appear above other elements when expanded
                    z: isExpanded ? 100 : 0
                    
                    radius: isExpanded ? expandedRadius : normalRadius
                    color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.1)

                    // Auto-close timer (5 seconds)
                    Timer {
                        id: autoCloseTimer
                        interval: 5000
                        running: false
                        repeat: false
                        onTriggered: {
                            if (currentSection.isExpanded) {
                                currentSection.isExpanded = false
                            }
                        }
                    }

                    // Animations
                    Behavior on Layout.preferredWidth {
                        NumberAnimation { 
                            duration: 200
                            easing.type: Easing.InOutQuad
                        }
                    }
                    Behavior on radius {
                        NumberAnimation { 
                            duration: 200
                            easing.type: Easing.InOutQuad
                        }
                    }

                    // Click and hover handler
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            currentSection.isExpanded = !currentSection.isExpanded
                            if (currentSection.isExpanded) {
                                autoCloseTimer.restart()
                            } else {
                                autoCloseTimer.stop()
                            }
                        }
                        onEntered: {
                            if (currentSection.isExpanded) {
                                autoCloseTimer.stop()
                            }
                        }
                        onExited: {
                            if (currentSection.isExpanded) {
                                autoCloseTimer.restart()
                            }
                        }
                        cursorShape: Qt.PointingHandCursor
                    }

                    // Normal content (visible when not expanded)
                    ColumnLayout {
                        id: contentLayout
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 2
                        visible: !currentSection.isExpanded
                        opacity: currentSection.isExpanded ? 0 : 1
                        
                        Behavior on opacity {
                            NumberAnimation { duration: 150; easing.type: Easing.InOutQuad }
                        }

                        Item { Layout.fillHeight: true } // Top Spacer

                        // 1. Current Weather Icon
                        Image {
                            id: currentIcon
                            source: root.getWeatherIcon(root.currentWeather)
                            // Responsive sizing: Shrink if text takes more space
                            readonly property real availableHeight: parent.height
                            Layout.preferredHeight: conditionText.lineCount > 1 ? availableHeight * 0.2 : availableHeight * 0.25
                            Layout.preferredWidth: Layout.preferredHeight
                            
                            Layout.alignment: Qt.AlignHCenter
                            
                            sourceSize.width: Layout.preferredWidth * 2
                            sourceSize.height: Layout.preferredHeight * 2
                            fillMode: Image.PreserveAspectFit
                            smooth: true
                            antialiasing: true
                        }

                        // 2. Weather Condition Text
                        Text {
                            id: conditionText
                            text: root.currentWeather ? root.tr("condition_" + root.currentWeather.condition.toLowerCase().replace(/ /g, "_")) : ""
                            color: Kirigami.Theme.textColor
                            opacity: 0.8
                            font.family: "Roboto Condensed"
                            font.pixelSize: Math.max(10, Math.min(14, root.height * 0.08))
                            Layout.alignment: Qt.AlignHCenter
                            wrapMode: Text.WordWrap // Enable WordWrap
                            Layout.maximumWidth: parent.width - 10
                            horizontalAlignment: Text.AlignHCenter
                            maximumLineCount: 2 // Allow 2 lines
                            elide: Text.ElideRight
                        }

                        // 3. Current Temperature with Degree Symbol
                        RowLayout {
                            Layout.alignment: Qt.AlignHCenter
                            spacing: 0
                            
                            Text {
                                id: currentTemp
                                text: root.currentWeather ? root.currentWeather.temp : "--"
                                color: Kirigami.Theme.textColor
                                font.family: "Roboto Condensed"
                                font.bold: true
                                // Shrink font if text wraps
                                font.pixelSize: conditionText.lineCount > 1 ? root.height * 0.2 : root.height * 0.25
                            }
                            
                            Text {
                                text: "°"
                                color: Kirigami.Theme.textColor
                                font.family: "Roboto Condensed"
                                font.bold: true
                                font.pixelSize: conditionText.lineCount > 1 ? root.height * 0.15 : root.height * 0.18
                                Layout.alignment: Qt.AlignTop
                                Layout.topMargin: root.height * 0.01
                            }
                        }

                        // 4. High/Low Horizontal Row
                        RowLayout {
                            Layout.alignment: Qt.AlignHCenter
                            spacing: 8
                            
                            // High Temperature
                            RowLayout {
                                spacing: 1
                                Text {
                                    text: "▲"
                                    color: Kirigami.Theme.positiveTextColor
                                    font.pixelSize: Math.max(9, Math.min(12, root.height * 0.07))
                                    font.bold: true
                                }
                                Text {
                                    text: root.currentWeather ? root.currentWeather.temp_max + "°" : "--"
                                    color: Kirigami.Theme.textColor
                                    font.pixelSize: Math.max(9, Math.min(12, root.height * 0.07))
                                    font.bold: true
                                }
                            }
                            
                            // Low Temperature
                            RowLayout {
                                spacing: 1
                                Text {
                                    text: "▼"
                                    color: Kirigami.Theme.negativeTextColor
                                    font.pixelSize: Math.max(9, Math.min(12, root.height * 0.07))
                                    font.bold: true
                                }
                                Text {
                                    text: root.currentWeather ? root.currentWeather.temp_min + "°" : "--"
                                    color: Kirigami.Theme.textColor
                                    font.pixelSize: Math.max(9, Math.min(12, root.height * 0.07))
                                    font.bold: true
                                }
                            }
                        }

                        Item { Layout.fillHeight: true } // Bottom Spacer
                    }
                    
                    // Expanded content (visible when expanded) - Scrollable
                    Flickable {
                        id: expandedFlickable
                        anchors.fill: parent
                        anchors.margins: 10
                        visible: currentSection.isExpanded
                        opacity: currentSection.isExpanded ? 1 : 0
                        
                        contentWidth: width
                        contentHeight: expandedContent.height
                        clip: true
                        flickableDirection: Flickable.VerticalFlick
                        boundsBehavior: Flickable.StopAtBounds
                        interactive: true
                        
                        Behavior on opacity {
                            NumberAnimation { duration: 150; easing.type: Easing.InOutQuad }
                        }
                        
                        // Enable mouse wheel scrolling
                        ScrollBar.vertical: ScrollBar {
                            id: expandedScrollBar
                            policy: expandedContent.height > expandedFlickable.height ? ScrollBar.AlwaysOn : ScrollBar.AlwaysOff
                            width: 6
                        }
                        
                        WheelHandler {
                            target: expandedFlickable
                            orientation: Qt.Vertical
                            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                            onWheel: function(wheel) {
                                expandedFlickable.contentY -= wheel.angleDelta.y * 0.5
                                expandedFlickable.contentY = Math.max(0, Math.min(expandedFlickable.contentY, expandedFlickable.contentHeight - expandedFlickable.height))
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            propagateComposedEvents: true
                            onClicked: {
                                currentSection.isExpanded = false
                                autoCloseTimer.stop()
                            }
                        }
                        
                        WeatherDetailsView {
                            id: expandedContent
                            width: expandedFlickable.width
                            weatherRoot: root
                        }
                    }
                }

                // Right Section: Location, Condition, Forecast
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredWidth: root.width * 0.55
                    Layout.minimumWidth: 150
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

                        // Toggle Button
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
                                id: toggleMouseArea
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.forecastMode = !root.forecastMode
                                hoverEnabled: true
                            }
                            
                            Rectangle {
                                anchors.fill: parent
                                color: Kirigami.Theme.highlightColor
                                opacity: toggleMouseArea.containsMouse ? 0.1 : 0
                                radius: parent.radius
                                Behavior on opacity { NumberAnimation { duration: 150 } }
                            }
                        }
                    }

                    // Forecast Grid
                    GridView {
                        id: forecastGrid
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.minimumHeight: 80
                        clip: true
                        
                        // Dynamic card sizing
                        readonly property real minCardWidth: 70
                        readonly property real minCardHeight: 100
                        
                        readonly property int cardsPerRow: Math.max(1, Math.floor(width / minCardWidth))
                        readonly property int visibleRows: Math.max(1, Math.floor(height / minCardHeight))
                        
                        readonly property real actualCardWidth: width / cardsPerRow
                        readonly property real actualCardHeight: height / visibleRows
                        
                        cellWidth: actualCardWidth
                        cellHeight: actualCardHeight
                        
                        // Snapping behavior
                        snapMode: GridView.SnapToRow
                        boundsBehavior: Flickable.StopAtBounds
                        
                        leftMargin: 0
                        flow: GridView.FlowLeftToRight
                        
                        model: root.forecastMode ? root.forecastHourly : root.forecastDaily
                        
                        delegate: ForecastItem {
                            required property var modelData
                            required property int index
                            
                            width: forecastGrid.cellWidth - 4
                            height: forecastGrid.cellHeight - 4
                            
                            label: root.forecastMode ? modelData.time : root.getLocalizedDay(modelData.day)
                            iconPath: root.getWeatherIcon(modelData)
                            temp: modelData.temp
                            isHourly: root.forecastMode
                            
                            // Radius Logic
                            readonly property real fullR: 24
                            readonly property int gridWidth: forecastGrid.width
                            readonly property int cw: forecastGrid.cellWidth
                            readonly property int cols: Math.max(1, Math.floor(gridWidth / cw))
                            readonly property int row: Math.floor(index / cols)
                            readonly property int col: index % cols
                            readonly property int totalRows: Math.ceil(forecastGrid.count / cols)
                            readonly property bool isTop: row % forecastGrid.visibleRows === 0 // Visually top of the 'page'
                            readonly property bool isBottom: (row + 1) % forecastGrid.visibleRows === 0 // Bottom of the 'page'
                            // Note regarding radius: If we are scrolling 'stage by stage', 
                            // maybe we want rounded corners on the *visible* block?
                            // But usually GridView items are individual. 
                            // Keeping the existing logic for now but adapting 'isTop' if needed.
                            // The user didn't ask to change radius logic, just scrolling.
                            // However, 'isTop' logic: row === 0 applies only to the very first row of dataset.
                            // If we want it to look like a 'block' per page, we might need to adjust.
                            // But usually simple per-item radius is safer.
                            // Let's stick to existing corner logic for now to avoid regression, 
                            // unless 'isTop' depends on View visibility.
                            
                            // Re-using the same radius logic from before
                            readonly property bool isFirstRow: row === 0
                            readonly property bool isLastRow: row === totalRows - 1
                            readonly property bool isLeft: col === 0
                            readonly property bool isRight: col === cols - 1 || index === forecastGrid.count - 1
                            
                            radiusTL: (isFirstRow && isLeft) ? fullR : 10
                            radiusTR: (isFirstRow && isRight) ? fullR : 10
                            radiusBL: (isLastRow && isLeft) ? fullR : 10
                            radiusBR: (isLastRow && isRight) ? fullR : 10
                        }
                    }
                }
            }
            
            // SMALL MODE LAYOUT (Square-ish / Narrow)
            Item {
                id: smallModeLayout
                anchors.fill: parent
                anchors.margins: 10
                visible: !root.isLoading && root.errorMessage === "" && root.currentWeather && root.isSmallMode
                
                // 1. Top Left: Condition & Location
                ColumnLayout {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    spacing: 0
                    width: parent.width * 0.6 // Save space for icon
                    
                    Text {
                        text: root.currentWeather ? root.tr("condition_" + root.currentWeather.condition.toLowerCase().replace(/ /g, "_")) : ""
                        color: Kirigami.Theme.textColor
                        font.family: "Roboto Condensed"
                        font.pixelSize: Math.max(16, Math.min(24, root.height * 0.12))
                        font.bold: false
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                    Text {
                        text: root.currentWeather ? root.currentWeather.location : root.location
                        color: Kirigami.Theme.textColor
                        font.family: "Roboto Condensed"
                        font.pixelSize: Math.max(14, Math.min(20, root.height * 0.1))
                        font.bold: true
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }
                
                // 2. Top Right: Big Icon
                Image {
                    source: root.getWeatherIcon(root.currentWeather)
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.topMargin: -5
                    width: parent.width * 0.5
                    height: width
                    sourceSize.width: width * 2
                    sourceSize.height: height * 2
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                }
                
                // 3. Bottom Left: Big Temperature
                Text {
                    id: smallTemp
                    anchors.left: parent.left
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: -10 // Pull it down a bit to fit tight
                    text: root.currentWeather ? root.currentWeather.temp : "--"
                    color: Kirigami.Theme.textColor
                    font.family: "Roboto Condensed"
                    font.pixelSize: root.height * 0.45
                    font.bold: true
                    lineHeight: 0.8
                }
                
                // 4. Bottom Middle: High/Low Stats (Next to Temp)
                ColumnLayout {
                    anchors.left: smallTemp.right
                    anchors.leftMargin: 5
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 10
                    spacing: 2
                    
                    // Degree Symbol (Big)
                    Text {
                        text: "°"
                        color: Kirigami.Theme.textColor
                        font.pixelSize: root.height * 0.2
                        font.bold: true
                        Layout.alignment: Qt.AlignHCenter
                    }
                    
                    // High
                    RowLayout {
                        spacing: 2
                        Text { text: "▲"; color: Kirigami.Theme.positiveTextColor; font.pixelSize: Math.max(12, root.height * 0.08); font.bold: true }
                        Text { 
                            text: root.currentWeather ? root.currentWeather.temp_max + "°" : "--"
                            color: Kirigami.Theme.textColor; font.pixelSize: Math.max(12, root.height * 0.08); font.bold: true 
                        }
                    }
                    
                    // Low
                    RowLayout {
                        spacing: 2
                        Text { text: "▼"; color: Kirigami.Theme.negativeTextColor; font.pixelSize: Math.max(12, root.height * 0.08); font.bold: true }
                        Text { 
                            text: root.currentWeather ? root.currentWeather.temp_min + "°" : "--"
                            color: Kirigami.Theme.textColor; font.pixelSize: Math.max(12, root.height * 0.08); font.bold: true 
                        }
                    }
                }
            } // End Small Mode Logic

            // LARGE MODE LAYOUT (Width > 350 && Height > 350)
            Item {
                id: largeModeLayout
                anchors.fill: parent
                anchors.margins: 20
                visible: !root.isLoading && root.errorMessage === "" && root.currentWeather && root.isLargeMode
                
                opacity: root.largeDetailsOpen ? 0 : 1
                Behavior on opacity { NumberAnimation { duration: 200 } }
                
                ColumnLayout {
                    anchors.fill: parent
                    spacing: 0
                    
                    // HEADER AREA
                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: root.height * 0.4
                        Layout.minimumHeight: 150
                        
                        // Left Column: Condition, Location, Temp
                        Column {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: parent.width * 0.6
                            spacing: 0
                            
                            // Condition
                            Text {
                                text: root.currentWeather ? root.tr("condition_" + root.currentWeather.condition.toLowerCase().replace(/ /g, "_")) : ""
                                color: Kirigami.Theme.textColor
                                font.family: "Roboto Condensed"
                                font.pixelSize: Math.min(36, root.height * 0.09) // Responsive but large
                                font.bold: true
                                elide: Text.ElideRight
                                width: parent.width
                                lineHeight: 0.9
                            }
                            
                            // Location
                            Text {
                                text: root.currentWeather ? root.currentWeather.location : root.location
                                color: Kirigami.Theme.textColor
                                font.family: "Roboto Condensed"
                                font.pixelSize: Math.min(24, root.height * 0.06)
                                font.bold: true
                                opacity: 0.8
                                elide: Text.ElideRight
                                width: parent.width
                                topPadding: 4
                            }
                            
                            
                            // Temperature (Huge)
                            Text {
                                text: root.currentWeather ? root.currentWeather.temp + "°" : "--"
                                color: Kirigami.Theme.textColor
                                font.family: "Roboto Condensed"
                                font.pixelSize: Math.min(110, root.height * 0.25)
                                font.bold: true
                                lineHeight: 0.8
                            }
                        }
                        
                        // Right Icon
                        Image {
                            anchors.right: parent.right
                            anchors.top: parent.top
                            width: parent.width * 0.35
                            height: width
                            source: root.getWeatherIcon(root.currentWeather)
                            sourceSize.width: width * 2
                            sourceSize.height: height * 2
                            fillMode: Image.PreserveAspectFit
                            smooth: true
                        }

                        // Header Buttons: Toggle Forecast & Details
                        Row {
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 5
                            spacing: 4
                            
                            // Details Button
                            Rectangle {
                                id: detailsButton
                                width: detailsText.implicitWidth + 20
                                height: 28
                                radius: 14
                                topRightRadius: 5
                                bottomRightRadius: 5
                                color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.1)
                                
                                Text {
                                    id: detailsText
                                    anchors.centerIn: parent
                                    text: root.tr("details")
                                    color: Kirigami.Theme.textColor
                                    font.family: "Roboto Condensed"
                                    font.pixelSize: 12
                                    font.bold: true
                                }
                                MouseArea {
                                    id: detailsMouseArea
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.largeDetailsOpen = true
                                    hoverEnabled: true
                                }
                                Rectangle {
                                    anchors.fill: parent
                                    color: Kirigami.Theme.highlightColor
                                    opacity: detailsMouseArea.containsMouse ? 0.1 : 0
                                    radius: 14
                                    topRightRadius: 5
                                    bottomRightRadius: 5
                                    Behavior on opacity { NumberAnimation { duration: 150 } }
                                }
                            }
                            
                            // Forecast Toggle Button
                            Rectangle {
                                width: toggleTextLarge.implicitWidth + 24
                                height: 28
                                radius: 14
                                topLeftRadius: 5
                                bottomLeftRadius: 5
                                color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.1)
                                
                                Text {
                                    id: toggleTextLarge
                                    anchors.centerIn: parent
                                    text: root.forecastMode ? root.tr("hourly_forecast") : root.tr("daily_forecast")
                                    color: Kirigami.Theme.textColor
                                    font.family: "Roboto Condensed"
                                    font.pixelSize: 12
                                    font.bold: true
                                }
                                MouseArea {
                                    id: toggleMouseAreaLarge
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.forecastMode = !root.forecastMode
                                    hoverEnabled: true
                                }
                                
                                Rectangle {
                                    anchors.fill: parent
                                    color: Kirigami.Theme.highlightColor
                                    opacity: toggleMouseAreaLarge.containsMouse ? 0.1 : 0
                                    radius: 14
                                    topLeftRadius: 5
                                    bottomLeftRadius: 5
                                    Behavior on opacity { NumberAnimation { duration: 150 } }
                                }
                            }
                        }
                    }
                    
                    // FORECAST GRID
                    GridView {
                        id: largeForecastGrid
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        
                        // Responsive Grid Config
                        readonly property real minCardHeight: 100
                        readonly property int visibleRows: Math.max(1, Math.floor(height / minCardHeight))
                        cellHeight: height / visibleRows
                        
                        readonly property real minCardWidth: 70
                        readonly property int cardsPerRow: Math.max(1, Math.floor(width / minCardWidth))
                        cellWidth: width / cardsPerRow
                        
                        snapMode: GridView.SnapToRow
                        boundsBehavior: Flickable.StopAtBounds
                        
                        leftMargin: 0
                        flow: GridView.FlowLeftToRight
                        
                        // User requested Visuals:
                        // Show DAILY or HOURLY? 
                        // The existing Wide mode uses a toggle.
                        // The user ASCII art shows "PZT, SAL, CAR..." (Days).
                        // So let's default to DAILY model for this view to match "Large Mode" concept usually showing overview.
                        // However, we can use the same `root.forecastMode` property to keep state consistent.
                        // User ASCII checks: "PZT" (Mon), "SAL" (Tue). This is Daily.
                        // Let's stick to `root.forecastMode` logic but default to daily if the user prefers.
                        // Or just bind to the existing toggle.
                        model: root.forecastMode ? root.forecastHourly : root.forecastDaily
                        
                        delegate: ForecastItem {
                            required property var modelData
                            required property int index
                             
                            width: largeForecastGrid.cellWidth - 4
                            height: largeForecastGrid.cellHeight - 4
                            
                            // Reuse existing logic
                            label: root.forecastMode ? modelData.time : root.getLocalizedDay(modelData.day)
                            iconPath: root.getWeatherIcon(modelData)
                            temp: modelData.temp
                            isHourly: root.forecastMode
                            
                            // Rounded corners for all
                            radiusTL: 12
                            radiusTR: 12
                            radiusBL: 12
                            radiusBR: 12
                        }
                    }
                }
            }
            
            // Details Overlay for Large Mode
            Rectangle {
                id: largeDetailsOverlay
                // No anchors.fill - we animate geometry manually
                visible: false // Hidden by default
                
                property var closedGeometry: Qt.rect(0,0,0,0)

                Connections {
                    target: root
                    function onLargeDetailsOpenChanged() {
                        if (root.largeDetailsOpen) {
                            // OPENING TRANSITION
                            // 1. Capture button geometry relatively to mainRect
                            var p = detailsButton.mapToItem(mainRect, 0, 0)
                            largeDetailsOverlay.closedGeometry = Qt.rect(p.x, p.y, detailsButton.width, detailsButton.height)
                            
                            // 2. Setup initial state (matching button)
                            largeDetailsOverlay.x = largeDetailsOverlay.closedGeometry.x
                            largeDetailsOverlay.y = largeDetailsOverlay.closedGeometry.y
                            largeDetailsOverlay.width = largeDetailsOverlay.closedGeometry.width
                            largeDetailsOverlay.height = largeDetailsOverlay.closedGeometry.height
                            
                            // Match Button radii
                            largeDetailsOverlay.radius = 14
                            largeDetailsOverlay.topLeftRadius = 14
                            largeDetailsOverlay.bottomLeftRadius = 14
                            largeDetailsOverlay.topRightRadius = 5
                            largeDetailsOverlay.bottomRightRadius = 5
                            
                            largeDetailsOverlay.color = Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.1)
                            largeDetailsOverlay.visible = true
                            
                            // 3. Start Expand Animation
                            expandAnim.start()
                        } else {
                            // CLOSING TRANSITION
                            collapseAnim.start()
                        }
                    }
                }

                ParallelAnimation {
                    id: expandAnim
                    NumberAnimation { target: largeDetailsOverlay; property: "x"; to: 0; duration: 200; easing.type: Easing.InOutQuad }
                    NumberAnimation { target: largeDetailsOverlay; property: "y"; to: 0; duration: 200; easing.type: Easing.InOutQuad }
                    NumberAnimation { target: largeDetailsOverlay; property: "width"; to: mainRect.width; duration: 200; easing.type: Easing.InOutQuad }
                    NumberAnimation { target: largeDetailsOverlay; property: "height"; to: mainRect.height; duration: 200; easing.type: Easing.InOutQuad }
                    // Animate all corners to 20
                    NumberAnimation { target: largeDetailsOverlay; properties: "radius,topLeftRadius,bottomLeftRadius,topRightRadius,bottomRightRadius"; to: 20; duration: 200; easing.type: Easing.InOutQuad }
                    
                    SequentialAnimation {
                        PauseAnimation { duration: 50 }
                        NumberAnimation { target: overlayFlickable; property: "opacity"; from: 0; to: 1; duration: 150 }
                    }
                }

                ParallelAnimation {
                    id: collapseAnim
                    NumberAnimation { target: largeDetailsOverlay; property: "x"; to: largeDetailsOverlay.closedGeometry.x; duration: 200; easing.type: Easing.InOutQuad }
                    NumberAnimation { target: largeDetailsOverlay; property: "y"; to: largeDetailsOverlay.closedGeometry.y; duration: 200; easing.type: Easing.InOutQuad }
                    NumberAnimation { target: largeDetailsOverlay; property: "width"; to: largeDetailsOverlay.closedGeometry.width; duration: 200; easing.type: Easing.InOutQuad }
                    NumberAnimation { target: largeDetailsOverlay; property: "height"; to: largeDetailsOverlay.closedGeometry.height; duration: 200; easing.type: Easing.InOutQuad }
                    
                    // Animate corners back to button state
                    NumberAnimation { target: largeDetailsOverlay; properties: "radius,topLeftRadius,bottomLeftRadius"; to: 14; duration: 200; easing.type: Easing.InOutQuad }
                    NumberAnimation { target: largeDetailsOverlay; properties: "topRightRadius,bottomRightRadius"; to: 5; duration: 200; easing.type: Easing.InOutQuad }
                    
                    NumberAnimation { target: overlayFlickable; property: "opacity"; to: 0; duration: 150 }
                    onFinished: largeDetailsOverlay.visible = false
                }
                
                Flickable {
                    id: overlayFlickable
                    anchors.fill: parent
                    anchors.margins: 12
                    contentHeight: overlayContent.height
                    contentWidth: width
                    clip: true
                    opacity: 0 // Start hidden until expanded
                    
                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded; width: 6 }
                    
                    // Tap content to close
                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.largeDetailsOpen = false
                    }
                    
                    WeatherDetailsView {
                        id: overlayContent
                        width: parent.width
                        weatherRoot: root
                    }
                }
            }

            // Click to Refresh (subtle)
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.MiddleButton
                onClicked: (mouse) => {
                    if (mouse.button === Qt.MiddleButton) {
                        root.fetchWeatherData()
                    }
                }
            }
        }
    }
}
