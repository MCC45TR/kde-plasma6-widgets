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
    // Clone array to trigger Update
    var newHistory = historyArray.slice(0)

    // Determine naturally if it's an application based on category or file path
    var catLower = (category || "").toString().toLowerCase()
    var isApp = catLower === "uygulamalar" || catLower === "applications" || catLower === "apps" ||
        catLower === "sistem ayarları" || catLower === "system settings" ||
        (filePath && filePath.toString().indexOf(".desktop") !== -1) ||
        (matchId && matchId.toString().indexOf(".desktop") !== -1)

    // Fix missing or invalid filePath for apps if matchId contains .desktop
    // This fixes the issue where apps appear in history but don't launch directly
    if (isApp && (!filePath || filePath === "applications") && matchId && matchId.toString().indexOf(".desktop") !== -1) {
        // If matchId looks like a path or a valid URL, use it as filePath
        if (matchId.indexOf("/") !== -1 || matchId.indexOf("applications:") === 0 || matchId.indexOf("file://") === 0) {
            filePath = matchId
        }
    }

    // Determine source type
    var detectedSourceType = sourceType || detectSourceType(category, isApp, filePath)

    // Deduplication: Check if already exists (by matchId or display)
    for (var i = 0; i < newHistory.length; i++) {
        var existing = newHistory[i]
        if ((matchId && existing.matchId === matchId) || existing.display === display) {
            // Move to top and update timestamp
            var item = newHistory.splice(i, 1)[0]
            item.timestamp = Date.now()
            item.queryText = queryText || item.queryText || display
            if (filePath) item.filePath = filePath // Update path if provided

            // Critical fix: Update category and isApplication for existing items
            item.isApplication = isApp
            item.category = category || item.category
            item.sourceType = detectedSourceType

            console.log("FileSearch [History]: Updated Item ->", JSON.stringify(item, null, 2))

            newHistory.unshift(item)
            return newHistory
        }
    }

    // Create new item object
    var newItem = {
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
    }

    console.log("FileSearch [History]: Added New Item ->", JSON.stringify(newItem, null, 2))

    // Add new item
    newHistory.unshift(newItem)

    // Limit to max items
    if (newHistory.length > maxItems) {
        newHistory = newHistory.slice(0, maxItems)
    }

    return newHistory
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

// Update icon of an item by UUID
function updateItemIcon(historyArray, uuid, newIcon) {
    for (var i = 0; i < historyArray.length; i++) {
        if (historyArray[i].uuid === uuid) {
            historyArray[i].decoration = newIcon;
            return true;
        }
    }
    return false;
}

// Clear all history
function clearHistory() {
    return []
}

// Remove single item by UUID
function removeFromHistory(historyArray, uuid) {
    return historyArray.filter(function (item) {
        return item.uuid !== uuid
    })
}
