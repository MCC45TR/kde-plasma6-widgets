// SimilarityUtils.js - Lightweight string similarity utilities for File Search Widget
// Optimized for real-time search result ranking without expensive algorithms

function foldCase(value) {
    var text = String(value || "").toLocaleLowerCase().replace(/\u0307/g, "");
    if (text.normalize) {
        try {
            text = text.normalize("NFKD").replace(/[\u0300-\u036f]/g, "");
        } catch (e) {
        }
    }
    return text;
}

function normalizedWords(value) {
    return foldCase(value).replace(/[\s._\-\/\\:;,+()[\]{}]+/g, " ").trim();
}

function wordInitials(value) {
    var words = normalizedWords(value).split(" ");
    var initials = "";
    for (var i = 0; i < words.length; i++) {
        if (words[i])
            initials += words[i].charAt(0);
    }
    return initials;
}

function orderedSubsequenceScore(query, target) {
    var qi = 0;
    var first = -1;
    var previous = -1;
    var gap = 0;
    var boundaryHits = 0;
    for (var ti = 0; ti < target.length && qi < query.length; ti++) {
        if (target.charAt(ti) !== query.charAt(qi))
            continue;
        if (first === -1)
            first = ti;
        if (previous !== -1)
            gap += Math.max(0, ti - previous - 1);
        if (ti === 0 || /[\s._\-/]/.test(target.charAt(ti - 1)))
            boundaryHits++;
        previous = ti;
        qi++;
    }
    if (qi !== query.length)
        return 0;
    var density = query.length / Math.max(query.length, query.length + gap);
    var coverage = query.length / Math.max(query.length, target.length);
    var boundary = boundaryHits / query.length;
    return Math.min(0.78, 0.28 + density * 0.25 + coverage * 0.15 + boundary * 0.1 - Math.min(first, 20) * 0.004);
}

function boundedDamerauDistance(left, right, maximum) {
    if (Math.abs(left.length - right.length) > maximum)
        return maximum + 1;
    var previousPrevious = null;
    var previous = new Array(right.length + 1);
    for (var j = 0; j <= right.length; j++)
        previous[j] = j;
    for (var i = 1; i <= left.length; i++) {
        var current = new Array(right.length + 1);
        current[0] = i;
        var rowMinimum = current[0];
        for (var k = 1; k <= right.length; k++) {
            var cost = left.charAt(i - 1) === right.charAt(k - 1) ? 0 : 1;
            current[k] = Math.min(current[k - 1] + 1, previous[k] + 1, previous[k - 1] + cost);
            if (previousPrevious && i > 1 && k > 1
                    && left.charAt(i - 1) === right.charAt(k - 2)
                    && left.charAt(i - 2) === right.charAt(k - 1)) {
                current[k] = Math.min(current[k], previousPrevious[k - 2] + 1);
            }
            rowMinimum = Math.min(rowMinimum, current[k]);
        }
        if (rowMinimum > maximum)
            return maximum + 1;
        previousPrevious = previous;
        previous = current;
    }
    return previous[right.length];
}

function typoScore(query, target) {
    if (query.length < 4 || query.length > 32 || target.length > 48)
        return 0;
    var maximum = query.length >= 8 ? 2 : 1;
    var distance = boundedDamerauDistance(query, target, maximum);
    return distance <= maximum ? 0.76 - distance * 0.09 : 0;
}

/**
 * Fast similarity score (0-1, higher is more similar)
 * Pre-lowercased version for optimal performance inside loops.
 * @param {string} q - Pre-lowercased search query
 * @param {string} t - Pre-lowercased target string to compare
 * @returns {number} - Similarity score between 0 and 1
 */
function similarityScoreParsed(q, t) {
    if (!q || !t) return 0;
    // Exact match
    if (t === q) return 1.0;

    // Contains query as substring (including starts with)
    var idx = t.indexOf(q);
    if (idx === 0) return 0.93 + Math.min(0.06, q.length / t.length * 0.06);
    if (idx !== -1) {
        // Earlier position = better match
        return Math.max(0.5, 0.85 - (idx * 0.01));
    }

    var words = normalizedWords(t).split(" ");
    for (var w = 0; w < words.length; w++) {
        if (words[w].indexOf(q) === 0)
            return 0.9 - Math.min(w, 8) * 0.015;
    }

    var initials = wordInitials(t);
    if (initials === q) return 0.86;
    if (initials.indexOf(q) === 0) return 0.8;

    var subsequence = orderedSubsequenceScore(q, t);
    var bestTypo = typoScore(q, normalizedWords(t));
    for (var i = 0; i < words.length && i < 12; i++)
        bestTypo = Math.max(bestTypo, typoScore(q, words[i]));
    if (bestTypo > subsequence)
        return bestTypo;
    if (subsequence > 0)
        return subsequence;

    return 0;
}

function pathBasename(value) {
    var path = foldCase(value).split(/[?#]/)[0];
    var slash = path.lastIndexOf("/");
    return slash === -1 ? path : path.substring(slash + 1);
}

function withoutExtension(value) {
    var dot = value.lastIndexOf(".");
    return dot > 0 ? value.substring(0, dot) : value;
}

function tokenCoverageScore(query, fields) {
    var tokens = normalizedWords(query).split(" ");
    if (tokens.length < 2)
        return 0;
    var haystack = normalizedWords(fields.join(" "));
    var matched = 0;
    var cursor = 0;
    var ordered = true;
    for (var i = 0; i < tokens.length; i++) {
        if (!tokens[i])
            continue;
        var position = haystack.indexOf(tokens[i]);
        if (position !== -1) {
            matched++;
            if (position < cursor)
                ordered = false;
            cursor = position + tokens[i].length;
        }
    }
    if (matched !== tokens.length)
        return matched / tokens.length * 0.48;
    return ordered ? 0.91 : 0.84;
}

function advancedResultScore(query, item) {
    if (typeof item._fixedRelevance === "number")
        return item._fixedRelevance;
    var q = foldCase(query);
    var display = item._normalizedDisplay !== undefined ? item._normalizedDisplay : foldCase(item.display || item.name || "");
    var url = item._normalizedUrl !== undefined ? item._normalizedUrl : foldCase(item.url || "");
    var basename = withoutExtension(pathBasename(url));
    var subtext = item._normalizedSubtext !== undefined ? item._normalizedSubtext : foldCase(item.subtext || "");
    var category = item._normalizedCategory !== undefined ? item._normalizedCategory : foldCase(item.category || "");
    var score = similarityScoreParsed(q, display);
    if (basename)
        score = Math.max(score, Math.min(0.99, similarityScoreParsed(q, basename) + 0.025));
    score = Math.max(score, similarityScoreParsed(q, pathBasename(url)) * 0.94);
    score = Math.max(score, similarityScoreParsed(q, subtext) * 0.76);
    score = Math.max(score, similarityScoreParsed(q, category) * 0.55);
    score = Math.max(score, tokenCoverageScore(q, [display, basename, subtext]) );
    if (item._isPinned)
        score = Math.min(1, score + 0.035);
    return score;
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
                score = advancedResultScore(q, item);

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
        // Relevance must win across categories; category priority is the stable
        // tie-breaker, not a reason to bury an exact match.
        if (hasQuery && a.score !== b.score)
            return b.score - a.score;
        if (a.priority !== b.priority)
            return a.priority - b.priority;
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
