# MSI Control Widget Changelog

## [1.0.0] - 2026-01-31

### ✨ Initial Release

**Features:**
- 🌡️ Real-time CPU/GPU temperature monitoring with color-coded display
- 🌀 Fan speed monitoring for both CPU and GPU
- ⚡ Shift Mode switching (eco/comfort/sport/turbo) via msi-ec driver
- 🔥 Cooler Boost toggle for maximum fan performance
- 🔋 Battery charge limit control (60-100%) for battery longevity
- 📷 Integrated webcam enable/disable toggle
- 📊 Firmware version display

**Technical:**
- System tray integration with compact temp badge icon
- Kirigami HIG compliant design
- PlasmaComponents and PlasmaExtras for consistent KDE look
- `pkexec` for privileged sysfs write operations
- 2-second polling interval for real-time updates
- Full i18n localization support (Turkish/English)

**Requirements:**
- `msi-ec` kernel module loaded
- `polkit` for privilege elevation
