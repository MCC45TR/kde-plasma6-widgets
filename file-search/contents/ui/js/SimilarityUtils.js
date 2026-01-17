// SimilarityUtils.js - String similarity utilities for File Search Widget
// Provides Levenshtein distance and similarity scoring for search result ranking

/**
 * Calculate Levenshtein distance between two strings
 * @param {string} str1 - First string
 * @param {string} str2 - Second string
 * @returns {number} - Edit distance
 */
function levenshteinDistance(str1, str2) {
    var s1 = str1.toLowerCase();
    var s2 = str2.toLowerCase();

    if (s1.length === 0) return s2.length;
    if (s2.length === 0) return s1.length;

    var matrix = [];

    // Initialize first column
    for (var i = 0; i <= s1.length; i++) {
        matrix[i] = [i];
    }

    // Initialize first row
    for (var j = 0; j <= s2.length; j++) {
        matrix[0][j] = j;
    }

    // Fill in the rest of the matrix
    for (var i = 1; i <= s1.length; i++) {
        for (var j = 1; j <= s2.length; j++) {
            if (s1.charAt(i - 1) === s2.charAt(j - 1)) {
                matrix[i][j] = matrix[i - 1][j - 1];
            } else {
                matrix[i][j] = Math.min(
                    matrix[i - 1][j - 1] + 1, // substitution
                    matrix[i][j - 1] + 1,     // insertion
                    matrix[i - 1][j] + 1      // deletion
                );
            }
        }
    }

    return matrix[s1.length][s2.length];
}

/**
 * Calculate normalized similarity score (0-1, higher is more similar)
 * @param {string} query - Search query
 * @param {string} target - Target string to compare
 * @returns {number} - Similarity score between 0 and 1
 */
function similarityScore(query, target) {
    if (!query || !target) return 0;

    var q = query.toLowerCase();
    var t = target.toLowerCase();

    // Exact match bonus
    if (t === q) return 1.0;

    // Starts with bonus
    if (t.indexOf(q) === 0) return 0.95;

    // Contains bonus
    if (t.indexOf(q) !== -1) return 0.85;

    // Levenshtein-based similarity
    var distance = levenshteinDistance(q, t);
    var maxLen = Math.max(q.length, t.length);
    var similarity = 1 - (distance / maxLen);

    return Math.max(0, similarity);
}

/**
 * Sort results by similarity to query text
 * Results with higher similarity come first
 * @param {Array} results - Array of result objects with 'display' property
 * @param {string} queryText - The search query
 * @returns {Array} - Sorted results
 */
function sortBySimilarity(results, queryText) {
    if (!queryText || queryText.length === 0) return results;

    return results.slice().sort(function (a, b) {
        var displayA = a.display || a.name || "";
        var displayB = b.display || b.name || "";

        var scoreA = similarityScore(queryText, displayA);
        var scoreB = similarityScore(queryText, displayB);

        return scoreB - scoreA; // Higher score first
    });
}

/**
 * Combined priority and similarity sort
 * First sorts by category priority, then by similarity within same priority
 * @param {Array} results - Array of result objects
 * @param {string} queryText - The search query
 * @param {Object} categorySettings - Category settings with priorities
 * @param {function} getPriorityFunc - Function to get priority for a category
 * @returns {Array} - Sorted results
 */
function sortByPriorityAndSimilarity(results, queryText, categorySettings, getPriorityFunc) {
    if (!results || results.length === 0) return results;

    return results.slice().sort(function (a, b) {
        var catA = a.category || "Other";
        var catB = b.category || "Other";

        var prioA = getPriorityFunc(categorySettings, catA);
        var prioB = getPriorityFunc(categorySettings, catB);

        // First, sort by priority
        if (prioA !== prioB) {
            return prioA - prioB;
        }

        // Same priority, sort by similarity
        if (queryText && queryText.length > 0) {
            var displayA = a.display || a.name || "";
            var displayB = b.display || b.name || "";

            var scoreA = similarityScore(queryText, displayA);
            var scoreB = similarityScore(queryText, displayB);

            return scoreB - scoreA; // Higher score first
        }

        return 0; // Preserve original order
    });
}
