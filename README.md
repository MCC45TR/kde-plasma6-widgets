# KDE Plasma 6 Widget Collection

A modern, highly customizable, and unified collection of widgets designed specifically for **KDE Plasma 6**.

This repository contains a suite of plasmoids ranging from advanced system tools (File Search, System Monitor) to essential desk utilities (Clock, Calendar, Notes), all re-engineered for performance, visual consistency, and ease of use.

## ✨ Key Features

*   **Plasma 6 Native**: Built fully on Qt6 and QML, optimized for the latest KDE Plasma desktop.
*   **Unified Design Language**: All widgets share a consistent look and feel, using system theme icons (`breeze-icons`) and standard metrics. No more mismatched custom icons.
*   **Global Localization**: Advanced synchronous JSON-based localization system supporting **10 languages** (English, Turkish, German, French, Spanish, Russian, Portuguese, Italian, Japanese, Czech).
*   **Modular Architecture**: Clean code structure with reusable components and logic separated into JavaScript modules.
*   **Feature-Rich**: "Power User" features like "Smart Query" in File Finder, dynamic MPRIS discovery in Music Player, and offline-first Calendar.

## 📦 Widget Catalog

### 🔍 File Finder (File Search)
A powerful Spotlight/Raycast alternative for Plasma.
*   **Architecture**: Built on a modular QML system with a custom synchronous localization engine and virtualized rendering for maximum performance.
*   **Smart Query**: Natively understands KRunner prefixes (`timeline:/today`, `gg:`, `kill`, `units`).
*   **View Profiles**: Switch between *Minimal*, *Developer* (with live telemetry & debug overlay), and *Power User* modes.
*   **Advanced Navigation**: Full arrow key navigation in tile view, tab cycling, and keyboard shortcuts (`Ctrl+1/2` for view modes).
*   **Rich Previews**: Instant hover previews for files and images with async thumbnail caching.
*   *[Read the detailed technical documentation here](./file-search/README.md)*

### 🎵 Music Player
A dynamic media controller that adapts to your workflow.
*   **Universal Control**: Automatically finds and controls the active media player (Spotify, VLC, browser, etc.).
*   **Smart Discovery**: Scans all active MPRIS services to lock onto your preferred player.
*   **Visual Polish**: "Squeeze" animations on buttons, dynamic pill-shaped app badge, and system-themed playback icons.

### 🗓️ Calendar
A clean, offline-focused calendar widget.
*   **Privacy-First**: Removed external dependencies (Google Calendar) for a fast, local experience.
*   **System Integration**: Uses system locale for date formats and month names.
*   **Modern UI**: Fluid animations and improved event markers.

### 🔋 Battery
A multi-device power monitor.
*   **Peripheral Support**: Layout expands to support up to 4 devices (Mouse, Keyboard, Headphones, etc.).
*   **Dynamic UI**: Charging indicators and text adapt to the available space using Roboto Condensed.

### 🔄 Advanced Reboot
Power management with granular control.
*   **Boot Options**: List and select UEFI/BIOS boot entries directly (requires `bootctl`).
*   **Safe UI**: Custom confirmation interface to prevent accidental shutdowns.

### ⏰ Clocks (Analog & Digital)
*   **Analog**: Minimalist design with dynamic opacity and hand smoothing.
*   **Digital**: Configurable font support (Roboto Condensed Variable) and hover-reveal seconds.

### 🛠️ Other Utilities
*   **System Monitor**: CPU, RAM, and Disk visualization.
*   **Notes**: List-based note taking with drag-and-drop reordering.
*   **Weather**: OpenMeteo based weather forecasts.
*   **Control Center**: Quick toggles for system settings.
*   **AUR Updates**: (Arch Linux) Update monitoring widget.

## 🚀 Installation

### Prerequisites
Ensure you have the Plasma 6 development tools installed:
*   `kpackagetool6`
*   `plasmawindowed` (for testing)
*   Python 3 (for the installation script)

### Automatic Installation (Recommended)
You can install all widgets at once using the provided script.

1.  Open a terminal in the project root.
2.  Make the script executable:
    ```bash
    chmod +x install_all.sh
    ```
3.  Run the script:
    ```bash
    ./install_all.sh
    ```
    *This will remove old versions and install the fresh ones to `~/.local/share/plasma/plasmoids/`.*

### Single Widget Installation & Testing
To install and immediately test a specific widget (e.g., `file-search`):

```bash
./install_all.sh file-search
```
*This command installs the widget and opens it in a standalone window for testing.*

### Manual Installation
You can also use the standard KDE tool:

```bash
cd widget-directory-name
kpackagetool6 --type Plasma/Applet --install .
# If updating:
kpackagetool6 --type Plasma/Applet --upgrade .
```

## ⚙️ Configuration

Most widgets come with a rich configuration panel accessible via **Right Click > Configure**.

*   **File Search**: Go to settings to choose your "View Profile" (Minimal, Developer, Power User) or manage Search History.
*   **Music Player**: Select your preferred default player in the "General" tab.

## 🐛 Troubleshooting

**Widget not showing up after install?**
You may need to restart the Plasma shell:
```bash
systemctl --user restart plasma-plasmashell
```
*Or simply log out and log back in.*

**"Error loading QML"?**
Check the logs using the Developer profile in widgets that support it, or run:
```bash
journalctl --user -f -g plasmashell
```
to see real-time errors.

**Missing Icons?**
Ensure you have the `breeze-icon-theme` or a compatible system icon theme installed, as widgets rely on standard icon names.

## 🤝 Contribution

Contributions are welcome! Please follow these guidelines:
1.  **Localization**: Add new strings to `localization.json` in the widget's root.
2.  **Icons**: Do **not** use local asset icons unless absolutely necessary; prefer system icons.
3.  **Versioning**: Update `metadata.json` version when making changes.

---
*Maintained by MCC45TR*

<small>Note: AI tools were used in the development of this project.</small>
