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
        
        property var recentIndices: []
        property var recentSources: []
        property string defaultText: i18nd("plasma_applet_com.mcc45tr.filesearch", "Arama yapmaya başla...")
        
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
        
        property int currentDuration: getInitialDuration()
        property string currentTargetText: currentState === "placeholder" ? defaultText : (rssTitles.length > 0 && currentRssIndex >= 0 ? rssTitles[currentRssIndex].text : defaultText)
        
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
            elide: Text.ElideRight
            opacity: 0.35
            color: Kirigami.Theme.textColor
            font.pixelSize: root.font.pixelSize
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
            elide: Text.ElideRight
            opacity: 0
            color: Kirigami.Theme.textColor
            font.pixelSize: root.font.pixelSize
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
        
        Timer {
            interval: placeholderContainer.currentDuration
            running: placeholderContainer.visible && placeholderContainer.rssTitles.length > 0 && root.rssPlaceholderCycling && root.text.length === 0
            repeat: true
            onTriggered: {
                var next = placeholderContainer.computeNextState();
                
                if (next.state === "rss") {
                    if (placeholderContainer.currentState === "rss") {
                        placeholderContainer.rssConsecutiveCount++;
                    } else {
                        placeholderContainer.rssConsecutiveCount = 0;
                    }
                    
                    var maxIndex = placeholderContainer.rssTitles.length - 1;
                    var allUnique = [];
                    for (var u = 0; u < placeholderContainer.rssTitles.length; u++) {
                        var s = placeholderContainer.rssTitles[u].source;
                        if (s && allUnique.indexOf(s) === -1) allUnique.push(s);
                    }
                    var uniqueSources = allUnique.length;
                    
                    if (placeholderContainer.rssTitles.length < 3 || uniqueSources < 3) {
                        placeholderContainer.currentRssIndex = (placeholderContainer.currentRssIndex + 1) % placeholderContainer.rssTitles.length;
                    } else {
                        var randomIndex;
                        var attempts = 0;
                        var chosenItem;
                        do {
                            randomIndex = Math.floor(Math.random() * (maxIndex + 1));
                            chosenItem = placeholderContainer.rssTitles[randomIndex];
                            
                            var isRecentIndex = placeholderContainer.recentIndices.indexOf(randomIndex) !== -1;
                            var isRecentSource = placeholderContainer.recentSources.indexOf(chosenItem.source) !== -1;
                            
                            if (!isRecentIndex && (!isRecentSource || attempts > 8)) {
                                break;
                            }
                            attempts++;
                        } while (attempts < 20);
                        
                        var newHistory = placeholderContainer.recentIndices.slice();
                        newHistory.push(randomIndex);
                        var maxHistory = Math.min(3, maxIndex);
                        if (newHistory.length > maxHistory) newHistory.shift();
                        placeholderContainer.recentIndices = newHistory;
                        
                        var newSources = placeholderContainer.recentSources.slice();
                        newSources.push(chosenItem.source);
                        var maxSources = Math.max(0, uniqueSources - 2);
                        if (newSources.length > maxSources && newSources.length > 0) newSources.shift();
                        placeholderContainer.recentSources = newSources;
                        
                        placeholderContainer.currentRssIndex = randomIndex;
                    }
                } else {
                    placeholderContainer.rssConsecutiveCount = 0;
                }
                
                placeholderContainer.currentState = next.state;
                placeholderContainer.currentDuration = next.duration;
                
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
