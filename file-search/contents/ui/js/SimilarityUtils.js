// SimilarityUtils.js - Lightweight string similarity utilities for File Search Widget
// Optimized for real-time search result ranking without expensive algorithms

function foldCase(value) {
    return String(value || "").toLocaleLowerCase().replace(/\u0307/g, "");
}

/**
 * Fast similarity score (0-1, higher is more similar)
 * Pre-lowercased version for optimal performance inside loops.
 * @param {string} q - Pre-lowercased search query
 * @param {string} t - Pre-lowercased target string to compare
 * @returns {number} - Similarity score between 0 and 1
 */
function similarityScoreParsed(q, t) {
    // Exact match
    if (t === q) return 1.0;

    // Contains query as substring (including starts with)
    var idx = t.indexOf(q);
    if (idx === 0) return 0.95;
    if (idx !== -1) {
        // Earlier position = better match
        return Math.max(0.5, 0.85 - (idx * 0.01));
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
    // Zero-allocation character-by-character scanner (O(L) time, O(1) space)
    var initials = "";
    var inWord = false;
    for (var i = 0; i < t.length; i++) {
        var c = t.charAt(i);
        if (c === " " || c === "-" || c === "_" || c === ".") {
            inWord = false;
        } else if (!inWord) {
            initials += c;
            inWord = true;
        }
    }
    if (initials.indexOf(q) !== -1) return 0.6;

    return 0;
}

/**
 * Public API wrapper for backward compatibility.
 * @param {string} query - Search query
 * @param {string} target - Target string to compare
 * @returns {number} - Similarity score
 */
function similarityScore(query, target) {
    if (!query || !target) return 0;
    return similarityScoreParsed(foldCase(query), foldCase(target));
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

    var q = foldCase(queryText);

    // Pre-compute scores (avoids recalculating in comparator)
    var scored = new Array(results.length);
    for (var i = 0; i < results.length; i++) {
        var displayText = foldCase(results[i].display || results[i].name || "");
        scored[i] = {
            item: results[i],
            score: similarityScoreParsed(q, displayText)
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
function sortByPriorityAndSimilarity(results, queryText, categorySettings, getPriorityFunc, maxResults, includeRssContent, options) {
    if (!results || results.length === 0) return results;

    options = options || {};
    var algorithm = Number(options.searchAlgorithm) || 0;
    var smartLimit = options.smartResultLimit !== false;
    var minimum = Math.max(0, Number(options.minResults) || 0);
    var hasQuery = queryText && queryText.length > 0;
    var q = hasQuery ? foldCase(queryText) : "";

    // Pre-compute all scores and priorities ONCE
    var scored = new Array(results.length);
    for (var i = 0; i < results.length; i++) {
        var item = results[i];
        var cat = item.category || "Other";
        var prio = (typeof item._categoryPriority === "number")
            ? item._categoryPriority
            : getPriorityFunc(categorySettings, cat);
        var score = 0;

        if (hasQuery) {
            var displayText = item._normalizedDisplay !== undefined
                ? item._normalizedDisplay
                : foldCase(item.display || item.name || "");
            if (algorithm === 1)
                score = displayText === q ? 1 : 0;
            else if (algorithm === 2)
                score = displayText.indexOf(q) === 0 ? (displayText === q ? 1 : 0.95) : 0;
            else
                score = similarityScoreParsed(q, displayText);

            // For RSS feeds, also check indexed content (weighted less)
            if (algorithm === 0 && includeRssContent && cat === "RSS" && item.indexedContent) {
                var contentText = item._normalizedIndexedContent !== undefined
                    ? item._normalizedIndexedContent
                    : item.indexedContent.toLowerCase();
                if (contentText.indexOf(q) !== -1) {
                    var contentScore = 0.5;
                    if (contentScore > score) {
                        score = contentScore;
                    }
                }
            }
        }

        scored[i] = {
            item: item,
            priority: prio,
            score: score,
            order: i
        };
    }

    function compareScored(a, b) {
        if (a.priority !== b.priority) {
            return a.priority - b.priority;
        }
        if (a.score !== b.score)
            return b.score - a.score;
        return a.order - b.order;
    }

    if (hasQuery && (algorithm !== 0 || smartLimit)) {
        var positiveCount = 0;
        for (var p = 0; p < scored.length; p++) {
            if (scored[p].score > 0)
                positiveCount++;
        }
        var zeroBudget = algorithm === 0 ? Math.max(0, minimum - positiveCount) : 0;
        var eligible = [];
        for (var e = 0; e < scored.length; e++) {
            if (scored[e].score > 0) {
                eligible.push(scored[e]);
            } else if (zeroBudget > 0) {
                eligible.push(scored[e]);
                zeroBudget--;
            }
        }
        scored = eligible;
    }

    var limit = Number(maxResults) || 0;
    if (limit > 0 && scored.length > limit) {
        // Keep the worst retained item at heap[0]. Each new candidate then
        // costs O(log limit), avoiding a full O(n log n) sort.
        var heap = [];

        function isWorse(a, b) {
            return compareScored(a, b) > 0;
        }

        function pushHeap(value) {
            heap.push(value);
            var child = heap.length - 1;
            while (child > 0) {
                var parent = Math.floor((child - 1) / 2);
                if (!isWorse(heap[child], heap[parent]))
                    break;
                var tmp = heap[parent];
                heap[parent] = heap[child];
                heap[child] = tmp;
                child = parent;
            }
        }

        function replaceWorst(value) {
            heap[0] = value;
            var parent = 0;
            while (true) {
                var left = parent * 2 + 1;
                var right = left + 1;
                var worst = parent;
                if (left < heap.length && isWorse(heap[left], heap[worst]))
                    worst = left;
                if (right < heap.length && isWorse(heap[right], heap[worst]))
                    worst = right;
                if (worst === parent)
                    break;
                var tmp = heap[parent];
                heap[parent] = heap[worst];
                heap[worst] = tmp;
                parent = worst;
            }
        }

        for (var h = 0; h < scored.length; h++) {
            if (heap.length < limit) {
                pushHeap(scored[h]);
            } else if (compareScored(scored[h], heap[0]) < 0) {
                replaceWorst(scored[h]);
            }
        }
        scored = heap;
    }

    scored.sort(compareScored);

    var sorted = new Array(scored.length);
    for (var j = 0; j < scored.length; j++) {
        sorted[j] = scored[j].item;
    }
    return sorted;
}
