// utils.js - Utility functions for File Search Widget

// UUID Generator - creates unique identifiers for history entries
function generateUUID() {
    return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
        var r = Math.random() * 16 | 0, v = c == 'x' ? r : (r & 0x3 | 0x8);
        return v.toString(16);
    });
}

// Format history timestamp for display
function formatHistoryTime(timestamp, trFunc) {
    if (!timestamp) return ""
    
    var now = new Date()
    var then = new Date(timestamp)
    var diffMs = now.getTime() - then.getTime()
    var diffDays = Math.floor(diffMs / (1000 * 60 * 60 * 24))
    
    var hours = then.getHours().toString().padStart(2, '0')
    var minutes = then.getMinutes().toString().padStart(2, '0')
    var timeStr = hours + ":" + minutes
    
    // Today
    if (now.toDateString() === then.toDateString()) {
        return (trFunc ? trFunc("Today") : "Today") + " " + timeStr
    }
    
    // Within last 6 days
    if (diffDays < 6) {
        return Qt.locale().dayName(then.getDay(), Locale.LongFormat) + " " + timeStr
    }
    
    // Older than 6 days
    return then.toLocaleDateString(Qt.locale(), Locale.ShortFormat) + " " + timeStr
}

// Detect source type from category
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

// Check if category is a primary result (calculator, unit, currency)
function isPrimaryCategory(category) {
    if (!category) return false
    return category.indexOf("Calculate") >= 0 || 
           category.indexOf("Hesapla") >= 0 ||
           category.indexOf("Unit") >= 0 ||
           category.indexOf("Birim") >= 0 ||
           category.indexOf("Currency") >= 0 ||
           category.indexOf("Döviz") >= 0
}

// Check if category is file-related
function isFileCategory(category) {
    if (!category) return false
    return category.indexOf("Dosya") >= 0 || 
           category.indexOf("Klasör") >= 0 || 
           category.indexOf("File") >= 0 || 
           category.indexOf("Folder") >= 0 ||
           category.indexOf("Document") >= 0 || 
           category.indexOf("Belge") >= 0
}

// Extract parent folder from file path
function getParentFolder(filePath) {
    if (!filePath) return ""
    var path = filePath.toString()
    if (path.startsWith("file://")) path = path.substring(7)
    var lastSlash = path.lastIndexOf("/")
    if (lastSlash > 0) {
        return path.substring(0, lastSlash)
    }
    return ""
}

// Get short parent name (just folder name, not full path)
function getShortParentName(filePath) {
    if (!filePath) return ""
    var path = filePath.toString()
    if (path.startsWith("file://")) path = path.substring(7)
    var lastSlash = path.lastIndexOf("/")
    if (lastSlash > 0) {
        var parentPath = path.substring(0, lastSlash)
        var parentSlash = parentPath.lastIndexOf("/")
        if (parentSlash >= 0) {
            return parentPath.substring(parentSlash + 1)
        }
        return parentPath
    }
    return ""
}

// Shell escape - wraps a string in single quotes with proper escaping.
// Prevents command injection when passing user-controlled values to shell commands.
// Single quotes prevent all interpretation except for embedded single quotes,
// which are handled by ending the quote, adding an escaped quote, and reopening.
function shellEscape(str) {
    if (str === undefined || str === null) return "''"
    return "'" + str.toString().replace(/'/g, "'\\''") + "'"
}

// Centralized app category detection.
// Used by HistoryManager, TileDataManager, SearchPopup to avoid duplicated logic.
// Checks both English and Turkish category names and .desktop file indicators.
function isAppCategory(category, filePath, matchId) {
    if (!category) return false
    var catLower = category.toString().toLowerCase()
    var isApp = catLower.indexOf("app") !== -1 || catLower.indexOf("uygulama") !== -1 || catLower.indexOf("program") !== -1 ||
                catLower.indexOf("ayar") !== -1 || catLower.indexOf("setting") !== -1 ||
                catLower.indexOf("oyun") !== -1 || catLower.indexOf("game") !== -1 ||
                catLower.indexOf("ofis") !== -1 || catLower.indexOf("office") !== -1 ||
                catLower.indexOf("sistem") !== -1 || catLower.indexOf("system") !== -1 ||
                catLower.indexOf("araç") !== -1 || catLower.indexOf("util") !== -1 ||
                catLower.indexOf("internet") !== -1 || catLower.indexOf("grafik") !== -1 || catLower.indexOf("graphic") !== -1 ||
                catLower.indexOf("geliştirme") !== -1 || catLower.indexOf("develop") !== -1 ||
                catLower.indexOf("ortam") !== -1 || catLower.indexOf("multimedia") !== -1 ||
                catLower.indexOf("eğitim") !== -1 || catLower.indexOf("educat") !== -1
    if (!isApp && filePath) {
        isApp = filePath.toString().indexOf(".desktop") !== -1
    }
    if (!isApp && matchId) {
        isApp = matchId.toString().indexOf(".desktop") !== -1
    }
    return isApp
}
