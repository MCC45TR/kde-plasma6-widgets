import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.private.mpris as Mpris
Kirigami.FormLayout {
    id: page
    anchors.fill: parent

    Component.onCompleted: {
        Qt.callLater(refreshPlayerList)
    }
    property string cfg_preferredPlayer
    property string cfg_preferredPlayerDefault: ""
    property bool cfg_showPlayerBadge
    property bool cfg_showPlayerBadgeDefault: false
    
    // Appearance config (to silence property warnings - these are handled by ConfigAppearance)
    property int cfg_edgeMargin
    property int cfg_edgeMarginDefault: 10
    property double cfg_backgroundOpacity
    property double cfg_backgroundOpacityDefault: 1.0
    property bool cfg_showPanelControls
    property bool cfg_showPanelControlsDefault: true
    property bool cfg_panelShowTitle
    property bool cfg_panelShowTitleDefault: true
    property bool cfg_panelShowArtist
    property bool cfg_panelShowArtistDefault: true
    property bool cfg_panelAutoFontSize
    property bool cfg_panelAutoFontSizeDefault: true
    property bool cfg_panelScrollingText
    property bool cfg_panelScrollingTextDefault: true
    property int cfg_panelMaxWidth
    property int cfg_panelMaxWidthDefault: 350
    property int cfg_panelScrollingSpeed
    property int cfg_panelScrollingSpeedDefault: 0
    property int cfg_panelFontSize
    property int cfg_panelFontSizeDefault: 12
    property int cfg_panelLayoutMode
    property int cfg_panelLayoutModeDefault: 0
    property int cfg_popupLayoutMode
    property int cfg_popupLayoutModeDefault: 0
    property bool cfg_panelAutoButtonSize
    property bool cfg_panelAutoButtonSizeDefault: true
    property int cfg_panelButtonSize
    property int cfg_panelButtonSizeDefault: 32
    property bool cfg_panelDynamicWidth
    property bool cfg_panelDynamicWidthDefault: true
    
    property string title: i18n("General")
    Mpris.Mpris2Model { 
        id: mpris2Model
        onRowsInserted: refreshPlayerList()
        onRowsRemoved: refreshPlayerList()
        onModelReset: refreshPlayerList()
    }
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
    function getAvailablePlayers() {
        var players = []
        var count = mpris2Model.rowCount()
        for (var i = 0; i < count; i++) {
            var savedIndex = mpris2Model.currentIndex
            mpris2Model.currentIndex = i
            var player = mpris2Model.currentPlayer
            if (player && player.identity) {
                var id = player.identity.toLowerCase()
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
        appListModel.append({ 
            id: "", 
            name: i18n("General"), 
            icon: "multimedia-player",
            available: true
        })
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
        playerCombo.currentIndex = 0
        cfg_preferredPlayer = ""
    }
    ListModel {
        id: appListModel
    }
    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: refreshPlayerList()
    }
    ComboBox {
        id: playerCombo
        Kirigami.FormData.label: i18n("Default Media Player") + ":"
        Layout.fillWidth: true
        Layout.minimumWidth: 350
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
        contentItem: Item {
            implicitWidth: contentRow.implicitWidth
            implicitHeight: contentRow.implicitHeight
            RowLayout {
                id: contentRow
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
                    Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                }
                Label {
                    text: playerCombo.displayText
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignLeft
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
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
    Item {
        Kirigami.FormData.label: i18n("Selected Player:")
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
                    var count = Math.max(0, appListModel.count - 1)
                    if (count <= 0) return i18n("⚠ No active players")
                    return i18n("✓ %1 active players found", count)
                }
            }
            Label {
                Layout.fillWidth: true
                wrapMode: Text.Wrap
                opacity: 0.7
                text: cfg_preferredPlayer === "" 
                    ? i18n("All media sources are tracked.")
                    : i18n("Only \"%1\" is tracked.", cfg_preferredPlayer)
            }
        }
    }
    CheckBox {
        id: showBadgeCheckbox
        Kirigami.FormData.label: i18n("Show media player badge") + ":"
        checked: cfg_showPlayerBadge
         onCheckedChanged: cfg_showPlayerBadge = checked
    }
}
