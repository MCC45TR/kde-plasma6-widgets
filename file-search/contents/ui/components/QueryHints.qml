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
    required property var logic // Access to LogicController for dependency checks (manInstalled)
    
    // Signals
    signal hintSelected(string text)
    
    // Localization function
    property var trFunc: function(key) { return key }
    
    // Computed hint based on search text
    property var currentHint: detectHint(searchText)
    
    // Visibility - show when there's a relevant hint
    visible: currentHint.show && searchText.length > 0
    
    height: visible ? (hintContent.implicitHeight + 12) * 2 : 0
    color: Qt.rgba(bgColor.r, bgColor.g, bgColor.b, 0.8)
    radius: 6
    border.width: 1
    border.color: currentHint.isError 
        ? Qt.rgba(1, 0.3, 0.3, 0.5) 
        : Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.3)
    
    Behavior on height { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
    
    // KRunner supported prefixes
    readonly property var knownPrefixes: [
        { 
            prefix: "timeline:/", 
            hint: "hint_timeline", 
            icon: "view-calendar",
            options: [
                { label: "Calendar", labelKey: "btn_calendar", value: "timeline:/calendar/" },
                { label: "Today", labelKey: "btn_today", value: "timeline:/today" },
                { label: "Yesterday", labelKey: "btn_yesterday", value: "timeline:/yesterday" },
                { label: "This Week", labelKey: "btn_thisweek", value: "timeline:/thisweek" },
                { label: "This Month", labelKey: "btn_thismonth", value: "timeline:/thismonth" }
            ]
        },
        // Specific timeline shortcuts (still needed for direct hits)
        { prefix: "timeline:/today", hint: "hint_timeline_today", icon: "view-calendar-day" },
        { prefix: "timeline:/yesterday", hint: "hint_timeline_yesterday", icon: "view-calendar-day" },
        { prefix: "timeline:/thisweek", hint: "hint_timeline_week", icon: "view-calendar-week" },
        { prefix: "timeline:/thismonth", hint: "hint_timeline_month", icon: "view-calendar-month" },
        
        { prefix: "file:/", hint: "hint_file_path", icon: "folder" },
        { prefix: "man:/", hint: "hint_man_page", icon: "help-contents" },
        { prefix: "gg:", hint: "hint_google", icon: "google" },
        { prefix: "dd:", hint: "hint_duckduckgo", icon: "internet-web-browser" },
        { prefix: "wp:", hint: "hint_wikipedia", icon: "wikipedia" },
        { prefix: "kill ", hint: "hint_kill", icon: "process-stop" },
        { prefix: "spell ", hint: "hint_spell", icon: "tools-check-spelling" },
        { prefix: "#", hint: "hint_unicode", icon: "character-set" },
        { prefix: "app:", hint: "hint_applications", icon: "applications-all" },
        { prefix: "shell:", hint: "hint_shell", icon: "utilities-terminal" },
        { prefix: "b:", hint: "hint_bookmarks", icon: "bookmarks" },
        { prefix: "power:", hint: "hint_power", icon: "system-shutdown" },
        { prefix: "services:", hint: "hint_services", icon: "preferences-system" },
        { prefix: "date", hint: "hint_datetime", icon: "alarm-clock" },
        { prefix: "define:", hint: "hint_define", icon: "accessories-dictionary" },
        { prefix: "unit:", hint: "hint_unit", icon: "accessories-calculator" },
        { prefix: "help:", hint: "hint_help", icon: "help-about" }
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
                value: val, 
                labelKey: "" 
            });
        }
        return options;
    }
    
    function getTimelineDayOptions(baseQuery) {
        var options = [];
        var today = new Date();
        
        // We assume we are showing days for the "Current Month" context mostly,
        // or just generic recent days if we can't parse the month from baseQuery.
        // For simplicity, let's list the last 31 days with their localized names.
        // The path will be constructed as baseQuery + DayName.
        
        // If baseQuery doesn't end with /, add it
        if (!baseQuery.endsWith("/")) baseQuery += "/";
        
        for (var i = 0; i < 31; i++) {
            var d = new Date();
            d.setDate(today.getDate() - i);
            
            // Format: "14 Ocak 2026 Çarşamba" to match folder structure
            var dayName = d.toLocaleDateString(currentLocale, "d MMMM yyyy dddd");
            
            var val = baseQuery + dayName;
            
            var label = "";
            var labelKey = "";
            
            if (i === 0) {
                label = ""; 
                labelKey = "btn_today";
            } else if (i === 1) {
                label = ""; 
                labelKey = "btn_yesterday";
            } else if (i === 2) {
                label = ""; 
                labelKey = "btn_two_days_ago";
            } else {
                label = dayName;
            }
            
            // For special labels, we still want the full dayName in the tooltip or hint?
            // The Button will show the label/key.
            // The Value is what matters for the search.
            
            // Special handling: The "value" must be correct. 
            // If the user's KIO uses "Bugün" as a folder name, we should use that?
            // Screenshot #2 showed folders "Bugün", "Dün", "İki gün önce".
            // So for i=0, 1, 2, the actual folder name MIGHT be the localized relative string.
            
            if (i === 0) val = baseQuery + (trFunc("btn_today") || "Today");
            else if (i === 1) val = baseQuery + (trFunc("btn_yesterday") || "Yesterday");
            else if (i === 2) val = baseQuery + (trFunc("btn_two_days_ago") || "Two days ago");
             
            options.push({ 
                label: label, 
                value: val, 
                labelKey: labelKey 
            });
        }
        return options;
    }
    
    function detectHint(query) {
        if (!query || query.length === 0) {
            return { show: false, text: "", icon: "", isError: false }
        }
        
        var lowerQuery = query.toLowerCase()
        
        // 1. timeline:/calendar/ -> Show Months
        if (lowerQuery === "timeline:/calendar/" || lowerQuery === "timeline:/calendar") {
             return {
                show: true,
                text: trFunc("hint_timeline_calendar"),
                icon: "view-calendar-month",
                isError: false,
                prefix: "timeline:/calendar/",
                options: getTimelineMonthOptions()
             }
        }
        
        // 2. timeline:/calendar/<Month>/ -> Show Days
        // Check if it starts with timeline:/calendar/ and has more text
        if (lowerQuery.startsWith("timeline:/calendar/")) {
            // Check if we are "inside" a month (e.g. not just exact match)
            // But we must assume the user picked a month or typed it.
            // We'll show day options for ANY sub-path of calendar/
            
            // Avoid showing options if we already typed a day?
            // We can rough check by length or slash count.
            // timeline:/calendar/January 2026/ -> 3 slashes.
            // If query has 3 slashes and ends with /, show days.
            var slashes = (query.match(/\//g) || []).length;
            if (slashes >= 3) { 
                 return {
                    show: true,
                    text: trFunc("hint_timeline_calendar"),
                    icon: "view-calendar-day",
                    isError: false,
                    prefix: query,
                    options: getTimelineDayOptions(query)
                 }
            }
        }
        
        // Check for known prefixes
        var bestMatch = null;
        var bestLen = -1;
        
        for (var i = 0; i < knownPrefixes.length; i++) {
             var p = knownPrefixes[i]
             if (lowerQuery.startsWith(p.prefix.toLowerCase())) {
                 if (p.prefix.length > bestLen) {
                     bestMatch = p;
                     bestLen = p.prefix.length;
                 }
             }
        }
        
        if (bestMatch) {
             // Handle timeline:/ options logic (show options only if exact match)
             if (bestMatch.options && lowerQuery !== bestMatch.prefix.toLowerCase() && lowerQuery !== bestMatch.prefix.toLowerCase().replace("/", "")) {
                  // If we typed more (e.g. timeline:/to...), don't show generic options
                  // Unless it's just the prefix
                  // We already handled exact logic inside 'options' property? No.
                  // Just don't pass options if we typed past it.
                  
                  // Wait, "timeline:/calendar/" logic above handles its own options.
                  // Here we handle "timeline:/"
                  
                  return {
                    show: true,
                    text: trFunc(bestMatch.hint) || bestMatch.hint,
                    icon: bestMatch.icon,
                    isError: false,
                    prefix: bestMatch.prefix,
                    // Hide options if we are continuing typing specific things
                    options: undefined 
                 }
             }
        
             if (bestMatch.prefix === "man:/" && logic && !logic.manInstalled) {
                 return { show: true, text: trFunc("man_not_installed"), icon: "dialog-error", isError: true, prefix: bestMatch.prefix }
             }
             var baseHint = trFunc(bestMatch.hint) || bestMatch.hint;
             var queryPart = "";

             // Check if user has typed something after the prefix
             if (query.length > bestMatch.prefix.length) {
                 var rawQuery = query.substring(bestMatch.prefix.length).trim();
                 if (rawQuery.length > 0) {
                     queryPart = ' "' + rawQuery + '"';
                 }
             }

             // If queryPart exists, append it to baseHint? 
             // "Google Search" + " \"x.com\"" -> "Google Search \"x.com\""
             // Or better: localized "Search Google for..."
             
             // For now, let's just append it if present for specific searchable types
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
                prefix: bestMatch.prefix,
                options: bestMatch.options
             }
        }
        
        // Partial matches
        for (var j = 0; j < knownPrefixes.length; j++) {
            var pf = knownPrefixes[j]
            if (pf.prefix.toLowerCase().startsWith(lowerQuery) && query.length >= 2) {
                return {
                    show: true,
                    text: trFunc("hint_try") + ": " + pf.prefix,
                    icon: "hint",
                    isError: false,
                    isSuggestion: true
                }
            }
        }
        
        // Unknown prefix
        var colonIndex = query.indexOf(":")
        if (colonIndex > 0 && colonIndex < 10) {
            var potentialPrefix = query.substring(0, colonIndex + 1).toLowerCase()
            var isKnown = knownPrefixes.some(function(p) { return p.prefix.toLowerCase().startsWith(potentialPrefix) })
            
            if (!isKnown && potentialPrefix !== "file:" && potentialPrefix !== "http:" && potentialPrefix !== "https:") {
                return {
                    show: true,
                    text: trFunc("hint_unknown_prefix") + ": " + potentialPrefix,
                    icon: "dialog-warning",
                    isError: true
                }
            }
        }
        
        return { show: false, text: "", icon: "", isError: false }
    }
    
    // Content Layout
    RowLayout {
        id: hintContent
        anchors.fill: parent
        anchors.margins: 6
        spacing: 8
        
        // Spacer Left (Only for Text mode - Center alignment)
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
        
        // Standard Text (Hide if options available)
        Text {
            visible: !queryHints.currentHint.options
            text: queryHints.currentHint.text || ""
            color: queryHints.currentHint.isError 
                ? "#ff6666" 
                : Qt.rgba(queryHints.textColor.r, queryHints.textColor.g, queryHints.textColor.b, 0.8)
            font.pixelSize: 11
            // Removed Layout.fillWidth: true to allow centering with spacers
            // Layout.fillWidth: true 
            Layout.alignment: Qt.AlignVCenter
            elide: Text.ElideRight
        }
        
        // Spacer Right (Only for Text mode - Center alignment)
        Item { Layout.fillWidth: true; visible: !queryHints.currentHint.options }
        
        // Result Limit Controls (Specific for this user request - buttons)
        RowLayout {
            visible: !!queryHints.currentHint.options
            spacing: 6
            Layout.fillWidth: true
            
            Repeater {
                model: queryHints.currentHint.options || []
                
                Button {
                    text: trFunc(modelData.labelKey) || modelData.label
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
