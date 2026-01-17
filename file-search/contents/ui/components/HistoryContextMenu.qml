import QtQuick
import QtQuick.Controls
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.plasma.components 3.0 as PC3

Item {
    id: root

    // Dependencies
    property var historyItem: null
    property var logic: null

    function popup(parentItem) {
        // If parentItem (MouseArea) is passed, we can rely on standard popup behavior in Menu
        contextMenu.popup()
    }

    // Helper to run commands
    Plasma5Support.DataSource {
        id: execSource
        engine: "executable"
        connectedSources: []
        onNewData: (source, data) => {
            disconnectSource(source)
        }
    }
    
    function runCmd(cmd) {
        execSource.connectedSources = [cmd]
    }

    PC3.Menu {
        id: contextMenu
        
        // Open (Standard)
        PC3.MenuItem {
            text: "Aç"
            icon.name: "document-open"
            onTriggered: {
                if (root.historyItem && root.historyItem.filePath) {
                     if (root.historyItem.filePath.toString().indexOf(".desktop") !== -1) {
                          root.runCmd("kioclient exec '" + root.historyItem.filePath + "'")
                     } else {
                          Qt.openUrlExternally(root.historyItem.filePath)
                     }
                }
            }
        }
        
        // Open With
        PC3.MenuItem {
            visible: root.historyItem && !root.historyItem.isApplication && root.historyItem.filePath
            text: "Birlikte Aç"
            icon.name: "document-open-with"
            onTriggered: {
                 root.runCmd("kioclient openProperties '" + root.historyItem.filePath + "'")
            }
        }
        
        // Move to Trash
        PC3.MenuItem {
             visible: root.historyItem && !root.historyItem.isApplication && root.historyItem.filePath
             text: "Çöp Kutusuna Taşı"
             icon.name: "user-trash"
             onTriggered: {
                 root.runCmd("kioclient move '" + root.historyItem.filePath + "' trash:/")
                 root.logic.removeFromHistory(root.historyItem.uuid)
             }
        }
        
        // Open Containing Location
        PC3.MenuItem {
             visible: root.historyItem && !root.historyItem.isApplication && root.historyItem.filePath
             text: "Bulunduğu Konumu Aç"
             icon.name: "folder-open"
             onTriggered: {
                  root.runCmd("dolphin --select '" + root.historyItem.filePath + "'")
             }
        }

        // Manage App
        PC3.MenuItem {
             visible: root.historyItem && root.historyItem.isApplication && root.historyItem.filePath
             text: "Uygulamayı Yönet"
             icon.name: "configure"
             onTriggered: {
                  root.runCmd("kioclient openProperties '" + root.historyItem.filePath + "'")
             }
        }

        PC3.MenuSeparator {}
        
        // Remove from History
        PC3.MenuItem {
            text: "Geçmişten Kaldır"
            icon.name: "edit-delete"
            onTriggered: {
                root.logic.removeFromHistory(root.historyItem.uuid)
            }
        }
    }
}
