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
                        // Merge loaded locales into the existing property
                        for (var lang in json) {
                            if (!newLocales[lang]) newLocales[lang] = {}
                            for (var key in json[lang]) {
                                newLocales[lang][key] = json[lang][key]
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
            RowLayout {
                id: mainLayout
                anchors.fill: parent
                anchors.margins: 8
                spacing: 8
                visible: !root.isLoading && root.errorMessage === "" && root.currentWeather
                
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
                            Layout.preferredHeight: root.height * 0.25
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
                            text: root.currentWeather ? root.tr("condition_" + root.currentWeather.condition.toLowerCase().replace(/ /g, "_")) : ""
                            color: Kirigami.Theme.textColor
                            opacity: 0.8
                            font.family: "Roboto Condensed"
                            font.pixelSize: Math.max(10, Math.min(14, root.height * 0.08))
                            Layout.alignment: Qt.AlignHCenter
                            wrapMode: Text.Wrap
                            Layout.maximumWidth: parent.width - 10
                            maximumLineCount: 1
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
                                font.pixelSize: root.height * 0.25
                            }
                            
                            Text {
                                text: "°"
                                color: Kirigami.Theme.textColor
                                font.family: "Roboto Condensed"
                                font.bold: true
                                font.pixelSize: root.height * 0.18
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
                        
                        ColumnLayout {
                            id: expandedContent
                            width: expandedFlickable.width
                            spacing: 8
                            
                            // Header Row - Compact
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 10
                                
                                // Icon
                                Image {
                                    source: root.getWeatherIcon(root.currentWeather)
                                    Layout.preferredHeight: 50
                                    Layout.preferredWidth: 50
                                    sourceSize.width: 100
                                    sourceSize.height: 100
                                    fillMode: Image.PreserveAspectFit
                                }
                                
                                // Location & Condition
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 0
                                    
                                    Text {
                                        text: root.currentWeather ? root.currentWeather.location : root.location
                                        color: Kirigami.Theme.textColor
                                        font.family: "Roboto Condensed"
                                        font.bold: true
                                        font.pixelSize: 16
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                    
                                    Text {
                                        text: root.currentWeather ? root.tr("condition_" + root.currentWeather.condition.toLowerCase().replace(/ /g, "_")) : ""
                                        color: Kirigami.Theme.textColor
                                        opacity: 0.7
                                        font.pixelSize: 12
                                    }
                                }
                                
                                // Temperature Block
                                ColumnLayout {
                                    spacing: 0
                                    
                                    RowLayout {
                                        spacing: 0
                                        Text {
                                            text: root.currentWeather ? root.currentWeather.temp : "--"
                                            color: Kirigami.Theme.textColor
                                            font.family: "Roboto Condensed"
                                            font.bold: true
                                            font.pixelSize: 36
                                        }
                                        Text {
                                            text: "°"
                                            color: Kirigami.Theme.textColor
                                            font.family: "Roboto Condensed"
                                            font.bold: true
                                            font.pixelSize: 22
                                            Layout.alignment: Qt.AlignTop
                                        }
                                    }
                                    
                                    // High/Low inline
                                    RowLayout {
                                        spacing: 8
                                        Layout.alignment: Qt.AlignHCenter
                                        RowLayout {
                                            spacing: 2
                                            Text { text: "▲"; color: Kirigami.Theme.positiveTextColor; font.pixelSize: 11 }
                                            Text { text: root.currentWeather ? root.currentWeather.temp_max + "°" : "--"; color: Kirigami.Theme.textColor; font.pixelSize: 11 }
                                        }
                                        RowLayout {
                                            spacing: 2
                                            Text { text: "▼"; color: Kirigami.Theme.negativeTextColor; font.pixelSize: 11 }
                                            Text { text: root.currentWeather ? root.currentWeather.temp_min + "°" : "--"; color: Kirigami.Theme.textColor; font.pixelSize: 11 }
                                        }
                                    }
                                }
                            }
                            
                            // Stats Cards Row 1
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 6
                                
                                // Card: Feels Like
                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 45
                                    radius: 8
                                    color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.05)
                                    visible: root.currentWeather && root.currentWeather.feels_like !== undefined
                                    
                                    ColumnLayout {
                                        anchors.centerIn: parent
                                        spacing: 1
                                        Text { text: root.tr("feels_like"); color: Kirigami.Theme.textColor; opacity: 0.6; font.pixelSize: 9; Layout.alignment: Qt.AlignHCenter }
                                        Text { 
                                            text: (root.currentWeather && root.currentWeather.feels_like !== undefined) ? root.currentWeather.feels_like + "°" : "--"
                                            color: Kirigami.Theme.textColor; font.pixelSize: 15; font.bold: true; Layout.alignment: Qt.AlignHCenter 
                                        }
                                    }
                                }
                                
                                // Card: Humidity
                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 45
                                    radius: 8
                                    color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.05)
                                    visible: root.currentWeather && root.currentWeather.humidity !== undefined
                                    
                                    ColumnLayout {
                                        anchors.centerIn: parent
                                        spacing: 1
                                        Text { text: "💧 " + root.tr("humidity"); color: Kirigami.Theme.textColor; opacity: 0.6; font.pixelSize: 9; Layout.alignment: Qt.AlignHCenter }
                                        Text { 
                                            text: (root.currentWeather && root.currentWeather.humidity !== undefined) ? root.currentWeather.humidity + "%" : "--"
                                            color: Kirigami.Theme.textColor; font.pixelSize: 15; font.bold: true; Layout.alignment: Qt.AlignHCenter 
                                        }
                                    }
                                }
                                
                                // Card: Wind
                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 45
                                    radius: 8
                                    color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.05)
                                    visible: root.currentWeather && root.currentWeather.wind_speed !== undefined
                                    
                                    ColumnLayout {
                                        anchors.centerIn: parent
                                        spacing: 1
                                        Text { text: "💨 " + root.tr("wind"); color: Kirigami.Theme.textColor; opacity: 0.6; font.pixelSize: 9; Layout.alignment: Qt.AlignHCenter }
                                        Text { 
                                            text: (root.currentWeather && root.currentWeather.wind_speed !== undefined) ? root.currentWeather.wind_speed + " km/h" : "--"
                                            color: Kirigami.Theme.textColor; font.pixelSize: 13; font.bold: true; Layout.alignment: Qt.AlignHCenter 
                                        }
                                    }
                                }
                                
                                // Card: Pressure
                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 45
                                    radius: 8
                                    color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.05)
                                    visible: root.currentWeather && root.currentWeather.pressure !== undefined && root.currentWeather.pressure !== null
                                    
                                    ColumnLayout {
                                        anchors.centerIn: parent
                                        spacing: 1
                                        Text { text: root.tr("pressure"); color: Kirigami.Theme.textColor; opacity: 0.6; font.pixelSize: 9; Layout.alignment: Qt.AlignHCenter }
                                        Text { 
                                            text: (root.currentWeather && root.currentWeather.pressure !== undefined && root.currentWeather.pressure !== null) ? root.currentWeather.pressure + " hPa" : "--"
                                            color: Kirigami.Theme.textColor; font.pixelSize: 11; font.bold: true; Layout.alignment: Qt.AlignHCenter 
                                        }
                                    }
                                }
                            }
                            
                            // Stats Cards Row 2
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 6
                                visible: {
                                    // Only show this row if at least one card has data
                                    var hasData = root.currentWeather && (
                                        root.currentWeather.clouds !== undefined ||
                                        root.currentWeather.uv_index !== undefined ||
                                        root.currentWeather.visibility !== undefined ||
                                        root.currentWeather.wind_deg !== undefined
                                    )
                                    return hasData
                                }
                                
                                // Card: Clouds
                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 45
                                    radius: 8
                                    color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.05)
                                    visible: root.currentWeather && root.currentWeather.clouds !== undefined
                                    
                                    ColumnLayout {
                                        anchors.centerIn: parent
                                        spacing: 1
                                        Text { text: "☁️ " + root.tr("clouds"); color: Kirigami.Theme.textColor; opacity: 0.6; font.pixelSize: 9; Layout.alignment: Qt.AlignHCenter }
                                        Text { 
                                            text: (root.currentWeather && root.currentWeather.clouds !== undefined) ? root.currentWeather.clouds + "%" : "--"
                                            color: Kirigami.Theme.textColor; font.pixelSize: 15; font.bold: true; Layout.alignment: Qt.AlignHCenter 
                                        }
                                    }
                                }
                                
                                // Card: UV Index
                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 45
                                    radius: 8
                                    color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.05)
                                    visible: root.currentWeather && root.currentWeather.uv_index !== undefined
                                    
                                    ColumnLayout {
                                        anchors.centerIn: parent
                                        spacing: 1
                                        Text { text: "☀️ " + root.tr("uv_index"); color: Kirigami.Theme.textColor; opacity: 0.6; font.pixelSize: 9; Layout.alignment: Qt.AlignHCenter }
                                        Text { 
                                            text: (root.currentWeather && root.currentWeather.uv_index !== undefined && root.currentWeather.uv_index !== null) ? root.currentWeather.uv_index.toString() : "--"
                                            color: {
                                                var uv = (root.currentWeather && root.currentWeather.uv_index !== undefined) ? root.currentWeather.uv_index : 0
                                                if (uv >= 11) return "#8B3FC7"
                                                if (uv >= 8) return "#D90011"
                                                if (uv >= 6) return "#F95901"
                                                if (uv >= 3) return "#F7E400"
                                                return Kirigami.Theme.textColor
                                            }
                                            font.pixelSize: 15; font.bold: true; Layout.alignment: Qt.AlignHCenter 
                                        }
                                    }
                                }
                                
                                // Card: Visibility
                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 45
                                    radius: 8
                                    color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.05)
                                    visible: root.currentWeather && root.currentWeather.visibility !== undefined && root.currentWeather.visibility !== null
                                    
                                    ColumnLayout {
                                        anchors.centerIn: parent
                                        spacing: 1
                                        Text { text: "👁️ " + root.tr("visibility"); color: Kirigami.Theme.textColor; opacity: 0.6; font.pixelSize: 9; Layout.alignment: Qt.AlignHCenter }
                                        Text { 
                                            text: (root.currentWeather && root.currentWeather.visibility !== undefined && root.currentWeather.visibility !== null) ? root.currentWeather.visibility + " km" : "--"
                                            color: Kirigami.Theme.textColor; font.pixelSize: 13; font.bold: true; Layout.alignment: Qt.AlignHCenter 
                                        }
                                    }
                                }
                                
                                // Card: Wind Direction
                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 45
                                    radius: 8
                                    color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.05)
                                    visible: root.currentWeather && root.currentWeather.wind_deg !== undefined
                                    
                                    ColumnLayout {
                                        anchors.centerIn: parent
                                        spacing: 1
                                        Text { text: "🧭 " + root.tr("wind_direction"); color: Kirigami.Theme.textColor; opacity: 0.6; font.pixelSize: 9; Layout.alignment: Qt.AlignHCenter }
                                        Text { 
                                            text: {
                                                if (!root.currentWeather || root.currentWeather.wind_deg === undefined) return "--"
                                                var deg = root.currentWeather.wind_deg
                                                var dirs = ["K", "KD", "D", "GD", "G", "GB", "B", "KB"]
                                                return dirs[Math.round(deg / 45) % 8]
                                            }
                                            color: Kirigami.Theme.textColor; font.pixelSize: 13; font.bold: true; Layout.alignment: Qt.AlignHCenter 
                                        }
                                    }
                                }
                            }
                            
                            // Sunrise/Sunset Row
                            RowLayout {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignHCenter
                                spacing: 20
                                visible: root.currentWeather && (root.currentWeather.sunrise !== undefined || root.currentWeather.sunset !== undefined)
                                RowLayout {
                                    spacing: 6
                                    Text { text: "🌅"; font.pixelSize: 14 }
                                    Text { 
                                        text: {
                                            if (!root.currentWeather || !root.currentWeather.sunrise) return "--"
                                            var sr = root.currentWeather.sunrise
                                            if (typeof sr === "number") {
                                                var d = new Date(sr * 1000)
                                                return d.getHours().toString().padStart(2, '0') + ":" + d.getMinutes().toString().padStart(2, '0')
                                            } else if (typeof sr === "string") {
                                                var d2 = new Date(sr)
                                                return d2.getHours().toString().padStart(2, '0') + ":" + d2.getMinutes().toString().padStart(2, '0')
                                            }
                                            return "--"
                                        }
                                        color: Kirigami.Theme.textColor; font.pixelSize: 12; font.bold: true 
                                    }
                                }
                                
                                RowLayout {
                                    spacing: 6
                                    Text { text: "🌇"; font.pixelSize: 14 }
                                    Text { 
                                        text: {
                                            if (!root.currentWeather || !root.currentWeather.sunset) return "--"
                                            var ss = root.currentWeather.sunset
                                            if (typeof ss === "number") {
                                                var d = new Date(ss * 1000)
                                                return d.getHours().toString().padStart(2, '0') + ":" + d.getMinutes().toString().padStart(2, '0')
                                            } else if (typeof ss === "string") {
                                                var d2 = new Date(ss)
                                                return d2.getHours().toString().padStart(2, '0') + ":" + d2.getMinutes().toString().padStart(2, '0')
                                            }
                                            return "--"
                                        }
                                        color: Kirigami.Theme.textColor; font.pixelSize: 12; font.bold: true 
                                    }
                                }
                            }
                            
                            // Close hint
                            Text {
                                text: root.tr("close_hint")
                                color: Kirigami.Theme.textColor
                                opacity: 0.4
                                font.pixelSize: 10
                                Layout.alignment: Qt.AlignHCenter
                                Layout.topMargin: 5
                            }
                        }
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


                    // Forecast Grid (fixed card width, wraps to multiple rows)
                    GridView {
                        id: forecastGrid
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.minimumHeight: 80
                        clip: true
                        
                        // Dynamic card width: minimum 70px, expands to fill available width
                        readonly property real minCardWidth: 70
                        readonly property int cardsPerRow: Math.max(1, Math.floor(width / minCardWidth))
                        // Actual width = available width divided equally among cards in row
                        readonly property real actualCardWidth: width / cardsPerRow
                        readonly property int rowCount: Math.ceil(count / cardsPerRow)
                        
                        cellWidth: actualCardWidth
                        cellHeight: 100  // Fixed card height
                        
                        // No leftMargin needed since cards fill the entire width
                        leftMargin: 0
                        
                        flow: GridView.FlowLeftToRight
                        
                        model: root.forecastMode ? root.forecastHourly : root.forecastDaily

                        delegate: ForecastItem {
                            required property var modelData
                            required property int index
                            
                            width: forecastGrid.cellWidth - 4
                            height: forecastGrid.cellHeight - 4
                            
                            // Visual properties
                            label: root.forecastMode ? modelData.time : modelData.day
                            iconPath: root.getWeatherIcon(modelData)
                            temp: modelData.temp
                            isHourly: root.forecastMode
                            
                            // Radius Logic
                            // Stronger contrast as per user feedback
                            readonly property real fullR: 24
                            readonly property real halfR: 6 // 50% of the previous ~12. But user said "half of radius", if radius was 24, half is 12. 
                            // Let's stick to visible difference. 8 is a good "inner" radius.
                            
                            // Robust Grid position helpers
                            // Recalculate cols locally to ensure binding updates with width
                            readonly property int gridWidth: forecastGrid.width
                            readonly property int cw: forecastGrid.cellWidth
                            readonly property int cols: Math.max(1, Math.floor(gridWidth / cw))
                            
                            readonly property int row: Math.floor(index / cols)
                            readonly property int col: index % cols
                            readonly property int totalRows: Math.ceil(forecastGrid.count / cols)
                            
                            readonly property bool isTop: row === 0
                            readonly property bool isBottom: row === totalRows - 1
                            readonly property bool isLeft: col === 0
                            
                            // Right Logic: Explicitly check column index or if it's the last item
                            // But for "Top Right Corner", we specifically mean the visual rightmost item of the top row.
                            // If top row is full: col == cols-1.
                            // If top row is NOT full (rare but possible count < cols): index == count-1.
                            readonly property bool isRight: col === cols - 1 || index === forecastGrid.count - 1
                            
                            // Specific corners:
                            // Top Left Corner of the Grid
                            radiusTL: (isTop && isLeft) ? fullR : 10
                            
                            // Top Right Corner of the Grid
                            radiusTR: (isTop && isRight) ? fullR : 10
                            
                            // Bottom Left Corner of the Grid
                            radiusBL: (isBottom && isLeft) ? fullR : 10
                            
                            // Bottom Right Corner of the Grid
                            radiusBR: (isBottom && isRight) ? fullR : 10
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
