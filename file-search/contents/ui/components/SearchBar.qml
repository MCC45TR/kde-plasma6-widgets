import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.extras as PlasmaExtras

/**
 * SearchBar component for file-search, matching app-menu's style.
 * Uses standard Plasma SearchField at the top of the popup.
 */
PlasmaExtras.SearchField {
    id: root
    
    // Properties for compatibility with file-search logic
    property int resultCount: 0
    property var resultsModel: null
    property var logic: null
    property bool rssPlaceholderCycling: true
    property int rssFrequency: 3
    
    placeholderText: "" // Hidden to use our animated labels
    
    // Animated Placeholder Logic
    Item {
        id: placeholderContainer
        anchors.fill: parent
        anchors.leftMargin: 36 // Space for search icon
        anchors.rightMargin: 32
        visible: root.text.length === 0
        clip: true
        
        TextMetrics {
            id: titleMetrics
            font.pixelSize: root.font.pixelSize
            font.family: root.font.family
        }
        
        property var titleChunks: []
        property int currentChunkIndex: -1
        
        property var recentIndices: []
        property var recentSources: []
        property string defaultText: i18nd("plasma_applet_com.mcc45tr.filesearch", "Arama yapmaya başla...")
        
        // Recalculate chunks if width changes (e.g. panel resize)
        onWidthChanged: {
            if (currentTargetText !== "" && currentLabel.width > 50) {
                var rawText = (currentState === "rss" && rssTitles.length > 0 && currentRssIndex >= 0) ? rssTitles[currentRssIndex].text : defaultText;
                var newChunks = splitTextIntoChunks(rawText, currentLabel.width);
                if (newChunks.length !== titleChunks.length) {
                    titleChunks = newChunks;
                    currentChunkIndex = 0;
                    currentTargetText = newChunks[0];
                    switchAnim.targetText = currentTargetText;
                    switchAnim.restart();
                }
            }
        }
        
        // Cache management
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
        property string currentState: root.rssFrequency === 0 ? "rss" : "placeholder"
        
        // Watch for RSS data arrival to potentially trigger a faster initial transition
        onRssTitlesChanged: {
            if (rssTitles.length > 0 && currentState === "placeholder" && !switchAnim.running) {
                // If data just arrived, maybe trigger sooner? 
                // For now, just ensure currentRssIndex is valid
                if (currentRssIndex < 0) currentRssIndex = 0;
            }
        }
        
        function getInitialDuration() {
            var f = root.rssFrequency;
            if (f === 0) return 10000;
            if (f === 1) return 10000;
            if (f === 2) return 15000;
            if (f === 3) return 20000;
            if (f === 4) return 50000;
            if (f === 5) return 300000;
            if (f === 6) return 10000;
            return 10000;
        }
        
        property int currentDuration: 3000 // User requested 3s per part
        property string currentTargetText: defaultText // Start with default text immediately
        
        // Right side icon
        Kirigami.Icon {
            id: searchIconRight
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            width: 16
            height: 16
            source: "plasma-search"
            color: Kirigami.Theme.textColor
            opacity: root.text.length === 0 ? 0.35 : 0.7
            Behavior on opacity { NumberAnimation { duration: 250 } }
        }

        Text {
            id: currentLabel
            anchors.left: parent.left
            anchors.right: searchIconRight.left
            anchors.rightMargin: 8
            height: parent.height
            verticalAlignment: Text.AlignVCenter
            text: placeholderContainer.currentTargetText
            elide: Text.ElideNone // Explicitly disable elision to show the full segment
            wrapMode: Text.NoWrap // Ensure it doesn't wrap and spill over
            opacity: 0.35
            color: Kirigami.Theme.textColor
            font.pixelSize: root.font.pixelSize
            font.family: root.font.family // Sync font family with root and metrics
        }
        
        Text {
            id: nextLabel
            anchors.left: parent.left
            anchors.right: searchIconRight.left
            anchors.rightMargin: 8
            height: parent.height
            y: -height
            verticalAlignment: Text.AlignVCenter
            text: ""
            elide: Text.ElideNone // Explicitly disable elision
            wrapMode: Text.NoWrap
            opacity: 0
            color: Kirigami.Theme.textColor
            font.pixelSize: root.font.pixelSize
            font.family: root.font.family // Sync font family
        }
        
        SequentialAnimation {
            id: switchAnim
            property string targetText: ""
            
            ParallelAnimation {
                NumberAnimation { target: currentLabel; property: "y"; to: placeholderContainer.height; duration: 600; easing.type: Easing.InOutCubic }
                NumberAnimation { target: currentLabel; property: "opacity"; to: 0; duration: 600; easing.type: Easing.InOutCubic }
                
                SequentialAnimation {
                    ScriptAction {
                        script: {
                            nextLabel.text = switchAnim.targetText
                            nextLabel.y = -placeholderContainer.height
                        }
                    }
                    ParallelAnimation {
                        NumberAnimation { target: nextLabel; property: "y"; to: 0; duration: 600; easing.type: Easing.InOutCubic }
                        NumberAnimation { target: nextLabel; property: "opacity"; to: 0.35; duration: 600; easing.type: Easing.InOutCubic }
                    }
                }
            }
            
            ScriptAction {
                script: {
                    currentLabel.text = nextLabel.text
                    currentLabel.y = 0
                    currentLabel.opacity = 0.35
                    nextLabel.opacity = 0
                }
            }
        }
        
        function computeNextState() {
            if (rssTitles.length === 0) return { state: "placeholder", duration: 10000 };
            var f = root.rssFrequency;
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

        function splitTextIntoChunks(text, maxWidth) {
            if (!text || maxWidth <= 60) return [text || ""];
            
            // Safety margin: 10% or at least 40px to account for icons and '..'
            var targetWidth = maxWidth - 40;
            
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
                
                // Measure with potential decorations
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
                    
                    // Handle single word longer than width
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
            
            // Fix the very last chunk decoration (no '..' at the end)
            if (chunks.length > 1) {
                var lastIdx = chunks.length - 1;
                var lastRaw = currentRawPart; 
                // Re-calculate last decoration to ensure it ends cleanly
                // Note: currentRawPart was already the last piece
                chunks[lastIdx] = ".." + currentRawPart.trim();
            }
            
            return chunks;
        }
        
        Timer {
            id: cycleTimer
            interval: 3000 // Default 3s
            running: placeholderContainer.visible && root.text.length === 0
            repeat: true
            triggeredOnStart: false // Wait for initial layout to get correct width
            
            onTriggered: {
                // 1. If we have more chunks for the current item, show next chunk
                if (placeholderContainer.currentChunkIndex < placeholderContainer.titleChunks.length - 1) {
                    placeholderContainer.currentChunkIndex++;
                    placeholderContainer.currentTargetText = placeholderContainer.titleChunks[placeholderContainer.currentChunkIndex];
                    switchAnim.targetText = placeholderContainer.currentTargetText;
                    switchAnim.restart();
                    return;
                }
                
                // 2. Otherwise, pick next item (Headline or Placeholder)
                var next = placeholderContainer.computeNextState();
                var newRawText = "";
                
                if (next.state === "rss" && placeholderContainer.rssTitles.length > 0) {
                    if (placeholderContainer.currentState === "rss") {
                        placeholderContainer.rssConsecutiveCount++;
                    } else {
                        placeholderContainer.rssConsecutiveCount = 0;
                    }
                    
                    var maxIndex = placeholderContainer.rssTitles.length - 1;
                    var randomIndex = placeholderContainer.currentRssIndex;
                    
                    // Logic to select a random item (same as before)
                    if (placeholderContainer.rssTitles.length < 3) {
                        randomIndex = (placeholderContainer.currentRssIndex + 1) % placeholderContainer.rssTitles.length;
                    } else {
                        var attempts = 0;
                        do {
                            randomIndex = Math.floor(Math.random() * (maxIndex + 1));
                            var chosenItem = placeholderContainer.rssTitles[randomIndex];
                            var isRecentIndex = placeholderContainer.recentIndices.indexOf(randomIndex) !== -1;
                            var isRecentSource = placeholderContainer.recentSources.indexOf(chosenItem.source) !== -1;
                            if (!isRecentIndex && (!isRecentSource || attempts > 10)) break;
                            attempts++;
                        } while (attempts < 20);
                        
                        // Update history
                        var newHistory = placeholderContainer.recentIndices.slice();
                        newHistory.push(randomIndex);
                        if (newHistory.length > 3) newHistory.shift();
                        placeholderContainer.recentIndices = newHistory;
                    }
                    
                    placeholderContainer.currentRssIndex = randomIndex;
                    newRawText = placeholderContainer.rssTitles[randomIndex].text;
                } else {
                    placeholderContainer.rssConsecutiveCount = 0;
                    newRawText = placeholderContainer.defaultText;
                }
                
                // 3. Prepare chunks for the new text
                // Use currentLabel's actual width as the reference.
                var availWidth = currentLabel.width;
                if (availWidth <= 50) {
                    // If still 0, try to estimate from placeholderContainer if available
                    availWidth = placeholderContainer.width - searchIconRight.width - 24;
                }
                if (availWidth <= 50) availWidth = 400; // Better fallback for "en geniş mod" (widest mode)
                
                var newChunks = placeholderContainer.splitTextIntoChunks(newRawText, availWidth);
                placeholderContainer.titleChunks = newChunks;
                placeholderContainer.currentChunkIndex = 0;
                placeholderContainer.currentState = next.state;
                
                // Duration Logic: 
                // - If multi-part (chunks > 1), use 3s per part.
                // - If single-part, use the user's frequency setting (next.duration).
                placeholderContainer.currentDuration = (newChunks.length > 1) ? 3000 : next.duration;
                cycleTimer.interval = placeholderContainer.currentDuration;
                
                placeholderContainer.currentTargetText = newChunks[0];
                switchAnim.targetText = placeholderContainer.currentTargetText;
                switchAnim.restart();
            }
        }
        
        // Initialization handled by LogicController directly

    }
    
    // Signals for navigation and control
    signal textUpdated(string newText)
    signal searchSubmitted(string text, int selectedIndex)
    signal escapePressed()
    signal upPressed()
    signal downPressed()
    signal leftPressed()
    signal rightPressed()
    signal tabPressedSignal()
    signal shiftTabPressedSignal()
    signal viewModeChangeRequested(int mode)
    
    // Ensure text is synced
    onTextChanged: {
        root.textUpdated(text)
    }
    
    onAccepted: {
        if (text.length > 0) {
            root.searchSubmitted(text, 0)
        }
    }
    
    // Keyboard navigation
    Keys.onEscapePressed: {
        root.escapePressed()
    }
    
    Keys.onDownPressed: {
        root.downPressed()
    }
    
    Keys.onUpPressed: {
        root.upPressed()
    }
    
    Keys.onLeftPressed: (event) => {
        if (cursorPosition === 0) {
            root.leftPressed()
            event.accepted = true
        } else {
            event.accepted = false
        }
    }
    
    Keys.onRightPressed: (event) => {
        if (cursorPosition === text.length) {
            root.rightPressed()
            event.accepted = true
        } else {
            event.accepted = false
        }
    }
    
    Keys.onTabPressed: (event) => {
        if (event.modifiers & Qt.ShiftModifier) {
            root.shiftTabPressedSignal()
        } else {
            root.tabPressedSignal()
        }
        event.accepted = true
    }
    
    Keys.onPressed: (event) => {
        if (event.modifiers & Qt.ControlModifier) {
            if (event.key === Qt.Key_1) {
                root.viewModeChangeRequested(0)
                event.accepted = true
            } else if (event.key === Qt.Key_2) {
                root.viewModeChangeRequested(1)
                event.accepted = true
            }
        }
    }
    
    // Focus helper
    function focusInput() {
        forceActiveFocus()
    }
    
    function setText(newText) {
        text = newText
    }
    
    function clear() {
        text = ""
    }
}
