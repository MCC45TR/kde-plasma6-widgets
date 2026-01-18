// PinnedManager.js - Pinned items management for File Search Widget
// Supports activity-aware pinning
//
// NOTE: generateUUID is duplicated from utils.js.
// This is intentional - QML does not support imports between JS modules.
// If updating this function, also update utils.js.

// UUID Generator (duplicated from utils.js)
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
            // Already pinned for this activity
            return pinnedArray
        }
    }

    // Create pinned item
    var pinnedItem = {
        uuid: generateUUID(),
        display: item.display || "",
        decoration: item.decoration || "application-x-executable",
        category: item.category || "Diğer",
        matchId: item.matchId || item.display,
        filePath: item.filePath || item.url || "",
        activityId: activityId || "global", // "global" means all activities
        pinnedAt: Date.now()
    }

    // Add to beginning
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

// Toggle pin state
function togglePin(pinnedArray, item, activityId) {
    if (isPinned(pinnedArray, item.matchId, activityId)) {
        return unpinItem(pinnedArray, item.matchId, activityId)
    } else {
        return pinItem(pinnedArray, item, activityId)
    }
}

// Get pin info for an item
function getPinInfo(pinnedArray, matchId, activityId) {
    for (var i = 0; i < pinnedArray.length; i++) {
        var item = pinnedArray[i]
        if (item.matchId === matchId) {
            if (!activityId || item.activityId === "global" || item.activityId === activityId) {
                return item
            }
        }
    }
    return null
}

// Reorder pinned items (move from oldIndex to newIndex)
function reorderPinned(pinnedArray, fromIndex, toIndex) {
    if (fromIndex < 0 || fromIndex >= pinnedArray.length) return pinnedArray
    if (toIndex < 0 || toIndex >= pinnedArray.length) return pinnedArray
    if (fromIndex === toIndex) return pinnedArray

    var newArray = pinnedArray.slice() // Create a copy
    var item = newArray.splice(fromIndex, 1)[0] // Remove from old position
    newArray.splice(toIndex, 0, item) // Insert at new position

    return newArray
}

// Move pinned item by matchId to a new index
function movePinnedItem(pinnedArray, matchId, newIndex) {
    var currentIndex = -1
    for (var i = 0; i < pinnedArray.length; i++) {
        if (pinnedArray[i].matchId === matchId) {
            currentIndex = i
            break
        }
    }

    if (currentIndex === -1) return pinnedArray
    return reorderPinned(pinnedArray, currentIndex, newIndex)
}
