import QtQuick
import QtTest
import "../contents/ui/js/PrefixRegistry.js" as PrefixRegistry

TestCase {
    name: "PrefixRegistry"

    property var localized: ({
        weather: "hava",
        help: "yardım",
        unit: "birim",
        shell: "kabuk"
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

    function test_longestAliasWins() {
        var match = PrefixRegistry.match("timeline:/today", localized);
        verify(match !== null);
        compare(match.definition.canonical, "timeline:/");
        compare(match.payload, "today");
    }
}
