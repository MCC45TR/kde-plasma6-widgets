import QtQuick
import QtTest
import "../contents/ui/js/PanelLayoutUtils.js" as PanelLayoutUtils

TestCase {
    name: "PanelLayoutUtils"

    function test_rotationFollowsVerticalPanelEdge() {
        var leftEdge = 5;
        var rightEdge = 6;
        compare(PanelLayoutUtils.rotationForPanel(true, rightEdge, leftEdge, rightEdge), 90);
        compare(PanelLayoutUtils.rotationForPanel(true, leftEdge, leftEdge, rightEdge), -90);
        compare(PanelLayoutUtils.rotationForPanel(false, rightEdge, leftEdge, rightEdge), 0);
        compare(PanelLayoutUtils.rotationForPanel(true, 0, leftEdge, rightEdge), -90);
    }

    function test_manualPlacementOverridesDetection() {
        var leftEdge = 5;
        var rightEdge = 6;
        compare(PanelLayoutUtils.effectivePlacement(true, 0, true, rightEdge, leftEdge, rightEdge), 2);
        compare(PanelLayoutUtils.effectivePlacement(false, 0, true, rightEdge, leftEdge, rightEdge), 0);
        compare(PanelLayoutUtils.effectivePlacement(false, 1, false, 0, leftEdge, rightEdge), 1);
        compare(PanelLayoutUtils.effectivePlacement(false, 2, false, 0, leftEdge, rightEdge), 2);
        compare(PanelLayoutUtils.effectivePlacement(false, 99, false, 0, leftEdge, rightEdge), 2);
        compare(PanelLayoutUtils.rotationForPlacement(0), 0);
        compare(PanelLayoutUtils.rotationForPlacement(1), -90);
        compare(PanelLayoutUtils.rotationForPlacement(2), 90);
    }

    function test_placeholderUsesLongestTextThatFits() {
        var texts = ["Ara", "Ara...", "Arama yapın", "Aramaya başla..."];
        var widths = [24, 42, 88, 126];
        compare(PanelLayoutUtils.longestFittingText(20, texts, widths), "Ara");
        compare(PanelLayoutUtils.longestFittingText(45, texts, widths), "Ara...");
        compare(PanelLayoutUtils.longestFittingText(90, texts, widths), "Arama yapın");
        compare(PanelLayoutUtils.longestFittingText(140, texts, widths), "Aramaya başla...");
    }
}
