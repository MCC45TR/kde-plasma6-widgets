import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

// Search Input Container for Button Mode
Rectangle {
    id: root
    
    // Required properties
    required property color bgColor
    required property color textColor
    required property color accentColor
    required property string placeholderText
    
    // Bindable properties
    property string searchText: ""
    property int resultCount: 0
    property var resultsModel: null
    
    // Signals
    signal searchSubmitted(string text, int selectedIndex)
    signal escapePressed()
    signal upPressed()
    signal downPressed()
    
    height: 56
    color: Qt.rgba(bgColor.r, bgColor.g, bgColor.b, 0.95)
    radius: 12
    
    // Focus the input field
    function focusInput() {
        searchInputField.forceActiveFocus()
    }
    
    // Set text
    function setText(text) {
        searchInputField.text = text
    }
    
    // Clear text
    function clear() {
        searchInputField.text = ""
    }
    
    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 8
        spacing: 8
        
        // Text Input Field
        TextField {
            id: searchInputField
            Layout.fillWidth: true
            Layout.fillHeight: true
            placeholderText: root.placeholderText
            placeholderTextColor: Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.5)
            color: root.textColor
            font.pixelSize: 18
            background: Item {} // No background
            
            onTextChanged: {
                root.searchText = text
            }
            
            onAccepted: {
                root.searchSubmitted(text, 0)
            }
            
            Keys.onEscapePressed: {
                root.escapePressed()
            }
            
            Keys.onDownPressed: {
                root.downPressed()
            }
            
            Keys.onUpPressed: {
                root.upPressed()
            }
        }
        
        // Search Icon Button
        Rectangle {
            id: searchIconBtn
            Layout.preferredWidth: 44
            Layout.preferredHeight: 44
            Layout.alignment: Qt.AlignVCenter
            radius: width / 2
            color: root.accentColor
            
            Kirigami.Icon {
                anchors.centerIn: parent
                width: 22
                height: 22
                source: "search"
                color: "white"
            }
            
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.searchSubmitted(searchInputField.text, 0)
                }
            }
        }
    }
}
