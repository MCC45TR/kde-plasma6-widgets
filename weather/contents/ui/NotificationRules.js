.pragma library

function hasValue(value) {
    return value !== undefined && value !== null
}

function weatherCode(item) {
    if (!item) return -1
    return hasValue(item.alert_code) ? item.alert_code : item.code
}

function findUpcoming(items, codeList, nowMs, horizonMs) {
    if (!items || items.length === 0) return null
    var horizonEnd = nowMs + horizonMs

    for (var i = 0; i < items.length; i++) {
        var item = items[i]
        if (!hasValue(item.timestamp) || item.timestamp < nowMs) continue
        if (item.timestamp > horizonEnd) break
        var code = weatherCode(item)
        if (codeList.indexOf(code) >= 0) return { code: code, startIndex: i }
    }
    return null
}

function formatTime(epochMs, utcOffsetSeconds) {
    var shifted = new Date(epochMs + (utcOffsetSeconds || 0) * 1000)
    return String(shifted.getUTCHours()).padStart(2, "0") + ":" + String(shifted.getUTCMinutes()).padStart(2, "0")
}

function analyzeEventDuration(items, startIndex, codeList) {
    if (!items || items.length === 0 || startIndex < 0 || startIndex >= items.length) {
        return { startTime: "--", endTime: "--", startTemp: 0, endTemp: 0, conditionName: "", totalPrecip: 0, maxProb: 0 }
    }

    var startItem = items[startIndex]
    var endIndex = startIndex
    for (var i = startIndex + 1; i < items.length; i++) {
        if (codeList.indexOf(weatherCode(items[i])) < 0) break
        endIndex = i
    }

    var totalPrecip = 0
    var maxProb = 0
    for (var k = startIndex; k <= endIndex; k++) {
        var item = items[k]
        if (hasValue(item.precipitation)) totalPrecip += Number(item.precipitation) || 0
        if (hasValue(item.precipitation_probability)) maxProb = Math.max(maxProb, Number(item.precipitation_probability) || 0)
    }

    var endItem = items[endIndex]
    var intervalMs = endItem.interval_ms || 60 * 60 * 1000
    var eventEnd = hasValue(endItem.timestamp) ? endItem.timestamp + intervalMs : NaN
    if (endIndex + 1 < items.length && hasValue(items[endIndex + 1].timestamp)) eventEnd = items[endIndex + 1].timestamp

    return {
        startTime: startItem.time || (hasValue(startItem.timestamp) ? formatTime(startItem.timestamp, startItem.timezone_offset) : "--"),
        endTime: isNaN(eventEnd) ? endItem.time : formatTime(eventEnd, endItem.timezone_offset),
        startTemp: Math.round(startItem.temp),
        endTemp: Math.round(endItem.temp),
        conditionName: startItem.condition || "Unknown",
        totalPrecip: parseFloat(totalPrecip.toFixed(1)),
        maxProb: maxProb
    }
}

function collectDailyChanges(items, nowMs, limit) {
    if (!items || items.length === 0) return []
    var changes = []
    var firstDate = ""
    var lastCode = -9999

    for (var i = 0; i < items.length; i++) {
        var item = items[i]
        if (hasValue(item.timestamp) && item.timestamp < nowMs) continue
        if (!firstDate) firstDate = item.date || ""
        if (firstDate && item.date && item.date !== firstDate) break

        var code = weatherCode(item)
        if (changes.length === 0 || code !== lastCode) {
            changes.push({
                time: item.time,
                cond: item.condition,
                temp: Math.round(item.temp),
                icon: item.icon
            })
            lastCode = code
            if (limit && changes.length >= limit) break
        }
    }
    return changes
}
