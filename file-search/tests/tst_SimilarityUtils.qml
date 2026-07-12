import QtQuick
import QtTest
import "../contents/ui/js/SimilarityUtils.js" as SimilarityUtils

TestCase {
    name: "SimilarityUtils"

    function test_foldCaseHandlesTurkishDottedI() {
        compare(SimilarityUtils.foldCase("İstanbul"), "istanbul");
    }

    function test_similarityOrdering() {
        verify(SimilarityUtils.similarityScore("kon", "Konsole") > SimilarityUtils.similarityScore("kon", "Dolphin"));
        verify(SimilarityUtils.similarityScore("abc", "a-b-c") > 0.8);
    }

    function test_priorityThenSimilarityThenStableOrder() {
        var items = [
            { display: "Dolphin", category: "Apps" },
            { display: "Konsole", category: "Apps" },
            { display: "Konsole Manual", category: "Docs" }
        ];
        var sorted = SimilarityUtils.sortByPriorityAndSimilarity(items, "kon", {}, function(_, category) {
            return category === "Docs" ? 0 : 1;
        }, 0, false, {});

        compare(sorted[0].display, "Konsole");
        compare(sorted[1].display, "Konsole Manual");
        compare(sorted.length, 2);
    }

    function test_smartLimitKeepsMinimumZeroScoreItems() {
        var items = [
            { display: "Konsole", category: "Apps" },
            { display: "Dolphin", category: "Apps" },
            { display: "Kate", category: "Apps" }
        ];
        var sorted = SimilarityUtils.sortByPriorityAndSimilarity(items, "kon", {}, function() {
            return 0;
        }, 0, false, { minResults: 2, smartResultLimit: true });

        compare(sorted.length, 2);
        compare(sorted[0].display, "Konsole");
    }

    function test_advancedSignalsHandleTyposAcronymsAndPaths() {
        verify(SimilarityUtils.similarityScore("konosle", "Konsole") > 0.6);
        verify(SimilarityUtils.similarityScore("vsc", "Visual Studio Code") > 0.75);

        var items = [
            { display: "Unrelated", category: "Files", url: "file:///home/user/Documents/quarterly-report.pdf" },
            { display: "Quarterly Notes", category: "Files", url: "file:///home/user/notes.txt" }
        ];
        var sorted = SimilarityUtils.sortByPriorityAndSimilarity(items, "quarterly report", {}, function() {
            return 0;
        }, 0, false, {});
        compare(sorted[0].url, "file:///home/user/Documents/quarterly-report.pdf");
    }

    function test_boundedTopKStaysResponsive() {
        var items = [];
        for (var i = 0; i < 1500; i++) {
            items.push({
                display: i === 1499 ? "Konsole Settings" : "Document " + i,
                category: i % 2 ? "Files" : "Applications",
                url: "file:///home/user/Documents/item-" + i + ".txt"
            });
        }
        var started = Date.now();
        var sorted = SimilarityUtils.sortByPriorityAndSimilarity(items, "konsole settings", {}, function() {
            return 0;
        }, 120, false, { minResults: 3, smartResultLimit: true });
        verify(Date.now() - started < 1000);
        verify(sorted.length <= 120);
        compare(sorted[0].display, "Konsole Settings");
    }
}
