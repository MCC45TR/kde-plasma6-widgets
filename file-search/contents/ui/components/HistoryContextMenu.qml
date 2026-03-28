import QtQuick
import QtQuick.Controls as QQC
import org.kde.kirigami as Kirigami

QQC.Menu {
    id: root

    // Dependencies
    property var historyItem: null
    property var logic: null

    // Helper: Check if item is a folder
    readonly property bool isFolder: {
        if (!historyItem) return false
        var cat = historyItem.category || ""
        return (cat === "Yerler" || cat === "Places" || cat === "Klasörler" || cat === "Folders")
    }

    // Helper: Get Match ID for pinning
    readonly property string matchId: {
        if (!historyItem) return ""
        return (historyItem.duplicateId !== undefined ? historyItem.duplicateId : historyItem.display) || ""
    }
    
    // ===== PIN / UNPIN =====
    QQC.MenuItem {
        text: logic && logic.isPinned(matchId) ? i18nd("plasma_applet_com.mcc45tr.filesearch", "Unpin") : i18nd("plasma_applet_com.mcc45tr.filesearch", "Pin")
        icon.name: logic && logic.isPinned(matchId) ? "window-unpin" : "pin"
        enabled: historyItem
        onTriggered: {
            if (historyItem) {
                var disp = historyItem.display || ""
                var dec = historyItem.decoration || "application-x-executable"
                var cat = historyItem.category || "Diğer"
                var path = historyItem.filePath || ""
                
                logic.togglePin({
                    display: disp,
                    decoration: dec,
                    category: cat,
                    matchId: matchId,
                    filePath: path
                })
            }
        }
    }
    
    QQC.MenuSeparator {}

    // ===== OPEN (Standard) =====
    QQC.MenuItem {
        text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Open")
        icon.name: "document-open"
        onTriggered: {
            if (historyItem && historyItem.filePath) {
                if (historyItem.filePath.toString().indexOf(".desktop") !== -1) {
                    logic.runShellCommand("kioclient6 exec \"" + historyItem.filePath + "\"")
                } else {
                    Qt.openUrlExternally(historyItem.filePath)
                }
            }
        }
    }
    
    QQC.MenuSeparator { visible: historyItem && !historyItem.isApplication && historyItem.filePath }
    
    // ===== COPY PATH =====
    QQC.MenuItem {
        text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Copy Path")
        icon.name: "edit-copy"
        enabled: historyItem && historyItem.filePath
        onTriggered: {
            if (historyItem && historyItem.filePath) {
                var path = historyItem.filePath.toString()
                if (path.indexOf("file://") === 0) {
                    path = path.substring(7)
                }
                logic.copyToClipboard(path)
            }
        }
    }
    
    // ===== OPEN IN TERMINAL =====
    QQC.MenuItem {
        text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Open in Terminal")
        icon.name: "utilities-terminal"
        visible: !!(historyItem && !historyItem.isApplication && (root.isFolder || (historyItem.filePath && historyItem.filePath.toString())))
        onTriggered: {
            if (historyItem && historyItem.filePath) {
                logic.openTerminal(historyItem.filePath)
            }
        }
    }
    
    // ===== OPEN CONTAINING FOLDER =====
    QQC.MenuItem {
        text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Open Containing Folder")
        icon.name: "folder-open"
        visible: !!(historyItem && !historyItem.isApplication && historyItem.filePath && !root.isFolder)
        onTriggered: logic.openFolder(historyItem.filePath)
    }
    
    QQC.MenuSeparator { visible: !!(historyItem && !historyItem.isApplication && historyItem.filePath) }
    
    // ===== MOVE TO TRASH =====
    QQC.MenuItem {
        text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Move to Trash")
        icon.name: "user-trash"
        visible: !!(historyItem && !historyItem.isApplication && historyItem.filePath)
        onTriggered: {
            logic.moveToTrash(historyItem.filePath)
            if (historyItem.uuid) {
                logic.removeFromHistory(historyItem.uuid)
            }
        }
    }
    
    // ===== SHOW PROPERTIES =====
    QQC.MenuItem {
        text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Properties")
        icon.name: "document-properties"
        visible: !!(historyItem && !historyItem.isApplication && historyItem.filePath)
        onTriggered: logic.runShellCommand("kioclient6 openProperties \"" + historyItem.filePath + "\"")
    }

    QQC.MenuSeparator { visible: !!(historyItem && historyItem.isApplication) }

    // ===== MANAGE APP =====
    QQC.MenuItem {
        text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Edit Application...")
        icon.name: "configure"
        visible: !!(historyItem && historyItem.isApplication && historyItem.filePath)
        onTriggered: logic.runShellCommand("kioclient6 openProperties \"" + historyItem.filePath + "\"")
    }

    QQC.MenuSeparator { visible: !!(historyItem && historyItem.uuid) }
    
    // ===== REMOVE FROM HISTORY =====
    QQC.MenuItem {
        text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Remove from History")
        icon.name: "edit-delete"
        visible: !!(historyItem && historyItem.uuid)
        onTriggered: {
            if (historyItem && historyItem.uuid) {
                logic.removeFromHistory(historyItem.uuid)
            }
        }
    }
}
