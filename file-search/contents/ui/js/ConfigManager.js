// ConfigManager.js - Configuration management for File Search Widget
// Provides profile-based defaults and validation for widget settings

// User profile definitions
var PROFILES = {
    MINIMAL: 0,
    DEVELOPER: 1,
    POWER_USER: 2
};

// Display mode definitions
var DISPLAY_MODES = {
    BUTTON: 0,
    MEDIUM: 1,
    WIDE: 2,
    EXTRA_WIDE: 3
};

// View mode definitions
var VIEW_MODES = {
    LIST: 0,
    TILE: 1
};

// Profile-based default configurations
var PROFILE_DEFAULTS = {
    0: { // Minimal
        displayMode: DISPLAY_MODES.MEDIUM,
        viewMode: VIEW_MODES.LIST,
        iconSize: 32,
        listIconSize: 18,
        previewEnabled: false,
        debugOverlay: false,
        maxHistoryItems: 10
    },
    1: { // Developer
        displayMode: DISPLAY_MODES.WIDE,
        viewMode: VIEW_MODES.LIST,
        iconSize: 48,
        listIconSize: 22,
        previewEnabled: true,
        debugOverlay: true,
        maxHistoryItems: 50
    },
    2: { // Power User
        displayMode: DISPLAY_MODES.EXTRA_WIDE,
        viewMode: VIEW_MODES.TILE,
        iconSize: 64,
        listIconSize: 24,
        previewEnabled: true,
        debugOverlay: false,
        maxHistoryItems: 30
    }
};

// Get default config for a profile
function getProfileDefaults(profileId) {
    return PROFILE_DEFAULTS[profileId] || PROFILE_DEFAULTS[0];
}

// Validate display mode
function isValidDisplayMode(mode) {
    return mode >= 0 && mode <= 3;
}

// Validate view mode
function isValidViewMode(mode) {
    return mode === 0 || mode === 1;
}

// Validate icon size (min 16, max 128)
function isValidIconSize(size) {
    return size >= 16 && size <= 128;
}

// Validate list icon size (min 12, max 64)
function isValidListIconSize(size) {
    return size >= 12 && size <= 64;
}

// Sanitize configuration object
function sanitizeConfig(config) {
    var sanitized = {};

    sanitized.displayMode = isValidDisplayMode(config.displayMode)
        ? config.displayMode
        : DISPLAY_MODES.MEDIUM;

    sanitized.viewMode = isValidViewMode(config.viewMode)
        ? config.viewMode
        : VIEW_MODES.LIST;

    sanitized.iconSize = isValidIconSize(config.iconSize)
        ? config.iconSize
        : 48;

    sanitized.listIconSize = isValidListIconSize(config.listIconSize)
        ? config.listIconSize
        : 22;

    sanitized.previewEnabled = typeof config.previewEnabled === 'boolean'
        ? config.previewEnabled
        : true;

    sanitized.debugOverlay = typeof config.debugOverlay === 'boolean'
        ? config.debugOverlay
        : false;

    sanitized.userProfile = (config.userProfile >= 0 && config.userProfile <= 2)
        ? config.userProfile
        : 0;

    return sanitized;
}

// Check if a feature is enabled for the current profile
function isFeatureEnabled(profileId, featureName) {
    var features = {
        debug: [PROFILES.DEVELOPER],
        preview: [PROFILES.DEVELOPER, PROFILES.POWER_USER],
        advancedSearch: [PROFILES.DEVELOPER, PROFILES.POWER_USER],
        telemetry: [PROFILES.DEVELOPER],
        categoryPriority: [PROFILES.POWER_USER, PROFILES.DEVELOPER],
        activityPinning: [PROFILES.POWER_USER]
    };

    var allowedProfiles = features[featureName] || [];
    return allowedProfiles.indexOf(profileId) >= 0;
}

// Get recommended icon size based on display mode
function getRecommendedIconSize(displayMode, viewMode) {
    if (viewMode === VIEW_MODES.TILE) {
        switch (displayMode) {
            case DISPLAY_MODES.BUTTON: return 32;
            case DISPLAY_MODES.MEDIUM: return 48;
            case DISPLAY_MODES.WIDE: return 56;
            case DISPLAY_MODES.EXTRA_WIDE: return 64;
            default: return 48;
        }
    } else {
        return 22; // List mode always uses smaller icons
    }
}

// Get max history items based on profile
function getMaxHistoryItems(profileId) {
    var defaults = getProfileDefaults(profileId);
    return defaults.maxHistoryItems || 20;
}

// Apply profile defaults (for migration or reset)
function applyProfileDefaults(currentConfig, profileId) {
    var defaults = getProfileDefaults(profileId);
    return {
        displayMode: currentConfig.displayMode !== undefined ? currentConfig.displayMode : defaults.displayMode,
        viewMode: currentConfig.viewMode !== undefined ? currentConfig.viewMode : defaults.viewMode,
        iconSize: currentConfig.iconSize !== undefined ? currentConfig.iconSize : defaults.iconSize,
        listIconSize: currentConfig.listIconSize !== undefined ? currentConfig.listIconSize : defaults.listIconSize,
        previewEnabled: currentConfig.previewEnabled !== undefined ? currentConfig.previewEnabled : defaults.previewEnabled,
        debugOverlay: currentConfig.debugOverlay !== undefined ? currentConfig.debugOverlay : defaults.debugOverlay,
        userProfile: profileId
    };
}

// Export configuration as JSON (for backup/restore)
function exportConfig(config) {
    return JSON.stringify(sanitizeConfig(config), null, 2);
}

// Import configuration from JSON
function importConfig(jsonString) {
    try {
        var parsed = JSON.parse(jsonString);
        return sanitizeConfig(parsed);
    } catch (e) {
        console.log("ConfigManager: Failed to import config:", e);
        return null;
    }
}
