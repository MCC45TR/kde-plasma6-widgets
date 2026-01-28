// PinnedManager.js - Pinned items management for File Search Widget
// Supports activity-aware pinning

// UUID Generator
function generateUUID() {
    return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function (c) {
        var r = Math.random() * 16 | 0, v = c == 'x' ? r : (r & 0x3 | 0x8);
        return v.toString(16);
    });
}

// Load pinned items from configuration
function loadPinned(configValue) {
    try {
        var str = configValue || "[]"
        return JSON.parse(str)
    } catch (e) {
        console.log("PinnedManager: Error loading pinned items:", e)
        return []
    }
}

// Save pinned items to JSON string
function savePinned(pinnedArray) {
    return JSON.stringify(pinnedArray)
}

// Pin an item
function pinItem(pinnedArray, item, activityId) {
    // Check if already pinned
    for (var i = 0; i < pinnedArray.length; i++) {
        var existing = pinnedArray[i]
        if (existing.matchId === item.matchId && existing.activityId === activityId) {
            return pinnedArray
        }
    }

    // Create pinned item
    var pinnedItem = {
        uuid: generateUUID(),
        display: item.display || item.name || "",
        decoration: item.decoration || item.icon || "application-x-executable",
        category: item.category || "Other",
        matchId: item.matchId || item.entryPath || item.url || item.display,
        filePath: item.filePath || item.url || "",
        activityId: activityId || "global",
        pinnedAt: Date.now()
    }

    pinnedArray.unshift(pinnedItem)
    return pinnedArray
}

// Unpin an item
function unpinItem(pinnedArray, matchId, activityId) {
    return pinnedArray.filter(function (item) {
        if (activityId) {
            return !(item.matchId === matchId && item.activityId === activityId)
        }
        return item.matchId !== matchId
    })
}

// Check if item is pinned
function isPinned(pinnedArray, matchId, activityId) {
    for (var i = 0; i < pinnedArray.length; i++) {
        var item = pinnedArray[i]
        if (item.matchId === matchId) {
            if (!activityId || item.activityId === "global" || item.activityId === activityId) {
                return true
            }
        }
    }
    return false
}

// Get pinned items for specific activity (includes global pins)
function getPinnedForActivity(pinnedArray, activityId) {
    return pinnedArray.filter(function (item) {
        return item.activityId === "global" || item.activityId === activityId
    })
}

// Reorder pinned items
function reorderPinned(pinnedArray, fromIndex, toIndex) {
    if (fromIndex < 0 || fromIndex >= pinnedArray.length) return pinnedArray
    if (toIndex < 0 || toIndex >= pinnedArray.length) return pinnedArray
    if (fromIndex === toIndex) return pinnedArray

    var newArray = pinnedArray.slice()
    var item = newArray.splice(fromIndex, 1)[0]
    newArray.splice(toIndex, 0, item)

    return newArray
}
