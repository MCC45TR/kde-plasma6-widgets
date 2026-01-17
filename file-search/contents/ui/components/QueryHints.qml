import QtQuick
import QtQuick.Layouts
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
        { prefix: "timeline:/today", hint: "hint_timeline_today", icon: "view-calendar-day" },
        { prefix: "timeline:/yesterday", hint: "hint_timeline_yesterday", icon: "view-calendar-day" },
        { prefix: "timeline:/thisweek", hint: "hint_timeline_week", icon: "view-calendar-week" },
        { prefix: "timeline:/thismonth", hint: "hint_timeline_month", icon: "view-calendar-month" },
        { prefix: "timeline:/", hint: "hint_timeline", icon: "view-calendar" },
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
    
    function detectHint(query) {
        if (!query || query.length === 0) {
            return { show: false, text: "", icon: "", isError: false }
        }
        
        var lowerQuery = query.toLowerCase()
        
        // Check for known prefixes
        for (var i = 0; i < knownPrefixes.length; i++) {
            var p = knownPrefixes[i]
            if (lowerQuery.startsWith(p.prefix.toLowerCase())) {
                
                // Special check for man pages availability
                if (p.prefix === "man:/" && logic && !logic.manInstalled) {
                     return {
                        show: true,
                        text: trFunc("man_not_installed"),
                        icon: "dialog-error",
                        isError: true,
                        prefix: p.prefix
                     }
                }

                return {
                    show: true,
                    text: trFunc(p.hint) || p.hint,
                    icon: p.icon,
                    isError: false,
                    prefix: p.prefix
                }
            }
        }
        
        // Check for partial prefix match (autocomplete suggestion)
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
        
        // Check for unknown prefix pattern (word:something)
        var colonIndex = query.indexOf(":")
        if (colonIndex > 0 && colonIndex < 10) {
            var potentialPrefix = query.substring(0, colonIndex + 1).toLowerCase()
            var isKnown = knownPrefixes.some(function(p) {
                return p.prefix.toLowerCase().startsWith(potentialPrefix)
            })
            
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
    
    RowLayout {
        id: hintContent
        anchors.fill: parent
        anchors.margins: 6
        spacing: 8
        
        Kirigami.Icon {
            source: queryHints.currentHint.icon || "dialog-information"
            Layout.preferredWidth: 16
            Layout.preferredHeight: 16
            Layout.alignment: Qt.AlignVCenter
            color: queryHints.currentHint.isError 
                ? "#ff6666" 
                : queryHints.textColor
        }
        
        Text {
            text: queryHints.currentHint.text || ""
            color: queryHints.currentHint.isError 
                ? "#ff6666" 
                : Qt.rgba(queryHints.textColor.r, queryHints.textColor.g, queryHints.textColor.b, 0.8)
            font.pixelSize: 11
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            elide: Text.ElideRight
        }
    }
}
