# 🌦️ Weather Widget (Plasma 6)

A stunning, responsive weather widget designed for KDE Plasma 6, featuring smooth animations, multiple provider support, and a detail-rich expandable interface.

## ✨ Key Features

*   **Adaptive Design**: Automatically switches layouts based on widget size:
    *   **Small Mode**: Compact view focusing on current temperature and icon.
    *   **Wide Mode**: Expanded card view with detailed metrics (Humidity, Wind, UV, Pressure, etc.).
    *   **Large Mode**: Comprehensive dashboard with a full Daily/Hourly forecast grid and a dedicated "Details" overlay.
*   **Smooth Animations**:
    *   **Morphing Details**: The "Details" button in Large Mode seamlessly expands into a full-glass overlay using advanced geometry transitions (`InOutQuad` easing).
    *   **Fluid Interactions**: Refined hover effects, fade-ins, and layout shifts.
*   **Multi-Provider Engine**:
    *   **Open-Meteo**: (Default) Fast, accurate, and requires **no API key**.
    *   **OpenWeatherMap**: Detailed global data (requires API key).
    *   **WeatherAPI.com**: Alternative reliable source (requires API key).
*   **Global Localization**:
    *   Fully translated into **20 languages** including English, Turkish, German, French, Spanish, Russian, Japanese, Chinese, and more.
    *   Smart fallback system ensures no text is ever missing.
*   **Smart Caching**: Efficient data caching (5-minute TTL) to minimize network usage and API quota consumption.

## 🛠️ Installation

### Automatic
Run the installer script from the root of the collection:
```bash
./install_all.sh weather
```

### Manual
```bash
cd weather
kpackagetool6 --type Plasma/Applet --install .
# To update:
kpackagetool6 --type Plasma/Applet --upgrade .
```

## ⚙️ Configuration

1.  **Right-Click** the widget and select **Configure Weather**.
2.  **General**: Choose your provider (Open-Meteo recommended for instant setup without keys).
3.  **Location**:
    *   Leave empty for **Auto-Detection** (via IP).
    *   Enter `City` or `City, Country` (e.g., "Istanbul" or "Berlin, DE") for specific locations.
4.  **Appearance**: Toggle between Icon Packs (Google Flat, System, etc.) and Unit systems (Metric/Imperial).

## 🎮 Interaction

*   **Left Click (Wide/Large)**: Expand the details view or specific cards.
*   **Middle Click**: Force refresh weather data.
*   **Scroll**: Navigate through the detailed metrics in the expanded view.

## 🤝 Contribution

Localized strings are stored in `contents/ui/localization.js`. If you'd like to improve a translation, simple edit the JS file (following the existing format) and submit a Pull Request!

## 📜 Credits & License

This widget uses **Google Weather Icons** (v1, v2, and v3) to provide a premium visual experience.
*   **Icon Designs**: All rights belong to **Google**.
*   **Collection Source**: Icons sourced and optimized from the [google-weather-icons](https://github.com/mrdarrengriffin/google-weather-icons) repository by **Darren Griffin**.
*   **License**: This project is distributed under the **GPL-3.0 License**. The weather icons are used under fair use/brand assett guidelines for personal desktop customization.

---
*Part of the [Plasma6Widgets](../README.md) Collection.*
