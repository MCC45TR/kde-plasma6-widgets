import QtQuick
import QtTest
import "../contents/ui/js/QueryPolicy.js" as QueryPolicy

TestCase {
    name: "QueryPolicy"

    property var disabledPolicy: ({
            shellEnabled: false,
            killEnabled: false,
            spellEnabled: false,
            unitEnabled: false,
            timelineEnabled: false,
            webSearchEnabled: false,
            locShell: "kabuk",
            locKill: "öldür",
            locSpell: "yazım",
            locUnit: "birim"
        })

    QtObject {
        id: fakeResultsModel

        property int runCount: 0

        function run() {
            runCount++;
        }
    }

    function runSafely(query) {
        if (!QueryPolicy.isAllowed(query, disabledPolicy))
            return false;
        fakeResultsModel.run(0);
        return true;
    }

    function init() {
        fakeResultsModel.runCount = 0;
    }

    function test_disabledPrefixesNeverReachRun_data() {
        return [
            {
                tag: "shell",
                query: "shell: echo unsafe"
            },
            {
                tag: "localized shell",
                query: "kabuk: echo unsafe"
            },
            {
                tag: "kill",
                query: "kill process"
            },
            {
                tag: "localized spell",
                query: "yazım word"
            },
            {
                tag: "unit",
                query: "unit: 1m to cm"
            },
            {
                tag: "timeline",
                query: "timeline:/today"
            },
            {
                tag: "google",
                query: "gg: query"
            },
            {
                tag: "duckduckgo",
                query: "dd: query"
            }
        ];
    }

    function test_disabledPrefixesNeverReachRun(data) {
        compare(runSafely(data.query), false);
        compare(fakeResultsModel.runCount, 0);
    }

    function test_staleResultCannotBypassPolicy() {
        compare(runSafely("shell: stale model row"), false);
        compare(fakeResultsModel.runCount, 0);
    }

    function test_normalQueryRuns() {
        compare(runSafely("ordinary search"), true);
        compare(fakeResultsModel.runCount, 1);
    }
}
