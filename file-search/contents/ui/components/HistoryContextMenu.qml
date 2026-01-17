import QtQuick
import org.kde.plasma.components 3.0 as PC3

PC3.Menu {
    id: root

    // Dependencies
    property var historyItem: null
    property var logic: null

    function popup() {
        root.open()
    }

    // Open (Standard)
    PC3.MenuItem {
        text: "Aç"
        icon.name: "document-open"
        onTriggered: {
            if (historyItem && historyItem.filePath) {
                 if (historyItem.filePath.toString().indexOf(".desktop") !== -1) {
                      logic.runShellCommand("kioclient exec '" + historyItem.filePath + "'")
                 } else {
                      Qt.openUrlExternally(historyItem.filePath)
                 }
            }
        }
    }
    
    // Open With
    PC3.MenuItem {
        visible: historyItem && !historyItem.isApplication && historyItem.filePath
        text: "Birlikte Aç"
        icon.name: "document-open-with"
        onTriggered: logic.runShellCommand("kioclient openProperties '" + historyItem.filePath + "'")
    }
    
    // Move to Trash
    PC3.MenuItem {
         visible: historyItem && !historyItem.isApplication && historyItem.filePath
         text: "Çöp Kutusuna Taşı"
         icon.name: "user-trash"
         onTriggered: {
             logic.runShellCommand("kioclient move '" + historyItem.filePath + "' trash:/")
             logic.removeFromHistory(historyItem.uuid)
         }
    }
    
    // Open Containing Location
    PC3.MenuItem {
         visible: historyItem && !historyItem.isApplication && historyItem.filePath
         text: "Bulunduğu Konumu Aç"
         icon.name: "folder-open"
         onTriggered: logic.runShellCommand("dolphin --select '" + historyItem.filePath + "'")
    }

    // Manage App
    PC3.MenuItem {
         visible: historyItem && historyItem.isApplication && historyItem.filePath
         text: "Uygulamayı Yönet"
         icon.name: "configure"
         onTriggered: logic.runShellCommand("kioclient openProperties '" + historyItem.filePath + "'")
    }

    PC3.MenuSeparator {}
    
    // Remove from History
    PC3.MenuItem {
        text: "Geçmişten Kaldır"
        icon.name: "edit-delete"
        onTriggered: logic.removeFromHistory(historyItem.uuid)
    }
}
