// CategoryManager.js - Category settings management for File Search Widget
// Handles visibility, priority, and custom icons for categories

// Default category priorities (lower = higher priority)
var defaultPriorities = {
    "Applications": 1,
    "Uygulamalar": 1,
    "Files": 2,
    "Dosyalar": 2,
    "Documents": 3,
    "Belgeler": 3,
    "Folders": 4,
    "Klasörler": 4,
    "Calculator": 5,
    "Hesap Makinesi": 5,
    "Web": 6,
    "Other": 100,
    "Diğer": 100
}

// Load category settings from configuration
function loadCategorySettings(configValue) {
    try {
        var str = configValue || "{}"
        return JSON.parse(str)
    } catch (e) {
        console.log("CategoryManager: Error loading category settings:", e)
        return {}
    }
}

// Save category settings to JSON string
function saveCategorySettings(settings) {
    return JSON.stringify(settings)
}

// Ensure category has a settings object
function ensureCategoryExists(settings, categoryName) {
    if (!settings[categoryName]) {
        settings[categoryName] = {
            visible: true,
            priority: defaultPriorities[categoryName] || 50,
            icon: null
        }
    }
    return settings
}

// Set category visibility
function setCategoryVisibility(settings, categoryName, visible) {
    settings = ensureCategoryExists(settings, categoryName)
    settings[categoryName].visible = visible
    return settings
}

// Get category visibility
function isCategoryVisible(settings, categoryName) {
    if (!settings[categoryName]) {
        return true // Default visible
    }
    return settings[categoryName].visible !== false
}

// Set category priority (lower number = higher priority)
function setCategoryPriority(settings, categoryName, priority) {
    settings = ensureCategoryExists(settings, categoryName)
    settings[categoryName].priority = priority
    return settings
}

// Get category priority
function getCategoryPriority(settings, categoryName) {
    if (settings[categoryName] && typeof settings[categoryName].priority === 'number') {
        return settings[categoryName].priority
    }
    return defaultPriorities[categoryName] || 50
}

// Set custom icon for category
function setCategoryIcon(settings, categoryName, iconName) {
    settings = ensureCategoryExists(settings, categoryName)
    settings[categoryName].icon = iconName
    return settings
}

// Get effective icon (custom or default)
function getEffectiveIcon(settings, categoryName, defaultIcon) {
    if (settings[categoryName] && settings[categoryName].icon) {
        return settings[categoryName].icon
    }
    return defaultIcon
}

// Sort categories by priority
function sortCategories(categories, settings) {
    return categories.slice().sort(function (a, b) {
        var prioA = getCategoryPriority(settings, a.categoryName)
        var prioB = getCategoryPriority(settings, b.categoryName)
        return prioA - prioB
    })
}

// Filter out hidden categories
function filterHiddenCategories(categories, settings) {
    return categories.filter(function (cat) {
        return isCategoryVisible(settings, cat.categoryName)
    })
}

// Process categories: filter hidden and sort by priority
function processCategories(categories, settings) {
    var visible = filterHiddenCategories(categories, settings)
    return sortCategories(visible, settings)
}

// Get all known categories from result set
function extractCategories(categorizedData) {
    var cats = []
    for (var i = 0; i < categorizedData.length; i++) {
        cats.push(categorizedData[i].categoryName)
    }
    return cats
}

// Move category up in priority
function moveCategoryUp(settings, categoryName, allCategories) {
    var sorted = allCategories.slice().sort(function (a, b) {
        return getCategoryPriority(settings, a) - getCategoryPriority(settings, b)
    })

    var idx = sorted.indexOf(categoryName)
    if (idx > 0) {
        var prevCat = sorted[idx - 1]
        var prevPrio = getCategoryPriority(settings, prevCat)
        var currentPrio = getCategoryPriority(settings, categoryName)

        // Swap priorities
        settings = setCategoryPriority(settings, categoryName, prevPrio)
        settings = setCategoryPriority(settings, prevCat, currentPrio)
    }
    return settings
}

// Move category down in priority
function moveCategoryDown(settings, categoryName, allCategories) {
    var sorted = allCategories.slice().sort(function (a, b) {
        return getCategoryPriority(settings, a) - getCategoryPriority(settings, b)
    })

    var idx = sorted.indexOf(categoryName)
    if (idx < sorted.length - 1) {
        var nextCat = sorted[idx + 1]
        var nextPrio = getCategoryPriority(settings, nextCat)
        var currentPrio = getCategoryPriority(settings, categoryName)

        // Swap priorities
        settings = setCategoryPriority(settings, categoryName, nextPrio)
        settings = setCategoryPriority(settings, nextCat, currentPrio)
    }
    return settings
}

// Apply priority sorting to individual results (not categories)
// Use this for sorting raw search results before display
function applyPriorityToResults(results, settings) {
    if (!results || results.length === 0) return results

    return results.slice().sort(function (a, b) {
        var catA = a.category || a.type || "Other"
        var catB = b.category || b.type || "Other"

        var prioA = getCategoryPriority(settings, catA)
        var prioB = getCategoryPriority(settings, catB)

        return prioA - prioB
    })
}

// Reorder categories based on new order (for drag-and-drop UI)
// Assigns new priority values based on position in array
function reorderCategories(settings, orderedCategoryNames) {
    for (var i = 0; i < orderedCategoryNames.length; i++) {
        settings = setCategoryPriority(settings, orderedCategoryNames[i], i + 1)
    }
    return settings
}

// Get sorted category names based on current priorities
function getSortedCategoryNames(settings, categoryNames) {
    return categoryNames.slice().sort(function (a, b) {
        return getCategoryPriority(settings, a) - getCategoryPriority(settings, b)
    })
}
