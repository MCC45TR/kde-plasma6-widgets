# 🗓️ MCalendar

A clean, modern, and privacy-focused calendar widget for KDE Plasma 6. MCalendar is designed to be fast, offline-first, and aesthetically pleasing, seamlessly integrating with your system's theme and locale.

## ✨ Key Features

*   **Adaptive Layout**: Automatically adjusts its view based on the widget size.
    *   **Compact Mode**: Shows a single month view for smaller spaces.
    *   **Dual View**: Expands to show two months side-by-side when widened.
    *   **Quad View**: Displays up to 4 months simultaneously in a 2x2 grid when fully expanded.
*   **Smart Navigation**:
    *   **Smooth Swiping**: Navigate through months effortlessly with swipe gestures or mouse wheel scrolling.
    *   **"Today" Quick Jump**: A floating button appears when you navigate away from the current date, allowing you to instantly return to today.
*   **System Integration**:
    *   **Theme Aware**: Automatically adapts to your Plasma color scheme (Kirigami integration).
    *   **Localized**: Fully supports 20+ languages, using system locale settings for date formats and first day of the week.
    *   **Custom Fonts**: Includes high-quality fonts (Roboto Condensed, NDot) for a polished look.
*   **Privacy-First**: Operates 100% offline with no external API calls or tracking.

## 📦 Installation

This widget is available as part of the [Plasma6Widgets](../README.md) collection.

### Manual Install
```bash
# Install the latest release
kpackagetool6 --type Plasma/Applet --install com.mcc45tr.mcalendar-v1.5.plasmoid
```
