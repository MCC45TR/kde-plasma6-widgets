import QtQuick
import QtTest
import "../contents/ui/components" as Components

TestCase {
    name: "CompactPanel"

    Components.CompactView {
        id: verticalCompact
        width: 40
        height: 240
        isButtonMode: false
        isWideMode: true
        isExtraWideMode: false
        isUltraWideMode: false
        expanded: false
        truncatedText: "Ara"
        responsiveFontSize: 12
        fontFamily: "Sans"
        bgColor: "white"
        textColor: "black"
        accentColor: "blue"
        searchTextLength: 0
        panelRadius: 2
        panelHeight: 40
        showSearchButton: true
        showSearchButtonBackground: false
        contentOpacity: 1
        isVerticalPanel: true
        panelRotation: 90
        maxChars: 65
        rssPlaceholderCycling: false
    }

    Components.CompactView {
        id: horizontalCompact
        width: 240
        height: 40
        isButtonMode: false
        isWideMode: true
        isExtraWideMode: false
        isUltraWideMode: false
        expanded: false
        truncatedText: "Ara"
        responsiveFontSize: 12
        fontFamily: "Sans"
        bgColor: "white"
        textColor: "black"
        accentColor: "blue"
        searchTextLength: 0
        panelRadius: 2
        panelHeight: 40
        showSearchButton: true
        showSearchButtonBackground: false
        contentOpacity: 1
        isVerticalPanel: false
        panelRotation: 0
        maxChars: 65
        rssPlaceholderCycling: false
    }

    function test_verticalContentSwapsAxesBeforeRotation() {
        var button = findChild(verticalCompact, "mainButton");
        verify(button !== null);
        compare(button.width, 240);
        compare(button.height, 40);
        compare(button.rotation, 90);
    }

    function test_horizontalContentKeepsAxes() {
        var button = findChild(horizontalCompact, "mainButton");
        verify(button !== null);
        compare(button.width, 240);
        compare(button.height, 40);
        compare(button.rotation, 0);
    }
}
