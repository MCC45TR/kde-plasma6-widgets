import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import "../js/utils.js" as Utils

PlasmaComponents.Menu {
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
    PlasmaComponents.MenuItem {
        text: logic && logic.isPinned(matchId) ? i18nd("plasma_applet_com.mcc45tr.filesearch", "Unpin") : i18nd("plasma_applet_com.mcc45tr.filesearch", "Pin")
        icon.name: logic && logic.isPinned(matchId) ? "window-unpin" : "pin"
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

    PlasmaComponents.MenuSeparator {}

    // ===== OPEN (Standard) =====
    PlasmaComponents.MenuItem {
        text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Open")
        icon.name: "document-open"
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

    PlasmaComponents.MenuItem {
        text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Open With...")
        icon.name: "application-menu"
        visible: !!(historyItem && !historyItem.isApplication && historyItem.filePath)
        onTriggered: if (logic) logic.openWith(historyItem.filePath)
    }

    PlasmaComponents.MenuSeparator { visible: historyItem && !historyItem.isApplication && historyItem.filePath }

    // ===== COPY PATH =====
    PlasmaComponents.MenuItem {
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
    PlasmaComponents.MenuItem {
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
    PlasmaComponents.MenuItem {
        text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Open Containing Folder")
        icon.name: "folder-open"
        visible: !!(historyItem && !historyItem.isApplication && historyItem.filePath && !root.isFolder)
        onTriggered: logic.openFolder(historyItem.filePath)
    }

    PlasmaComponents.MenuSeparator { visible: !!(historyItem && !historyItem.isApplication && historyItem.filePath) }

    // ===== MOVE TO TRASH =====
    PlasmaComponents.MenuItem {
        text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Move to Trash")
        icon.name: "user-trash"
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
    PlasmaComponents.MenuItem {
        text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Properties")
        icon.name: "document-properties"
        visible: !!(historyItem && !historyItem.isApplication && historyItem.filePath)
        onTriggered: logic.showProperties(historyItem.filePath)
    }

    PlasmaComponents.MenuSeparator { visible: !!(historyItem && historyItem.isApplication) }

    // ===== MANAGE APP =====
    PlasmaComponents.MenuItem {
        text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Edit Application...")
        icon.name: "configure"
        visible: !!(historyItem && historyItem.isApplication && historyItem.filePath)
        onTriggered: logic.showProperties(historyItem.filePath)
    }

    PlasmaComponents.MenuSeparator { visible: !!(historyItem && historyItem.uuid) }

    // ===== REMOVE FROM HISTORY =====
    PlasmaComponents.MenuItem {
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
