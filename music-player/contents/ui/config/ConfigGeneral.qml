import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.private.mpris as Mpris

Kirigami.FormLayout {
    id: page
    
    // --- Localization Logic ---
    property var locales: ({})
    property string currentLocale: Qt.locale().name.substring(0, 2)
    
    // Fallback dictionary in case JSON fails to load
    readonly property var fallbackLocales: {
        "no_media_playing": "No Media Playing",
        "prev_track": "Previous Track",
        "next_track": "Next Track",
        "general_all": "General (Follow All)",
        "default_player": "Default Media Player",
        "inactive_players_hidden": "Inactive players are not shown.",
        "selected_player": "Selected Player:",
        "select_app": "Select Application",
        "no_active_players": "⚠ No active players",
        "active_players_found": "✓ %1 active players found",
        "all_sources_tracked": "All media sources are tracked.",
        "only_x_tracked": "Only \"%1\" is tracked."
    }
    
    function loadLocales() {
        var xhr = new XMLHttpRequest()
        xhr.open("GET", Qt.resolvedUrl("../localization.json"))
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200 || xhr.status === 0) {
                    try {
                        locales = JSON.parse(xhr.responseText)
                        refreshPlayerList() // Refresh list to update "General" text
                    } catch (e) {
                        console.log("Error parsing localization.json: " + e)
                    }
                }
            }
        }
        xhr.send()
    }
    
    function tr(key, arg1) {
        var text = fallbackLocales[key] || key.replace(/_/g, " ") // Use fallback or readable key
        
        if (locales[currentLocale] && locales[currentLocale][key]) {
            text = locales[currentLocale][key]
        } else if (locales["en"] && locales["en"][key]) {
            text = locales["en"][key]
        }
        
        if (arg1 !== undefined) {
            text = text.replace("%1", arg1)
        }
        return text
    }
    
    Component.onCompleted: {
        loadLocales()
        // Delay to ensure MPRIS model is populated
        Qt.callLater(refreshPlayerList)
    }
    // --- End Localization Logic ---
    
    property string cfg_preferredPlayer
    
    // MPRIS2 Model to get currently active players
    Mpris.Mpris2Model { 
        id: mpris2Model
        
        onRowsInserted: refreshPlayerList()
        onRowsRemoved: refreshPlayerList()
        onModelReset: refreshPlayerList()
    }
    
    // Known app icons mapping (for display purposes)
    readonly property var appIcons: {
        "spotify": "spotify",
        "elisa": "elisa",
        "vlc": "vlc",
        "audacious": "audacious",
        "rhythmbox": "rhythmbox",
        "clementine": "clementine",
        "strawberry": "strawberry",
        "amarok": "amarok",
        "lollypop": "lollypop",
        "cantata": "cantata",
        "mpv": "mpv",
        "smplayer": "smplayer",
        "celluloid": "celluloid",
        "haruna": "haruna",
        "totem": "totem",
        "kaffeine": "kaffeine",
        "dragonplayer": "dragonplayer",
        "brave": "brave",
        "firefox": "firefox",
        "chromium": "chromium",
        "chrome": "google-chrome",
        "edge": "microsoft-edge",
        "opera": "opera",
        "vivaldi": "vivaldi"
    }
    
    function getPlayerIcon(identity) {
        if (!identity) return "multimedia-player"
        var id = identity.toLowerCase()
        for (var key in appIcons) {
            if (id.includes(key)) return appIcons[key]
        }
        return "multimedia-player"
    }
    
    // Get list of available players from MPRIS
    function getAvailablePlayers() {
        var players = []
        var count = mpris2Model.rowCount()
        
        for (var i = 0; i < count; i++) {
            // Access the player at index i using currentIndex temporarily
            var savedIndex = mpris2Model.currentIndex
            mpris2Model.currentIndex = i
            var player = mpris2Model.currentPlayer
            if (player && player.identity) {
                var id = player.identity.toLowerCase()
                // Avoid duplicates
                var found = false
                for (var j = 0; j < players.length; j++) {
                    if (players[j].id === id) {
                        found = true
                        break
                    }
                }
                if (!found) {
                    players.push({
                        id: id,
                        name: player.identity,
                        icon: getPlayerIcon(player.identity)
                    })
                }
            }
            mpris2Model.currentIndex = savedIndex
        }
        return players
    }
    
    function refreshPlayerList() {
        var currentSelection = cfg_preferredPlayer
        appListModel.clear()
        
        // Always add "General" option first
        appListModel.append({ 
            id: "", 
            name: page.tr("general_all"), 
            icon: "multimedia-player",
            available: true
        })
        
        // Get active players
        var availablePlayers = getAvailablePlayers()
        
        for (var i = 0; i < availablePlayers.length; i++) {
            var p = availablePlayers[i]
            appListModel.append({
                id: p.id,
                name: p.name,
                icon: p.icon,
                available: true
            })
        }
        
        // Restore selection
        setCurrentIndexFromConfig(currentSelection)
    }
    
    function setCurrentIndexFromConfig(targetId) {
        var target = (targetId !== undefined) ? targetId : cfg_preferredPlayer
        for (var i = 0; i < appListModel.count; i++) {
            if (appListModel.get(i).id === target) {
                playerCombo.currentIndex = i
                return
            }
        }
        // If preferred player not found in active list, reset to "General"
        playerCombo.currentIndex = 0
        cfg_preferredPlayer = ""
    }
    
    ListModel {
        id: appListModel
    }
    
    // Timer to refresh list periodically (in case players start/stop)
    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: refreshPlayerList()
    }
    
    // --- UI Elements ---
    
    ComboBox {
        id: playerCombo
        Kirigami.FormData.label: page.tr("default_player") + ":"
        Layout.fillWidth: true
        model: appListModel
        textRole: "name"
        
        delegate: ItemDelegate {
            width: playerCombo.width
            contentItem: RowLayout {
                spacing: 10
                opacity: model.available ? 1.0 : 0.4
                
                Kirigami.Icon {
                    source: model.icon || "application-x-executable"
                    Layout.preferredWidth: 22
                    Layout.preferredHeight: 22
                }
                
                Label {
                    text: model.name
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    verticalAlignment: Text.AlignVCenter
                }
            }
            highlighted: playerCombo.highlightedIndex === index
        }
        
        // Simplified content item without nested layouts causing issues
        contentItem: Item {
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 30
                spacing: 10
                
                Kirigami.Icon {
                    source: playerCombo.currentIndex >= 0 && appListModel.count > playerCombo.currentIndex
                        ? (appListModel.get(playerCombo.currentIndex).icon || "multimedia-player")
                        : "multimedia-player"
                    Layout.preferredWidth: 22
                    Layout.preferredHeight: 22
                }
                
                Label {
                    text: playerCombo.displayText
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }
        
        onCurrentIndexChanged: {
            if (currentIndex >= 0 && currentIndex < appListModel.count) {
                var item = appListModel.get(currentIndex)
                if (item && item.available) {
                     cfg_preferredPlayer = item.id
                }
            }
        }
    }
    
    // Status Information
    Item {
        Kirigami.FormData.label: page.tr("selected_player")
        Kirigami.FormData.isSection: false
        Layout.fillWidth: true
        Layout.preferredHeight: statusColumn.implicitHeight
        
        ColumnLayout {
            id: statusColumn
            anchors.fill: parent
            spacing: 5
            
            Label {
                Layout.fillWidth: true
                wrapMode: Text.Wrap
                font.bold: true
                color: Kirigami.Theme.positiveTextColor
                text: {
                    var count = Math.max(0, appListModel.count - 1) // Exclude "General"
                    if (count <= 0) return page.tr("no_active_players")
                    return page.tr("active_players_found", count)
                }
            }
            
            Label {
                Layout.fillWidth: true
                wrapMode: Text.Wrap
                opacity: 0.7
                text: cfg_preferredPlayer === "" 
                    ? page.tr("all_sources_tracked")
                    : page.tr("only_x_tracked", cfg_preferredPlayer)
            }
        }
    }
}
