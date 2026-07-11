import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.kirigami as Kirigami
import "WeatherIconMapper.js" as WeatherIcons

Item {
    id: tickerContainer
    clip: true
    
    // Properties to be set by parent
    property var logic: null
    property int rssFrequency: 0
    property bool rssPlaceholderCycling: true
    property bool rssShowFullHeadline: true
    property bool rssShowSource: false
    property int maxChars: 0 // Used by fallback, though width based is preferred
    
    property color textColor: "#ffffff"
    property int fontSize: 14
    property string fontFamily: Kirigami.Theme.defaultFont.family
    property string defaultText: "Arama"
    property int horizontalAlignment: Text.AlignLeft
    property int rightMarginValue: 0
    property real textOpacity: 0.35
    property bool isSearching: false // Stop ticker when typing
    
    // Weather properties
    property bool weatherPlaceholderCycling: true
    property int weatherFrequency: 2
    property string weatherIconPack: "default"
    property bool isUltraWideMode: false
    property bool isMediumMode: false
    
    property bool isWeatherIconSlide: false
    property string currentWeatherIconSource: ""
    
    // Internal State
    property var titleChunks: []
    property int currentChunkIndex: -1
    property var recentIndices: []
    property var recentSources: []
    property string currentTargetText: defaultText
    property int currentDuration: 3000
    property string currentState: rssFrequency === 0 ? "rss" : "placeholder"
    property var stateQueue: []
    property int cycleCounter: 0
    property real lastWeatherShowTime: 0
    
    // Computed Properties
    property var rssTitles: {
        var list = []
        var cache = (logic && logic.rssTickerEntries) ? logic.rssTickerEntries : []
        if (rssPlaceholderCycling && cache.length > 0) {
            for (var i = 0; i < cache.length; i++) {
                var title = cache[i].text
                if (title && title.length > 3 && title !== defaultText) {
                    list.push({
                        text: title,
                        source: cache[i].source || "Unknown"
                    })
                }
            }
        }
        return list
    }
    
    property int currentRssIndex: rssTitles.length > 0 ? 0 : -1
    property int rssConsecutiveCount: 0
    
    onRssTitlesChanged: {
        if (rssTitles.length > 0 && currentState === "placeholder" && !switchAnim.running) {
            if (currentRssIndex < 0) currentRssIndex = 0;
        }
        recalculateChunks();
    }
    
    onWidthChanged: {
        if (width > 0 && currentTargetText !== "")
            layoutDebouncer.restart();
    }
    
    onDefaultTextChanged: recalculateChunks()
    onCurrentStateChanged: {
        recalculateChunks();
        if (currentState === "weather") {
            lastWeatherShowTime = Date.now();
        }
    }

    property string parsedWeatherCacheSource: ""
    property var parsedWeatherCache: null

    Timer {
        id: layoutDebouncer
        interval: 75
        repeat: false
        onTriggered: tickerContainer.recalculateChunks()
    }
    
    function getWeatherData() {
        var config = (logic && logic.plasmoidConfig) ? logic.plasmoidConfig : null;
        if (!config || !config.weatherEnabled) return null;
        
        var cached = config.weatherCache || "";
        if (cached === parsedWeatherCacheSource) return parsedWeatherCache;
        parsedWeatherCacheSource = cached;
        parsedWeatherCache = null;
        if (cached && cached !== "{}" && cached !== "") {
            try {
                var result = JSON.parse(cached);
                if (result && result.current) {
                    parsedWeatherCache = result;
                    return parsedWeatherCache;
                }
            } catch (e) {
                console.warn("RssTicker: Failed to parse cached weather:", e);
            }
        }
        return null;
    }

    function getFormattedTemp(current) {
        var config = (logic && logic.plasmoidConfig) ? logic.plasmoidConfig : null;
        var isMetric = true;
        if (config) {
            if (config.weatherUseSystemUnits) {
                isMetric = Qt.locale().measurementSystem === Locale.MetricSystem;
            } else {
                isMetric = (config.weatherUnits || "metric") === "metric";
            }
        }
        var unitSymbol = isMetric ? "°C" : "°F";
        return current.temp + unitSymbol;
    }

    function getShortCity(locationStr) {
        if (!locationStr) return "";
        var parts = locationStr.split(",");
        if (parts.length === 1) return parts[0].trim();
        
        var first = parts[0].trim();
        var last = parts[parts.length - 1].trim();
        
        var countryIndicators = [
            "türkiye", "turkey", "united states", "us", "usa", "germany", "deutschland", 
            "france", "united kingdom", "uk", "italy", "italia", "spain", "españa", "canada", "england"
        ];
        var isFirstCountry = countryIndicators.indexOf(first.toLowerCase()) !== -1;
        var isLastCountry = countryIndicators.indexOf(last.toLowerCase()) !== -1 || last.length === 2;
        
        if (isFirstCountry) {
            return last;
        } else if (isLastCountry) {
            return first;
        }
        return first;
    }

    function getWeatherIconSource(current) {
        if (!current) return "";
        var config = (logic && logic.plasmoidConfig) ? logic.plasmoidConfig : null;
        var isDark = ((textColor.r + textColor.g + textColor.b) / 3) < 0.5;
        var provider = config ? (config.weatherProvider || "openmeteo") : "openmeteo";
        var pack = config ? (config.weatherIconPack || "default") : "default";
        var path = WeatherIcons.getIconPath(current.code, provider, isDark, pack);
        if (path.indexOf("/") !== -1) {
            return Qt.resolvedUrl(path);
        }
        return path;
    }

    function recalculateChunks() {
        var rawText = "";
        var weatherData = getWeatherData();
        
        if (currentState === "weather" && weatherData) {
            var current = weatherData.current;
            var city = getShortCity(current.location);
            var temp = getFormattedTemp(current);
            var cond = current.condition || current.description || "";
            var condText = i18nd("plasma_applet_com.mcc45tr.filesearch", cond);
            
            // Resolve icon source for the icon slide
            currentWeatherIconSource = getWeatherIconSource(current);
            
            if (isMediumMode) {
                // In Medium Mode, the chunks are: City -> Temp -> Icon (or just Temp -> Icon if city is not short)
                var showCity = (city !== "" && city.length <= 15);
                if (showCity) {
                    titleChunks = [city, temp, "WEATHER_ICON_PLACEHOLDER"];
                } else {
                    titleChunks = [temp, "WEATHER_ICON_PLACEHOLDER"];
                }
                currentChunkIndex = 0;
                currentTargetText = titleChunks[0];
                isWeatherIconSlide = false;
                
                // Trigger transition
                switchAnim.targetText = currentTargetText;
                switchAnim.restart();
                return;
            } else {
                // In other modes, the text is: "City Temp Condition"
                rawText = city + " " + temp + " " + condText;
            }
        } else if (currentState === "rss" && rssTitles.length > 0 && currentRssIndex >= 0) {
            rawText = rssTitles[currentRssIndex].text;
            if (rssShowSource) {
                rawText = "[" + (rssTitles[currentRssIndex].source || "RSS") + "] " + rawText;
            }
        } else {
            rawText = defaultText;
        }
        
        isWeatherIconSlide = false; // Reset weather icon slide flag for text states
        
        var availWidth = width - rightMarginValue;
        // Shift left margin if leftWeatherIcon is shown
        if (currentState === "weather" && !isMediumMode) {
            availWidth -= (fontSize * 1.2 + 6);
        }
        if (availWidth <= 50) availWidth = width > 50 ? width : 200;
        
        var newChunks = splitTextIntoChunks(rawText, availWidth);
        if (newChunks.length > 0 && newChunks[0] !== titleChunks[0]) {
            var isInitial = titleChunks.length === 0;
            titleChunks = newChunks;
            currentChunkIndex = 0;
            currentTargetText = newChunks[0];
            if (!isInitial) {
                switchAnim.targetText = currentTargetText;
                switchAnim.restart();
            }
        }
    }
    
    TextMetrics {
        id: titleMetrics
        font.pixelSize: tickerContainer.fontSize
        font.family: tickerContainer.fontFamily
    }
    
    function splitTextIntoChunks(text, maxWidth) {
        if (!text || maxWidth <= 60) return [text || ""];
        
        if (!rssShowFullHeadline && currentState === "rss") {
            titleMetrics.text = text;
            if (titleMetrics.advanceWidth <= maxWidth) return [text];
            var low = 1;
            var high = text.length;
            var fit = 1;
            while (low <= high) {
                var mid = Math.floor((low + high) / 2);
                titleMetrics.text = text.substring(0, mid) + "...";
                if (titleMetrics.advanceWidth <= maxWidth) {
                    fit = mid;
                    low = mid + 1;
                } else {
                    high = mid - 1;
                }
            }
            return [text.substring(0, fit) + "..."];
        }
        
        var targetWidth = maxWidth - 20; // 20px safety margin
        var chunks = [];
        var words = text.split(" ");
        var currentRawPart = "";
        
        function getDecorated(raw, isStart, isEnd) {
            if (raw === "") return "";
            var piece = raw.trim();
            return (isStart ? "" : "..") + piece + (isEnd ? "" : "..");
        }
        
        for (var i = 0; i < words.length; i++) {
            var word = words[i];
            var testRaw = currentRawPart + (currentRawPart === "" ? "" : " ") + word;
            
            titleMetrics.text = getDecorated(testRaw, chunks.length === 0, false);
            
            if (titleMetrics.advanceWidth <= targetWidth) {
                currentRawPart = testRaw;
            } else {
                if (currentRawPart !== "") {
                    chunks.push(getDecorated(currentRawPart, chunks.length === 0, false));
                    currentRawPart = word;
                } else {
                    currentRawPart = word;
                }
                
                titleMetrics.text = getDecorated(currentRawPart, chunks.length === 0, false);
                if (titleMetrics.advanceWidth > targetWidth) {
                    var remaining = currentRawPart;
                    while (remaining.length > 0) {
                        var low = 1, high = remaining.length, fitCount = 1;
                        while (low <= high) {
                            var mid = Math.floor((low + high) / 2);
                            var sub = remaining.substring(0, mid);
                            titleMetrics.text = getDecorated(sub, chunks.length === 0, false);
                            if (titleMetrics.advanceWidth <= targetWidth) {
                                fitCount = mid;
                                low = mid + 1;
                            } else {
                                high = mid - 1;
                            }
                        }
                        chunks.push(getDecorated(remaining.substring(0, fitCount), chunks.length === 0, false));
                        remaining = remaining.substring(fitCount);
                        if (chunks.length > 20) break;
                    }
                    currentRawPart = "";
                }
            }
        }
        if (currentRawPart !== "") {
            chunks.push(getDecorated(currentRawPart, chunks.length === 0, true));
        }
        
        if (chunks.length > 1) {
            var lastIdx = chunks.length - 1;
            chunks[lastIdx] = ".." + currentRawPart.trim();
        }
        
        return chunks;
    }
    
    Text {
        id: currentLabel
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.rightMargin: tickerContainer.rightMarginValue
        anchors.leftMargin: 0
        rightPadding: (tickerContainer.currentState === "weather" && !tickerContainer.isMediumMode) ? (tickerContainer.fontSize * 1.2 + 6) : 0
        height: parent.height
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: tickerContainer.horizontalAlignment
        text: tickerContainer.currentTargetText
        textFormat: Text.PlainText
        elide: Text.ElideRight
        wrapMode: Text.NoWrap
        opacity: tickerContainer.textOpacity
        color: tickerContainer.textColor
        font.pixelSize: tickerContainer.fontSize
        font.family: tickerContainer.fontFamily
        
        Image {
            id: currentCenterIconImage
            anchors.centerIn: parent
            width: tickerContainer.fontSize * 1.5
            height: width
            fillMode: Image.PreserveAspectFit
            visible: tickerContainer.isMediumMode && tickerContainer.currentState === "weather" && tickerContainer.isWeatherIconSlide && parent.text === "" && String(tickerContainer.currentWeatherIconSource).indexOf("/") !== -1
            source: visible ? tickerContainer.currentWeatherIconSource : ""
        }
        Kirigami.Icon {
            id: currentCenterIconSystem
            anchors.centerIn: parent
            width: tickerContainer.fontSize * 1.5
            height: width
            visible: tickerContainer.isMediumMode && tickerContainer.currentState === "weather" && tickerContainer.isWeatherIconSlide && parent.text === "" && String(tickerContainer.currentWeatherIconSource).indexOf("/") === -1
            source: visible ? tickerContainer.currentWeatherIconSource : ""
        }
        Image {
            id: currentRightIconImage
            anchors.left: parent.left
            anchors.leftMargin: Math.min(parent.width - width, parent.contentWidth + 6)
            anchors.verticalCenter: parent.verticalCenter
            width: tickerContainer.fontSize * 1.2
            height: width
            fillMode: Image.PreserveAspectFit
            visible: !tickerContainer.isMediumMode && tickerContainer.currentState === "weather" && String(tickerContainer.currentWeatherIconSource).indexOf("/") !== -1
            source: visible ? tickerContainer.currentWeatherIconSource : ""
        }
        Kirigami.Icon {
            id: currentRightIconSystem
            anchors.left: parent.left
            anchors.leftMargin: Math.min(parent.width - width, parent.contentWidth + 6)
            anchors.verticalCenter: parent.verticalCenter
            width: tickerContainer.fontSize * 1.2
            height: width
            visible: !tickerContainer.isMediumMode && tickerContainer.currentState === "weather" && String(tickerContainer.currentWeatherIconSource).indexOf("/") === -1
            source: visible ? tickerContainer.currentWeatherIconSource : ""
        }
    }
    
    Text {
        id: nextLabel
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.rightMargin: tickerContainer.rightMarginValue
        anchors.leftMargin: 0
        rightPadding: (tickerContainer.currentState === "weather" && !tickerContainer.isMediumMode) ? (tickerContainer.fontSize * 1.2 + 6) : 0
        height: parent.height
        y: -height
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: tickerContainer.horizontalAlignment
        text: ""
        textFormat: Text.PlainText
        elide: Text.ElideRight
        wrapMode: Text.NoWrap
        opacity: 0
        color: tickerContainer.textColor
        font.pixelSize: tickerContainer.fontSize
        font.family: tickerContainer.fontFamily
        
        Image {
            id: nextCenterIconImage
            anchors.centerIn: parent
            width: tickerContainer.fontSize * 1.5
            height: width
            fillMode: Image.PreserveAspectFit
            visible: tickerContainer.isMediumMode && tickerContainer.currentState === "weather" && tickerContainer.isWeatherIconSlide && parent.text === "" && String(tickerContainer.currentWeatherIconSource).indexOf("/") !== -1
            source: visible ? tickerContainer.currentWeatherIconSource : ""
        }
        Kirigami.Icon {
            id: nextCenterIconSystem
            anchors.centerIn: parent
            width: tickerContainer.fontSize * 1.5
            height: width
            visible: tickerContainer.isMediumMode && tickerContainer.currentState === "weather" && tickerContainer.isWeatherIconSlide && parent.text === "" && String(tickerContainer.currentWeatherIconSource).indexOf("/") === -1
            source: visible ? tickerContainer.currentWeatherIconSource : ""
        }
        Image {
            id: nextRightIconImage
            anchors.left: parent.left
            anchors.leftMargin: Math.min(parent.width - width, parent.contentWidth + 6)
            anchors.verticalCenter: parent.verticalCenter
            width: tickerContainer.fontSize * 1.2
            height: width
            fillMode: Image.PreserveAspectFit
            visible: !tickerContainer.isMediumMode && tickerContainer.currentState === "weather" && String(tickerContainer.currentWeatherIconSource).indexOf("/") !== -1
            source: visible ? tickerContainer.currentWeatherIconSource : ""
        }
        Kirigami.Icon {
            id: nextRightIconSystem
            anchors.left: parent.left
            anchors.leftMargin: Math.min(parent.width - width, parent.contentWidth + 6)
            anchors.verticalCenter: parent.verticalCenter
            width: tickerContainer.fontSize * 1.2
            height: width
            visible: !tickerContainer.isMediumMode && tickerContainer.currentState === "weather" && String(tickerContainer.currentWeatherIconSource).indexOf("/") === -1
            source: visible ? tickerContainer.currentWeatherIconSource : ""
        }
    }
    
    SequentialAnimation {
        id: switchAnim
        property string targetText: ""
        
        ParallelAnimation {
            NumberAnimation { target: currentLabel; property: "y"; to: tickerContainer.height; duration: 600; easing.type: Easing.InOutCubic }
            NumberAnimation { target: currentLabel; property: "opacity"; to: 0; duration: 600; easing.type: Easing.InOutCubic }
            
            SequentialAnimation {
                ScriptAction {
                    script: {
                        nextLabel.text = switchAnim.targetText
                        nextLabel.y = -tickerContainer.height
                    }
                }
                ParallelAnimation {
                    NumberAnimation { target: nextLabel; property: "y"; to: 0; duration: 600; easing.type: Easing.InOutCubic }
                    NumberAnimation { target: nextLabel; property: "opacity"; to: tickerContainer.textOpacity; duration: 600; easing.type: Easing.InOutCubic }
                }
            }
        }
        
        ScriptAction {
            script: {
                currentLabel.text = nextLabel.text
                currentLabel.y = 0
                currentLabel.opacity = tickerContainer.textOpacity
                nextLabel.opacity = 0
            }
        }
    }
    
    function computeNextState() {
        var weatherData = getWeatherData();
        var weatherAvailable = weatherPlaceholderCycling && (weatherData !== null);
        var rssAvailable = rssPlaceholderCycling && (rssTitles.length > 0);
        var f = rssFrequency;
        
        // 1. Process queue first
        if (stateQueue.length > 0) {
            var nextQueued = stateQueue.shift();
            var dur = 10000;
            if (nextQueued === "placeholder") {
                var pDur = 20000;
                if (f === 1) pDur = 10000;
                if (f === 2) pDur = 15000;
                if (f === 3) pDur = 20000;
                if (f === 4) pDur = 50000;
                if (f === 5) pDur = 300000;
                if (f === 6) pDur = 10000;
                dur = pDur;
            }
            return { state: nextQueued, duration: dur };
        }
        
        // Helper to check weather frequency
        function isWeatherDue(cycle) {
            if (!weatherAvailable) return false;
            var elapsedMs = Date.now() - lastWeatherShowTime;
            var intervalMs = 1800000; // default 30 min (Normal)
            if (weatherFrequency === 0) intervalMs = 60000;
            else if (weatherFrequency === 1) intervalMs = 300000;
            else if (weatherFrequency === 2) intervalMs = 1800000;
            else if (weatherFrequency === 3) intervalMs = 3600000;
            
            return (elapsedMs >= intervalMs);
        }

        // 2. Medium Mode Logic (no RSS)
        if (isMediumMode) {
            if (currentState === "placeholder") {
                cycleCounter++;
                var weatherDueMedium = isWeatherDue(cycleCounter);
                if (weatherDueMedium) {
                    return { state: "weather", duration: 3000 };
                } else {
                    return { state: "placeholder", duration: 180000 };
                }
            } else if (currentState === "weather") {
                return { state: "placeholder", duration: 180000 };
            }
            return { state: "placeholder", duration: 180000 };
        }

        // 3. Wide/Extra-Wide/Ultra-Wide modes
        if (currentState === "placeholder") {
            cycleCounter++;
            var weatherDue = isWeatherDue(cycleCounter);
            var rssDue = rssAvailable;
            
            if (rssDue && weatherDue) {
                // Queue weather after the current RSS item.
                stateQueue = ["weather"];
                return { state: "rss", duration: 10000 };
            } else if (rssDue) {
                return { state: "rss", duration: 10000 };
            } else if (weatherDue) {
                return { state: "weather", duration: 10000 };
            } else {
                var pDuration = 20000;
                if (f === 1) pDuration = 10000;
                if (f === 2) pDuration = 15000;
                if (f === 3) pDuration = 20000;
                if (f === 4) pDuration = 50000;
                if (f === 5) pDuration = 300000;
                if (f === 6) pDuration = 10000;
                return { state: "placeholder", duration: pDuration };
            }
        }
        
        if (currentState === "rss") {
            var maxConsecutive = 1;
            if (f === 1) maxConsecutive = 5;
            if (f === 2) maxConsecutive = 2;
            
            // Queue weather when it becomes due during an RSS item.
            var weatherDueNow = isWeatherDue(cycleCounter);
            if (weatherDueNow && stateQueue.indexOf("weather") === -1) {
                stateQueue.push("weather");
            }
            
            if (rssConsecutiveCount >= maxConsecutive - 1) {
                var pDuration = 20000;
                if (f === 1) pDuration = 10000;
                if (f === 2) pDuration = 15000;
                if (f === 3) pDuration = 20000;
                if (f === 4) pDuration = 50000;
                if (f === 5) pDuration = 300000;
                if (f === 6) pDuration = 10000;
                
                if (stateQueue.length > 0) {
                    var nextState = stateQueue.shift();
                    var dur = (nextState === "weather") ? 10000 : pDuration;
                    return { state: nextState, duration: dur };
                } else {
                    return { state: "placeholder", duration: pDuration };
                }
            } else {
                return { state: "rss", duration: 10000 };
            }
        }
        
        if (currentState === "weather") {
            var pDuration2 = 20000;
            if (f === 1) pDuration2 = 10000;
            if (f === 2) pDuration2 = 15000;
            if (f === 3) pDuration2 = 20000;
            if (f === 4) pDuration2 = 50000;
            if (f === 5) pDuration2 = 300000;
            if (f === 6) pDuration2 = 10000;
            
            // While weather is showing, if RSS becomes due/available, queue it
            if (rssAvailable && stateQueue.indexOf("rss") === -1) {
                stateQueue.push("rss");
            }
            
            if (stateQueue.length > 0) {
                var nextState2 = stateQueue.shift();
                var dur2 = (nextState2 === "rss") ? 10000 : pDuration2;
                return { state: nextState2, duration: dur2 };
            } else {
                return { state: "placeholder", duration: pDuration2 };
            }
        }
        
        return { state: "placeholder", duration: 20000 };
    }
    
    Timer {
        id: cycleTimer
        interval: tickerContainer.currentDuration
        running: tickerContainer.visible && !tickerContainer.isSearching && (
            (!tickerContainer.isMediumMode && tickerContainer.rssPlaceholderCycling && tickerContainer.rssTitles.length > 0) || 
            (tickerContainer.weatherPlaceholderCycling && tickerContainer.getWeatherData() !== null)
        )
        repeat: true
        triggeredOnStart: false
        
        onTriggered: {
            var weatherData = tickerContainer.getWeatherData();
            
            if (tickerContainer.titleChunks.length === 0) {
                tickerContainer.recalculateChunks();
                return;
            }
            
            if (tickerContainer.currentChunkIndex < tickerContainer.titleChunks.length - 1) {
                tickerContainer.currentChunkIndex++;
                tickerContainer.currentDuration = 3000;
                
                var chunkText = tickerContainer.titleChunks[tickerContainer.currentChunkIndex];
                if (chunkText === "WEATHER_ICON_PLACEHOLDER") {
                    tickerContainer.isWeatherIconSlide = true;
                    tickerContainer.currentTargetText = "";
                } else {
                    tickerContainer.isWeatherIconSlide = false;
                    tickerContainer.currentTargetText = chunkText;
                }
                switchAnim.targetText = tickerContainer.currentTargetText;
                switchAnim.restart();
                return;
            }
            
            var next = tickerContainer.computeNextState();
            var newRawText = "";
            
            if (next.state === "rss" && tickerContainer.rssTitles.length > 0) {
                if (tickerContainer.currentState === "rss") {
                    tickerContainer.rssConsecutiveCount++;
                } else {
                    tickerContainer.rssConsecutiveCount = 0;
                }
                
                var maxIndex = tickerContainer.rssTitles.length - 1;
                var randomIndex = tickerContainer.currentRssIndex;
                
                if (tickerContainer.rssTitles.length < 3) {
                    randomIndex = (tickerContainer.currentRssIndex + 1) % tickerContainer.rssTitles.length;
                } else {
                    var attempts = 0;
                    do {
                        randomIndex = Math.floor(Math.random() * (maxIndex + 1));
                        var chosenItem = tickerContainer.rssTitles[randomIndex];
                        var isRecentIndex = tickerContainer.recentIndices.indexOf(randomIndex) !== -1;
                        var isRecentSource = tickerContainer.recentSources.indexOf(chosenItem.source) !== -1;
                        if (!isRecentIndex && (!isRecentSource || attempts > 10)) break;
                        attempts++;
                    } while (attempts < 20);
                    
                    var newHistory = tickerContainer.recentIndices.slice();
                    newHistory.push(randomIndex);
                    if (newHistory.length > 3) newHistory.shift();
                    tickerContainer.recentIndices = newHistory;
                }
                
                tickerContainer.currentRssIndex = randomIndex;
                var tickerItem = tickerContainer.rssTitles[randomIndex];
                newRawText = tickerContainer.rssShowSource ? ("[" + (tickerItem.source || "RSS") + "] " + tickerItem.text) : tickerItem.text;
            } else if (next.state === "weather" && weatherData) {
                tickerContainer.rssConsecutiveCount = 0;
                var current = weatherData.current;
                var city = tickerContainer.getShortCity(current.location);
                var temp = tickerContainer.getFormattedTemp(current);
                var cond = current.condition || current.description || "";
                var condText = i18nd("plasma_applet_com.mcc45tr.filesearch", cond);
                
                tickerContainer.currentWeatherIconSource = tickerContainer.getWeatherIconSource(current);
                newRawText = city + " " + temp + " " + condText;
            } else {
                tickerContainer.rssConsecutiveCount = 0;
                newRawText = tickerContainer.defaultText;
            }
            
            tickerContainer.currentState = next.state;
            
            var availWidth = currentLabel.width;
            if (availWidth <= 50) availWidth = tickerContainer.width - tickerContainer.rightMarginValue;
            if (availWidth <= 50) availWidth = 200;
            
            var newChunks = [];
            if (next.state === "weather" && tickerContainer.isMediumMode && weatherData) {
                var current = weatherData.current;
                var city = tickerContainer.getShortCity(current.location);
                var temp = tickerContainer.getFormattedTemp(current);
                tickerContainer.currentWeatherIconSource = tickerContainer.getWeatherIconSource(current);
                
                var showCity = (city !== "" && city.length <= 15);
                if (showCity) {
                    newChunks = [city, temp, "WEATHER_ICON_PLACEHOLDER"];
                } else {
                    newChunks = [temp, "WEATHER_ICON_PLACEHOLDER"];
                }
            } else {
                newChunks = tickerContainer.splitTextIntoChunks(newRawText, availWidth);
            }
            
            if (newChunks.length === 1 && newChunks[0] === currentLabel.text && tickerContainer.titleChunks.length <= 1) {
                cycleTimer.interval = next.duration;
                tickerContainer.currentDuration = next.duration;
                tickerContainer.isWeatherIconSlide = false;
                return;
            }
            
            tickerContainer.titleChunks = newChunks;
            tickerContainer.currentChunkIndex = 0;
            
            tickerContainer.currentDuration = (newChunks.length > 1) ? 3000 : next.duration;
            cycleTimer.interval = tickerContainer.currentDuration;
            
            var firstChunk = newChunks[0];
            if (firstChunk === "WEATHER_ICON_PLACEHOLDER") {
                tickerContainer.isWeatherIconSlide = true;
                tickerContainer.currentTargetText = "";
            } else {
                tickerContainer.isWeatherIconSlide = false;
                tickerContainer.currentTargetText = firstChunk;
            }
            
            switchAnim.targetText = tickerContainer.currentTargetText;
            switchAnim.restart();
        }
    }
}
