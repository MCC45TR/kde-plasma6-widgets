import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import QtQuick.Dialogs

Item {
    id: root
    
    // Signals
    signal messageSent(string text, var attachments)
    
    // Properties
    property bool isLoading: false
    property var trFunc: function(k) { return k; }
    
    Layout.fillWidth: true
    Layout.preferredHeight: colLayout.implicitHeight

    // State for attachment
    property string attachedFile: ""
    
    FileDialog {
        id: fileDialog
        title: root.trFunc("attach_file")
        nameFilters: ["Image files (*.jpg *.png *.jpeg *.webp)"]
        onAccepted: {
            // Need to handle file URL to base64 conversion in main.qml potentially or passing URL
            // QML cannot easily "read" file content to base64 without C++ or specialized calls.
            // However, we can pass the URL to our logic if it handles local files.
            // Standard XMLHTTPRequest in QML doesn't upload files easily.
            // We might need to assume the backend (GeminiManager) can handle it?
            // Wait, pure QML JS restrictions...
            // Actually, we can use an Image item to load it, but getting Base64 is hard.
            // WORKAROUND: For now, we just pass the URL string, and GeminiManager will try a trick or we accept limitation.
            // Actually, newer Qt/Plasma versions support FileReader in QML? No.
            // We will store the path.
            root.attachedFile = selectedFile
        }
    }

    ColumnLayout {
        id: colLayout
        anchors.fill: parent
        spacing: 4
        
        // Attachment Preview
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 60
            color: Kirigami.Theme.backgroundColor
            border.color: Kirigami.Theme.highlightColor
            border.width: 1
            visible: root.attachedFile !== ""
            radius: 4
            
            RowLayout {
                anchors.fill: parent
                anchors.margins: 4
                
                Image {
                    source: root.attachedFile
                    Layout.preferredWidth: 50
                    Layout.preferredHeight: 50
                    fillMode: Image.PreserveAspectCrop
                }
                
                Label {
                    text: root.attachedFile.toString().split("/").pop()
                    Layout.fillWidth: true
                    elide: Text.ElideMiddle
                }
                
                PlasmaComponents.Button {
                    icon.name: "edit-delete"
                    display: PlasmaComponents.AbstractButton.IconOnly
                    flat: true
                    onClicked: root.attachedFile = ""
                }
            }
        }
    
        RowLayout {
            Layout.fillWidth: true
            
            // Attach Button
            PlasmaComponents.Button {
                icon.name: "paper-clip"
                display: PlasmaComponents.AbstractButton.IconOnly
                text: root.trFunc("attach_file")
                enabled: !root.isLoading
                
                onClicked: fileDialog.open()
                
                PlasmaComponents.ToolTip.text: text
                PlasmaComponents.ToolTip.visible: hovered
            }
            
            // Text Input
            ScrollView {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(100, Math.max(40, messageField.implicitHeight))
                
                TextArea {
                    id: messageField
                    enabled: !root.isLoading
                    placeholderText: root.trFunc("type_message")
                    wrapMode: TextArea.Wrap
                    selectByMouse: true
                    color: Kirigami.Theme.textColor
                    placeholderTextColor: Kirigami.Theme.disabledTextColor
                    
                    Keys.onReturnPressed: (event) => {
                        if (event.modifiers & Qt.ControlModifier) {
                            messageField.insert(messageField.cursorPosition, "\n")
                        } else {
                            sendMessageInternal()
                            event.accepted = true
                        }
                    }
                }
            }
            
            // Send Button
            PlasmaComponents.Button {
                icon.name: "document-send"
                display: PlasmaComponents.AbstractButton.IconOnly
                text: root.trFunc("send")
                enabled: !root.isLoading && (messageField.text.trim().length > 0 || root.attachedFile !== "")
                
                onClicked: sendMessageInternal()
                
                PlasmaComponents.ToolTip.text: text
                PlasmaComponents.ToolTip.visible: hovered
            }
        }
    }
    
    function sendMessageInternal() {
        if (messageField.text.trim() === "" && root.attachedFile === "") return;
        
        var attachments = [];
        if (root.attachedFile !== "") {
            attachments.push({
                url: root.attachedFile,
                mimeType: "image/jpeg" // Simplified assumption
            });
        }
        
        root.messageSent(messageField.text, attachments);
        
        messageField.clear();
        root.attachedFile = "";
    }
}
