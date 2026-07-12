import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import "../js/PrefixRegistry.js" as PrefixRegistry

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
                { label: i18nd("plasma_applet_com.mcc45tr.filesearch", "Calendar"), value: "timeline:/calendar" },
                { label: i18nd("plasma_applet_com.mcc45tr.filesearch", "Today"), value: "timeline:/today" }
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
        { prefix: "weather:", hint: i18nd("plasma_applet_com.mcc45tr.filesearch", "Weather"), desc: i18nd("plasma_applet_com.mcc45tr.filesearch", "Show current weather"), icon: "weather-many-clouds", category: "Utility", localeBase: "weather" },
        { prefix: "calendar:", hint: i18nd("plasma_applet_com.mcc45tr.filesearch", "Calendar"), desc: i18nd("plasma_applet_com.mcc45tr.filesearch", "Show calendar"), icon: "view-calendar", category: "Utility", localeBase: "Calendar" },
        { prefix: "clock:", hint: i18nd("plasma_applet_com.mcc45tr.filesearch", "Clock"), desc: i18nd("plasma_applet_com.mcc45tr.filesearch", "Show large clock"), icon: "preferences-system-time", category: "Utility", localeBase: "clock" },
        { prefix: "date:", hint: i18nd("plasma_applet_com.mcc45tr.filesearch", "Date"), desc: i18nd("plasma_applet_com.mcc45tr.filesearch", "Show calendar and date information"), icon: "view-calendar-day", category: "Utility", localeBase: "date" },
        { prefix: "power:", hint: i18nd("plasma_applet_com.mcc45tr.filesearch", "Power"), desc: i18nd("plasma_applet_com.mcc45tr.filesearch", "Show power management options"), icon: "system-shutdown", category: "System", localeBase: "power" },
        { prefix: "define:", hint: i18nd("plasma_applet_com.mcc45tr.filesearch", "Define"), desc: i18nd("plasma_applet_com.mcc45tr.filesearch", "Check word definition"), icon: "accessories-dictionary", category: "Utility", localeBase: "define" },
        { prefix: "#", hint: i18nd("plasma_applet_com.mcc45tr.filesearch", "Unicode Characters"), desc: i18nd("plasma_applet_com.mcc45tr.filesearch", "Search unicode characters"), icon: "character-set", category: "Utility", localeBase: "unicode" },

        { prefix: "man:/", hint: i18nd("plasma_applet_com.mcc45tr.filesearch", "Man Pages"), desc: i18nd("plasma_applet_com.mcc45tr.filesearch", "Browse system manual pages"), icon: "help-contents", category: "Help", localeBase: "man" },
        { prefix: "help:", hint: i18nd("plasma_applet_com.mcc45tr.filesearch", "Help"), desc: i18nd("plasma_applet_com.mcc45tr.filesearch", "Show widget documentation"), icon: "help-about", category: "Help", localeBase: "help" }
    ]

    // Filtered list of known prefixes based on settings
    readonly property var activePrefixes: {
        var list = [];
        for (var i = 0; i < knownPrefixes.length; i++) {
            var p = knownPrefixes[i];
            if (p.prefix === ":") continue; // Skip trigger

            if (!PrefixRegistry.isEnabled(p.prefix, plasmoidConfig)) continue;

            list.push(p);
        }
        return list;
    }

    // Helper for date formatting
    property var currentLocale: Qt.locale()

    // ===== CACHED LOCALIZED PREFIX MAP (computed once at startup) =====
    // Avoids calling i18nd() inside detectHint() on every keystroke
    readonly property var _localizedPrefixMap: {
        var map = {};
        for (var i = 0; i < knownPrefixes.length; i++) {
            var p = knownPrefixes[i];
            if (p.localeBase) {
                var locKeyVal = i18nd("plasma_applet_com.mcc45tr.filesearch", p.localeBase);
                var suffix = "";
                if (p.prefix.endsWith(":")) suffix = ":";
                else if (p.prefix.endsWith(" ")) suffix = " ";
                else if (p.prefix.endsWith(":/")) suffix = ":/";
                map[p.prefix] = ((locKeyVal || p.localeBase) + suffix).toLowerCase();
            } else {
                map[p.prefix] = p.prefix.toLowerCase();
            }
        }
        return map;
    }
    readonly property var _registryLocalizedPrefixes: ({
        weather: i18nd("plasma_applet_com.mcc45tr.filesearch", "weather"),
        calendar: i18nd("plasma_applet_com.mcc45tr.filesearch", "Calendar"),
        date: i18nd("plasma_applet_com.mcc45tr.filesearch", "date"),
        clock: i18nd("plasma_applet_com.mcc45tr.filesearch", "clock"),
        power: i18nd("plasma_applet_com.mcc45tr.filesearch", "power"),
        help: i18nd("plasma_applet_com.mcc45tr.filesearch", "help"),
        unit: i18nd("plasma_applet_com.mcc45tr.filesearch", "unit"),
        shell: i18nd("plasma_applet_com.mcc45tr.filesearch", "shell"),
        define: i18nd("plasma_runner_krunner_dictionary", "define"),
        kill: i18nd("plasma_runner_kill", "kill"),
        spell: i18nd("plasma_runner_spellcheckrunner", "spell")
    })
    // Cached i18n strings used in detectHint error paths
    readonly property string _unknownPrefixText: i18nd("plasma_applet_com.mcc45tr.filesearch", "Unknown prefix")
    readonly property string _tryText: i18nd("plasma_applet_com.mcc45tr.filesearch", "try")
    readonly property string _locHelp: {
        var val = i18nd("plasma_applet_com.mcc45tr.filesearch", "help");
        return val ? val.toLowerCase() : "help";
    }
    readonly property string _searchPrefixesText: i18nd("plasma_applet_com.mcc45tr.filesearch", "Search Prefixes")
    readonly property string _browseCalendarText: i18nd("plasma_applet_com.mcc45tr.filesearch", "Browse calendar")
    readonly property string _manNotInstalledText: i18nd("plasma_applet_com.mcc45tr.filesearch", "Man pages not installed")

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

            var year = d.getFullYear().toString();
            var month = (d.getMonth() + 1).toString().padStart(2, "0");
            var val = "timeline:/calendar/" + year + "-" + month;

            options.push({
                label: monthName,
                value: val
            });
        }
        return options;
    }

    function getTimelineDayOptions(baseQuery) {
        var options = [];
        var monthMatch = baseQuery.match(/(\d{4})-(\d{2})$/);
        if (!monthMatch) return options;
        var year = Number(monthMatch[1]);
        var month = Number(monthMatch[2]);
        var daysInMonth = new Date(year, month, 0).getDate();
        var today = new Date();
        var normalizedBase = baseQuery.endsWith("/") ? baseQuery : baseQuery + "/";

        for (var day = daysInMonth; day >= 1; day--) {
            var d = new Date(year, month - 1, day);
            if (d > today) continue;
            var dayName = d.toLocaleDateString(currentLocale, "d MMMM yyyy dddd");
            var isoDate = year.toString() + "-" + month.toString().padStart(2, "0") + "-" + day.toString().padStart(2, "0");

            options.push({
                label: dayName,
                value: normalizedBase + isoDate
            });
        }
        return options;
    }

    function detectHint(query) {
        if (!query || query.length === 0) {
            return { show: false, text: "", icon: "", isError: false, isPrefixMenu: false, options: undefined }
        }

        // Full prefix menu trigger
        if (query === ":") {
            return {
                show: true,
                isPrefixMenu: true,
                text: _searchPrefixesText,
                icon: "help-about",
                isError: false
            }
        }

        var lowerQuery = query.toLowerCase()

        // 1. Check for known prefixes using cached locale map
        var bestMatch = null;
        var bestLen = -1;
        var matchedPrefix = "";

        for (var i = 0; i < activePrefixes.length; i++) {
             var p = activePrefixes[i]

             var aliases = PrefixRegistry.aliasesFor(p.prefix, _registryLocalizedPrefixes)
             // Prefixes that are only presentation metadata still use their
             // cached localized spelling.
             if (!PrefixRegistry.definitionFor(p.prefix)) {
                 aliases.push(p.prefix.toLowerCase())
                 aliases.push(_localizedPrefixMap[p.prefix] || "")
             }
             for (var a = 0; a < aliases.length; ++a) {
                 var candidate = aliases[a]
                 if (candidate && lowerQuery.startsWith(candidate) && candidate.length > bestLen) {
                     bestMatch = p
                     bestLen = candidate.length
                     matchedPrefix = candidate
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
                    options: bestMatch.options
                 }
             }

             // Check calendar sub-path
             if (lowerQuery === "timeline:/calendar") {
                  return {
                       show: true,
                       text: _browseCalendarText,
                       icon: "view-calendar-month",
                       isError: false,
                       prefix: matchedPrefix,
                       options: getTimelineMonthOptions()
                  }
             }

             if (/^timeline:\/calendar\/\d{4}-\d{2}$/.test(lowerQuery)) {
                       return {
                            show: true,
                            text: _browseCalendarText,
                            icon: "view-calendar-day",
                            isError: false,
                            prefix: query,
                            options: getTimelineDayOptions(query)
                       }
             }
        }

        if (bestMatch) {
             // Known prefix found

             // Check for Man page installation
             if (bestMatch.prefix === "man:/" && logic && logic.ensureManAvailability) {
                 logic.ensureManAvailability();
             }
             if (bestMatch.prefix === "man:/" && logic && logic.manCheckCompleted && !logic.manInstalled) {
                 return { show: true, text: _manNotInstalledText, icon: "dialog-error", isError: true, prefix: matchedPrefix }
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
                isPrefixMenu: false,
                prefix: matchedPrefix,
                options: bestMatch.options
             }
        }

        // Unknown prefix detection
        var prefixMatch = query.match(/^([A-Za-z][A-Za-z0-9+.-]{0,31}:)/)
        if (prefixMatch) {
            var potentialPrefix = prefixMatch[1].toLowerCase()

            var isKnown = false;
            for (var k = 0; k < activePrefixes.length; k++) {
                 var kp = activePrefixes[k];
                 var knownAliases = PrefixRegistry.aliasesFor(kp.prefix, _registryLocalizedPrefixes)
                 if (!PrefixRegistry.definitionFor(kp.prefix)) {
                     knownAliases.push(kp.prefix.toLowerCase())
                     knownAliases.push(_localizedPrefixMap[kp.prefix] || "")
                 }
                 for (var aliasIndex = 0; aliasIndex < knownAliases.length; ++aliasIndex) {
                     if (knownAliases[aliasIndex] && knownAliases[aliasIndex].startsWith(potentialPrefix)) {
                         isKnown = true
                         break
                     }
                 }
                 if (isKnown) break;
            }

            if (!isKnown && potentialPrefix !== "file:" && potentialPrefix !== "http:" && potentialPrefix !== "https:") {
                return {
                    show: true,
                    text: _unknownPrefixText + ": " + potentialPrefix + " — " + _tryText + ": " + _locHelp + ":",
                    icon: "dialog-warning",
                    isError: true,
                    isPrefixMenu: false,
                    options: undefined
                }
            }
        }

        return { show: false, text: "", icon: "", isError: false, isPrefixMenu: false, options: undefined }
    }

    // Read-only helper for view mode
    readonly property bool isTileView: plasmoidConfig ? (plasmoidConfig.viewMode === 1) : false

    height: visible ? (currentHint.isPrefixMenu ? Kirigami.Units.gridUnit * 2.4 : Math.max(Kirigami.Units.gridUnit * 2, hintContent.implicitHeight + Kirigami.Units.smallSpacing * 2)) : 0
    color: Qt.rgba(bgColor.r, bgColor.g, bgColor.b, 0.95)
    radius: 12
    border.width: currentHint.isError ? 0 : 1
    border.color: currentHint.isError
        ? Qt.rgba(1, 0.3, 0.3, 0.5)
        : Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.3)

    Kirigami.InlineMessage {
        anchors.fill: parent
        visible: queryHints.currentHint.isError && !queryHints.currentHint.isPrefixMenu
        type: Kirigami.MessageType.Warning
        text: queryHints.currentHint.text || ""
    }

    Behavior on height {
        NumberAnimation {
            duration: Kirigami.Units.shortDuration
            easing.type: Easing.OutCubic
        }
    }

    // Prefix strip
    ListView {
        id: prefixStrip
        anchors.fill: parent
        anchors.margins: Kirigami.Units.smallSpacing
        visible: queryHints.currentHint ? !!queryHints.currentHint.isPrefixMenu : false
        clip: true
        orientation: ListView.Horizontal
        spacing: Kirigami.Units.smallSpacing
        boundsBehavior: Flickable.StopAtBounds
        model: queryHints.activePrefixes

        delegate: Rectangle {
            width: Math.min(Math.max(prefixContent.implicitWidth + Kirigami.Units.largeSpacing * 2, Kirigami.Units.gridUnit * 4.5), Kirigami.Units.gridUnit * 9)
            height: prefixStrip.height
            radius: Kirigami.Units.cornerRadius
            color: prefixMouse.containsMouse ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.16) : "transparent"
            border.width: 1
            border.color: Qt.rgba(accentColor.r, accentColor.g, accentColor.b, prefixMouse.containsMouse ? 0.42 : 0.22)

            RowLayout {
                id: prefixContent
                anchors.fill: parent
                anchors.leftMargin: Kirigami.Units.smallSpacing
                anchors.rightMargin: Kirigami.Units.smallSpacing
                spacing: Kirigami.Units.smallSpacing

                Text {
                    text: modelData.hint
                    Layout.fillWidth: true
                    color: queryHints.textColor
                    font.family: Kirigami.Theme.smallFont.family
                    font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                    elide: Text.ElideRight
                    verticalAlignment: Text.AlignVCenter
                }
            }

            MouseArea {
                id: prefixMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: queryHints.hintSelected(modelData.prefix)
            }
        }
    }

    // Original Single Hint Content Layout
    RowLayout {
        id: hintContent
        anchors.fill: parent
        anchors.margins: 6
        spacing: 8
        visible: !queryHints.currentHint.isPrefixMenu && !queryHints.currentHint.isError

        // Spacer Left
        Item { Layout.fillWidth: true; visible: !queryHints.currentHint.options }

        // Icon
        Kirigami.Icon {
            source: queryHints.currentHint.icon || "dialog-information"
            Layout.preferredWidth: 16
            Layout.preferredHeight: 16
            Layout.alignment: Qt.AlignVCenter
            color: queryHints.currentHint.isError
                ? Kirigami.Theme.negativeTextColor
                : queryHints.textColor
        }

        // Standard Text
        Text {
            visible: !queryHints.currentHint.options
            text: queryHints.currentHint.text || ""
            color: queryHints.currentHint.isError
                ? Kirigami.Theme.negativeTextColor
                : Qt.rgba(queryHints.textColor.r, queryHints.textColor.g, queryHints.textColor.b, 0.8)
            font.family: Kirigami.Theme.smallFont.family
            font.pixelSize: Kirigami.Theme.smallFont.pixelSize
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

                PlasmaComponents.Button {
                    text: modelData.displayLabel || modelData.label
                    Layout.preferredHeight: 22
                    font.family: Kirigami.Theme.smallFont.family
                    font.pixelSize: Kirigami.Theme.smallFont.pixelSize
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
