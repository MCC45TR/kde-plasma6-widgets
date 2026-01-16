# 🎵 MMusic Player (Music Player)

A dynamic and modern media controller for KDE Plasma 6 that adapts to your workflow.

<p align="center">
  <img src="../.Samples/MMusic-Player-Small.png" height="150" style="margin: 5px;">
  <img src="../.Samples/MMusic-Player-Large.png" height="150" style="margin: 5px;">
  <br>
  <img src="../.Samples/MMusic-Player-Big.png" height="300" style="margin: 5px;">
</p>

## ✨ Features

- **Universal Control**: Automatically detects and controls any active media player (Spotify, VLC, Audacious, Elisa, web browsers, etc.).
- **Smart MPRIS Discovery**: Scans all active MPRIS services on the system.
- **Dynamic Icons**: Automatically displays the correct application icon for popular players.
- **Visual Squeeze**: Smooth animations when interacting with playback controls.
- **Flexible Tracking**: Choose to follow all media sources or lock onto a specific favorite player.
- **Multilingual**: Supports 20 languages with native-like localization.

## 🚀 Installation

### Prerequisites
- KDE Plasma 6
- `kpackagetool6` (usually part of `plasma-sdk` or `kde-cli-tools`)

### Quick Install
```bash
# From the project root
./install_all.sh music-player
```

### Manual Install
```bash
kpackagetool6 --type Plasma/Applet --install .
```

## ⚙️ Configuration

1. **Right-click** the widget and select **Configure Music Player**.
2. Under the **General** tab:
   - **Default Media Player**: Select a specific player to track, or choose "General (Follow All)" to automatically switch to whatever is currently playing.
   - The interface shows real-time discovery of active players.

## 🌍 Supported Languages

- English (en)
- Turkish (tr)
- German (de)
- French (fr)
- Italian (it)
- Spanish (es)
- Portuguese (pt)
- Russian (ru)
- Japanese (ja)
- Chinese (zh)
- Greek (el)
- Azerbaijani (az)
- Armenian (hy)
- Romanian (ro)
- Czech (cs)
- Hindi (hi)
- Bengali (bn)
- Urdu (ur)
- Indonesian (id)
- Persian (fa)

---
Maintained with ❤️ by [MCC45TR](https://github.com/MCC45TR)
