.pragma library

function startsCommand(lower, englishPrefix, localizedPrefix, separator) {
    var english = englishPrefix + separator
    if (lower.startsWith(english)) return true
    if (localizedPrefix && lower.startsWith(localizedPrefix + separator)) return true
    return false
}

function isAllowed(text, policy) {
    var lower = String(text || "").trim().toLowerCase()
    if (!lower) return true
    if (!policy.shellEnabled && startsCommand(lower, "shell", policy.locShell, ":")) return false
    if (!policy.killEnabled && startsCommand(lower, "kill", policy.locKill, " ")) return false
    if (!policy.spellEnabled && startsCommand(lower, "spell", policy.locSpell, " ")) return false
    if (!policy.unitEnabled && startsCommand(lower, "unit", policy.locUnit, ":")) return false
    if (!policy.timelineEnabled && lower.startsWith("timeline:/")) return false
    if (!policy.webSearchEnabled && (lower.startsWith("gg:") || lower.startsWith("dd:"))) return false
    return true
}
