// PlayerData.js - Player verilerini içeren sabit değerler

// Player priority list (dedicated music players first, browsers last)
var playerPriority = [
    "spotify", "elisa", "amarok", "clementine", "audacious", "rhythmbox",
    "lollypop", "strawberry", "cantata", "vlc", "mpv", "smplayer",
    "celluloid", "haruna", "totem", "kaffeine", "dragon",
    "chromium", "chrome", "firefox", "brave", "edge", "opera", "vivaldi"
]

// Known app icons mapping
var appIcons = {
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

// Desktop file mapping for app launching
var desktopFiles = {
    "spotify": "spotify.desktop",
    "elisa": "org.kde.elisa.desktop",
    "vlc": "vlc.desktop",
    "audacious": "audacious.desktop",
    "rhythmbox": "org.gnome.Rhythmbox3.desktop",
    "clementine": "clementine.desktop",
    "strawberry": "org.strawberrymusicplayer.strawberry.desktop",
    "amarok": "org.kde.amarok.desktop",
    "lollypop": "org.gnome.Lollypop.desktop",
    "cantata": "cantata.desktop",
    "mpv": "mpv.desktop",
    "smplayer": "smplayer.desktop",
    "celluloid": "io.github.celluloid_player.Celluloid.desktop",
    "haruna": "org.kde.haruna.desktop",
    "totem": "org.gnome.Totem.desktop",
    "kaffeine": "org.kde.kaffeine.desktop",
    "dragonplayer": "org.kde.dragonplayer.desktop",
    "brave": "brave-browser.desktop",
    "firefox": "firefox.desktop",
    "chromium": "chromium.desktop",
    "chrome": "google-chrome.desktop",
    "edge": "microsoft-edge.desktop",
    "opera": "opera.desktop",
    "vivaldi": "vivaldi-stable.desktop"
}

function getPlayerIcon(identity) {
    if (!identity) return "multimedia-player"
    var id = identity.toLowerCase()
    for (var key in appIcons) {
        if (id.includes(key)) return appIcons[key]
    }
    return "multimedia-player"
}

function getDesktopFile(appId) {
    return desktopFiles[appId] || (appId + ".desktop")
}

function formatTime(micros) {
    var s = Math.floor(micros / 1000000)
    var m = Math.floor(s / 60)
    s = s % 60
    return m + ":" + (s < 10 ? "0" + s : s)
}
