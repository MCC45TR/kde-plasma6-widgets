// TelemetryManager.js

// Default structure
function getEmptyStats() {
    return {
        totalSearches: 0,
        averageLatency: 0,
        totalLatencySum: 0, // Helper for moving average
        lastReset: new Date().toISOString(),
        backend: "Milou/KRunner"
    };
}

function loadStats(jsonString) {
    try {
        var stats = JSON.parse(jsonString);
        // Ensure structure validity
        if (!stats || typeof stats.totalSearches === 'undefined') {
            return getEmptyStats();
        }
        return stats;
    } catch (e) {
        return getEmptyStats();
    }
}

function recordSearch(currentJson, latencyMs) {
    var stats = loadStats(currentJson);

    stats.totalSearches = (stats.totalSearches || 0) + 1;
    stats.totalLatencySum = (stats.totalLatencySum || 0) + latencyMs;

    // Avoid division by zero
    if (stats.totalSearches > 0) {
        stats.averageLatency = Math.round(stats.totalLatencySum / stats.totalSearches);
    }

    stats.lastUpdated = new Date().toISOString();

    return JSON.stringify(stats);
}

function resetStats() {
    return JSON.stringify(getEmptyStats());
}

function getStatsObject(jsonString) {
    return loadStats(jsonString);
}
