.pragma library

// One source of truth for prefixes that affect execution or open an internal
// view. Presentation metadata (labels/icons) stays in QueryHints.qml.
var definitions = [
    { canonical: "weather:", aliases: ["hava:"], localeKey: "weather", setting: "weatherEnabled", view: "weather" },
    { canonical: "calendar:", aliases: [], localeKey: "calendar", view: "date" },
    { canonical: "date:", aliases: [], localeKey: "date", view: "date" },
    { canonical: "clock:", aliases: [], localeKey: "clock", view: "clock" },
    { canonical: "power:", aliases: [], localeKey: "power", view: "power" },
    { canonical: "help:", aliases: [], localeKey: "help", view: "help" },
    { canonical: "unit:", aliases: [], localeKey: "unit", setting: "prefixUnitEnabled", stripPayload: true },
    { canonical: "shell:", aliases: [], localeKey: "shell", setting: "prefixShellEnabled" },
    { canonical: "kill ", aliases: [], localeKey: "kill", setting: "prefixKillEnabled" },
    { canonical: "spell ", aliases: [], localeKey: "spell", setting: "prefixSpellEnabled" },
    { canonical: "timeline:/", aliases: [], setting: "prefixTimelineEnabled" },
    { canonical: "gg:", aliases: [], setting: "prefixWebSearchEnabled" },
    { canonical: "dd:", aliases: [], setting: "prefixWebSearchEnabled" }
]

function definitionFor(canonical) {
    var value = String(canonical || "").toLowerCase()
    for (var i = 0; i < definitions.length; ++i) {
        if (definitions[i].canonical === value) return definitions[i]
    }
    return null
}

function _appendUnique(target, value) {
    value = String(value || "").toLowerCase()
    if (value && target.indexOf(value) < 0) target.push(value)
}

function aliasesFor(canonical, localized) {
    var def = definitionFor(canonical)
    var result = []
    if (!def) {
        _appendUnique(result, canonical)
        return result
    }
    _appendUnique(result, def.canonical)
    for (var i = 0; i < def.aliases.length; ++i) _appendUnique(result, def.aliases[i])
    if (def.localeKey && localized && localized[def.localeKey]) {
        var suffix = def.canonical.endsWith(" ") ? " " : (def.canonical.endsWith(":/") ? ":/" : ":")
        _appendUnique(result, String(localized[def.localeKey]).replace(/[:\/\s]+$/, "") + suffix)
    }
    return result
}

function isEnabled(defOrCanonical, settings) {
    var def = typeof defOrCanonical === "string" ? definitionFor(defOrCanonical) : defOrCanonical
    if (!def || !def.setting || !settings || settings[def.setting] === undefined) return true
    return settings[def.setting] !== false
}

function match(text, localized) {
    var lower = String(text || "").trim().toLowerCase()
    var best = null
    for (var i = 0; i < definitions.length; ++i) {
        var def = definitions[i]
        var aliases = aliasesFor(def.canonical, localized)
        for (var j = 0; j < aliases.length; ++j) {
            var alias = aliases[j]
            if (lower.startsWith(alias) && (!best || alias.length > best.alias.length)) {
                best = { definition: def, alias: alias, payload: lower.substring(alias.length).trim() }
            }
        }
    }
    return best
}

function canonicalize(text, localized, settings) {
    var raw = String(text || "")
    var found = match(raw, localized)
    if (!found || !isEnabled(found.definition, settings)) return raw
    var payload = raw.trim().substring(found.alias.length).trim()
    if (found.definition.stripPayload) return payload
    return found.definition.canonical + payload
}

function opensInternalView(text, localized, settings) {
    var found = match(text, localized)
    return !!(found && found.definition.view && isEnabled(found.definition, settings))
}

function isAllowed(text, localized, settings) {
    var found = match(text, localized)
    return !found || isEnabled(found.definition, settings)
}
