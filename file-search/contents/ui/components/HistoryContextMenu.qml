import QtQuick
import "../js/utils.js" as Utils

NativeContextMenu {
    id: root

    // Dependencies
    property var historyItem: null
    property var logic: null
    signal searchAgainRequested(var item)

    readonly property string itemPath: historyItem && historyItem.filePath ? historyItem.filePath.toString() : ""
    readonly property bool isWebLink: Utils.isHttpUrl(itemPath)
    readonly property bool isLocalFile: !historyItem || historyItem.isApplication ? false : Utils.decodeLocalPath(itemPath).indexOf("/") === 0

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

    function pinPayload() {
        return {
            display: historyItem.display || "",
            decoration: historyItem.decoration || "application-x-executable",
            category: historyItem.category || "Other",
            matchId: matchId,
            filePath: itemPath
        }
    }

    function localName() {
        var path = Utils.decodeLocalPath(itemPath).replace(/\/+$/, "")
        return path.substring(path.lastIndexOf("/") + 1)
    }

    function folderPath() {
        var path = Utils.decodeLocalPath(itemPath).replace(/\/+$/, "")
        return root.isFolder ? path : Utils.getParentFolder(path)
    }

    // ===== PIN / UNPIN =====
    NativeContextMenuItem {
        text: logic && logic.isPinned(matchId) ? i18nd("plasma_applet_com.mcc45tr.filesearch", "Unpin") : i18nd("plasma_applet_com.mcc45tr.filesearch", "Pin")
        icon: logic && logic.isPinned(matchId) ? "window-unpin" : "pin"
        enabled: historyItem
        onTriggered: {
            if (historyItem) {
                logic.togglePin(pinPayload())
            }
        }
    }

    NativeContextMenuItem {
        text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Pin Globally")
        icon: "pin"
        visible: !!(historyItem && logic && logic.activityPinningEnabled && logic.currentActivityId !== "global" && !logic.isPinnedForActivity(matchId, "global"))
        onTriggered: logic.pinItemToActivity(pinPayload(), "global")
    }

    NativeContextMenuSeparator {}

    NativeContextMenuItem {
        text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Search Again")
        icon: "edit-find"
        visible: !!(historyItem && (historyItem.queryText || !itemPath))
        onTriggered: root.searchAgainRequested(historyItem)
    }

    NativeContextMenuSeparator { visible: !!(historyItem && (historyItem.queryText || !itemPath)) }

    // ===== OPEN (Standard) =====
    NativeContextMenuItem {
        text: root.isWebLink ? i18nd("plasma_applet_com.mcc45tr.filesearch", "Open in Browser") : i18nd("plasma_applet_com.mcc45tr.filesearch", "Open")
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

    NativeContextMenuItem {
        text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Copy File Name")
        icon: "edit-copy"
        visible: root.isLocalFile
        onTriggered: logic.copyToClipboard(root.localName())
    }

    NativeContextMenuItem {
        text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Copy Folder Path")
        icon: "edit-copy"
        visible: root.isLocalFile && root.folderPath().length > 0
        onTriggered: logic.copyToClipboard(root.folderPath())
    }

    NativeContextMenuItem {
        text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Copy Link")
        icon: "edit-copy"
        visible: root.isWebLink
        onTriggered: logic.copyToClipboard(root.itemPath)
    }

    // ===== OPEN IN TERMINAL =====
    NativeContextMenuItem {
        text: root.isFolder ? i18nd("plasma_applet_com.mcc45tr.filesearch", "Open Terminal Here") : i18nd("plasma_applet_com.mcc45tr.filesearch", "Open Terminal in Containing Folder")
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

    NativeContextMenuItem {
        text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Rename")
        icon: "edit-rename"
        visible: root.isLocalFile
        onTriggered: logic.renameLocalFile(root.itemPath)
    }

    NativeContextMenuItem {
        text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Create Copy")
        icon: "edit-copy"
        visible: root.isLocalFile
        onTriggered: logic.duplicateLocalFile(root.itemPath)
    }

    NativeContextMenuItem {
        text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Share / Send via KDE Connect...")
        icon: "document-share"
        visible: root.isLocalFile || root.isWebLink
        onTriggered: logic.shareItem(root.itemPath)
    }

    NativeContextMenuSeparator { visible: root.isLocalFile || root.isWebLink }

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

    NativeContextMenuItem {
        text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Remove This Application from History")
        icon: "edit-clear-history"
        visible: !!(historyItem && historyItem.isApplication)
        onTriggered: logic.removeApplicationFromHistory(historyItem)
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
