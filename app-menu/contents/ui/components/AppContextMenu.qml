import QtQuick
import QtQuick.Controls as QQC
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.plasma.plasmoid
import "../js/PinnedManager.js" as PinnedManager

QQC.Menu {
    id: root

    // Item properties passed when opening the context menu
    // Object should have: matchId, filePath, display, decoration, category, triggerFunc (optional)
    property var actionItem: null

    // Helper: Check if item is an app
    readonly property bool isApp: {
        if (!actionItem) return false;
        var cat = actionItem.category || "";
        return (cat === "Uygulamalar" || cat === "Applications" || cat === "System Settings" || cat === "System" || cat === "Settings" || cat === "Development" || cat === "Games" || cat === "Graphics" || cat === "Internet" || cat === "Multimedia" || cat === "Office" || cat === "Utilities" || actionItem.isApplication);
    }

    // DataSource for shell commands
    Plasma5Support.DataSource {
        id: cmdSource
        engine: "executable"
        connectedSources: []
        onNewData: (sourceName, data) => {
            disconnectSource(sourceName);
        }
    }

    function runCmd(cmd) {
        cmdSource.connectedSources = [cmd];
    }
    
    // Keep pinning self-contained within the menu.
    function isPinned() {
        if (!actionItem || !actionItem.matchId) return false;
        var pins = PinnedManager.loadPinned(Plasmoid.configuration.pinnedItems);
        for (var i = 0; i < pins.length; i++) {
            if (pins[i].matchId === actionItem.matchId) return true;
        }
        return false;
    }
    
    function pinItem() {
        if (!actionItem) return;
        var pins = PinnedManager.loadPinned(Plasmoid.configuration.pinnedItems);
        pins = PinnedManager.pinItem(pins, {
            display: actionItem.display || "",
            decoration: actionItem.decoration || "application-x-executable",
            matchId: actionItem.matchId,
            filePath: actionItem.filePath || ""
        }, "global");
        Plasmoid.configuration.pinnedItems = PinnedManager.savePinned(pins);
    }
    
    function unpinItem() {
        if (!actionItem || !actionItem.matchId) return;
        var pins = PinnedManager.loadPinned(Plasmoid.configuration.pinnedItems);
        pins = PinnedManager.unpinItem(pins, actionItem.matchId, "global");
        Plasmoid.configuration.pinnedItems = PinnedManager.savePinned(pins);
    }

    // ===== PIN / UNPIN =====
    QQC.MenuItem {
        text: root.isPinned() ? i18n("Unpin") : i18n("Pin")
        icon.name: root.isPinned() ? "window-unpin" : "pin"
        enabled: actionItem !== null
        onTriggered: {
            if (root.isPinned()) {
                root.unpinItem();
            } else {
                root.pinItem();
            }
        }
    }
    
    QQC.MenuSeparator {}

    // ===== OPEN =====
    QQC.MenuItem {
        text: i18n("Open")
        icon.name: "document-open"
        onTriggered: {
            if (actionItem && actionItem.triggerFunc) {
                actionItem.triggerFunc();
            } else if (actionItem && actionItem.filePath) {
                if (actionItem.filePath.toString().indexOf(".desktop") !== -1 || actionItem.filePath.toString().indexOf("applications:") === 0) {
                    runCmd("kioclient exec '" + actionItem.filePath + "'");
                } else {
                    Qt.openUrlExternally(actionItem.filePath);
                }
            }
            try { Plasmoid.expanded = false; } catch (e) {}
        }
    }
    
    QQC.MenuSeparator { visible: actionItem && actionItem.filePath && !root.isApp }

    // ===== OPEN IN TERMINAL =====
    QQC.MenuItem {
        text: i18n("Open in Terminal")
        icon.name: "utilities-terminal"
        visible: actionItem && actionItem.filePath && !root.isApp
        onTriggered: {
            if (actionItem && actionItem.filePath) {
                var path = actionItem.filePath.toString().replace("file://", "");
                runCmd("konsole --workdir '" + path + "'");
            }
            try { Plasmoid.expanded = false; } catch (e) {}
        }
    }
    
    // ===== OPEN CONTAINING FOLDER =====
    QQC.MenuItem {
        text: i18n("Open Containing Folder")
        icon.name: "folder-open"
        visible: actionItem && actionItem.filePath && !root.isApp
        onTriggered: {
            if (actionItem && actionItem.filePath) {
                 var path = actionItem.filePath.toString().replace("file://", "");
                 runCmd("dolphin --select '" + path + "'");
            }
            try { Plasmoid.expanded = false; } catch (e) {}
        }
    }

    QQC.MenuSeparator { visible: actionItem && actionItem.filePath }

    // ===== MANAGE APP / PROPERTIES =====
    QQC.MenuItem {
        text: root.isApp ? i18n("Edit Application...") : i18n("Properties")
        icon.name: root.isApp ? "configure" : "document-properties"
        visible: actionItem && actionItem.filePath 
        onTriggered: {
            if (actionItem && actionItem.filePath) {
                runCmd("kioclient openProperties '" + actionItem.filePath + "'");
            }
            try { Plasmoid.expanded = false; } catch (e) {}
        }
    }
}
