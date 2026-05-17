// SimilarityUtils.js - Lightweight string similarity utilities for File Search Widget
// Optimized for real-time search result ranking without expensive algorithms

/**
 * Fast similarity score (0-1, higher is more similar)
 * Uses indexOf-based matching instead of Levenshtein distance for performance.
 * This is called inside sort comparators, so it must be O(1) or O(n) at most.
 * @param {string} query - Search query
 * @param {string} target - Target string to compare
 * @returns {number} - Similarity score between 0 and 1
 */
function similarityScore(query, target) {
    if (!query || !target) return 0;

    var q = query.toLowerCase();
    var t = target.toLowerCase();

    // Exact match
    if (t === q) return 1.0;

    // Starts with query
    if (t.indexOf(q) === 0) return 0.95;

    // Contains query as substring
    var idx = t.indexOf(q);
    if (idx !== -1) {
        // Earlier position = better match
        return 0.85 - (idx * 0.01);
    }

    // Check if all query characters appear in order (fuzzy match)
    var qi = 0;
    for (var ti = 0; ti < t.length && qi < q.length; ti++) {
        if (t.charAt(ti) === q.charAt(qi)) qi++;
    }
    if (qi === q.length) {
        // All chars found in order — weak match
        return 0.3 + (q.length / t.length) * 0.3;
    }

    // Word-initial match: check if query matches first letters of words
    var words = t.split(/[\s\-_\.]+/);
    var initials = "";
    for (var w = 0; w < words.length; w++) {
        if (words[w].length > 0) initials += words[w].charAt(0);
    }
    if (initials.indexOf(q) !== -1) return 0.6;

    return 0;
}

/**
 * Sort results by similarity to query text
 * Pre-computes scores to avoid redundant calculation during sort
 * @param {Array} results - Array of result objects with 'display' property
 * @param {string} queryText - The search query
 * @returns {Array} - Sorted results
 */
function sortBySimilarity(results, queryText) {
    if (!queryText || queryText.length === 0) return results;

    // Pre-compute scores (avoids recalculating in comparator)
    var scored = new Array(results.length);
    for (var i = 0; i < results.length; i++) {
        var displayText = results[i].display || results[i].name || "";
        scored[i] = {
            item: results[i],
            score: similarityScore(queryText, displayText)
        };
    }

    scored.sort(function (a, b) {
        return b.score - a.score;
    });

    var sorted = new Array(scored.length);
    for (var j = 0; j < scored.length; j++) {
        sorted[j] = scored[j].item;
    }
    return sorted;
}

/**
 * Combined priority and similarity sort
 * Pre-computes all scores before sorting to avoid O(n² * m) complexity
 * @param {Array} results - Array of result objects
 * @param {string} queryText - The search query
 * @param {Object} categorySettings - Category settings with priorities
 * @param {function} getPriorityFunc - Function to get priority for a category
 * @returns {Array} - Sorted results
 */
function sortByPriorityAndSimilarity(results, queryText, categorySettings, getPriorityFunc) {
    if (!results || results.length === 0) return results;

    var hasQuery = queryText && queryText.length > 0;

    // Pre-compute all scores and priorities ONCE
    var scored = new Array(results.length);
    for (var i = 0; i < results.length; i++) {
        var item = results[i];
        var cat = item.category || "Other";
        var prio = getPriorityFunc(categorySettings, cat);
        var score = 0;

        if (hasQuery) {
            var displayText = item.display || item.name || "";
            score = similarityScore(queryText, displayText);

            // For RSS feeds, also check indexed content (weighted less)
            if (cat === "RSS" && item.indexedContent) {
                var contentScore = similarityScore(queryText, item.indexedContent);
                if (contentScore * 0.8 > score) {
                    score = contentScore * 0.8;
                }
            }
        }

        scored[i] = {
            item: item,
            priority: prio,
            score: score
        };
    }

    scored.sort(function (a, b) {
        // First sort by priority
        if (a.priority !== b.priority) {
            return a.priority - b.priority;
        }
        // Then by pre-computed score
        return b.score - a.score;
    });

    var sorted = new Array(scored.length);
    for (var j = 0; j < scored.length; j++) {
        sorted[j] = scored[j].item;
    }
    return sorted;
}
