import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

Kirigami.AbstractCard {
    id: root
    
    required property string chatRole // "user" or "model" or "error"
    required property string chatText
    property var chatImage: null // Optional image source
    
    // Configurable properties
    property var trFunc: function(k) { return k; }

    Layout.fillWidth: true
    // implicitHeight calculated automatically by ColumnLayout

    contentItem: ColumnLayout {
        spacing: Kirigami.Units.smallSpacing
        
        // Header (Role Name)
        Label {
            text: root.chatRole === "user" ? root.trFunc("you") : (root.chatRole === "error" ? root.trFunc("error") : root.trFunc("assistant"))
            font.bold: true
            color: root.chatRole === "error" ? Kirigami.Theme.negativeTextColor : Kirigami.Theme.highlightColor
            Layout.fillWidth: true
        }
        
        // Attached Image (if any)
        Image {
            visible: root.chatImage !== null && root.chatImage !== ""
            source: root.chatImage || ""
            fillMode: Image.PreserveAspectFit
            Layout.preferredWidth: 200
            Layout.preferredHeight: 200
            Layout.maximumWidth: parent.width
            
            Rectangle {
                anchors.fill: parent
                color: "transparent"
                border.color: Kirigami.Theme.textColor
                border.width: 1
                visible: parent.status === Image.Error
            }
        }
        
        // Message Text
        TextArea {
            id: messageText
            text: root.chatText
            textFormat: TextArea.RichText
            wrapMode: TextArea.WordWrap
            readOnly: true
            selectByMouse: true
            color: Kirigami.Theme.textColor
            background: null // Transparent background to use Card's background
            Layout.fillWidth: true
            
            // Custom link handling if needed
            onLinkActivated: Qt.openUrlExternally(link)
        }
        
        // Action Bar (Copy)
        RowLayout {
            Layout.fillWidth: true
            visible: hoverHandler.hovered
            
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
    
    HoverHandler {
        id: hoverHandler
    }
    
    // Visual styling for User vs Model
    background: Rectangle {
        color: root.chatRole === "user" ? Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.1) : Kirigami.Theme.backgroundColor
        radius: 4
        border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.1)
        border.width: 1
    }
}
