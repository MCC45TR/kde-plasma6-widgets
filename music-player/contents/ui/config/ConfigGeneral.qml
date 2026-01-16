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
                        locales = {}
                    }
                }
            }
        }
        xhr.send()
    }
    
    function tr(key, arg1) {
        var text = key
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
        // If preferred player not found in active list, reset to "Genel"
        playerCombo.currentIndex = 0
        cfg_preferredPlayer = ""
    }
    
    ListModel {
        id: appListModel
    }
    
    // Component.onCompleted moved up for localization loading
    
    // Timer to refresh list periodically (in case players start/stop)
    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: refreshPlayerList()
    }
    
    ComboBox {
        id: playerCombo
        Kirigami.FormData.label: page.tr("default_player") + ":"
        Layout.fillWidth: true
        model: appListModel
        textRole: "name"
        
        delegate: ItemDelegate {
            width: playerCombo.width
            height: 40
            enabled: model.available === true
            
            contentItem: RowLayout {
                spacing: 12
                opacity: model.available ? 1.0 : 0.4
                
                Kirigami.Icon {
                    source: model.icon ? model.icon : "application-x-executable"
                    Layout.preferredWidth: 24
                    Layout.preferredHeight: 24
                }
                
                Label {
                    text: model.name
                    font.pixelSize: 14
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }
            }
            
            highlighted: playerCombo.highlightedIndex === index
        }
        
        // Custom contentItem to display selected icon and text properly
        contentItem: Item {
            width: parent.width
            height: parent.height
            
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 30 // Space for drop-down arrow
                spacing: 12
                
                Kirigami.Icon {
                    source: playerCombo.currentIndex >= 0 && appListModel.count > 0 
                        ? (appListModel.get(playerCombo.currentIndex) ? appListModel.get(playerCombo.currentIndex).icon : "multimedia-player")
                        : "multimedia-player"
                    Layout.preferredWidth: 22
                    Layout.preferredHeight: 22
                }
                
                Label {
                    text: playerCombo.displayText
                    font.pixelSize: 14
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
    
    // Show active player count
    Label {
        Layout.fillWidth: true
        wrapMode: Text.Wrap
        font.pixelSize: 12
        font.bold: true
        color: Kirigami.Theme.positiveTextColor
        text: {
            var count = appListModel.count - 1 // Exclude "Genel"
            if (count <= 0) return page.tr("no_active_players")
            return page.tr("active_players_found", count)
        }
    }
    
    Label {
        Layout.fillWidth: true
        wrapMode: Text.Wrap
        font.pixelSize: 12
        opacity: 0.7
        text: cfg_preferredPlayer === "" 
            ? page.tr("all_sources_tracked")
            : page.tr("only_x_tracked", cfg_preferredPlayer)
    }
}
