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
    QQC.Action {
        text: logic && logic.isPinned(matchId) ? i18n("Unpin") : i18n("Pin")
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
    QQC.Action {
        text: i18n("Open")
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
    
    QQC.MenuSeparator { visible: historyItem && !historyItem.isApplication && historyItem.filePath }
    
    // ===== COPY PATH =====
    QQC.Action {
        text: i18n("Copy Location")
        icon.name: "edit-copy"
        enabled: historyItem && historyItem.filePath
        onTriggered: {
            if (historyItem && historyItem.filePath) {
                var path = historyItem.filePath.toString()
                if (path.indexOf("file://") === 0) {
                    path = path.substring(7)
                }
                logic.runShellCommand("echo -n '" + path + "' | xclip -selection clipboard")
            }
        }
    }
    
    // ===== OPEN IN TERMINAL =====
    QQC.Action {
        text: i18n("Open in Terminal")
        icon.name: "utilities-terminal"
        enabled: historyItem && !historyItem.isApplication && root.isFolder
        onTriggered: {
            if (historyItem && historyItem.filePath) {
                var path = historyItem.filePath.toString()
                if (path.indexOf("file://") === 0) {
                    path = path.substring(7)
                }
                logic.runShellCommand("konsole --workdir '" + path + "'")
            }
        }
    }
    
    // ===== OPEN CONTAINING FOLDER =====
    QQC.Action {
        text: i18n("Open Containing Folder")
        icon.name: "folder-open"
        enabled: historyItem && !historyItem.isApplication && historyItem.filePath && !root.isFolder
        onTriggered: logic.runShellCommand("dolphin --select '" + historyItem.filePath + "'")
    }
    
    QQC.MenuSeparator { visible: historyItem && !historyItem.isApplication && historyItem.filePath }
    
    // ===== MOVE TO TRASH =====
    QQC.Action {
        text: i18n("Move to Trash")
        icon.name: "user-trash"
        enabled: historyItem && !historyItem.isApplication && historyItem.filePath
        onTriggered: {
            logic.runShellCommand("kioclient move '" + historyItem.filePath + "' trash:/")
            if (historyItem.uuid) {
                logic.removeFromHistory(historyItem.uuid)
            }
        }
    }
    
    // ===== SHOW PROPERTIES =====
    QQC.Action {
        text: i18n("Properties")
        icon.name: "document-properties"
        enabled: historyItem && !historyItem.isApplication && historyItem.filePath
        onTriggered: logic.runShellCommand("kioclient openProperties '" + historyItem.filePath + "'")
    }

    QQC.MenuSeparator { visible: historyItem && historyItem.isApplication }

    // ===== MANAGE APP =====
    QQC.Action {
        text: i18n("Edit Application...")
        icon.name: "configure"
        enabled: historyItem && historyItem.isApplication && historyItem.filePath
        onTriggered: logic.runShellCommand("kioclient openProperties '" + historyItem.filePath + "'")
    }

    QQC.MenuSeparator {}
    
    // ===== REMOVE FROM HISTORY =====
    QQC.Action {
        text: i18n("Remove from History")
        icon.name: "edit-delete"
        onTriggered: {
            if (historyItem && historyItem.uuid) {
                logic.removeFromHistory(historyItem.uuid)
            }
        }
    }
}
