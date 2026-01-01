import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents



Item {
    id: root
    
    // Bind directly to model to ensure data is received
    property string chatRole: model.chatRole || "error"
    property string chatText: model.chatText || ""
    property var chatImage: model.chatImage || null
    property var trFunc: function(k) { return k; }

    // Width management for ListView
    width: ListView.view ? ListView.view.width : parent.width
    height: bubble.height + Kirigami.Units.largeSpacing
    
    // The Chat Bubble
    Rectangle {
        id: bubble
        
        // Dynamic Width: Min 100 or implicit, Max 85% of view
        width: Math.min(root.width * 0.85, Math.max(100, contentLayout.implicitWidth + (Kirigami.Units.largeSpacing * 2)))
        height: contentLayout.implicitHeight + (Kirigami.Units.smallSpacing * 2)
        
        // Alignment: User RIGHT, AI LEFT
        anchors.right: root.chatRole === "user" ? root.right : undefined
        anchors.left: root.chatRole !== "user" ? root.left : undefined
        anchors.margins: Kirigami.Units.largeSpacing
        
        // Visuals
        radius: Kirigami.Units.smallSpacing
        color: {
            if (root.chatRole === "user") return Kirigami.Theme.highlightColor // Distinct User Color
            if (root.chatRole === "error") return Kirigami.Theme.negativeBackgroundColor
            return Kirigami.Theme.backgroundColor // AI Color
        }
        
        // Border for AI/Standard messages to separate from background
        border.width: root.chatRole === "user" ? 0 : 1
        border.color: Kirigami.Theme.separatorColor
        
        ColumnLayout {
            id: contentLayout
            anchors.centerIn: parent
            width: parent.width - (Kirigami.Units.largeSpacing * 2)
            spacing: Kirigami.Units.smallSpacing
            
            // Header: Name
            Label {
                Layout.fillWidth: true
                text: {
                    if (root.chatRole === "user") return root.trFunc("you")
                    if (root.chatRole === "error") return root.trFunc("error")
                    if (root.chatRole === "loading") return root.trFunc("assistant") 
                    return root.trFunc("assistant") // "Gemini"
                }
                font.bold: true
                font.pixelSize: Kirigami.Theme.smallFont.pixelSize * 0.9
                // Text Color: White on Highlight (User), Theme Text on Background (AI)
                color: root.chatRole === "user" ? "white" : Kirigami.Theme.textColor
                opacity: 0.8
            }
            
            // Attached Image (if any)
            Image {
                visible: root.chatImage !== null && root.chatImage !== "" && root.chatRole !== "loading"
                source: root.chatImage || ""
                fillMode: Image.PreserveAspectFit
                Layout.preferredWidth: 250
                Layout.preferredHeight: 250
                Layout.maximumWidth: parent.width
                
                Rectangle {
                    anchors.fill: parent
                    color: "transparent"
                    border.color: "red"
                    visible: parent.status === Image.Error
                }
            }
            
            // CONTENT: Loading Indicator OR Text
            
            // Loading State
            RowLayout {
                visible: root.chatRole === "loading"
                spacing: Kirigami.Units.largeSpacing
                
                BusyIndicator {
                    running: root.chatRole === "loading"
                    Layout.preferredWidth: Kirigami.Units.iconSizes.small
                    Layout.preferredHeight: Kirigami.Units.iconSizes.small
                }
                
                Label {
                    text: root.trFunc("waiting") // "Waiting..."
                    color: Kirigami.Theme.textColor
                    font.italic: true
                }
            }
            
            // Message Text
            TextArea {
                id: messageText
                visible: root.chatRole !== "loading"
                text: root.chatText
                textFormat: TextArea.RichText
                wrapMode: TextArea.WordWrap
                readOnly: true
                selectByMouse: true
                
                // Force colors for contrast
                color: root.chatRole === "user" ? "white" : Kirigami.Theme.textColor
                selectionColor: Kirigami.Theme.highlightColor
                selectedTextColor: Kirigami.Theme.highlightedTextColor
                
                background: null
                Layout.fillWidth: true
                
                // Custom link handling
                onLinkActivated: Qt.openUrlExternally(link)
            }
            
            // Action Bar (Copy) - Only show on hover and if not loading
            RowLayout {
                Layout.fillWidth: true
                visible: root.hovered && root.chatRole !== "loading"
                
                Item { Layout.fillWidth: true } // Spacer
                
                PlasmaComponents.Button {
                    icon.name: "edit-copy-symbolic"
                    text: root.trFunc("copy")
                    display: PlasmaComponents.AbstractButton.IconOnly
                    flat: true
                    
                    onClicked: {
                        messageText.selectAll()
                        messageText.copy()
                        messageText.deselect()
                    }
                    
                    PlasmaComponents.ToolTip.text: text
                    PlasmaComponents.ToolTip.visible: hovered
                }
            }
        }
    }
}
