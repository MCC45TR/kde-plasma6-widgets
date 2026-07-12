import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

// Compact panel representation for the File Search widget
Item {
    id: compactRoot

    // Required properties from parent
    required property bool isButtonMode
    required property bool isWideMode
    required property bool isExtraWideMode
    required property bool expanded
    required property string truncatedText
    required property int responsiveFontSize
    required property string fontFamily
    required property color bgColor
    required property color textColor
    required property color accentColor
    required property int searchTextLength
    required property int panelRadius
    required property int panelHeight
    required property bool showSearchButton
    required property bool showSearchButtonBackground
    required property real contentOpacity
    // New properties for animated ticker
    property var logic: null
    property bool rssPlaceholderCycling: true
    property bool rssShowFullHeadline: true
    property int rssFrequency: 3
    property int weatherFrequency: 2
    property bool rssShowSource: true
    property bool isUltraWideMode: false
    required property int maxChars

    readonly property bool isMediumMode: !isButtonMode && !isWideMode && !isExtraWideMode && !isUltraWideMode

    readonly property bool showMediumModeWeatherTicker: compactRoot.isMediumMode &&
        compactRoot.logic &&
        compactRoot.logic.plasmoidConfig &&
        compactRoot.logic.plasmoidConfig.weatherEnabled &&
        compactRoot.logic.plasmoidConfig.weatherPlaceholderCycling &&
        compactRoot.logic.weatherCacheLoaded &&
        compactRoot.logic.weatherCache !== ""

    // Signals
    signal toggleExpanded()

    // Button Mode - icon only (no background)
    Kirigami.Icon {
        id: buttonModeIcon
        anchors.centerIn: parent
        width: Math.min(parent.width, parent.height)
        height: width
        source: "plasma-search"
        color: buttonModeMouse.containsMouse ? compactRoot.accentColor : compactRoot.textColor
        opacity: compactRoot.contentOpacity
        visible: compactRoot.isButtonMode

        MouseArea {
            id: buttonModeMouse
            anchors.fill: parent
            anchors.margins: -8
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true

            onClicked: compactRoot.toggleExpanded()
        }
    }



    // Main Button Container (for non-button modes)
    Rectangle {
        id: mainButton
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        height: compactRoot.panelHeight > 0 ? compactRoot.panelHeight : parent.height
        radius: compactRoot.panelRadius === 0 ? height / 2 : (compactRoot.panelRadius === 1 ? 12 : (compactRoot.panelRadius === 2 ? 6 : 0))
        color: Qt.rgba(compactRoot.bgColor.r, compactRoot.bgColor.g, compactRoot.bgColor.b, mainMouse.containsMouse ? 1.0 : 0.95)
        visible: !compactRoot.isButtonMode

        // Border for definition
        border.width: 1
        border.color: compactRoot.expanded ? compactRoot.accentColor : Qt.rgba(compactRoot.textColor.r, compactRoot.textColor.g, compactRoot.textColor.b, 0.1)

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: (compactRoot.isWideMode || compactRoot.isExtraWideMode || compactRoot.isUltraWideMode) ? 10 : 0
            anchors.rightMargin: (compactRoot.isWideMode || compactRoot.isExtraWideMode || compactRoot.isUltraWideMode) ? (compactRoot.showSearchButton ? 4 : 10) : 0
            spacing: 6
            opacity: compactRoot.contentOpacity

            // Display text (Static when searching, Hidden when ticker is running)
            Text {
                id: displayText
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                text: compactRoot.truncatedText
                color: compactRoot.textColor
                font.pixelSize: compactRoot.responsiveFontSize
                font.family: compactRoot.fontFamily
                horizontalAlignment: (compactRoot.isWideMode || compactRoot.isExtraWideMode || compactRoot.isUltraWideMode) ? Text.AlignLeft : Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
                visible: compactRoot.searchTextLength > 0 || (compactRoot.isMediumMode && !compactRoot.showMediumModeWeatherTicker)
            }

            RssTicker {
                id: tickerContainer
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: !compactRoot.isButtonMode && compactRoot.searchTextLength === 0 && (!compactRoot.isMediumMode || compactRoot.showMediumModeWeatherTicker)

                logic: compactRoot.logic
                rssFrequency: compactRoot.rssFrequency
                weatherFrequency: compactRoot.weatherFrequency
                rssPlaceholderCycling: compactRoot.rssPlaceholderCycling
                rssShowFullHeadline: compactRoot.rssShowFullHeadline
                rssShowSource: compactRoot.rssShowSource
                maxChars: compactRoot.maxChars

                // Weather properties
                weatherPlaceholderCycling: compactRoot.logic ? (compactRoot.logic.plasmoidConfig.weatherPlaceholderCycling ?? true) : true
                weatherIconPack: compactRoot.logic ? (compactRoot.logic.plasmoidConfig.weatherIconPack ?? "default") : "default"
                isMediumMode: compactRoot.isMediumMode
                isUltraWideMode: compactRoot.isUltraWideMode

                textColor: compactRoot.textColor
                fontSize: compactRoot.responsiveFontSize
                fontFamily: compactRoot.fontFamily
                defaultText: (compactRoot.isExtraWideMode || compactRoot.isUltraWideMode) ? i18nd("plasma_applet_com.mcc45tr.filesearch", "Start searching...") : (compactRoot.isWideMode ? i18nd("plasma_applet_com.mcc45tr.filesearch", "Search...") : i18nd("plasma_applet_com.mcc45tr.filesearch", "Search"))
                horizontalAlignment: (compactRoot.isWideMode || compactRoot.isExtraWideMode || compactRoot.isUltraWideMode) ? Text.AlignLeft : Text.AlignHCenter

                rightMarginValue: 0
                textOpacity: 1.0
                isSearching: compactRoot.searchTextLength > 0
            }

            // Search Icon Button (Wide and Extra Wide Mode only)
            Rectangle {
                id: searchIconButton
                Layout.preferredWidth: ((compactRoot.isWideMode || compactRoot.isExtraWideMode || compactRoot.isUltraWideMode) && compactRoot.showSearchButton) ? (mainButton.height - 6) : 0
                Layout.preferredHeight: mainButton.height - 6
                Layout.alignment: Qt.AlignVCenter
                radius: compactRoot.panelRadius === 0 ? width / 2 : (compactRoot.panelRadius === 1 ? 8 : (compactRoot.panelRadius === 2 ? 4 : 0))
                color: compactRoot.showSearchButtonBackground ? compactRoot.accentColor : "transparent"
                visible: (compactRoot.isWideMode || compactRoot.isExtraWideMode || compactRoot.isUltraWideMode) && compactRoot.showSearchButton

                Behavior on Layout.preferredWidth { NumberAnimation { duration: 200 } }

                Kirigami.Icon {
                    anchors.centerIn: parent
                    width: parent.width * 0.55
                    height: width
                    source: "search"
                    color: compactRoot.textColor
                }
            }
        }

        // Click handler - opens popup
        MouseArea {
            id: mainMouse
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true

            onClicked: compactRoot.toggleExpanded()
        }
    }

}
