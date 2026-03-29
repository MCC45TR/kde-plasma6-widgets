import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.kirigami as Kirigami

// Query Hints - Shows KRunner prefix hints and syntax feedback
Rectangle {
    id: queryHints
    
    // Required properties
    required property string searchText
    required property color textColor
    required property color accentColor
    required property color bgColor
    required property var logic
    property var plasmoidConfig // injected from SearchPopup
    
    // Signals
    signal hintSelected(string text)
    
    // Computed hint based on search text
    property var currentHint: detectHint(searchText)
    
    // Visibility - show when there's a relevant hint
    visible: currentHint.show && searchText.length > 0
    
    // KRunner supported prefixes with detailed descriptions
    readonly property var knownPrefixes: [
        { 
            prefix: ":",
            hint: i18nd("plasma_applet_com.mcc45tr.filesearch", "Search Prefixes"),
            desc: i18nd("plasma_applet_com.mcc45tr.filesearch", "Show all available search filters"),
            icon: "help-about",
            category: "Help"
        },
        { 
            prefix: "timeline:/", 
            hint: i18nd("plasma_applet_com.mcc45tr.filesearch", "Timeline View"), 
            desc: i18nd("plasma_applet_com.mcc45tr.filesearch", "Browse files by date (Today, Yesterday, etc.)"),
            icon: "view-calendar",
            category: "Files",
            options: [
                { label: i18nd("plasma_applet_com.mcc45tr.filesearch", "Calendar"), value: "timeline:/calendar/" },
                { label: i18nd("plasma_applet_com.mcc45tr.filesearch", "Today"), value: "timeline:/today" },
                { label: i18nd("plasma_applet_com.mcc45tr.filesearch", "Yesterday"), value: "timeline:/yesterday" },
                { label: i18nd("plasma_applet_com.mcc45tr.filesearch", "This Week"), value: "timeline:/thisweek" },
                { label: i18nd("plasma_applet_com.mcc45tr.filesearch", "This Month"), value: "timeline:/thismonth" }
            ]
        },
        { prefix: "file:/", hint: i18nd("plasma_applet_com.mcc45tr.filesearch", "File Path"), desc: i18nd("plasma_applet_com.mcc45tr.filesearch", "Search via absolute file path"), icon: "folder", category: "Files", localeBase: "file" },
        { prefix: "baloo:", hint: i18nd("plasma_applet_com.mcc45tr.filesearch", "File Index"), desc: i18nd("plasma_applet_com.mcc45tr.filesearch", "Search exclusively in Baloo file index"), icon: "baloo", category: "Files" },
        { prefix: "documents:", hint: i18nd("plasma_applet_com.mcc45tr.filesearch", "Documents"), desc: i18nd("plasma_applet_com.mcc45tr.filesearch", "Search only document files"), icon: "document-multiple", category: "Files" },
        { prefix: "images:", hint: i18nd("plasma_applet_com.mcc45tr.filesearch", "Images"), desc: i18nd("plasma_applet_com.mcc45tr.filesearch", "Search only image files"), icon: "image-jpeg", category: "Files" },
        
        { prefix: "app:", hint: i18nd("plasma_applet_com.mcc45tr.filesearch", "Applications"), desc: i18nd("plasma_applet_com.mcc45tr.filesearch", "Search for installed applications"), icon: "applications-all", category: "System", localeBase: "app" },
        { prefix: "services:", hint: i18nd("plasma_applet_com.mcc45tr.filesearch", "Services"), desc: i18nd("plasma_applet_com.mcc45tr.filesearch", "Search system background services"), icon: "preferences-system", category: "System", localeBase: "services" },
        { prefix: "shell:", hint: i18nd("plasma_applet_com.mcc45tr.filesearch", "Shell"), desc: i18nd("plasma_applet_com.mcc45tr.filesearch", "Execute shell commands directly"), icon: "utilities-terminal", category: "System", localeBase: "shell" },
        
        { prefix: "calc:", hint: i18nd("plasma_applet_com.mcc45tr.filesearch", "Calculator"), desc: i18nd("plasma_applet_com.mcc45tr.filesearch", "Perform mathematical calculations"), icon: "accessories-calculator", category: "Utility" },
        { prefix: "unit:", hint: i18nd("plasma_applet_com.mcc45tr.filesearch", "Unit Converter"), desc: i18nd("plasma_applet_com.mcc45tr.filesearch", "Convert between weights, distances, etc."), icon: "measure", category: "Utility", localeBase: "unit" },
        { prefix: "spell ", hint: i18nd("plasma_applet_com.mcc45tr.filesearch", "Spelling"), desc: i18nd("plasma_applet_com.mcc45tr.filesearch", "Check word spelling"), icon: "tools-check-spelling", category: "Utility", localeBase: "spell" },
        
        { prefix: "gg:", hint: i18nd("plasma_applet_com.mcc45tr.filesearch", "Google"), desc: i18nd("plasma_applet_com.mcc45tr.filesearch", "Search the web using Google"), icon: "google", category: "Web", localeBase: "google" },
        { prefix: "dd:", hint: i18nd("plasma_applet_com.mcc45tr.filesearch", "DuckDuckGo"), desc: i18nd("plasma_applet_com.mcc45tr.filesearch", "Search the web using DuckDuckGo"), icon: "internet-web-browser", category: "Web", localeBase: "ddg" },
        { prefix: "wp:", hint: i18nd("plasma_applet_com.mcc45tr.filesearch", "Wikipedia"), desc: i18nd("plasma_applet_com.mcc45tr.filesearch", "Search Wikipedia articles"), icon: "wikipedia", category: "Web", localeBase: "wikipedia" },
        { prefix: "b:", hint: i18nd("plasma_applet_com.mcc45tr.filesearch", "Bookmarks"), desc: i18nd("plasma_applet_com.mcc45tr.filesearch", "Search browser bookmarks"), icon: "bookmarks", category: "Web", localeBase: "bookmarks" },
        { prefix: "rss:", hint: i18nd("plasma_applet_com.mcc45tr.filesearch", "RSS Feeds"), desc: i18nd("plasma_applet_com.mcc45tr.filesearch", "Search exclusively in RSS news feeds"), icon: "news-subscribe", category: "Web", localeBase: "rss" },
        
        { prefix: "man:/", hint: i18nd("plasma_applet_com.mcc45tr.filesearch", "Man Pages"), desc: i18nd("plasma_applet_com.mcc45tr.filesearch", "Browse system manual pages"), icon: "help-contents", category: "Help", localeBase: "man" },
        { prefix: "help:", hint: i18nd("plasma_applet_com.mcc45tr.filesearch", "Help"), desc: i18nd("plasma_applet_com.mcc45tr.filesearch", "Show widget documentation"), icon: "help-about", category: "Help", localeBase: "help" }
    ]
    
    // Helper for date formatting
    property var currentLocale: Qt.locale(Qt.locale().name.substring(0, 2))
    
    function getTimelineMonthOptions() {
        var options = [];
        var today = new Date();
        
        // Generate current and previous 5 months
        for (var i = 0; i < 6; i++) {
            var d = new Date(today.getFullYear(), today.getMonth() - i, 1);
            // Format: "January 2026" (Localized)
            var monthName = d.toLocaleDateString(currentLocale, "MMMM yyyy");
            // Capitalize first letter if needed (some locales don't)
            monthName = monthName.charAt(0).toUpperCase() + monthName.slice(1);
            
            var val = "timeline:/calendar/" + monthName + "/";
            
            options.push({ 
                label: monthName, 
                value: val
            });
        }
        return options;
    }
    
    function getTimelineDayOptions(baseQuery) {
        var options = [];
        var today = new Date();
        
        // If baseQuery doesn't end with /, add it
        if (!baseQuery.endsWith("/")) baseQuery += "/";
        
        for (var i = 0; i < 31; i++) {
            var d = new Date();
            d.setDate(today.getDate() - i);
            
            // Format: "14 Ocak 2026 Çarşamba" to match folder structure
            var dayName = d.toLocaleDateString(currentLocale, "d MMMM yyyy dddd");
            
            var val = baseQuery + dayName;
            
            var label = "";
            
            if (i === 0) {
                label = ""; 
            } else if (i === 1) {
                label = ""; 
            } else if (i === 2) {
                label = ""; 
            } else {
                label = dayName;
            }
            
            if (i === 0) val = baseQuery + i18nd("plasma_applet_com.mcc45tr.filesearch", "Today");
            else if (i === 1) val = baseQuery + i18nd("plasma_applet_com.mcc45tr.filesearch", "Yesterday");
            else if (i === 2) val = baseQuery + i18nd("plasma_applet_com.mcc45tr.filesearch", "Two days ago");
             
            options.push({ 
                label: label, 
                value: val,
                // These are used for button labels
                displayLabel: (i===0 ? i18nd("plasma_applet_com.mcc45tr.filesearch", "Today") : (i===1 ? i18nd("plasma_applet_com.mcc45tr.filesearch", "Yesterday") : (i===2 ? i18nd("plasma_applet_com.mcc45tr.filesearch", "Two days ago") : dayName)))
            });
        }
        return options;
    }
    
    function detectHint(query) {
        if (!query || query.length === 0) {
            return { show: false, text: "", icon: "", isError: false, isPrefixMenu: false }
        }
        
        // Full prefix menu trigger
        if (query === ":") {
            return {
                show: true,
                isPrefixMenu: true,
                text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Search Prefixes"),
                icon: "help-about",
                isError: false
            }
        }

        var lowerQuery = query.toLowerCase()
        
        // 1. Check for known prefixes (both English keys and Localized keys)
        var bestMatch = null;
        var bestLen = -1;
        var matchedPrefix = ""; 
        
        for (var i = 0; i < knownPrefixes.length; i++) {
             var p = knownPrefixes[i]
             
             // Skip the ':' menu trigger itself during normal prefix matching
             if (p.prefix === ":") continue;
             
             // Check if disabled by config (weather)
             if (p.prefix === "weather:" && plasmoidConfig && !plasmoidConfig.weatherEnabled) {
                 continue;
             }
             
             // Check standard prefix
             var standardP = p.prefix.toLowerCase();
             
             // Check localized prefix (simple approximation using i18n of the localeBase)
             // This assumes the translated "file" corresponds to the prefix.
             // e.g. i18nd("plasma_applet_com.mcc45tr.filesearch", "file") -> "dosya". user types "dosya:/"
             var localizedP = "";
             if (p.localeBase) {
                 var locKeyVal = i18nd("plasma_applet_com.mcc45tr.filesearch", p.localeBase); // e.g. "dosya"
                 if (locKeyVal && locKeyVal !== p.localeBase) {
                      // Reconstruct suffix style
                      var suffix = "";
                      if (p.prefix.endsWith(":")) suffix = ":";
                      else if (p.prefix.endsWith(" ")) suffix = " ";
                      else if (p.prefix.endsWith(":/")) suffix = ":/";
                      
                      localizedP = (locKeyVal + suffix).toLowerCase();
                 }
             }
             
             // Check match against standard
             if (lowerQuery.startsWith(standardP)) {
                 if (standardP.length > bestLen) {
                     bestMatch = p;
                     bestLen = standardP.length;
                     matchedPrefix = p.prefix; 
                 }
             }
             
             // Check match against localized
             if (localizedP && localizedP.length > 0 && lowerQuery.startsWith(localizedP)) {
                 if (localizedP.length > bestLen) {
                     bestMatch = p;
                     bestLen = localizedP.length;
                     matchedPrefix = localizedP;
                 }
             }
        }
        
        // Special Timeline sub-logic
        if (bestMatch && bestMatch.prefix === "timeline:/") {
             // Basic timeline:/ match
             if (lowerQuery === matchedPrefix.toLowerCase() || lowerQuery === matchedPrefix.toLowerCase().replace("/", "")) {
                  return {
                    show: true,
                    text: bestMatch.hint,
                    icon: bestMatch.icon,
                    isError: false,
                    prefix: matchedPrefix,
                    options: getTimelineMonthOptions()
                 }
             }
             
             // Check calendar sub-path
             if (lowerQuery.indexOf("/calendar/") !== -1) {
                  // If slashes count >= 3, show days
                  var slashes = (query.match(/\//g) || []).length;
                  if (slashes >= 3) {
                       return {
                            show: true,
                            text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Browse calendar"),
                            icon: "view-calendar-day",
                            isError: false,
                            prefix: query, 
                            options: getTimelineDayOptions(query)
                       }
                  }
                  
                   return {
                        show: true,
                        text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Browse calendar"),
                        icon: "view-calendar-month",
                        isError: false,
                        prefix: matchedPrefix,
                        options: getTimelineMonthOptions()
                   }
             }
        }
        
        if (bestMatch) {
             // Known prefix found
             
             // Check for Man page installation
             if (bestMatch.prefix === "man:/" && logic && !logic.manInstalled) {
                 return { show: true, text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Man pages not installed"), icon: "dialog-error", isError: true, prefix: matchedPrefix }
             }
             
             var baseHint = bestMatch.hint;
             var queryPart = "";

             // Check if user has typed something after the prefix
             if (query.length > bestLen) {
                 var rawQuery = query.substring(bestLen).trim();
                 if (rawQuery.length > 0) {
                     queryPart = ' "' + rawQuery + '"';
                 }
             }

             if (queryPart.length > 0) {
                 if (bestMatch.prefix === "gg:" || bestMatch.prefix === "dd:" || bestMatch.prefix === "wp:" || bestMatch.prefix === "define:") {
                      baseHint = baseHint + queryPart;
                 }
             }
             
             return {
                show: true,
                text: baseHint,
                icon: bestMatch.icon,
                isError: false,
                prefix: matchedPrefix,
                options: bestMatch.options
             }
        }
        
        // Unknown prefix detection
        var colonIndex = query.indexOf(":")
        if (colonIndex > 0 && colonIndex < 10) {
            var potentialPrefix = query.substring(0, colonIndex + 1).toLowerCase()
            
            var isKnown = false;
            for (var k = 0; k < knownPrefixes.length; k++) {
                 var kp = knownPrefixes[k];
                 if (kp.prefix.toLowerCase().startsWith(potentialPrefix)) isKnown = true;
                 
                 if (kp.localeBase) {
                     var locK = i18nd("plasma_applet_com.mcc45tr.filesearch", kp.localeBase);
                     if (locK) {
                        var safeLocK = locK.toLowerCase();
                        if ((safeLocK + ":").startsWith(potentialPrefix)) isKnown = true;
                        if ((safeLocK + " ").startsWith(potentialPrefix)) isKnown = true;
                     }
                 }
                 if (isKnown) break;
            }
            
            if (!isKnown && potentialPrefix !== "file:" && potentialPrefix !== "http:" && potentialPrefix !== "https:") {
                return {
                    show: true,
                    text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Unknown prefix") + ": " + potentialPrefix + " (" + i18nd("plasma_applet_com.mcc45tr.filesearch", "try") + " 'help:')",
                    icon: "dialog-warning",
                    isError: true
                }
            }
        }
        
        return { show: false, text: "", icon: "", isError: false }
    }
    
    // Read-only helper for view mode
    readonly property bool isTileView: plasmoidConfig ? (plasmoidConfig.viewMode === 1) : false

    height: visible ? (currentHint.isPrefixMenu ? 320 : (hintContent.implicitHeight + 12) * 2) : 0
    color: Qt.rgba(bgColor.r, bgColor.g, bgColor.b, 0.95)
    radius: 12
    border.width: 1
    border.color: currentHint.isError 
        ? Qt.rgba(1, 0.3, 0.3, 0.5) 
        : Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.3)
    
    // Header for Menu
    Rectangle {
        id: menuHeader
        width: parent.width
        height: visible ? 32 : 0
        visible: queryHints.currentHint ? queryHints.currentHint.isPrefixMenu : false
        color: "transparent"
        
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 8
            
            Kirigami.Icon {
                source: "help-about"
                Layout.preferredWidth: 16
                Layout.preferredHeight: 16
                color: queryHints.textColor
            }
            
            Text {
                text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Available Search Prefixes")
                color: queryHints.textColor
                font.bold: true
                font.pixelSize: 12
            }
            
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Qt.rgba(queryHints.textColor.r, queryHints.textColor.g, queryHints.textColor.b, 0.1)
            }
        }
    }

    Behavior on height { NumberAnimation { duration: 250; easing.type: Easing.OutQuint } }
    
    // Prefix Grid/List View
    ScrollView {
        id: prefixScrollView
        anchors.top: menuHeader.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 8
        visible: queryHints.currentHint ? queryHints.currentHint.isPrefixMenu : false
        clip: true
        
        GridView {
            id: prefixGrid
            anchors.fill: parent
            model: queryHints.knownPrefixes.slice(1) // Skip the trigger itself
            cellWidth: isTileView ? 110 : width
            cellHeight: isTileView ? 80 : 50
            
            delegate: Item {
                width: prefixGrid.cellWidth
                height: prefixGrid.cellHeight
                
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 4
                    radius: 8
                    color: prefixMouse.containsMouse ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.15) : "transparent"
                    border.width: prefixMouse.containsMouse ? 1 : 0
                    border.color: Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.3)
                    
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 6
                        spacing: 2
                        visible: isTileView
                        
                        Kirigami.Icon {
                            source: modelData.icon || "dialog-information"
                            Layout.preferredWidth: 24
                            Layout.preferredHeight: 24
                            Layout.alignment: Qt.AlignHCenter
                            color: queryHints.textColor
                        }
                        
                        Text {
                            text: modelData.prefix
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                            color: queryHints.textColor
                            font.bold: true
                            font.pixelSize: 10
                        }
                        
                        Text {
                            text: modelData.hint
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                            color: Qt.rgba(queryHints.textColor.r, queryHints.textColor.g, queryHints.textColor.b, 0.7)
                            font.pixelSize: 8
                            elide: Text.ElideRight
                        }
                    }
                    
                    // List Layout
                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 12
                        visible: !isTileView
                        
                        Kirigami.Icon {
                            source: modelData.icon || "dialog-information"
                            Layout.preferredWidth: 24
                            Layout.preferredHeight: 24
                            color: queryHints.textColor
                        }
                        
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            
                            Text {
                                text: modelData.prefix + " — " + modelData.hint
                                color: queryHints.textColor
                                font.bold: true
                                font.pixelSize: 11
                            }
                            
                            Text {
                                text: modelData.desc || ""
                                color: Qt.rgba(queryHints.textColor.r, queryHints.textColor.g, queryHints.textColor.b, 0.6)
                                font.pixelSize: 9
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                                visible: text.length > 0
                            }
                        }
                    }
                    
                    MouseArea {
                        id: prefixMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            queryHints.hintSelected(modelData.prefix)
                        }
                    }
                }
            }
        }
    }
    
    // Original Single Hint Content Layout
    RowLayout {
        id: hintContent
        anchors.fill: parent
        anchors.margins: 6
        spacing: 8
        visible: !queryHints.currentHint.isPrefixMenu
        
        // Spacer Left
        Item { Layout.fillWidth: true; visible: !queryHints.currentHint.options }

        // Icon
        Kirigami.Icon {
            source: queryHints.currentHint.icon || "dialog-information"
            Layout.preferredWidth: 16
            Layout.preferredHeight: 16
            Layout.alignment: Qt.AlignVCenter
            color: queryHints.currentHint.isError 
                ? "#ff6666" 
                : queryHints.textColor
        }
        
        // Standard Text
        Text {
            visible: !queryHints.currentHint.options
            text: queryHints.currentHint.text || ""
            color: queryHints.currentHint.isError 
                ? "#ff6666" 
                : Qt.rgba(queryHints.textColor.r, queryHints.textColor.g, queryHints.textColor.b, 0.8)
            font.pixelSize: 11
            Layout.alignment: Qt.AlignVCenter
            elide: Text.ElideRight
        }
        
        // Spacer Right
        Item { Layout.fillWidth: true; visible: !queryHints.currentHint.options }
        
        // Result Limit Controls (Sub-options for timeline etc)
        RowLayout {
            visible: !!queryHints.currentHint.options
            spacing: 6
            Layout.fillWidth: true
            
            Repeater {
                model: queryHints.currentHint.options || []
                
                Button {
                    text: modelData.displayLabel || modelData.label
                    Layout.preferredHeight: 22
                    font.pixelSize: 11
                    flat: false
                    
                    background: Rectangle {
                        color: parent.down ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.4) : (parent.hovered ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.2) : "transparent")
                        radius: 4
                        border.width: 1
                        border.color: Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.3)
                    }
                    
                    contentItem: Text {
                        text: parent.text
                        color: queryHints.textColor
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    
                    onClicked: {
                        hintSelected(modelData.value)
                    }
                }
            }
            
            Item { Layout.fillWidth: true } // Spacer
        }
    }
}
