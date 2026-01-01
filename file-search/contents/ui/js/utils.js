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
        return (trFunc ? trFunc("today") : "Today") + " " + timeStr
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
