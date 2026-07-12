import QtQuick
import "../js/utils.js" as Utils

NativeContextMenu {
    id: root

    // Dependencies
    property var historyItem: null
    property var logic: null

    // Helper: Check if item is a folder
    readonly property bool isFolder: {
        if (!historyItem) return false
        return Utils.isFolderCategory(historyItem.category || "", historyItem.filePath || "", historyItem.decoration || "")
    }

    // Helper: Get Match ID for pinning
    readonly property string matchId: {
        if (!historyItem) return ""
        return historyItem.matchId || historyItem.display || ""
    }

    // ===== PIN / UNPIN =====
    NativeContextMenuItem {
        text: logic && logic.isPinned(matchId) ? i18nd("plasma_applet_com.mcc45tr.filesearch", "Unpin") : i18nd("plasma_applet_com.mcc45tr.filesearch", "Pin")
        icon: logic && logic.isPinned(matchId) ? "window-unpin" : "pin"
        enabled: historyItem
        onTriggered: {
            if (historyItem) {
                var disp = historyItem.display || ""
                var dec = historyItem.decoration || "application-x-executable"
                var cat = historyItem.category || "Other"
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

    NativeContextMenuSeparator {}

    // ===== OPEN (Standard) =====
    NativeContextMenuItem {
        text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Open")
        icon: "document-open"
        onTriggered: {
            if (historyItem && historyItem.filePath) {
                if (Utils.isDesktopEntry(historyItem.filePath)) {
                    logic.launchApp(historyItem.filePath)
                } else {
                    if (Utils.isSafeExternalUrl(historyItem.filePath)) Qt.openUrlExternally(historyItem.filePath)
                }
            }
        }
    }

    NativeContextMenuItem {
        text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Open With...")
        icon: "application-menu"
        visible: !!(historyItem && !historyItem.isApplication && historyItem.filePath)
        onTriggered: if (logic) logic.openWith(historyItem.filePath)
    }

    NativeContextMenuSeparator { visible: !!(historyItem && !historyItem.isApplication && historyItem.filePath) }

    // ===== COPY PATH =====
    NativeContextMenuItem {
        text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Copy Path")
        icon: "edit-copy"
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
    NativeContextMenuItem {
        text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Open in Terminal")
        icon: "utilities-terminal"
        visible: !!(historyItem && !historyItem.isApplication && (root.isFolder || (historyItem.filePath && historyItem.filePath.toString())))
        onTriggered: {
            if (historyItem && historyItem.filePath) {
                logic.openTerminal(historyItem.filePath)
            }
        }
    }

    // ===== OPEN CONTAINING FOLDER =====
    NativeContextMenuItem {
        text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Open Containing Folder")
        icon: "folder-open"
        visible: !!(historyItem && !historyItem.isApplication && historyItem.filePath && !root.isFolder)
        onTriggered: logic.openFolder(historyItem.filePath)
    }

    NativeContextMenuSeparator { visible: !!(historyItem && !historyItem.isApplication && historyItem.filePath) }

    // ===== MOVE TO TRASH =====
    NativeContextMenuItem {
        text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Move to Trash")
        icon: "user-trash"
        visible: !!(historyItem && !historyItem.isApplication && historyItem.filePath)
        onTriggered: {
            logic.moveToTrash(historyItem.filePath)
            if (logic.isPinned(matchId)) logic.unpinItem(matchId)
            if (historyItem.uuid) {
                logic.removeFromHistory(historyItem.uuid)
            }
        }
    }

    // ===== SHOW PROPERTIES =====
    NativeContextMenuItem {
        text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Properties")
        icon: "document-properties"
        visible: !!(historyItem && !historyItem.isApplication && historyItem.filePath)
        onTriggered: logic.showProperties(historyItem.filePath)
    }

    NativeContextMenuSeparator { visible: !!(historyItem && historyItem.isApplication) }

    // ===== MANAGE APP =====
    NativeContextMenuItem {
        text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Edit Application...")
        icon: "configure"
        visible: !!(historyItem && historyItem.isApplication && historyItem.filePath)
        onTriggered: logic.showProperties(historyItem.filePath)
    }

    NativeContextMenuSeparator { visible: !!(historyItem && historyItem.uuid) }

    // ===== REMOVE FROM HISTORY =====
    NativeContextMenuItem {
        text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Remove from History")
        icon: "edit-delete"
        visible: !!(historyItem && historyItem.uuid)
        onTriggered: {
            if (historyItem && historyItem.uuid) {
                logic.removeFromHistory(historyItem.uuid)
            }
        }
    }
}
