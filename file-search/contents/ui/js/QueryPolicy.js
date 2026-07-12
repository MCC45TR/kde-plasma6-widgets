.pragma library
.import "PrefixRegistry.js" as PrefixRegistry

function isAllowed(text, policy) {
    return PrefixRegistry.isAllowed(text, {
        shell: policy.locShell,
        kill: policy.locKill,
        spell: policy.locSpell,
        unit: policy.locUnit,
        weather: policy.locWeather
    }, {
        prefixShellEnabled: policy.shellEnabled,
        prefixKillEnabled: policy.killEnabled,
        prefixSpellEnabled: policy.spellEnabled,
        prefixUnitEnabled: policy.unitEnabled,
        prefixTimelineEnabled: policy.timelineEnabled,
        prefixWebSearchEnabled: policy.webSearchEnabled,
        weatherEnabled: policy.weatherEnabled
    })
}
