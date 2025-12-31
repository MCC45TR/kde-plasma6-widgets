import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    id: page
    
    property string cfg_preferredPlayer
    
    // Known media applications
    readonly property var knownMediaApps: [
        { id: "spotify", name: "Spotify", icon: "spotify" },
        { id: "elisa", name: "Elisa", icon: "elisa" },
        { id: "vlc", name: "VLC", icon: "vlc" },
        { id: "audacious", name: "Audacious", icon: "audacious" },
        { id: "rhythmbox", name: "Rhythmbox", icon: "rhythmbox" },
        { id: "clementine", name: "Clementine", icon: "clementine" },
        { id: "strawberry", name: "Strawberry", icon: "strawberry" },
        { id: "amarok", name: "Amarok", icon: "amarok" },
        { id: "lollypop", name: "Lollypop", icon: "lollypop" },
        { id: "cantata", name: "Cantata", icon: "cantata" },
        { id: "mpv", name: "mpv", icon: "mpv" },
        { id: "smplayer", name: "SMPlayer", icon: "smplayer" },
        { id: "celluloid", name: "Celluloid", icon: "celluloid" },
        { id: "haruna", name: "Haruna", icon: "haruna" },
        { id: "totem", name: "GNOME Videos", icon: "totem" },
        { id: "kaffeine", name: "Kaffeine", icon: "kaffeine" },
        { id: "dragonplayer", name: "Dragon Player", icon: "dragonplayer" },
        { id: "brave", name: "Brave", icon: "brave" },
        { id: "firefox", name: "Firefox", icon: "firefox" },
        { id: "chromium", name: "Chromium", icon: "chromium" },
        { id: "chrome", name: "Google Chrome", icon: "google-chrome" },
        { id: "edge", name: "Microsoft Edge", icon: "microsoft-edge" },
        { id: "opera", name: "Opera", icon: "opera" },
        { id: "vivaldi", name: "Vivaldi", icon: "vivaldi" }
    ]
    
    function setCurrentIndexFromConfig() {
        for (var i = 0; i < appListModel.count; i++) {
            if (appListModel.get(i).id === cfg_preferredPlayer) {
                playerCombo.currentIndex = i
                return
            }
        }
        playerCombo.currentIndex = 0
    }
    
    ListModel {
        id: appListModel
    }
    
    Component.onCompleted: {
        appListModel.clear()
        appListModel.append({ id: "", name: "Genel (Tümünü Takip Et)", icon: "multimedia-player" })
        
        for (var i = 0; i < knownMediaApps.length; i++) {
            appListModel.append(knownMediaApps[i])
        }
        
        setCurrentIndexFromConfig()
    }
    
    ComboBox {
        id: playerCombo
        Kirigami.FormData.label: "Varsayılan Oynatıcı:"
        Layout.fillWidth: true
        model: appListModel
        textRole: "name"
        
        delegate: ItemDelegate {
            width: playerCombo.width
            height: 40
            
            contentItem: RowLayout {
                spacing: 12
                
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
                if (item) {
                     cfg_preferredPlayer = item.id
                }
            }
        }
    }
    
    Label {
        Layout.fillWidth: true
        wrapMode: Text.Wrap
        font.pixelSize: 12
        opacity: 0.7
        text: cfg_preferredPlayer === "" 
            ? "Tüm medya kaynakları takip edilir. Öncelik: Müzik oynatıcılar → Video oynatıcılar → Tarayıcılar"
            : "Sadece seçilen uygulama takip edilir. Medya yokken tıklanırsa uygulama başlatılır."
    }
}
