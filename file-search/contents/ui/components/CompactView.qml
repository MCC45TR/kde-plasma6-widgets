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
    required property color bgColor
    required property color textColor
    required property color accentColor
    required property int searchTextLength
    required property int panelRadius
    
    // Signals
    signal toggleExpanded()
    
    // Button Mode - icon only (no background)
    Kirigami.Icon {
        id: buttonModeIcon
        anchors.centerIn: parent
        width: Math.min(parent.width, parent.height)
        height: width
        source: "plasma-search"
        color: compactRoot.textColor
        visible: compactRoot.isButtonMode
        
        MouseArea {
            anchors.fill: parent
            anchors.margins: -8
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            
            onEntered: buttonModeIcon.color = compactRoot.accentColor
            onExited: buttonModeIcon.color = compactRoot.textColor
            
            onClicked: compactRoot.toggleExpanded()
        }
    }
    
    // Main Button Container (for non-button modes)
    Rectangle {
        id: mainButton
        anchors.fill: parent
        anchors.margins: 0
        radius: compactRoot.panelRadius === 0 ? height / 2 : (compactRoot.panelRadius === 1 ? 12 : (compactRoot.panelRadius === 2 ? 6 : 0))
        color: Qt.rgba(compactRoot.bgColor.r, compactRoot.bgColor.g, compactRoot.bgColor.b, 0.95)
        visible: !compactRoot.isButtonMode
        
        // Border for definition
        border.width: 1
        border.color: compactRoot.expanded ? compactRoot.accentColor : Qt.rgba(compactRoot.textColor.r, compactRoot.textColor.g, compactRoot.textColor.b, 0.1)
        
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 4
            spacing: 6
            
            // Display text (not editable - shows placeholder or search text)
            Text {
                id: displayText
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                text: compactRoot.truncatedText
                color: Qt.rgba(compactRoot.textColor.r, compactRoot.textColor.g, compactRoot.textColor.b, compactRoot.searchTextLength > 0 ? 1.0 : 0.6)
                font.pixelSize: compactRoot.responsiveFontSize
                font.family: "Roboto Condensed"
                horizontalAlignment: (compactRoot.isWideMode || compactRoot.isExtraWideMode) ? Text.AlignLeft : Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
            }
            
            // Search Icon Button (Wide and Extra Wide Mode only)
            Rectangle {
                id: searchIconButton
                Layout.preferredWidth: (compactRoot.isWideMode || compactRoot.isExtraWideMode) ? (mainButton.height - 6) : 0
                Layout.preferredHeight: mainButton.height - 6
                Layout.alignment: Qt.AlignVCenter
                radius: compactRoot.panelRadius === 0 ? width / 2 : (compactRoot.panelRadius === 1 ? 8 : (compactRoot.panelRadius === 2 ? 4 : 0))
                color: compactRoot.accentColor
                visible: compactRoot.isWideMode || compactRoot.isExtraWideMode
                
                Behavior on Layout.preferredWidth { NumberAnimation { duration: 200 } }
                
                Kirigami.Icon {
                    anchors.centerIn: parent
                    width: parent.width * 0.55
                    height: width
                    source: "search"
                    color: "#ffffff"
                }
            }
        }
        
        // Click handler - opens popup
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            
            onEntered: mainButton.color = Qt.rgba(compactRoot.bgColor.r, compactRoot.bgColor.g, compactRoot.bgColor.b, 1.0)
            onExited: mainButton.color = Qt.rgba(compactRoot.bgColor.r, compactRoot.bgColor.g, compactRoot.bgColor.b, 0.95)
            
            onClicked: compactRoot.toggleExpanded()
        }
    }
}
