import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.kirigami as Kirigami

// Compact panel representation for the File Search widget
Item {
    id: compactRoot
    
    // Required properties from parent
    required property bool isButtonMode
    required property bool isWideMode
    required property bool isExtraWideMode
    required property bool expanded
    required property string truncatedText
    required property int responsiveFontSize
    required property color bgColor
    required property color textColor
    required property color accentColor
    required property int searchTextLength
    required property int panelRadius
    required property int panelHeight
    required property bool showSearchButton
    required property bool showSearchButtonBackground
    // New properties for animated ticker
    property var logic: null
    property bool rssPlaceholderCycling: true
    property int rssFrequency: 3
    
    // Signals
    signal toggleExpanded()
    
    // Button Mode - icon only (no background)
    Kirigami.Icon {
        id: buttonModeIcon
        anchors.centerIn: parent
        width: Math.min(parent.width, parent.height)
        height: width
        source: "plasma-search"
        color: compactRoot.textColor
        visible: compactRoot.isButtonMode
        
        MouseArea {
            anchors.fill: parent
            anchors.margins: -8
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            
            onEntered: buttonModeIcon.color = compactRoot.accentColor
            onExited: buttonModeIcon.color = compactRoot.textColor
            
            onClicked: compactRoot.toggleExpanded()
        }
    }


    
    // Main Button Container (for non-button modes)
    Rectangle {
        id: mainButton
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        height: compactRoot.panelHeight > 0 ? compactRoot.panelHeight : parent.height
        radius: compactRoot.panelRadius === 0 ? height / 2 : (compactRoot.panelRadius === 1 ? 12 : (compactRoot.panelRadius === 2 ? 6 : 0))
        color: Qt.rgba(compactRoot.bgColor.r, compactRoot.bgColor.g, compactRoot.bgColor.b, 0.95)
        visible: !compactRoot.isButtonMode
        
        // Border for definition
        border.width: 1
        border.color: compactRoot.expanded ? compactRoot.accentColor : Qt.rgba(compactRoot.textColor.r, compactRoot.textColor.g, compactRoot.textColor.b, 0.1)
        
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: (compactRoot.isWideMode || compactRoot.isExtraWideMode) ? 10 : 0
            anchors.rightMargin: (compactRoot.isWideMode || compactRoot.isExtraWideMode) ? (compactRoot.showSearchButton ? 4 : 10) : 0
            spacing: 6
            
            // Display text (Static when searching, Hidden when ticker is running)
            Text {
                id: displayText
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                text: compactRoot.truncatedText
                color: compactRoot.textColor
                font.pixelSize: compactRoot.responsiveFontSize
                font.family: "Roboto Condensed"
                horizontalAlignment: (compactRoot.isWideMode || compactRoot.isExtraWideMode) ? Text.AlignLeft : Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
                visible: compactRoot.searchTextLength > 0 // Only show static text when user is typing
            }

            // Animated Ticker Logic
            Item {
                id: tickerContainer
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: !compactRoot.isButtonMode && compactRoot.searchTextLength === 0
                clip: true
                
                property var recentIndices: []
                property var recentSources: []
                property string defaultText: compactRoot.isExtraWideMode ? i18nd("plasma_applet_com.mcc45tr.filesearch", "Arama yapmaya başla...") : (compactRoot.isWideMode ? i18nd("plasma_applet_com.mcc45tr.filesearch", "Arama yap...") : i18nd("plasma_applet_com.mcc45tr.filesearch", "Arama"))
                
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
                property string currentState: compactRoot.rssFrequency === 0 ? "rss" : "placeholder"
                
                onRssTitlesChanged: {
                    if (rssTitles.length > 0 && currentState === "placeholder" && !switchAnim.running) {
                        if (currentRssIndex < 0) currentRssIndex = 0;
                    }
                }
                
                function getInitialDuration() {
                    var f = compactRoot.rssFrequency;
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
                
                Text {
                    id: currentLabel
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: parent.height
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: (compactRoot.isWideMode || compactRoot.isExtraWideMode) ? Text.AlignLeft : Text.AlignHCenter
                    text: tickerContainer.currentTargetText
                    elide: Text.ElideRight
                    opacity: 0.35
                    color: compactRoot.textColor
                    font.pixelSize: compactRoot.responsiveFontSize
                    font.family: "Roboto Condensed"
                }
                
                Text {
                    id: nextLabel
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: parent.height
                    y: -height
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: currentLabel.horizontalAlignment
                    text: ""
                    elide: Text.ElideRight
                    opacity: 0
                    color: compactRoot.textColor
                    font.pixelSize: compactRoot.responsiveFontSize
                    font.family: "Roboto Condensed"
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
                    var f = compactRoot.rssFrequency;
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
                    interval: tickerContainer.currentDuration
                    running: tickerContainer.visible && tickerContainer.rssTitles.length > 0 && compactRoot.rssPlaceholderCycling && compactRoot.searchTextLength === 0
                    repeat: true
                    onTriggered: {
                        var next = tickerContainer.computeNextState();
                        
                        if (next.state === "rss") {
                            if (tickerContainer.currentState === "rss") {
                                tickerContainer.rssConsecutiveCount++;
                            } else {
                                tickerContainer.rssConsecutiveCount = 0;
                            }
                            
                            var maxIndex = tickerContainer.rssTitles.length - 1;
                            var allUnique = [];
                            for (var u = 0; u < tickerContainer.rssTitles.length; u++) {
                                var s = tickerContainer.rssTitles[u].source;
                                if (s && allUnique.indexOf(s) === -1) allUnique.push(s);
                            }
                            var uniqueSources = allUnique.length;
                            
                            if (tickerContainer.rssTitles.length < 3 || uniqueSources < 3) {
                                tickerContainer.currentRssIndex = (tickerContainer.currentRssIndex + 1) % tickerContainer.rssTitles.length;
                            } else {
                                var randomIndex;
                                var attempts = 0;
                                var chosenItem;
                                do {
                                    randomIndex = Math.floor(Math.random() * (maxIndex + 1));
                                    chosenItem = tickerContainer.rssTitles[randomIndex];
                                    
                                    var isRecentIndex = tickerContainer.recentIndices.indexOf(randomIndex) !== -1;
                                    var isRecentSource = tickerContainer.recentSources.indexOf(chosenItem.source) !== -1;
                                    
                                    if (!isRecentIndex && (!isRecentSource || attempts > 8)) {
                                        break;
                                    }
                                    attempts++;
                                } while (attempts < 20);
                                
                                var newHistory = tickerContainer.recentIndices.slice();
                                newHistory.push(randomIndex);
                                var maxHistory = Math.min(3, maxIndex);
                                if (newHistory.length > maxHistory) newHistory.shift();
                                tickerContainer.recentIndices = newHistory;
                                
                                var newSources = tickerContainer.recentSources.slice();
                                newSources.push(chosenItem.source);
                                var maxSources = Math.max(0, uniqueSources - 2);
                                if (newSources.length > maxSources && newSources.length > 0) newSources.shift();
                                tickerContainer.recentSources = newSources;
                                
                                tickerContainer.currentRssIndex = randomIndex;
                            }
                        } else {
                            tickerContainer.rssConsecutiveCount = 0;
                        }
                        
                        tickerContainer.currentState = next.state;
                        tickerContainer.currentDuration = next.duration;
                        
                        switchAnim.targetText = tickerContainer.currentTargetText;
                        switchAnim.restart();
                    }
                }
                
                // Initialization handled by LogicController directly

            }
            
            // Search Icon Button (Wide and Extra Wide Mode only)
            Rectangle {
                id: searchIconButton
                Layout.preferredWidth: ((compactRoot.isWideMode || compactRoot.isExtraWideMode) && compactRoot.showSearchButton) ? (mainButton.height - 6) : 0
                Layout.preferredHeight: mainButton.height - 6
                Layout.alignment: Qt.AlignVCenter
                radius: compactRoot.panelRadius === 0 ? width / 2 : (compactRoot.panelRadius === 1 ? 8 : (compactRoot.panelRadius === 2 ? 4 : 0))
                color: compactRoot.showSearchButtonBackground ? compactRoot.accentColor : "transparent"
                visible: (compactRoot.isWideMode || compactRoot.isExtraWideMode) && compactRoot.showSearchButton
                
                Behavior on Layout.preferredWidth { NumberAnimation { duration: 200 } }
                
                Kirigami.Icon {
                    anchors.centerIn: parent
                    width: parent.width * 0.55
                    height: width
                    source: "search"
                    color: compactRoot.showSearchButtonBackground ? "#ffffff" : compactRoot.textColor
                }
            }
        }
        
        // Click handler - opens popup
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            
            onEntered: mainButton.color = Qt.rgba(compactRoot.bgColor.r, compactRoot.bgColor.g, compactRoot.bgColor.b, 1.0)
            onExited: mainButton.color = Qt.rgba(compactRoot.bgColor.r, compactRoot.bgColor.g, compactRoot.bgColor.b, 0.95)
            
            onClicked: compactRoot.toggleExpanded()
        }
    }

}
