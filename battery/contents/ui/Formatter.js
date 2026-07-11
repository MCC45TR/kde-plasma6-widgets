// Formatter utilities for battery widget

function formatDuration(msec) {
    if (msec <= 0) return ""
    var totalMins = Math.floor(msec / 60000)

    if (totalMins < 60) {
        return i18nc("minutes", "%1 m", totalMins)
    } else if (totalMins < 1440) {
        var h = Math.floor(totalMins / 60)
        var m = totalMins % 60
        return i18nc("hours and minutes", "%1 h %2 m", h, m)
    } else {
        var d = Math.floor(totalMins / 1440)
        var h = Math.round((totalMins % 1440) / 60)
        if (h === 24) { d++; h = 0; }
        return i18nc("days and hours", "%1 d %2 h", d, h)
    }
}
