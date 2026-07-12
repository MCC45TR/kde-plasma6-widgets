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
        compare(SimilarityUtils.similarityScore("abc", "a-b-c"), 0.6);
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

        compare(sorted[0].display, "Konsole Manual");
        compare(sorted[1].display, "Konsole");
        compare(sorted[2].display, "Dolphin");
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
}
