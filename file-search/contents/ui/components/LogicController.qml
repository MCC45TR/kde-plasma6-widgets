import "../js/CategoryManager.js" as CategoryManager
import "../js/ConfigManager.js" as ConfigManager
import "../js/HistoryManager.js" as HistoryManager
import "../js/PinnedManager.js" as PinnedManager
import "../js/RSSManager.js" as RSSManager
import "../js/TelemetryManager.js" as TelemetryManager
import "../js/utils.js" as Utils
import QtCore
import QtQuick
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.plasma.plasmoid
import org.kde.plasma.workspace.dbus as DBus

Item {
    id: logicRoot

    signal backgroundMaintenanceRequested()

    // Required dependencies
    required property var plasmoidConfig
    // ===== CONFIGURATION MANAGEMENT =====
    readonly property int userProfile: plasmoidConfig.userProfile || 0
    readonly property var profileDefaults: ConfigManager.getProfileDefaults(userProfile)
    readonly property int maxHistoryItems: ConfigManager.getMaxHistoryItems(userProfile)
    // Feature flags based on profile
    readonly property bool debugEnabled: ConfigManager.isFeatureEnabled(userProfile, "debug")
    readonly property bool previewEnabled: ConfigManager.isFeatureEnabled(userProfile, "preview")
    readonly property bool advancedSearchEnabled: ConfigManager.isFeatureEnabled(userProfile, "advancedSearch")
    readonly property bool telemetryEnabled: ConfigManager.isFeatureEnabled(userProfile, "telemetry")
    readonly property bool categoryPriorityEnabled: ConfigManager.isFeatureEnabled(userProfile, "categoryPriority")
    readonly property bool activityPinningEnabled: ConfigManager.isFeatureEnabled(userProfile, "activityPinning")
    // ===== HISTORY MANAGEMENT =====
    property var searchHistory: []
    property string pendingHistoryJson: ""
    // ===== PINNED ITEMS MANAGEMENT =====
    property var pinnedItems: []
    property string pendingPinnedJson: ""
    property string currentActivityId: "global"
    // ===== CATEGORY SETTINGS =====
    property var categorySettings: {
    }
    // ===== TELEMETRY =====
    property var telemetryStats: TelemetryManager.getStatsObject(plasmoidConfig.telemetryData || "{}")
    property bool telemetryDirty: false
    // Reactive property for bindings
    readonly property var visiblePinnedItems: PinnedManager.getPinnedForActivity(pinnedItems, currentActivityId)
    readonly property var pinnedLookup: {
        var lookup = ({})
        for (var i = 0; i < visiblePinnedItems.length; i++) {
            lookup["$" + visiblePinnedItems[i].matchId] = visiblePinnedItems[i]
        }
        return lookup
    }
    // Activity management
    readonly property string currentActivityName: currentActivityId === "global" ? "Global" : currentActivityId
    // ===== DEPENDENCY CHECKS =====
    property bool manInstalled: true
    // ===== RSS MANAGEMENT =====
    property var rssSources: []
    property var rssCache: []
    property var rssTickerEntries: []
    readonly property bool rssEnabled: plasmoidConfig.rssEnabled || false
    readonly property string rssCacheBase: {
        var path = StandardPaths.writableLocation(StandardPaths.HomeLocation) + "/.cache/com.mcc45tr.filesearch/rss";
        if (path.indexOf("file://") === 0) {
            return path.replace(/^file:\/\/\/?/, "/");
        }
        return path;
    }
    readonly property string weatherCacheBase: {
        var path = StandardPaths.writableLocation(StandardPaths.HomeLocation) + "/.cache/com.mcc45tr.filesearch/weather";
        if (path.indexOf("file://") === 0)
            return path.replace(/^file:\/\/\/?/, "/");
        return path;
    }
    readonly property string weatherCachePath: weatherCacheBase + "/cache.json"
    property string weatherCache: ""
    property bool weatherCacheLoaded: false
    property var syncQueue: []
    property bool isSyncing: false
    property int rssBatchId: 0
    property real rssBatchStartedAt: 0
    property int rssBatchQueued: 0
    property int rssBatchCompleted: 0
    property int rssCacheRebuildCount: 0
    property bool rssMergeInProgress: false
    property bool rssMergeRequested: false
    property var rssMergeWaiters: []
    property string lastPersistedRssSources: ""
    readonly property int rssMaxConcurrentSyncs: 2

    function completeRssBatchIfIdle() {
        if (!isSyncing || syncQueue.length !== 0 || pendingSyncs !== 0)
            return;

        isSyncing = false;
        processQueueTimer.stop();
        var completedBatchId = rssBatchId;
        var completedBatchStartedAt = rssBatchStartedAt;
        var completedBatchQueued = rssBatchQueued;
        var completedBatchCount = rssBatchCompleted;
        persistRssSources();
        mergeCombinedCache(function(success) {
            if (success)
                updateCombinedCache(true);
            if (debugEnabled && completedBatchStartedAt > 0) {
                console.info("FileSearch RSS batch:", JSON.stringify({
                    id: completedBatchId,
                    queued: completedBatchQueued,
                    completed: completedBatchCount,
                    merged: success,
                    durationMs: Date.now() - completedBatchStartedAt
                }));
            }
        });
        rssBatchStartedAt = 0;
    }

    function pumpRssQueue() {
        while (pendingSyncs < rssMaxConcurrentSyncs && syncQueue.length > 0) {
            var sourceUrl = syncQueue.shift();
            if (sourceUrl)
                syncSourceSingle(sourceUrl);
        }
        completeRssBatchIfIdle();
    }
    // Small bounded cache/queue for text previews. This prevents rapid keyboard
    // navigation from spawning one shell process per selected result.
    property var snippetCache: ({})
    property var snippetCacheOrder: []
    property var snippetPendingCallbacks: ({})
    property var snippetRequestStartedAt: ({})
    property var snippetQueue: []
    property int snippetActiveRequests: 0
    readonly property int snippetCacheLimit: 32
    readonly property int snippetMaxConcurrentRequests: 2
    readonly property int snippetCacheTtlMs: 60000

    // Config validation
    function validateConfig() {
        return ConfigManager.sanitizeConfig({
            "displayMode": plasmoidConfig.displayMode,
            "viewMode": plasmoidConfig.viewMode,
            "iconSize": plasmoidConfig.iconSize,
            "listIconSize": plasmoidConfig.listIconSize,
            "previewEnabled": plasmoidConfig.previewEnabled,
            "debugOverlay": plasmoidConfig.debugOverlay,
            "userProfile": plasmoidConfig.userProfile
        });
    }

    function getRecommendedIconSize() {
        return ConfigManager.getRecommendedIconSize(plasmoidConfig.displayMode, plasmoidConfig.viewMode);
    }

    // ===== HISTORY FUNCTIONS =====
    function loadHistory() {
        var original = plasmoidConfig.searchHistory || "";
        searchHistory = HistoryManager.loadHistory(original).slice(0, maxHistoryItems);
        var normalized = JSON.stringify(searchHistory);
        // Persist only an actual migration/repair/truncation. A clean startup
        // must not schedule a no-op KConfig write.
        if (original && original !== normalized) {
            pendingHistoryJson = normalized;
            historySaveTimer.restart();
        }
    }

    function saveHistory() {
        pendingHistoryJson = JSON.stringify(searchHistory);
        historySaveTimer.restart();
    }

    function addToHistory(display, decoration, category, matchId, filePath, sourceType, queryText) {
        var isApp = Utils.isAppCategory(category, filePath, matchId, decoration);
        searchHistory = HistoryManager.addToHistory(searchHistory, display, decoration, category, matchId, filePath, sourceType, queryText, maxHistoryItems, isApp);
        saveHistory();
        // Schedule delayed icon check (1s)
        if (searchHistory.length > 0) {
            iconCheckTimer.uuid = searchHistory[0].uuid;
            iconCheckTimer.filePath = filePath;
            iconCheckTimer.decoration = decoration;
            iconCheckTimer.category = category;
            iconCheckTimer.restart();
        }
    }

    function formatHistoryTime(timestamp) {
        return Utils.formatHistoryTime(timestamp, function(s) { return i18nd("plasma_applet_com.mcc45tr.filesearch", s); });
    }

    function clearHistory() {
        searchHistory = HistoryManager.clearHistory();
        saveHistory();
    }

    function removeFromHistory(uuid) {
        searchHistory = HistoryManager.removeFromHistory(searchHistory, uuid);
        saveHistory();
    }

    // Shell escape helper - delegates to Utils.shellEscape
    function shellEscape(str) {
        return Utils.shellEscape(str)
    }

    // Launch a .desktop application safely
    function launchApp(filePath) {
        if (!filePath) return
        runShellCommand("kioclient exec " + shellEscape(filePath.toString()))
    }

    // Show file/app properties dialog safely
    function showProperties(filePath) {
        if (!filePath) return
        callSessionDBus(
            "org.freedesktop.FileManager1",
            "/org/freedesktop/FileManager1",
            "org.freedesktop.FileManager1",
            "ShowItemProperties",
            "ass",
            [[filePath.toString()], ""]
        )
    }

    function callSessionDBus(service, path, iface, member, signature, args) {
        var message = {
            service: service,
            path: path,
            iface: iface,
            member: member,
            signature: signature,
            arguments: args || []
        } as DBus.dbusMessage
        var reply = DBus.SessionBus.asyncCall(message)
        reply.finished.connect(function() { reply.destroy() })
    }

    function runShellCommand(cmd) {
        if (!cmd)
            return ;

        globalShellSource.connectSource(cmd);
    }

    function runExecutable(cmd, callback) {
        var uniqueCmd = cmd + " #uniq_" + Date.now() + "_" + Math.floor(Math.random() * 1000000);
        executable.callbacks[uniqueCmd] = callback;
        executable.connectSource(uniqueCmd);
        return uniqueCmd;
    }

    // ===== FILE OPERATIONS =====
    function openFolder(url) {
        if (!url)
            return ;

        callSessionDBus(
            "org.freedesktop.FileManager1",
            "/org/freedesktop/FileManager1",
            "org.freedesktop.FileManager1",
            "ShowItems",
            "ass",
            [[url.toString()], ""]
        );
    }

    function openContainingFolder(url) {
        openFolder(url);
    }

    function openWith(url) {
        if (!url)
            return ;

        callSessionDBus(
            "org.kde.klauncher5",
            "/KLauncher",
            "org.kde.KLauncher",
            "openUrl",
            "sss",
            [url.toString(), "", ""]
        );
    }

    function copyToClipboard(text) {
        if (!text)
            return ;

        callSessionDBus(
            "org.kde.klipper",
            "/klipper",
            "org.kde.klipper.klipper",
            "setClipboardContents",
            "s",
            [text.toString()]
        );
    }

    function moveToTrash(url) {
        if (!url)
            return ;

        var path = url.toString();
        var cmd = "kioclient move " + shellEscape(path) + " trash:/";
        runShellCommand(cmd);
    }

    function openTerminal(url) {
        if (!url)
            return ;

        var path = Utils.decodeLocalPath(url);
        var escapedPath = shellEscape(path);
        var cmd = "target=" + escapedPath
                + "; if test -d \"$target\"; then workdir=$target; else workdir=$(dirname -- \"$target\"); fi"
                + "; konsole --workdir \"$workdir\"";
        runShellCommand(cmd);
    }

    // ===== PINNED FUNCTIONS =====
    function loadPinned() {
        // Debug: console.log("FileSearch [Pinned]: Loading pinned items...")
        pinnedItems = PinnedManager.loadPinned(plasmoidConfig.pinnedItems);
    }

    function savePinned() {
        pendingPinnedJson = PinnedManager.savePinned(pinnedItems);
        pinnedSaveTimer.restart();
    }

    function pinItem(item) {
        pinnedItems = PinnedManager.pinItem(pinnedItems, item, currentActivityId);
        savePinned();
    }

    function unpinItem(matchId) {
        pinnedItems = PinnedManager.unpinItem(pinnedItems, matchId, currentActivityId);
        savePinned();
    }

    function isPinned(matchId) {
        return pinnedLookup["$" + matchId] !== undefined;
    }

    function togglePin(item) {
        pinnedItems = PinnedManager.togglePin(pinnedItems, item, currentActivityId);
        savePinned();
    }

    function getVisiblePinnedItems() {
        return visiblePinnedItems;
    }

    function getPinInfo(matchId) {
        return pinnedLookup["$" + matchId] || null;
    }

    function reorderPinnedItems(fromUuid, toUuid) {
        pinnedItems = PinnedManager.reorderPinnedById(pinnedItems, fromUuid, toUuid, currentActivityId);
        savePinned();
    }

    function setActivity(activityId) {
        currentActivityId = activityId || "global";
    }

    function pinItemToActivity(item, activityId) {
        pinnedItems = PinnedManager.pinItem(pinnedItems, item, activityId || "global");
        savePinned();
    }

    // ===== CATEGORY SETTINGS FUNCTIONS =====
    function loadCategorySettings() {
        // Debug: console.log("FileSearch [Category]: Loading category settings...")
        categorySettings = CategoryManager.loadCategorySettings(plasmoidConfig.categorySettings);
    }

    function processCategories(categories) {
        return CategoryManager.processCategories(categories, categorySettings);
    }

    function isCategoryVisible(categoryName) {
        return CategoryManager.isCategoryVisible(categorySettings, categoryName);
    }

    function getEffectiveIcon(categoryName, defaultIcon) {
        return CategoryManager.getEffectiveIcon(categorySettings, categoryName, defaultIcon);
    }

    function updateTelemetry(latency) {
        if (!telemetryEnabled)
            return;

        var current = telemetryStats || TelemetryManager.getEmptyStats();
        var next = Object.assign({}, current);
        next.totalSearches = (next.totalSearches || 0) + 1;
        next.totalLatencySum = (next.totalLatencySum || 0) + latency;
        next.averageLatency = Math.round(next.totalLatencySum / next.totalSearches);
        next.lastUpdated = new Date().toISOString();
        telemetryStats = next;
        telemetryDirty = true;
        if (!telemetrySaveTimer.running)
            telemetrySaveTimer.start();
    }

    function flushTelemetry() {
        if (!telemetryDirty)
            return;
        plasmoidConfig.telemetryData = JSON.stringify(telemetryStats);
        telemetryDirty = false;
    }

    property bool manCheckCompleted: false
    property bool manCheckPending: false

    function ensureManAvailability() {
        if (manCheckCompleted || manCheckPending)
            return;
        manCheckPending = true;
        manCheckSource.connectedSources = ["command -v man"];
    }

    function loadRSS() {
        try {
            rssSources = JSON.parse(plasmoidConfig.rssSources || "[]");
        } catch (e) {
            rssSources = [];
        }
        // Cache is loaded from files via updateCombinedCache(), not from KConfig
        rssCache = [];
        rssTickerEntries = [];
    }

    function persistRssSources() {
        var serialized = JSON.stringify(rssSources || []);
        lastPersistedRssSources = serialized;
        plasmoidConfig.rssSources = serialized;
    }

    function rebuildRssTickerEntries() {
        var cache = Array.isArray(rssCache) ? rssCache : [];
        if (cache.length === 0) {
            rssTickerEntries = [];
            return;
        }

        var grouped = {};
        var sourceOrder = [];
        for (var i = 0; i < cache.length; i++) {
            var entry = cache[i];
            if (!entry || !entry.display || entry.display.length <= 3)
                continue;

            var subtext = entry.subtext || "";
            var sourceName = subtext.split(" | ")[0] || "Unknown";
            if (!grouped[sourceName]) {
                grouped[sourceName] = [];
                sourceOrder.push(sourceName);
            }
            grouped[sourceName].push({
                text: entry.display,
                source: sourceName
            });
        }

        var mixed = [];
        var offset = 0;
        // Limit to 40 items for ticker to avoid heavy memory usage
        while (mixed.length < 40) {
            var added = false;
            for (var j = 0; j < sourceOrder.length; j++) {
                var source = sourceOrder[j];
                var sourceEntries = grouped[source];
                if (sourceEntries && offset < sourceEntries.length) {
                    mixed.push(sourceEntries[offset]);
                    added = true;
                    if (mixed.length >= 40)
                        break;
                }
            }
            if (!added)
                break;
            offset++;
        }

        rssTickerEntries = mixed;
    }

    function finalizeUpdate(combined, markAsFresh) {
        // rss_sync.py is the single writer and already publishes a bounded,
        // sorted combined cache. Avoid sorting/mutating the full set again on
        // the plasmashell main thread.
        rssCache = Array.isArray(combined) ? combined.slice(0, 1500) : [];
        // Optimization: Do NOT serialize the massive RSS cache string back to plasmoidConfig
        // to prevent Plasma shell stutters during synchronous KConfig writing.
        if (markAsFresh)
            plasmoidConfig.rssLastSyncAll = new Date().getTime();

        rebuildRssTickerEntries();
    }

    function getSourceFilePath(url) {
        return RSSManager.getSourceFilePath(url, rssCacheBase);
    }

    function clearRssCache() {
        var cmd = "rm -rf " + shellEscape(rssCacheBase) + " && mkdir -p " + shellEscape(rssCacheBase);
        runExecutable(cmd, function(stdout, isFinished, exitCode) {
        });
        rssCache = [];
        rssTickerEntries = [];
        // Set to empty string instead of writing JSON array representation to KConfig
        plasmoidConfig.rssCache = "";
        plasmoidConfig.rssLastSyncAll = 0;

        // Reset lastSync for all sources
        for (var i = 0; i < rssSources.length; i++) {
            rssSources[i].lastSync = 0;
        }
        persistRssSources();
    }

    function loadSourceEntries(url, callback) {
        if (!url) {
            callback([]);
            return ;
        }
        var path = getSourceFilePath(url);

        var xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200 || xhr.status === 0) {
                    var raw = xhr.responseText.trim();
                    if (raw) {
                        tryParseRaw(raw);
                        return;
                    }
                }
                readLocalTextSnippetFallback();
            }
        };

        function tryParseRaw(raw) {
            try {
                var decodedJson = RSSManager.decodeBase64(raw);
                if (decodedJson && (decodedJson.indexOf("[") !== -1 || decodedJson.indexOf("{") !== -1)) {
                    var data = JSON.parse(decodedJson);
                    callback(Array.isArray(data) ? data : []);
                } else {
                    var rawData = JSON.parse(raw);
                    callback(Array.isArray(rawData) ? rawData : []);
                }
            } catch (e) {
                try {
                    var rawData2 = JSON.parse(raw);
                    callback(Array.isArray(rawData2) ? rawData2 : []);
                } catch (e2) {
                    console.warn("LogicController: Failed to parse RSS cache:", e2);
                    callback([]);
                }
            }
        }

        function readLocalTextSnippetFallback() {
            readFullLocalFile(path, function(content) {
                var raw = (content || "").trim();
                if (raw) {
                    tryParseRaw(raw);
                } else {
                    callback([]);
                }
            });
        }

        try {
            xhr.open("GET", "file://" + path);
            xhr.send();
        } catch (e) {
            readLocalTextSnippetFallback();
        }
    }

    function readFullLocalFile(filePath, callback) {
        var path = Utils.decodeLocalPath(filePath);
        path = path.trim();
        if (!path) {
            callback("");
            return;
        }
        var cmd = "cat " + shellEscape(path);
        runExecutable(cmd, function(stdout, isFinished, exitCode) {
            if (isFinished) {
                callback(stdout);
            }
        });
    }

    function loadWeatherCache() {
        readFullLocalFile(weatherCachePath, function(content) {
            var cached = (content || "").trim();
            if (!cached || cached === "{}") {
                // One-time migration from older releases that stored the full
                // forecast JSON synchronously in KConfig.
                cached = (plasmoidConfig.weatherCache || "").trim();
                if (cached && cached !== "{}")
                    saveWeatherCache(cached);
            }
            weatherCache = cached && cached !== "{}" ? cached : "";
            weatherCacheLoaded = true;
            if (plasmoidConfig.weatherCache && plasmoidConfig.weatherCache !== "{}")
                plasmoidConfig.weatherCache = "{}";
        });
    }

    function saveWeatherCache(value) {
        var serialized = typeof value === "string" ? value : JSON.stringify(value || {});
        weatherCache = serialized && serialized !== "{}" ? serialized : "";
        weatherCacheLoaded = true;
        var temporaryPath = weatherCachePath + ".tmp." + Date.now() + "." + Math.floor(Math.random() * 1000000);
        var cmd = "mkdir -p " + shellEscape(weatherCacheBase)
                + " && chmod 700 " + shellEscape(weatherCacheBase)
                + " && printf '%s' " + shellEscape(serialized)
                + " > " + shellEscape(temporaryPath)
                + " && chmod 600 " + shellEscape(temporaryPath)
                + " && mv -f " + shellEscape(temporaryPath) + " " + shellEscape(weatherCachePath);
        runExecutable(cmd, function(stdout, isFinished, exitCode) {
            if (isFinished && exitCode !== 0)
                console.warn("LogicController: Failed to persist weather cache");
        });
    }

    function checkAndSyncRSS() {
        if (!rssEnabled || rssSources.length === 0)
            return ;

        var now = new Date().getTime();
        for (var i = 0; i < rssSources.length; i++) {
            var source = rssSources[i];
            var interval = source.syncInterval || plasmoidConfig.rssSyncInterval || 60;
            var intervalMs = interval * 60 * 1000;
            var lastSync = source.lastSync || 0;
            if (now - lastSync > intervalMs)
                syncSource(i);

        }
    }

    function syncSource(index) {
        var source = rssSources[index]
        if (!source || !source.url) return
        if (!isSyncing) {
            rssBatchId++;
            rssBatchStartedAt = Date.now();
            rssBatchQueued = 0;
            rssBatchCompleted = 0;
        }
        if (syncQueue.indexOf(source.url) === -1) {
            syncQueue.push(source.url);
            rssBatchQueued++;
        }

        if (!isSyncing)
            isSyncing = true;
        processQueueTimer.restart();
    }

    property int pendingSyncs: 0

    function syncSourceSingle(sourceUrl) {
        var index = -1
        for (var sourceIndex = 0; sourceIndex < rssSources.length; sourceIndex++) {
            if (rssSources[sourceIndex].url === sourceUrl) {
                index = sourceIndex
                break
            }
        }
        var source = rssSources[index];
        if (!source || !source.url) {
            processQueueTimer.restart();
            return ;
        }

        var scriptPath = getScriptPath();
        var max = source.maxEntries || plasmoidConfig.rssMaxEntries || 10;
        var cmd = "sh " + shellEscape(scriptPath) + " " + shellEscape(rssCacheBase) + " " + shellEscape(source.url) + " " + shellEscape(source.name) + " " + shellEscape(String(max));

        logicRoot.pendingSyncs++;

        runExecutable(cmd, function(stdout, isFinished, exitCode) {
            if (isFinished) {
                if (exitCode === 0) {
                    for (var updateIndex = 0; updateIndex < rssSources.length; updateIndex++) {
                        if (rssSources[updateIndex].url === sourceUrl) {
                            rssSources[updateIndex].lastSync = new Date().getTime();
                            break
                        }
                    }
                }
                logicRoot.rssBatchCompleted++;
                logicRoot.pendingSyncs = Math.max(0, logicRoot.pendingSyncs - 1);
                logicRoot.pumpRssQueue();
            }
        });
    }

    // New non-blocking sync for config UI usage
    function syncSourceBackground(index, callback) {
        var source = rssSources[index];
        if (!source || !source.url) {
            if (callback) callback("FAIL: Invalid source");
            return;
        }

        var scriptPath = getScriptPath();
        var max = source.maxEntries || plasmoidConfig.rssMaxEntries || 10;
        var cmd = "sh " + shellEscape(scriptPath) + " " + shellEscape(rssCacheBase) + " " + shellEscape(source.url) + " " + shellEscape(source.name) + " " + shellEscape(String(max));

        var lastLength = 0;
        runExecutable(cmd, function(stdout, isFinished, exitCode) {
            if (stdout.length > lastLength) {
                var newPart = stdout.substring(lastLength);
                lastLength = stdout.length;

                var lines = newPart.split("\n");
                for (var i = 0; i < lines.length; i++) {
                    var line = lines[i].trim();
                    if (line && line !== "SUCCESS" && callback) {
                        callback(line, cmd);
                    }
                }
            }
            if (isFinished) {
                if (exitCode === 0) {
                    mergeCombinedCache(function(merged) {
                        if (callback)
                            callback(merged ? "SUCCESS" : "FAIL: Cache merge failed", cmd);
                        if (merged)
                            updateCombinedCache(true);
                    });
                } else {
                    if (callback) {
                        callback("FAIL: Sync failed with exit code " + exitCode, cmd);
                    }
                }
            }
        });
    }

    function getScriptPath() {
        var path = Qt.resolvedUrl("../../tools/rss_sync.sh").toString();
        if (path.indexOf("file://") === 0) {
            return path.replace(/^file:\/\/\/?/, "/");
        }
        return path;
    }

    function mergeCombinedCache(callback) {
        if (callback)
            rssMergeWaiters.push(callback);
        if (rssMergeInProgress) {
            // A source may have been atomically replaced after the active merge
            // enumerated it. Coalesce all overlap into exactly one follow-up.
            rssMergeRequested = true;
            return;
        }
        rssMergeInProgress = true;
        var command = "sh " + shellEscape(getScriptPath())
                    + " --merge " + shellEscape(rssCacheBase);
        runExecutable(command, function(stdout, isFinished, exitCode) {
            if (!isFinished)
                return;
            rssMergeInProgress = false;
            if (rssMergeRequested) {
                rssMergeRequested = false;
                mergeCombinedCache();
                return;
            }
            var waiters = rssMergeWaiters.slice();
            rssMergeWaiters = [];
            for (var i = 0; i < waiters.length; i++)
                waiters[i](exitCode === 0);
        });
    }

    function syncAllRSS() {
        if (!rssEnabled || rssSources.length === 0)
            return ;

        for (var i = 0; i < rssSources.length; i++) {
            syncSource(i);
        }
    }

    function updateCombinedCache(markAsFresh) {
        rssCacheRebuildCount++;
        var path = rssCacheBase + "/combined.json";
        readFullLocalFile(path, function(content) {
            var raw = (content || "").trim();
            if (raw) {
                try {
                    var data = JSON.parse(raw);
                    finalizeUpdate(Array.isArray(data) ? data : [], markAsFresh);
                } catch (e) {
                    console.warn("LogicController: Failed to parse combined.json:", e);
                    finalizeUpdate([], markAsFresh);
                }
            } else {
                finalizeUpdate([], markAsFresh);
            }
        });
    }

    function hashStr(s) {
        var hash = 0;
        for (var i = 0; i < s.length; i++) {
            hash = ((hash << 5) - hash) + s.charCodeAt(i);
            hash |= 0;
        }
        return Math.abs(hash);
    }

    function touchSnippetCacheKey(path) {
        var order = snippetCacheOrder.slice();
        var oldIndex = order.indexOf(path);
        if (oldIndex !== -1)
            order.splice(oldIndex, 1);
        order.push(path);
        while (order.length > snippetCacheLimit) {
            var evicted = order.shift();
            delete snippetCache[evicted];
        }
        snippetCacheOrder = order;
    }

    function finishSnippetRequest(path, content, bytes) {
        snippetCache[path] = {
            content: content,
            bytes: bytes,
            cachedAt: Date.now()
        };
        touchSnippetCacheKey(path);

        var callbacks = snippetPendingCallbacks[path] || [];
        delete snippetPendingCallbacks[path];
        var startedAt = snippetRequestStartedAt[path] || 0;
        delete snippetRequestStartedAt[path];
        snippetActiveRequests = Math.max(0, snippetActiveRequests - 1);
        if (debugEnabled) {
            console.info("FileSearch preview:", JSON.stringify({
                id: hashStr(path),
                bytes: bytes,
                durationMs: startedAt > 0 ? Date.now() - startedAt : -1,
                listeners: callbacks.length,
                queued: snippetQueue.length,
                active: snippetActiveRequests
            }));
        }
        for (var i = 0; i < callbacks.length; i++) {
            try {
                callbacks[i](content, bytes);
            } catch (e) {
                console.warn("LogicController: text preview callback failed:", e);
            }
        }
        pumpSnippetQueue();
    }

    function startSnippetRequest(request) {
        var requestPath = request.path;
        var cmd = "stat -c %s " + shellEscape(requestPath) + " && echo '---SIZE_END---' && head -c 20000 " + shellEscape(requestPath);
        runExecutable(cmd, function(stdout, isFinished, exitCode) {
            if (!isFinished)
                return;

            var delimiter = "---SIZE_END---";
            var idx = stdout.indexOf(delimiter);
            var content = "";
            var bytes = 0;
            if (exitCode === 0 && idx !== -1) {
                bytes = parseInt(stdout.substring(0, idx).trim(), 10) || 0;
                content = stdout.substring(idx + delimiter.length);
                if (content.startsWith("\n"))
                    content = content.substring(1);
            }
            finishSnippetRequest(requestPath, content, bytes);
        });
    }

    function pumpSnippetQueue() {
        while (snippetActiveRequests < snippetMaxConcurrentRequests && snippetQueue.length > 0) {
            var request = snippetQueue.shift();
            if (!request || !snippetPendingCallbacks[request.path])
                continue;

            snippetActiveRequests++;
            startSnippetRequest(request);
        }
    }

    // Returns cached text immediately, coalesces duplicate requests, and limits
    // the remaining non-blocking stat/head jobs to two concurrent processes.
    function readLocalTextSnippet(filePath, callback) {
        var path = Utils.decodeLocalPath(filePath);
        path = path.trim();
        if (!path) {
            callback("", 0);
            return;
        }

        var cached = snippetCache[path];
        if (cached && Date.now() - cached.cachedAt < snippetCacheTtlMs) {
            touchSnippetCacheKey(path);
            callback(cached.content, cached.bytes);
            return;
        }

        if (snippetPendingCallbacks[path]) {
            snippetPendingCallbacks[path].push(callback);
            return;
        }

        snippetPendingCallbacks[path] = [callback];
        snippetRequestStartedAt[path] = Date.now();
        snippetQueue.push({ path: path });
        pumpSnippetQueue();
    }

    Timer {
        id: historySaveTimer
        interval: 250
        repeat: false
        onTriggered: {
            if (logicRoot.pendingHistoryJson !== "") {
                logicRoot.plasmoidConfig.searchHistory = logicRoot.pendingHistoryJson
                logicRoot.pendingHistoryJson = ""
            }
        }
    }

    Timer {
        id: pinnedSaveTimer
        interval: 250
        repeat: false
        onTriggered: {
            if (logicRoot.pendingPinnedJson !== "") {
                logicRoot.plasmoidConfig.pinnedItems = logicRoot.pendingPinnedJson
                logicRoot.pendingPinnedJson = ""
            }
        }
    }

    Timer {
        id: telemetrySaveTimer
        interval: 10000
        repeat: false
        onTriggered: logicRoot.flushTelemetry()
    }

    Component.onCompleted: {
        loadHistory();
        loadPinned();
        loadCategorySettings();
        loadRSS();
        loadWeatherCache();
        if (rssEnabled || rssSources.length > 0)
            updateCombinedCache(false);
        // Initial sync check is feature-gated; a disabled RSS setup should not
        // schedule even a no-op maintenance turn at startup.
        if (rssEnabled && rssSources.length > 0) {
            Qt.callLater(() => {
                checkAndSyncRSS();
            });
        }
    }
    // Global DataSource for shell commands
    Plasma5Support.DataSource {
        id: globalShellSource

        engine: "executable"
        connectedSources: []
        onNewData: (source, data) => {
            disconnectSource(source);
        }
    }

    // ===== ICON CHECK TIMER =====
    Timer {
        id: iconCheckTimer

        property string uuid
        property string filePath
        property string decoration
        property string category

        interval: 1000
        repeat: false
        onTriggered: {
            if (!uuid)
                return ;

            /// Only check if it has a file path
            if (filePath && filePath.toString().indexOf("file://") === 0) {
                // If decoration is broken (QIcon()) or missing
                if (decoration === "QIcon()" || decoration === "") {
                    // Use the folder icon until richer metadata is available.
                    var isFolder = Utils.isFolderCategory(category, filePath, decoration);
                    if (isFolder) {
                        var updatedHistory = HistoryManager.updateItemIcon(searchHistory, uuid, "folder");
                        if (updatedHistory) {
                            searchHistory = updatedHistory
                            saveHistory();
                        }
                    }
                    // Avoid spawning a shell process just to inspect .directory;
                    // the stable folder fallback is sufficient for history.
                }
            }
        }
    }

    Plasma5Support.DataSource {
        id: manCheckSource

        engine: "executable"
        connectedSources: []
        onNewData: (source, data) => {
            if (data["exit code"] !== undefined) {
                logicRoot.manInstalled = (data["exit code"] === 0);
                logicRoot.manCheckCompleted = true;
                logicRoot.manCheckPending = false;
                disconnectSource(source);
            }
        }
    }

    Plasma5Support.DataSource {
        id: executable

        property var callbacks: ({})

        engine: "executable"
        connectedSources: []
        onNewData: (source, data) => {
            var stdout = data["stdout"] || "";
            var exitCode = data["exit code"];
            var isFinished = (exitCode !== undefined);

            var callback = callbacks[source];

            if (callback) {
                callback(stdout, isFinished, exitCode);

                if (isFinished) {
                    delete callbacks[source];
                    disconnectSource(source);
                }
            } else if (isFinished) {
                disconnectSource(source);
            }
        }
    }

    Timer {
        id: processQueueTimer

        interval: 1
        repeat: false
        running: false
        onTriggered: logicRoot.pumpRssQueue()
    }

    Timer {
        id: backgroundSchedulerTimer

        // One wake-up services both RSS and weather maintenance.
        interval: 60000
        running: rssEnabled || !!plasmoidConfig.weatherEnabled
        repeat: true
        onTriggered: {
            if (rssEnabled)
                checkAndSyncRSS();
            logicRoot.backgroundMaintenanceRequested();
        }
    }

    // Watch for config changes (source addition/removal)
    Connections {
        function onCategorySettingsChanged() {
            loadCategorySettings();
        }

        function onRssSourcesChanged() {
            if (lastPersistedRssSources && plasmoidConfig.rssSources === lastPersistedRssSources) {
                lastPersistedRssSources = "";
                loadRSS();
                return;
            }
            loadRSS();
            if (rssEnabled)
                syncAllRSS();
            else {
                rssCache = [];
                rssTickerEntries = [];
            }
        }

        function onRssEnabledChanged() {
            if (rssEnabled)
                syncAllRSS();
            else {
                rssCache = [];
                rssTickerEntries = [];
            }
        }

        target: plasmoidConfig
    }

    Component.onDestruction: {
        if (pendingHistoryJson !== "") plasmoidConfig.searchHistory = pendingHistoryJson
        if (pendingPinnedJson !== "") plasmoidConfig.pinnedItems = pendingPinnedJson
        flushTelemetry()
        if (executable) {
            executable.callbacks = {};
        }
    }
}
