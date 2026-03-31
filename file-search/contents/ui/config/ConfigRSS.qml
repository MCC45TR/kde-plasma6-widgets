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

    // Access to the main logic controller for background tasks
    property var logic: {
        if (typeof plasmoid === "undefined" || !plasmoid.rootItem) return null;
        if (plasmoid.rootItem.logic) return plasmoid.rootItem.logic;
        if (plasmoid.rootItem.controller) return plasmoid.rootItem.controller;
        
        // Fallback for cases where the rootItem might be a wrapper
        for (var i = 0; i < plasmoid.rootItem.children.length; i++) {
            var child = plasmoid.rootItem.children[i];
            if (child && (child.syncSourceBackground || child.logic)) return child.logic || child;
        }
        return null;
    }
    
    function getScriptPath() {
        // More reliable way in Plasma 6 to get absolute path from relative
        var path = Qt.resolvedUrl("../../tools/rss_sync.sh").toString();
        // Remove file:// prefix (can be 7 or 8 chars depending on // or ///)
        if (path.indexOf("file://") === 0) {
            return path.replace(/^file:\/\/\/?/, "/");
        }
        return path;
    }

    readonly property string rssCacheBase: StandardPaths.writableLocation(StandardPaths.CacheLocation) + "/com.mcc45tr.filesearch/rss"

    Plasma5Support.DataSource {
        id: executable
        engine: "executable"
        connectedSources: []
        property var callbacks: ({})
        onNewData: (source, data) => {
            var stdout = data["stdout"] || ""
            var lines = stdout.split("\n")
            
            for (var key in callbacks) {
                if (source === key || source.indexOf(key) !== -1) {
                    // If the process is persistent, we might get partial output here
                    // For this widget, we treat the final callback call as the end of synchronization
                    for (var i = 0; i < lines.length; i++) {
                        var line = lines[i].trim()
                        if (line) callbacks[key](line, source)
                    }
                    
                    // If it contains "SUCCESS" or "FAIL:", delete the callback
                    if (stdout.indexOf("SUCCESS") !== -1 || stdout.indexOf("FAIL:") !== -1) {
                        delete callbacks[key]
                    }
                    break
                }
            }
            
            // Only disconnect if it finished or failed (to handle multi-line outputs)
            if (stdout.indexOf("SUCCESS") !== -1 || stdout.indexOf("FAIL:") !== -1) {
                disconnectSource(source)
            }
        }
    }

    // Internal state
    property var rssSources: []
    property var testLogs: ({}) // { index: [{msg: string, status: string}] }
    property var testResults: ({}) // Still needed for final state

    function addLog(index, msg, status) {
        var logs = testLogs[index] || []
        logs.push({msg: msg, status: status})
        testLogs[index] = logs
        testLogs = JSON.parse(JSON.stringify(testLogs))
    }

    function updateLastLog(index, msg, status) {
        var logs = testLogs[index] || []
        if (logs.length > 0) {
            logs[logs.length - 1].msg = msg || logs[logs.length - 1].msg
            logs[logs.length - 1].status = status || logs[logs.length - 1].status
            testLogs[index] = logs
            testLogs = JSON.parse(JSON.stringify(testLogs))
        } else {
            addLog(index, msg, status)
        }
    }
    
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
    
    readonly property var presetSources: (function() {
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
            presets.push({ section: i18nd("plasma_applet_com.mcc45tr.filesearch", "Türkiye News"), items: [
                { name: "Anadolu Ajansı", url: "https://www.aa.com.tr/tr/rss" },
                { name: "Hürriyet", url: "https://www.hurriyet.com.tr/rss/anasayfa" },
                { name: "Cumhuriyet", url: "https://www.cumhuriyet.com.tr/rss" },
                { name: "Webtekno", url: "https://www.webtekno.com/rss.xml" },
                { name: "TeknoSeyir", url: "https://teknoseyir.com/feed" },
                { name: "Sözcü", url: "https://www.sozcu.com.tr/feeds-haberler" },
                { name: "TRT Haber", url: "https://www.trthaber.com/sondakika.rss" },
                { name: "NTV", url: "https://www.ntv.com.tr/son-dakika.rss" },
                { name: "Habertürk", url: "https://www.haberturk.com.tr/rss" },
                { name: "CNN Türk", url: "https://www.cnnturk.com/feed/rss/all/news" },
                { name: "Beyaz Gazete", url: "https://beyazgazete.com/rss/guncel.xml" }
            ]});
        } else if (lang === "az") {
            presets.push({ section: i18nd("plasma_applet_com.mcc45tr.filesearch", "Azerbaijan News"), items: [
                { name: "AZERTAC", url: "https://azertag.az/rss" },
                { name: "APA", url: "https://apa.az/rss" },
                { name: "Trend News", url: "https://az.trend.az/feeds/index.rss" },
                { name: "Report.az", url: "https://report.az/rss/" },
                { name: "Tech.az", url: "https://tech.az/feed/" }
            ]});
        } else if (lang === "bn") {
            presets.push({ section: i18nd("plasma_applet_com.mcc45tr.filesearch", "Bangladesh News"), items: [
                { name: "Prothom Alo", url: "https://www.prothomalo.com/feed" },
                { name: "The Daily Star", url: "https://www.thedailystar.net/rss.xml" },
                { name: "Ittefaq", url: "https://www.ittefaq.com.bd/rss.xml" },
                { name: "Dhaka Tribune Tech", url: "https://www.dhakatribune.com/feed/articles/technology" }
            ]});
        } else if (lang === "cs") {
            presets.push({ section: i18nd("plasma_applet_com.mcc45tr.filesearch", "Czech Republic"), items: [
                { name: "iDNES.cz", url: "https://servis.idnes.cz/rss.aspx?c=zpravodaj" },
                { name: "Novinky.cz", url: "https://www.novinky.cz/rss" },
                { name: "Aktuálně.cz", url: "https://vyhledavani.aktualne.cz/zpravy/rss/" },
                { name: "Živě.cz", url: "https://www.zive.cz/rss/sc-47/" }
            ]});
        } else if (lang === "de") {
            presets.push({ section: i18nd("plasma_applet_com.mcc45tr.filesearch", "Germany News"), items: [
                { name: "Spiegel Online", url: "https://www.spiegel.de/schlagzeilen/index.rss" },
                { name: "Die Zeit", url: "https://newsfeed.zeit.de/index" },
                { name: "FAZ", url: "https://www.faz.net/rss/aktuell/" },
                { name: "Heise Online", url: "https://www.heise.de/rss/heise-atom.xml" }
            ]});
        } else if (lang === "el") {
            presets.push({ section: i18nd("plasma_applet_com.mcc45tr.filesearch", "Greece News"), items: [
                { name: "Kathimerini", url: "https://www.kathimerini.gr/rss" },
                { name: "To Vima", url: "https://www.tovima.gr/feed/" },
                { name: "Naftemporiki", url: "https://www.naftemporiki.gr/rss/" },
                { name: "ProtoThema", url: "https://www.protothema.gr/rss" },
                { name: "News247", url: "https://www.news247.gr/rss/" },
                { name: "Techblog.gr", url: "https://techblog.gr/feed/" }
            ]});
        } else if (lang === "es") {
            presets.push({ section: i18nd("plasma_applet_com.mcc45tr.filesearch", "Spain & Mexico"), items: [
                { name: "El País", url: "https://feeds.elpais.com/mrss-s/pages/ep/site/elpais.com/portada" },
                { name: "El Mundo", url: "https://e00-elmundo.uecdn.es/elmundo/rss/portada.xml" },
                { name: "ABC.es", url: "https://www.abc.es/rss/2.0/portada/" },
                { name: "RTVE", url: "https://www.rtve.es/api/noticias/rss" },
                { name: "Xataka", url: "http://feeds.weblogssl.com/xataka2" }
            ]});
        } else if (lang === "fa") {
            presets.push({ section: i18nd("plasma_applet_com.mcc45tr.filesearch", "Iran News"), items: [
                { name: "Fars News", url: "https://www.farsnews.ir/rss" },
                { name: "ISNA", url: "https://www.isna.ir/rss" },
                { name: "Hamshahri", url: "https://www.hamshahrionline.ir/rss" },
                { name: "Zoomit", url: "https://zoomit.ir/feed/" }
            ]});
        } else if (lang === "fr") {
            presets.push({ section: i18nd("plasma_applet_com.mcc45tr.filesearch", "France News"), items: [
                { name: "Le Monde", url: "https://www.lemonde.fr/rss/une.xml" },
                { name: "Le Figaro", url: "https://www.lefigaro.fr/rss/figaro_actualites.xml" },
                { name: "Libération", url: "https://www.liberation.fr/arc/outboundfeeds/rss-all/collection/accueil-une/?outputType=xml" },
                { name: "France 24", url: "https://www.france24.com/fr/rss" },
                { name: "Journal du Geek", url: "https://www.journaldugeek.com/feed/" }
            ]});
        } else if (lang === "hi") {
            presets.push({ section: i18nd("plasma_applet_com.mcc45tr.filesearch", "India News (Hindi)"), items: [
                { name: "Dainik Jagran", url: "https://www.jagran.com/rss/news/latest-news-rss.xml" },
                { name: "Amar Ujala", url: "https://www.amarujala.com/rss/india-news.xml" },
                { name: "Navbharat Times", url: "https://navbharattimes.indiatimes.com/rssfeeds/2292.cms" },
                { name: "Gadgets 360", url: "https://hindi.gadgets360.com/rss/feeds" }
            ]});
        } else if (lang === "hy") {
            presets.push({ section: i18nd("plasma_applet_com.mcc45tr.filesearch", "Armenia News"), items: [
                { name: "Armenpress", url: "https://armenpress.am/en/rss" },
                { name: "PanARMENIAN", url: "https://www.panarmenian.net/rss/arm/" },
                { name: "CivilNet", url: "https://www.civilnet.am/feed/" },
                { name: "Itel.am", url: "https://itel.am/am/feed" }
            ]});
        } else if (lang === "id") {
            presets.push({ section: i18nd("plasma_applet_com.mcc45tr.filesearch", "Indonesia News"), items: [
                { name: "Detikcom", url: "https://rss.detik.com/" },
                { name: "Kompas.com", url: "https://www.kompas.com/feed" },
                { name: "Tempo", url: "https://www.tempo.co/rss/current" },
                { name: "Tekno Kompas", url: "https://tekno.kompas.com/feed" }
            ]});
        } else if (lang === "it") {
            presets.push({ section: i18nd("plasma_applet_com.mcc45tr.filesearch", "Italy News"), items: [
                { name: "Corriere della Sera", url: "http://xml2.corriereobjects.it/rss/homepage.xml" },
                { name: "La Repubblica", url: "https://www.repubblica.it/rss/homepage/rss2.0.xml" },
                { name: "ANSA", url: "https://www.ansa.it/sito/ansait_rss.xml" },
                { name: "Il Sole 24 Ore", url: "https://www.ilsole24ore.com/rss/italia.xml" },
                { name: "HDblog.it", url: "https://www.hdblog.it/feed/" }
            ]});
        } else if (lang === "ja") {
            presets.push({ section: i18nd("plasma_applet_com.mcc45tr.filesearch", "Japan News"), items: [
                { name: "NHK News", url: "https://www3.nhk.or.jp/rss/news/shuyou.xml" },
                { name: "Asahi Shimbun", url: "https://www.asahi.com/rss/asahi/newsheadlines.rdf" },
                { name: "Nikkei", url: "https://www.nikkei.com/rss/index.rdf" },
                { name: "ITmedia", url: "https://rss.itmedia.co.jp/rss/2.0/itmedia_all.xml" }
            ]});
        } else if (lang === "pt") {
            presets.push({ section: i18nd("plasma_applet_com.mcc45tr.filesearch", "Brazil & Portugal"), items: [
                { name: "G1 (Globo)", url: "https://g1.globo.com/dynamo/rss2.xml" },
                { name: "Folha de S.Paulo", url: "https://feeds.folha.uol.com.br/em-cima-da-hora/rss091.xml" },
                { name: "Público", url: "https://www.publico.pt/feed/all" },
                { name: "TecMundo", url: "https://www.tecmundo.com.br/rss" }
            ]});
        } else if (lang === "ro") {
            presets.push({ section: i18nd("plasma_applet_com.mcc45tr.filesearch", "Romania News"), items: [
                { name: "HotNews", url: "https://www.hotnews.ro/rss" },
                { name: "Digi24", url: "https://www.digi24.ro/rss" },
                { name: "Adevarul", url: "https://adevarul.ro/rss/" },
                { name: "Știrile ProTV", url: "https://stirileprotv.ro/rss" },
                { name: "Start-up.ro", url: "https://www.start-up.ro/feed/" }
            ]});
        } else if (lang === "ru") {
            presets.push({ section: i18nd("plasma_applet_com.mcc45tr.filesearch", "Russia News"), items: [
                { name: "RIA Novosti", url: "https://ria.ru/export/rss2/archive/index.xml" },
                { name: "TASS", url: "http://tass.ru/rss/v2.xml" },
                { name: "Kommersant", url: "https://www.kommersant.ru/RSS/main.xml" },
                { name: "Habr", url: "https://habr.com/ru/rss/all/all/" }
            ]});
        } else if (lang === "ur") {
            presets.push({ section: i18nd("plasma_applet_com.mcc45tr.filesearch", "Pakistan News"), items: [
                { name: "Dawn Urdu", url: "https://www.dawnnews.tv/rss" },
                { name: "Jang", url: "https://jang.com.pk/rss/" },
                { name: "Geo News", url: "https://urdu.geo.tv/rss/1" },
                { name: "ProPakistani", url: "https://propakistani.pk/feed/" }
            ]});
        } else if (lang === "zh") {
            presets.push({ section: i18nd("plasma_applet_com.mcc45tr.filesearch", "China News"), items: [
                { name: "Xinhua", url: "http://www.news.cn/rss/top.xml" },
                { name: "Caixin", url: "https://www.caixin.com/rss/" },
                { name: "People's Daily", url: "http://www.people.com.cn/rss/politics.xml" },
                { name: "36Kr", url: "https://36kr.com/feed" }
            ]});
        } else if (lang === "en") {
            presets.push({ section: i18nd("plasma_applet_com.mcc45tr.filesearch", "USA & UK News"), items: [
                { name: "BBC News", url: "http://feeds.bbci.co.uk/news/rss.xml" },
                { name: "NY Times", url: "https://rss.nytimes.com/services/xml/rss/nyt/HomePage.xml" },
                { name: "The Guardian", url: "https://www.theguardian.com/uk/rss" },
                { name: "CNNTürk", url: "http://rss.cnn.com/rss/edition.rss" },
                { name: "Reuters", url: "https://www.reuters.com/arc/outboundfeeds/rss/?outputType=xml" },
                { name: "The Verge", url: "https://www.theverge.com/rss/index.xml" }
            ]});
        } else {
            presets.push({ section: i18nd("plasma_applet_com.mcc45tr.filesearch", "World News"), items: [
                { name: "BBC News", url: "http://feeds.bbci.co.uk/news/rss.xml" },
                { name: "CNN", url: "http://rss.cnn.com/rss/edition.rss" },
                { name: "Reuters", url: "https://www.reuters.com/arc/outboundfeeds/rss/?outputType=xml" },
                { name: "Al Jazeera", url: "https://www.aljazeera.com/xml/rss/all.xml" }
            ]});
        }
        return presets;
    })()
    
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
        if (rssSources.length >= 30) return
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
        if (rssSources.length >= 30) return
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
    }

    function clearLogs(index) {
        var logs = testLogs
        delete logs[index]
        testLogs = JSON.parse(JSON.stringify(logs))
    }

    function cacheBasePath() {
        return StandardPaths.writableLocation(StandardPaths.HomeLocation) + "/.cache/com.mcc45tr.filesearch/rss"
    }

    function writeEntriesToCache(url, entries) {
        var base = rssCacheBase
        var path = RSSManager.getSourceFilePath(url, base)
        var json = JSON.stringify(entries)
        var base64Json = RSSManager.encodeBase64(json)
        executable.connectSource("mkdir -p '" + base + "' && (echo '" + base64Json + "' > '" + path + "')")
    }

    function updateCombinedCache(entriesBySource, markAsFresh) {
        var combined = []
        for (var key in entriesBySource) {
            if (!entriesBySource.hasOwnProperty(key)) {
                continue
            }

            var entries = entriesBySource[key]
            if (Array.isArray(entries)) {
                combined = combined.concat(entries)
            }
        }

        combined.sort(function(a, b) {
            return new Date(b.rawDate || 0).getTime() - new Date(a.rawDate || 0).getTime()
        })

        cfg_rssCache = JSON.stringify(combined)
        if (markAsFresh) {
            cfg_rssLastSyncAll = String(Date.now())
        }
    }

    function syncSource(url, index, onComplete) {
        if (!url || url.indexOf("http") !== 0) {
            addLog(index, i18nd("plasma_applet_com.mcc45tr.filesearch", "Invalid URL"), "fail")
            if (onComplete) onComplete(false, [])
            return
        }

        testResults[index] = "testing"
        testLogs[index] = []
        addLog(index, i18nd("plasma_applet_com.mcc45tr.filesearch", "Starting background sync..."), "testing")

        var l = logic
        if (l) {
            l.syncSourceBackground(index, function(line, source) {
                processSyncLine(index, line, true)
                if (line === "SUCCESS" && onComplete) onComplete(true)
                else if (line.indexOf("FAIL:") === 0 && onComplete) onComplete(false)
            })
        } else {
            // Standalone sync logic using local executable DataSource
            var scriptPath = getScriptPath()
            if (!scriptPath || scriptPath === "undefined" || scriptPath.indexOf("rss_sync.sh") === -1) {
                 addLog(index, i18nd("plasma_applet_com.mcc45tr.filesearch", "Script not found at: %1", scriptPath), "fail")
                 testResults[index] = "error"
                 if (onComplete) onComplete(false)
                 return
            }
            
            var max = rssSources[index].maxEntries || cfg_rssMaxEntries || 10
            var cmd = "sh \"" + scriptPath + "\" \"" + rssCacheBase + "\" \"" + url + "\" \"" + rssSources[index].name + "\" \"" + max + "\""
            
            executable.callbacks[cmd] = function(line, source) {
                processSyncLine(index, line)
                if (line === "SUCCESS" && onComplete) onComplete(true)
                else if (line.indexOf("FAIL:") === 0 && onComplete) onComplete(false)
            }
            executable.connectSource(cmd)
        }
    }

    function processSyncLine(index, line, useLogic) {
        if (line === "SUCCESS") {
            updateLastLog(index, i18nd("plasma_applet_com.mcc45tr.filesearch", "Sync: SUCCESS"), "ok")
            testResults[index] = "success"
            updateSource(index, "lastSync", Date.now())
            cfg_rssLastSyncAll = String(Date.now())
            if (useLogic && logic) {
                logic.updateCombinedCache(true)
            }
            clearLogsTimer.indexToClear = index
            clearLogsTimer.restart()
        } else if (line.indexOf("FAIL:") === 0) {
            updateLastLog(index, line.replace("FAIL:", "Sync: FAIL -"), "fail")
            testResults[index] = "error"
        } else if (line.indexOf(": START") !== -1) {
            addLog(index, line.replace(": START", "..."), "testing")
        } else if (line.indexOf(": OK") !== -1) {
            updateLastLog(index, line, "ok")
        } else if (line.indexOf("saved OK") !== -1) {
            updateLastLog(index, line, "ok")
        } else {
            // Generic line, maybe part of larger stdout
            console.log("RSS Config [Sync Log]: " + line)
        }
    }

    function testSource(url, index) {
        syncSource(url, index, function(success) {
            // Background script already updated the cache file
        })
    }

    function syncAllSources() {
        if (!rssSources.length) {
            cfg_rssCache = "[]"
            cfg_rssLastSyncAll = String(Date.now())
            return
        }

        var remaining = rssSources.length
        for (var i = 0; i < rssSources.length; i++) {
            (function(sourceIndex) {
                var sourceUrl = rssSources[sourceIndex].url
                syncSource(sourceUrl, sourceIndex, function(success) {
                    remaining--
                    if (remaining === 0 && logic) {
                        logic.updateCombinedCache(true)
                    }
                })
            })(i)
        }
    }

    function clearCacheFolder() {
        if (logic) {
            logic.clearRssCache()
            
            // Sync local state with logic state
            rssSources = JSON.parse(cfg_rssSources || "[]")
            testLogs = ({})
            testResults = ({})
        } else {
            // Fallback if logic is missing
            var base = rssCacheBase
            executable.connectSource("rm -rf \"" + base + "\" && mkdir -p \"" + base + "\"")
            cfg_rssCache = "[]"
            cfg_rssLastSyncAll = "0"
            for (var i = 0; i < rssSources.length; i++) {
                rssSources[i].lastSync = 0
            }
            rssSources = JSON.parse(JSON.stringify(rssSources))
            saveSources()
        }
    }

    function formatLastSync(timestamp) {
        if (!timestamp || Number(timestamp) <= 0) {
            return i18nd("plasma_applet_com.mcc45tr.filesearch", "Never")
        }

        var dt = new Date(Number(timestamp))
        return Qt.formatDateTime(dt, "dd.MM.yyyy HH:mm")
    }

    QQC2.ScrollView {
        anchors.fill: parent
        contentWidth: -1 // Disable horizontal scroll
        
        ColumnLayout {
            width: parent.width - (parent.ScrollBar.vertical.visible ? parent.ScrollBar.vertical.width : 0)
            spacing: Kirigami.Units.gridUnit

            QQC2.CheckBox {
            Kirigami.FormData.label: i18nd("plasma_applet_com.mcc45tr.filesearch", "Enable RSS")
            text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Show RSS feed updates in search results")
            checked: cfg_rssEnabled
            onToggled: cfg_rssEnabled = checked
            Layout.leftMargin: Kirigami.Units.gridUnit
        }

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: Kirigami.Units.gridUnit
                Layout.rightMargin: Kirigami.Units.gridUnit

                QQC2.Button {
                    text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Sync All Sources")
                    icon.name: "view-refresh"
                    enabled: cfg_rssEnabled && rssSources.length > 0
                    onClicked: syncAllSources()
                }

                QQC2.Button {
                    text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Clear Cache Folder")
                    icon.name: "edit-clear"
                    enabled: rssSources.length > 0 || (cfg_rssCache || "").length > 2
                    onClicked: clearCacheFolder()
                }

                Item { Layout.fillWidth: true }

                QQC2.Label {
                    text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Last full sync: %1", formatLastSync(cfg_rssLastSyncAll))
                    opacity: 0.75
                }
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
                    visible: modelData ? !!modelData.items && modelData.items.length > 0 : false
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
                                    property bool isSelected: !!isPresetSelected(modelData.url)
                                    text: modelData.name
                                    icon.name: isSelected ? "checkmark" : "list-add"
                                    enabled: (isSelected || rssSources.length < 30)
                                    checkable: true
                                    checked: isSelected
                                    onClicked: {
                                        checked = isSelected // Preserve state until added/removed
                                        addPreset(modelData)
                                    }
                                    
                                    QQC2.ToolTip.visible: !!hovered
                                    QQC2.ToolTip.text: modelData.url
                                }
                            }
                        }
                    }
                }
            }

            Kirigami.Separator { 
                Kirigami.FormData.isSection: true
                Kirigami.FormData.label: i18nd("plasma_applet_com.mcc45tr.filesearch", "RSS Sources (Max 30)") 
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
                                            text: modelData >= 60 ? i18nd("plasma_applet_com.mcc45tr.filesearch", "%1 hours", modelData/60) : i18nd("plasma_applet_com.mcc45tr.filesearch", "%1 mins", modelData)
                                            onTriggered: updateSource(index, "syncInterval", modelData)
                                        }
                                    }
                                }
                            }

                            Item { Layout.fillWidth: true }

                            QQC2.Label {
                                text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Last sync: %1", formatLastSync(modelData.lastSync))
                                opacity: 0.75
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
                Layout.fillWidth: true
            }

            Kirigami.FormLayout {
                Layout.fillWidth: true

                QQC2.CheckBox {
                    Kirigami.FormData.label: i18nd("plasma_applet_com.mcc45tr.filesearch", "News Features:")
                    text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Show RSS titles in placeholder cycling")
                    checked: cfg_rssPlaceholderCycling
                    onCheckedChanged: cfg_rssPlaceholderCycling = checked
                }

                QQC2.SpinBox {
                    Kirigami.FormData.label: i18nd("plasma_applet_com.mcc45tr.filesearch", "Default Interval:")
                    from: 5; to: 1440
                    value: cfg_rssSyncInterval || 60
                    onValueModified: cfg_rssSyncInterval = value
                }

                QQC2.SpinBox {
                    Kirigami.FormData.label: i18nd("plasma_applet_com.mcc45tr.filesearch", "Default Entries:")
                    from: 1; to: 50
                    value: cfg_rssMaxEntries || 10
                    onValueModified: cfg_rssMaxEntries = value
                }
            }
            
            Item { Layout.fillHeight: true }
        }
    }
}
