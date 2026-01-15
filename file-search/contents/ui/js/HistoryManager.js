// HistoryManager.js - History management functions for File Search Widget
// Self-contained module with inline utility functions
//
// NOTE: generateUUID and detectSourceType are duplicated from utils.js.
// This is intentional - QML does not support imports between JS modules.
// If updating these functions, also update utils.js.

// UUID Generator (duplicated from utils.js)
function generateUUID() {
    return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function (c) {
        var r = Math.random() * 16 | 0, v = c == 'x' ? r : (r & 0x3 | 0x8);
        return v.toString(16);
    });
}

// Detect source type from category (duplicated from utils.js)
function detectSourceType(category, isApp, filePath) {
    if (isApp) {
        return "app"
    } else if (category && (category.indexOf("Calculate") >= 0 || category.indexOf("Hesapla") >= 0)) {
        return "calculator"
    } else if (filePath && filePath.length > 0) {
        return "file"
    } else {
        return "krunner"
    }
}

// Load history from configuration with migration support
function loadHistory(configValue) {
    try {
        var historyStr = configValue || "[]"
        var loaded = JSON.parse(historyStr)
        // Migrate old entries to new format
        return loaded.map(function (item) {
            if (!item.uuid) {
                item.uuid = generateUUID()
            }
            if (!item.sourceType) {
                item.sourceType = item.isApplication ? "app" : "krunner"
            }
            if (!item.queryText) {
                item.queryText = item.display
            }
            return item
        })
    } catch (e) {
        console.log("Error loading history:", e)
        return []
    }
}

// Add item to history with deduplication
function addToHistory(historyArray, display, decoration, category, matchId, filePath, sourceType, queryText, maxItems) {
    // Deduplication: Check if already exists (by matchId or display)
    for (var i = 0; i < historyArray.length; i++) {
        var existing = historyArray[i]
        if ((matchId && existing.matchId === matchId) || existing.display === display) {
            // Move to top and update timestamp
            var item = historyArray.splice(i, 1)[0]
            item.timestamp = Date.now()
            item.queryText = queryText || item.queryText || display
            historyArray.unshift(item)
            return historyArray
        }
    }

    // Determine if it's an application
    var isApp = category === "Uygulamalar" || category === "Applications"

    // Determine source type
    var detectedSourceType = sourceType || detectSourceType(category, isApp, filePath)

    // Add new item
    historyArray.unshift({
        uuid: generateUUID(),
        display: display,
        decoration: decoration || "application-x-executable",
        category: category || "Diğer",
        isApplication: isApp,
        matchId: matchId || "",
        filePath: filePath || "",
        sourceType: detectedSourceType,
        queryText: queryText || display,
        timestamp: Date.now()
    })

    // Limit to max items
    if (historyArray.length > maxItems) {
        historyArray = historyArray.slice(0, maxItems)
    }

    return historyArray
}

// Categorize history items into groups
function categorizeHistory(historyArray, appLabel, otherLabel) {
    var apps = []
    var others = []

    for (var i = 0; i < historyArray.length; i++) {
        var item = historyArray[i]
        if (item.isApplication) {
            apps.push(item)
        } else {
            others.push(item)
        }
    }

    var result = []
    if (apps.length > 0) {
        result.push({ categoryName: appLabel, items: apps })
    }
    if (others.length > 0) {
        result.push({ categoryName: otherLabel, items: others })
    }
    return result
}

// Clear all history
function clearHistory() {
    return []
}
