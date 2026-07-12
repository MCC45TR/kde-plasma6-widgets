import QtQuick
import QtTest
import "../contents/ui/js/PrefixRegistry.js" as PrefixRegistry

TestCase {
    name: "PrefixRegistry"

    property var localized: ({
        weather: "hava",
        help: "yardım",
        unit: "birim",
        shell: "kabuk",
        define: "define",
        kill: "öldür",
        spell: "yazımı"
    })

    function test_localizedWeatherAliasCanonicalizes() {
        compare(PrefixRegistry.canonicalize("hava: Ankara", localized, { weatherEnabled: true }), "weather:Ankara");
    }

    function test_disabledPrefixDoesNotOpenInternalView() {
        compare(PrefixRegistry.opensInternalView("hava:", localized, { weatherEnabled: false }), false);
        compare(PrefixRegistry.isAllowed("hava:", localized, { weatherEnabled: false }), false);
    }

    function test_unitPrefixStripsPayloadForBackendQuery() {
        compare(PrefixRegistry.canonicalize("birim: 10 km to m", localized, { prefixUnitEnabled: true }), "10 km to m");
    }

    function test_searchFilterPrefixesStripPayloadAndSelectCategory() {
        compare(PrefixRegistry.canonicalize("app: Dolphin", localized, {}), "Dolphin");
        compare(PrefixRegistry.resultFilter("app: Dolphin", localized, {}), "Apps");
        compare(PrefixRegistry.canonicalize("documents: rapor", localized, {}), "rapor");
        compare(PrefixRegistry.resultFilter("documents: rapor", localized, {}), "Docs");
        compare(PrefixRegistry.canonicalize("images: tatil", localized, {}), "tatil");
        compare(PrefixRegistry.resultFilter("images: tatil", localized, {}), "Images");
    }

    function test_runnerPrefixesUseTheirRealSyntax() {
        compare(PrefixRegistry.canonicalize("calc: 2+2", localized, {}), "2+2");
        compare(PrefixRegistry.canonicalize("shell: echo ok", localized, { prefixShellEnabled: true }), "echo ok");
        compare(PrefixRegistry.canonicalize("spell hello", localized, { prefixSpellEnabled: true }), "yazımı hello");
        compare(PrefixRegistry.canonicalize("kill firefox", localized, { prefixKillEnabled: true }), "öldür firefox");
        compare(PrefixRegistry.canonicalize("define:kernel", localized, {}), "define kernel");
    }

    function test_longestAliasWins() {
        var match = PrefixRegistry.match("timeline:/today", localized);
        verify(match !== null);
        compare(match.definition.canonical, "timeline:/");
        compare(match.payload, "today");
    }
}
