import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

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
    property string fontFamily: "Roboto Condensed"
    property string defaultText: "Arama"
    property int horizontalAlignment: Text.AlignLeft
    property int rightMarginValue: 0
    property real textOpacity: 0.35
    property bool isSearching: false // Stop ticker when typing
    
    // Internal State
    property var titleChunks: []
    property int currentChunkIndex: -1
    property var recentIndices: []
    property var recentSources: []
    property string currentTargetText: defaultText
    property int currentDuration: 3000
    property string currentState: rssFrequency === 0 ? "rss" : "placeholder"
    
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
    }
    
    onWidthChanged: {
        if (width > 0 && currentTargetText !== "") {
            recalculateChunks();
        }
    }
    
    function recalculateChunks() {
        var rawText = (currentState === "rss" && rssTitles.length > 0 && currentRssIndex >= 0) ? rssTitles[currentRssIndex].text : defaultText;
        if (currentState === "rss" && rssShowSource && currentRssIndex >= 0) {
            rawText = "[" + (rssTitles[currentRssIndex].source || "RSS") + "] " + rawText;
        }
        var availWidth = width - rightMarginValue;
        if (availWidth <= 50) availWidth = width > 50 ? width : 200;
        
        var newChunks = splitTextIntoChunks(rawText, availWidth);
        if (newChunks.length > 0 && newChunks[0] !== titleChunks[0]) {
            titleChunks = newChunks;
            currentChunkIndex = 0;
            currentTargetText = newChunks[0];
            switchAnim.targetText = currentTargetText;
            switchAnim.restart();
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
            var truncated = text;
            while (truncated.length > 3) {
                titleMetrics.text = truncated + "...";
                if (titleMetrics.advanceWidth <= maxWidth) break;
                truncated = truncated.substring(0, truncated.length - 1);
            }
            return [truncated + "..."];
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
        height: parent.height
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: tickerContainer.horizontalAlignment
        text: tickerContainer.currentTargetText
        elide: Text.ElideRight
        wrapMode: Text.NoWrap
        opacity: tickerContainer.textOpacity
        color: tickerContainer.textColor
        font.pixelSize: tickerContainer.fontSize
        font.family: tickerContainer.fontFamily
    }
    
    Text {
        id: nextLabel
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.rightMargin: tickerContainer.rightMarginValue
        height: parent.height
        y: -height
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: tickerContainer.horizontalAlignment
        text: ""
        elide: Text.ElideRight
        wrapMode: Text.NoWrap
        opacity: 0
        color: tickerContainer.textColor
        font.pixelSize: tickerContainer.fontSize
        font.family: tickerContainer.fontFamily
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
        if (rssTitles.length === 0) return { state: "placeholder", duration: 10000 };
        var f = rssFrequency;
        if (f === 0) return { state: "rss", duration: 10000 };
        
        if (currentState === "placeholder") {
            if (f === 6) {
                var isNew = logic && logic.plasmoidConfig && (Date.now() - logic.plasmoidConfig.rssLastSyncAll < 300000);
                if (!isNew) return { state: "placeholder", duration: 30000 };
                return { state: "rss", duration: 10000 };
            }
            return { state: "rss", duration: 10000 };
        }
        
        if (currentState === "rss") {
            var maxConsecutive = 1;
            if (f === 1) maxConsecutive = 5;
            if (f === 2) maxConsecutive = 2;
            
            if (rssConsecutiveCount >= maxConsecutive - 1) {
                var pDuration = 20000;
                if (f === 1) pDuration = 10000;
                if (f === 2) pDuration = 15000;
                if (f === 3) pDuration = 20000;
                if (f === 4) pDuration = 50000;
                if (f === 5) pDuration = 300000;
                if (f === 6) pDuration = 10000;
                return { state: "placeholder", duration: pDuration };
            } else {
                return { state: "rss", duration: 10000 };
            }
        }
        return { state: "placeholder", duration: 10000 };
    }
    
    Timer {
        id: cycleTimer
        interval: tickerContainer.currentDuration
        running: tickerContainer.visible && !tickerContainer.isSearching
        repeat: true
        triggeredOnStart: false
        
        onTriggered: {
            if (tickerContainer.titleChunks.length === 0) {
                tickerContainer.recalculateChunks();
                return;
            }
            
            if (tickerContainer.currentChunkIndex < tickerContainer.titleChunks.length - 1) {
                tickerContainer.currentChunkIndex++;
                tickerContainer.currentDuration = 3000;
                switchAnim.targetText = tickerContainer.titleChunks[tickerContainer.currentChunkIndex];
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
            } else {
                tickerContainer.rssConsecutiveCount = 0;
                newRawText = tickerContainer.defaultText;
            }
            
            var availWidth = currentLabel.width;
            if (availWidth <= 50) availWidth = tickerContainer.width - tickerContainer.rightMarginValue;
            if (availWidth <= 50) availWidth = 200;
            
            var newChunks = tickerContainer.splitTextIntoChunks(newRawText, availWidth);
            tickerContainer.titleChunks = newChunks;
            tickerContainer.currentChunkIndex = 0;
            tickerContainer.currentState = next.state;
            
            tickerContainer.currentDuration = (newChunks.length > 1) ? 3000 : next.duration;
            cycleTimer.interval = tickerContainer.currentDuration;
            
            tickerContainer.currentTargetText = newChunks[0];
            switchAnim.targetText = tickerContainer.currentTargetText;
            switchAnim.restart();
        }
    }
}
