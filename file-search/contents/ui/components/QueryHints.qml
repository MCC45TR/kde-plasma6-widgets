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
            hint: i18nd("plasma_applet_com.mcc45tr.filesearch", "Timeline View"), 
            icon: "view-calendar",
            options: [
                { label: i18nd("plasma_applet_com.mcc45tr.filesearch", "Calendar"), value: "timeline:/calendar/" },
                { label: i18nd("plasma_applet_com.mcc45tr.filesearch", "Today"), value: "timeline:/today" },
                { label: i18nd("plasma_applet_com.mcc45tr.filesearch", "Yesterday"), value: "timeline:/yesterday" },
                { label: i18nd("plasma_applet_com.mcc45tr.filesearch", "This Week"), value: "timeline:/thisweek" },
                { label: i18nd("plasma_applet_com.mcc45tr.filesearch", "This Month"), value: "timeline:/thismonth" }
            ]
        },
        // Specific timeline shortcuts (still needed for direct hits)
        { prefix: "timeline:/today", hint: i18nd("plasma_applet_com.mcc45tr.filesearch", "Files modified today"), icon: "view-calendar-day" },
        { prefix: "timeline:/yesterday", hint: i18nd("plasma_applet_com.mcc45tr.filesearch", "Files modified yesterday"), icon: "view-calendar-day" },
        { prefix: "timeline:/thisweek", hint: i18nd("plasma_applet_com.mcc45tr.filesearch", "Files modified this week"), icon: "view-calendar-week" },
        { prefix: "timeline:/thismonth", hint: i18nd("plasma_applet_com.mcc45tr.filesearch", "Files modified this month"), icon: "view-calendar-month" },
        
        { prefix: "file:/", hint: i18nd("plasma_applet_com.mcc45tr.filesearch", "File Path Search"), icon: "folder", localeBase: "file" },
        { prefix: "man:/", hint: i18nd("plasma_applet_com.mcc45tr.filesearch", "Man Pages"), icon: "help-contents", localeBase: "man" },
        { prefix: "gg:", hint: i18nd("plasma_applet_com.mcc45tr.filesearch", "Search on Google"), icon: "google", localeBase: "google" },
        { prefix: "dd:", hint: i18nd("plasma_applet_com.mcc45tr.filesearch", "Search on DuckDuckGo"), icon: "internet-web-browser", localeBase: "ddg" },
        { prefix: "wp:", hint: i18nd("plasma_applet_com.mcc45tr.filesearch", "Search on Wikipedia"), icon: "wikipedia", localeBase: "wikipedia" },
        { prefix: "kill ", hint: i18nd("plasma_applet_com.mcc45tr.filesearch", "Terminate processes"), icon: "process-stop", localeBase: "kill" },
        { prefix: "spell ", hint: i18nd("plasma_applet_com.mcc45tr.filesearch", "Check spelling"), icon: "tools-check-spelling", localeBase: "spell" },
        { prefix: "#", hint: i18nd("plasma_applet_com.mcc45tr.filesearch", "Unicode Characters"), icon: "character-set", localeBase: "unicode" },
        { prefix: "app:", hint: i18nd("plasma_applet_com.mcc45tr.filesearch", "Applications"), icon: "applications-all", localeBase: "app" },
        { prefix: "shell:", hint: i18nd("plasma_applet_com.mcc45tr.filesearch", "Shell Commands"), icon: "utilities-terminal", localeBase: "shell" },
        { prefix: "b:", hint: i18nd("plasma_applet_com.mcc45tr.filesearch", "Bookmarks"), icon: "bookmarks", localeBase: "bookmarks" },
        { prefix: "power:", hint: i18nd("plasma_applet_com.mcc45tr.filesearch", "Show power management options"), icon: "system-shutdown", localeBase: "power" },
        { prefix: "services:", hint: i18nd("plasma_applet_com.mcc45tr.filesearch", "System Services"), icon: "preferences-system", localeBase: "services" },
        { prefix: "date", hint: i18nd("plasma_applet_com.mcc45tr.filesearch", "Show calendar and date information"), icon: "alarm-clock", localeBase: "date" },
        { prefix: "define:", hint: i18nd("plasma_applet_com.mcc45tr.filesearch", "Dictionary Definition"), icon: "accessories-dictionary", localeBase: "define" },
        { prefix: "unit:", hint: i18nd("plasma_applet_com.mcc45tr.filesearch", "Convert units (requires KRunner)"), icon: "accessories-calculator", localeBase: "unit" },
        { prefix: "help:", hint: i18nd("plasma_applet_com.mcc45tr.filesearch", "Show this help screen"), icon: "help-about", localeBase: "help" }
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
            return { show: false, text: "", icon: "", isError: false }
        }
        
        var lowerQuery = query.toLowerCase()
        
        // 1. Check for known prefixes (both English keys and Localized keys)
        var bestMatch = null;
        var bestLen = -1;
        var matchedPrefix = ""; 
        
        for (var i = 0; i < knownPrefixes.length; i++) {
             var p = knownPrefixes[i]
             
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
    
    // Content Layout
    RowLayout {
        id: hintContent
        anchors.fill: parent
        anchors.margins: 6
        spacing: 8
        
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
        
        // Result Limit Controls
        RowLayout {
            visible: !!queryHints.currentHint.options
            spacing: 6
            Layout.fillWidth: true
            
            Repeater {
                model: queryHints.currentHint.options || []
                
                Button {
                    // Use displayLabel if available (for days), otherwise label
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
