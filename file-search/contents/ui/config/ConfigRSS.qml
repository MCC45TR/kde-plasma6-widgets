import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import QtCore
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasma5support as Plasma5Support
import "../js/RSSManager.js" as RSSManager

Item {
    id: configRSS
    
    // Properties matching main.xml
    property bool cfg_rssEnabled
    property bool cfg_rssEnabledDefault: true
    property string cfg_rssSources
    property string cfg_rssSourcesDefault: "[]"
    property int cfg_rssMaxEntries
    property int cfg_rssMaxEntriesDefault: 10
    property int cfg_rssSyncInterval
    property int cfg_rssSyncIntervalDefault: 60
    property string cfg_rssCache: ""
    property string cfg_rssCacheDefault: ""
    property string cfg_rssLastSyncAll: ""
    property string cfg_rssLastSyncAllDefault: ""
    property int cfg_smartResultLimit: 0
    property int cfg_smartResultLimitDefault: 0
    
    property bool cfg_rssPlaceholderCycling: true
    property bool cfg_rssPlaceholderCyclingDefault: true
    
    // Dummy properties to satisfy Plasma's automatic config injection
    property string title: ""
    property int cfg_displayMode: 0
    property int cfg_displayModeDefault: 0
    property int cfg_panelRadius: 0
    property int cfg_panelRadiusDefault: 0
    property int cfg_panelHeight: 0
    property int cfg_panelHeightDefault: 0
    property int cfg_viewMode: 0
    property int cfg_viewModeDefault: 0
    property int cfg_iconSize: 0
    property int cfg_iconSizeDefault: 0
    property int cfg_listIconSize: 0
    property int cfg_listIconSizeDefault: 0
    property int cfg_minResults: 0
    property int cfg_minResultsDefault: 0
    property int cfg_maxResults: 0
    property int cfg_maxResultsDefault: 0
    property bool cfg_showPinnedBar: true
    property bool cfg_showPinnedBarDefault: true
    property bool cfg_autoMinimizePinned: false
    property bool cfg_autoMinimizePinnedDefault: false
    property int cfg_compactPinnedView: 0
    property int cfg_compactPinnedViewDefault: 0
    property int cfg_filterChipStyle: 0
    property int cfg_filterChipStyleDefault: 0
    property int cfg_scrollBarStyle: 0
    property int cfg_scrollBarStyleDefault: 0
    property bool cfg_previewEnabled: true
    property bool cfg_previewEnabledDefault: true
    property string cfg_previewSettings: ""
    property string cfg_previewSettingsDefault: ""
    property bool cfg_prefixDateShowClock: true
    property bool cfg_prefixDateShowClockDefault: true
    property bool cfg_prefixDateShowEvents: true
    property bool cfg_prefixDateShowEventsDefault: true
    property bool cfg_weatherEnabled: true
    property bool cfg_weatherEnabledDefault: true
    property bool cfg_weatherUseSystemUnits: true
    property bool cfg_weatherUseSystemUnitsDefault: true
    property int cfg_weatherRefreshInterval: 0
    property int cfg_weatherRefreshIntervalDefault: 0
    property bool cfg_prefixPowerShowHibernate: false
    property bool cfg_prefixPowerShowHibernateDefault: false
    property bool cfg_prefixPowerShowSleep: true
    property bool cfg_prefixPowerShowSleepDefault: true
    property bool cfg_showBootOptions: false
    property bool cfg_showBootOptionsDefault: false
    property int cfg_searchAlgorithm: 0
    property int cfg_searchAlgorithmDefault: 0
    property string cfg_searchHistory: ""
    property string cfg_searchHistoryDefault: ""
    property string cfg_cachedBootEntries: ""
    property string cfg_cachedBootEntriesDefault: ""
    property string cfg_pinnedItems: ""
    property string cfg_pinnedItemsDefault: ""
    property string cfg_categorySettings: ""
    property string cfg_categorySettingsDefault: ""
    property bool cfg_debugOverlay: false
    property bool cfg_debugOverlayDefault: false
    property string cfg_telemetryData: ""
    property string cfg_telemetryDataDefault: ""
    property bool cfg_showSearchButton: true
    property bool cfg_showSearchButtonDefault: true
    property bool cfg_showSearchButtonBackground: true
    property bool cfg_showSearchButtonBackgroundDefault: true
    property string cfg_weatherCache: ""
    property string cfg_weatherCacheDefault: ""
    property string cfg_weatherLastUpdate: ""
    property string cfg_weatherLastUpdateDefault: ""
    property string cfg_weatherUnits: ""
    property string cfg_weatherUnitsDefault: ""
    property int cfg_userProfile: 0
    property int cfg_userProfileDefault: 0

    Plasma5Support.DataSource {
        id: executable
        engine: "executable"
        connectedSources: []
    }

    // Internal state
    property var rssSources: []
    property var testLogs: ({}) // { index: [{msg: string, status: string}] }
    property var testResults: ({}) // Still needed for final state
    
    Timer {
        id: clearLogsTimer
        interval: 3000
        repeat: false
        property int indexToClear: -1
        onTriggered: {
            if (indexToClear !== -1) {
                clearLogs(indexToClear)
                testResults[indexToClear] = ""
                testResults = JSON.parse(JSON.stringify(testResults))
                indexToClear = -1
            }
        }
    }
    
    readonly property var presetSources: {
        var lang = Qt.locale().name.substring(0, 2);
        var presets = [];
        
        presets.push({ section: i18nd("plasma_applet_com.mcc45tr.filesearch", "Arch & Linux News"), items: [
            { name: "Arch News", url: "https://archlinux.org/feeds/news/" },
            { name: "AUR News", url: "https://aur.archlinux.org/RSS/" }, 
            { name: "Phoronix", url: "https://www.phoronix.com/rss.php" },
            { name: "OMGUbuntu", url: "https://feeds.feedburner.com/d0od" },
            { name: "It's FOSS", url: "https://itsfoss.com/feed/" },
            { name: "9to5Linux", url: "https://9to5linux.com/feed" },
            { name: "GamingOnLinux", url: "https://www.gamingonlinux.com/headlines.rss" }
        ]});

        presets.push({ section: i18nd("plasma_applet_com.mcc45tr.filesearch", "Security Bulletins"), items: [
            { name: "TheHackerNews", url: "https://feeds.feedburner.com/TheHackersNews" },
            { name: "BleepingComp", url: "https://www.bleepingcomputer.com/feed/" },
            { name: "CISA Alerts", url: "https://www.cisa.gov/cybersecurity-advisories/feed" },
            { name: "Dark Reading", url: "https://www.darkreading.com/rss.xml" },
            { name: "KrebsSecurity", url: "https://krebsonsecurity.com/feed/" }
        ]});

        if (lang === "tr") {
            presets.push({ section: i18nd("plasma_applet_com.mcc45tr.filesearch", "Turkey TV"), items: [
                { name: "NTV", url: "https://www.ntv.com.tr/son-dakika.rss" },
                { name: "Habertürk", url: "https://www.haberturk.com.tr/rss" },
                { name: "CNN Türk", url: "https://www.cnnturk.com/feed/rss/all/news" },
                { name: "TeknoSeyir", url: "https://teknoseyir.com/feed" }
            ]});
        } else {
            presets.push({ section: i18nd("plasma_applet_com.mcc45tr.filesearch", "World TV"), items: [
                { name: "BBC News", url: "http://feeds.bbci.co.uk/news/rss.xml" },
                { name: "CNN", url: "http://rss.cnn.com/rss/edition.rss" },
                { name: "Reuters", url: "https://www.reuters.com/arc/outboundfeeds/rss/?outputType=xml" },
                { name: "Al Jazeera", url: "https://www.aljazeera.com/xml/rss/all.xml" }
            ]});
        }
        return presets
    }
    
    function isPresetSelected(url) {
        for (var i = 0; i < rssSources.length; i++) {
            if (rssSources[i].url === url) return true
        }
        return false
    }

    function addPreset(item) {
        for (var i = 0; i < rssSources.length; i++) {
            if (rssSources[i].url === item.url) {
                removeSource(i)
                return
            }
        }
        if (rssSources.length >= 5) return
        rssSources.push({ 
            url: item.url, 
            name: item.name, 
            lastSync: 0,
            maxEntries: cfg_rssMaxEntries || 10, 
            syncInterval: cfg_rssSyncInterval || 60 
        })
        rssSources = JSON.parse(JSON.stringify(rssSources))
        saveSources()
    }
    
    function moveSource(index, delta) {
        var newIndex = index + delta
        if (newIndex < 0 || newIndex >= rssSources.length) return
        var item = rssSources.splice(index, 1)[0]
        rssSources.splice(newIndex, 0, item)
        rssSources = JSON.parse(JSON.stringify(rssSources))
        saveSources()
    }
    
    function addSource() {
        if (rssSources.length >= 5) return
        rssSources.push({ 
            url: "", 
            name: i18nd("plasma_applet_com.mcc45tr.filesearch", "New Source"), 
            lastSync: 0,
            maxEntries: cfg_rssMaxEntries || 10,
            syncInterval: cfg_rssSyncInterval || 60
        })
        rssSources = JSON.parse(JSON.stringify(rssSources)) 
        saveSources()
    }
    
    Component.onCompleted: {
        try {
            rssSources = JSON.parse(cfg_rssSources || "[]")
        } catch (e) {
            rssSources = []
        }
    }
    
    function saveSources() {
        cfg_rssSources = JSON.stringify(rssSources)
    }
    
    function removeSource(index) {
        rssSources.splice(index, 1)
        rssSources = JSON.parse(JSON.stringify(rssSources)) 
        saveSources()
    }
    
    function updateSource(index, key, value) {
        if (rssSources[index]) {
            rssSources[index][key] = value
            rssSources = JSON.parse(JSON.stringify(rssSources)) 
            saveSources()
        }
    }    function addLog(index, msg, status) {
        var logs = testLogs[index] || []
        logs.push({msg: msg, status: status})
        testLogs[index] = logs
        testLogs = JSON.parse(JSON.stringify(testLogs))
    }

    function clearLogs(index) {
        var logs = testLogs
        delete logs[index]
        testLogs = JSON.parse(JSON.stringify(logs))
    }

    function testSource(url, index) {
        if (!url || url.indexOf("http") !== 0) {
            addLog(index, "Invalid URL", "fail")
            return
        }
        
        testResults[index] = "testing"
        testLogs[index] = []
        addLog(index, "Network Check...", "testing")
        
        var xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    addLog(index, "Network Check: OK", "ok")
                    
                    Qt.callLater(function() {
                        addLog(index, "XML Format Check...", "testing")
                        var rawText = xhr.responseText.trim().toLowerCase()
                        var isXml = rawText.indexOf("<?xml") !== -1 || rawText.indexOf("<rss") !== -1 || rawText.indexOf("<feed") !== -1
                        
                        if (!isXml) {
                            addLog(index, "XML Format: FAIL", "fail")
                            testResults[index] = "invalid"
                            return
                        }
                        addLog(index, "XML Format: OK", "ok")
                        
                        Qt.callLater(function() {
                            addLog(index, "Parsing Entries...", "testing")
                            var entries = RSSManager.parseRSS(xhr.responseText, rssSources[index].name)
                            
                            if (entries.length > 0) {
                                addLog(index, "Parsing: OK (" + entries.length + " items)", "ok")
                                
                                Qt.callLater(function() {
                                    addLog(index, "Saving to Cache...", "testing")
                                    var base = StandardPaths.writableLocation(StandardPaths.CacheLocation) + "/plasma-file-search-rss"
                                    var path = RSSManager.getSourceFilePath(url, base)
                                    var json = JSON.stringify(entries)
                                    var base64Json = Qt.btoa(unescape(encodeURIComponent(json)))
                                    
                                    executable.connectSource("mkdir -p '" + base + "' && (echo '" + base64Json + "' > '" + path + "')")
                                    
                                    addLog(index, "Persistence: OK", "ok")
                                    testResults[index] = "success"
                                    updateSource(index, "lastSync", new Date().getTime())
                                    if (logic && logic.updateCombinedCache) logic.updateCombinedCache()
                                    
                                    // Auto-clear logs after success
                                    clearLogsTimer.indexToClear = index
                                    clearLogsTimer.restart()
                                })
                            } else {
                                addLog(index, "Parsing: FAIL", "fail")
                                testResults[index] = "sync_failed"
                            }
                        })
                    })
                } else {
                    addLog(index, "Network Check: FAIL (HTTP " + xhr.status + ")", "fail")
                    testResults[index] = "error"
                    testResults = JSON.parse(JSON.stringify(testResults))
                }
            }
        }
        xhr.open("GET", url);
        xhr.send();
    }

    Kirigami.ScrollablePage {
        anchors.fill: parent
        
        ColumnLayout {
            spacing: Kirigami.Units.gridUnit
            Layout.fillWidth: true

            QQC2.CheckBox {
                Kirigami.FormData.label: i18nd("plasma_applet_com.mcc45tr.filesearch", "Enable RSS")
                text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Show RSS feed updates in search results")
                checked: cfg_rssEnabled
                onToggled: cfg_rssEnabled = checked
                Layout.leftMargin: Kirigami.Units.gridUnit
            }
            
            Kirigami.Separator { 
                Kirigami.FormData.isSection: true
                Kirigami.FormData.label: i18nd("plasma_applet_com.mcc45tr.filesearch", "Popular Presets") 
                Layout.fillWidth: true
            }
            
            Repeater {
                model: presetSources
                delegate: Kirigami.AbstractCard {
                    Layout.fillWidth: true
                    contentItem: ColumnLayout {
                        QQC2.Label { 
                            text: modelData.section
                            font.bold: true
                            color: Kirigami.Theme.highlightColor
                        }
                        Flow {
                            spacing: 8
                            Layout.fillWidth: true
                            Repeater {
                                model: modelData.items
                                delegate: QQC2.Button {
                                    id: presetBtn
                                    property bool isSelected: isPresetSelected(modelData.url)
                                    text: modelData.name
                                    icon.name: isSelected ? "checkmark" : "list-add"
                                    enabled: (isSelected || rssSources.length < 5)
                                    checkable: true
                                    checked: isSelected
                                    onClicked: {
                                        checked = isSelected // Preserve state until added/removed
                                        addPreset(modelData)
                                    }
                                    
                                    QQC2.ToolTip.visible: hovered
                                    QQC2.ToolTip.text: modelData.url
                                }
                            }
                        }
                    }
                }
            }

            Kirigami.Separator { 
                Kirigami.FormData.isSection: true
                Kirigami.FormData.label: i18nd("plasma_applet_com.mcc45tr.filesearch", "RSS Sources (Max 5)") 
                Layout.fillWidth: true
            }
            
            Repeater {
                model: rssSources
                delegate: Kirigami.AbstractCard {
                    Layout.fillWidth: true
                    contentItem: ColumnLayout {
                        spacing: 8
                        RowLayout {
                            Layout.fillWidth: true
                            ColumnLayout {
                                spacing: 2
                                QQC2.Button {
                                    icon.name: "arrow-up"
                                    onClicked: moveSource(index, -1)
                                    enabled: index > 0
                                    flat: true
                                    implicitWidth: 32
                                    implicitHeight: 24
                                }
                                QQC2.Button {
                                    icon.name: "arrow-down"
                                    onClicked: moveSource(index, 1)
                                    enabled: index < rssSources.length - 1
                                    flat: true
                                    implicitWidth: 32
                                    implicitHeight: 24
                                }
                            }

                            QQC2.TextField {
                                placeholderText: i18nd("plasma_applet_com.mcc45tr.filesearch", "Name")
                                text: modelData.name
                                onTextChanged: if (focus) updateSource(index, "name", text)
                                Layout.preferredWidth: 100
                            }
                            QQC2.TextField {
                                placeholderText: i18nd("plasma_applet_com.mcc45tr.filesearch", "URL")
                                text: modelData.url
                                onTextChanged: if (focus) updateSource(index, "url", text)
                                Layout.fillWidth: true
                            }
                            QQC2.Button {
                                icon.name: "network-connect"
                                onClicked: testSource(modelData.url, index)
                                flat: true
                            }
                            QQC2.Button {
                                icon.name: "list-remove"
                                onClicked: removeSource(index)
                                flat: true
                            }
                        }
                        
                        RowLayout {
                            Layout.fillWidth: true
                            QQC2.Label { text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Entries:") }
                            QQC2.SpinBox {
                                from: 1; to: 50
                                value: modelData.maxEntries || (cfg_rssMaxEntries || 10)
                                onValueModified: updateSource(index, "maxEntries", value)
                            }
                            // General Settings
            Kirigami.FormLayout {
                Layout.fillWidth: true
                
                QQC2.CheckBox {
                    Kirigami.FormData.label: i18nd("plasma_applet_com.mcc45tr.filesearch", "Haber Özellikleri:")
                    text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Önizlemede RSS başlıkları")
                    checked: cfg_rssPlaceholderCycling
                    onCheckedChanged: cfg_rssPlaceholderCycling = checked
                }

                QQC2.SpinBox {
                    Kirigami.FormData.label: i18nd("plasma_applet_com.mcc45tr.filesearch", "Maksimum Haber (Kaynak Başlı):")
                    from: 5
                    to: 50
                    value: cfg_rssMaxEntries
                    onValueModified: cfg_rssMaxEntries = value
                }
            }

            Kirigami.Separator { Layout.fillWidth: true }
                            QQC2.Label { text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Interval:") }
                            QQC2.Button {
                                property int currentVal: modelData.syncInterval || (cfg_rssSyncInterval || 60)
                                text: currentVal >= 60 ? i18n("%1h", Math.floor(currentVal/60)) : i18n("%1m", currentVal)
                                onClicked: intervalMenu.open()
                                flat: true
                                QQC2.Menu {
                                    id: intervalMenu
                                    Repeater {
                                        model: [10, 15, 30, 45, 60, 120, 180, 240, 300, 360, 480, 600, 720, 1440]
                                        QQC2.MenuItem {
                                            text: modelData >= 60 ? i18n("%1 hours", modelData/60) : i18n("%1 mins", modelData)
                                            onTriggered: updateSource(index, "syncInterval", modelData)
                                        }
                                    }
                                }
                            }
                        }
                        
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1
                            visible: testLogs[index] && testLogs[index].length > 0
                            
                            Repeater {
                                model: testLogs[index] || []
                                delegate: RowLayout {
                                    spacing: 8
                                    QQC2.Label {
                                        text: modelData.msg
                                        color: Kirigami.Theme.textColor
                                        font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                                        opacity: 0.7
                                    }
                                    QQC2.Label {
                                        text: modelData.status === "ok" ? "OK" : (modelData.status === "fail" ? "FAIL" : "TRYING")
                                        color: modelData.status === "ok" ? Kirigami.Theme.positiveTextColor : (modelData.status === "fail" ? Kirigami.Theme.negativeTextColor : Kirigami.Theme.neutralTextColor)
                                        font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                                        font.bold: true
                                    }
                                }
                            }
                        }
                    }
                }
            }

            QQC2.Button {
                text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Add Custom Source")
                icon.name: "list-add"
                Layout.alignment: Qt.AlignHCenter
                onClicked: addSource()
            }

            Kirigami.Separator { 
                Kirigami.FormData.isSection: true
                Kirigami.FormData.label: i18nd("plasma_applet_com.mcc45tr.filesearch", "Global Defaults") 
                Layout.fillWidth: true
            }
            
            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: Kirigami.Units.gridUnit
                QQC2.Label { text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Default Interval:") }
                QQC2.SpinBox {
                    from: 5; to: 1440
                    value: cfg_rssSyncInterval || 60
                    onValueModified: cfg_rssSyncInterval = value
                }
                QQC2.Label { text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Default Entries:") }
                QQC2.SpinBox {
                    from: 1; to: 50
                    value: cfg_rssMaxEntries || 10
                    onValueModified: cfg_rssMaxEntries = value
                }
            }
            
            Item { Layout.fillHeight: true }
        }
    }
}
