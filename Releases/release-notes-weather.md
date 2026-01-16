# ⛅ Weather Widget Release Notes

---

## 🚀 MWeather v1.1.3 - Optimization & Cleanup
*Released on January 16, 2026*

Internal cleanup and final transition to JS-based localization for ultimate reliability.

### 🧹 Improvements
*   **Asset Optimization**: Removed the obsolete `localization.json` file. All translations are now exclusively served via `localization.js`, which prevents any XHR-related loading issues.
*   **Code Maintenance**: Updated internal references and documentation to reflect the new modular localization structure.

### 📦 Installation
```bash
kpackagetool6 -t Plasma/Applet --upgrade com.mcc45tr.mweather-v1.1.3.plasmoid
```

---

## 🎨 MWeather v1.1.2 - Layout Polish & JS Localization
*Released on January 16, 2026*

This update finalizes layout adjustments and solves localization loading issues permanently.

### ✨ What's New
*   **Localization Fix**: Switched from JSON/XHR to a pure **JS-based localization** (`localization.js`) method. This bypasses browser/QML file access restrictions, ensuring translations load reliably on all systems.
*   **Layout Polish**: Added subtle spacing (4px) between the header buttons (Details/Daily) and the forecast grid in Large Mode for better visual separation.
*   **Code Cleanup**: Removed obsolete inline fallback logic in favor of the robust JS import method.

### 📦 Installation
```bash
kpackagetool6 -t Plasma/Applet --upgrade com.mcc45tr.mweather-v1.1.2.plasmoid
```

---

## 🛠️ MWeather v1.1.1 - UI Polish & Fixes
*Released on January 16, 2026*

A minor polish update focusing on header alignment and initial refactoring stabilization.

### 🔧 Improvements & Fixes
*   **Large Mode Header Layout**: 
    *   Temperature is now prominently displayed above the forecast cards on the left side.
    *   Weather icon size is optimized to grow within limits, ensuring no overlap with header buttons.
    *   Improved spacing and visual hierarchy.
*   **Refactor Optimization**: Finalized the extraction of `SmallModeLayout`, `WideModeLayout`, and `LargeModeLayout` into separate files for better maintainability.

### 📦 Installation
```bash
kpackagetool6 -t Plasma/Applet --upgrade com.mcc45tr.mweather-v1.1.1.plasmoid
```

---

## 🌟 MWeather v1.1.0 - Morphing Details & UI Overhaul
*Released on January 16, 2026*

The **"Polish & Animation"** Update. This update introduces major UI refinements and a high-end interaction model for Large Mode.

### ✨ What's New
*   **Morphing Details Animation**: The "Details" button in Large Mode now triggers a stunning, animated expansion. The button morphs into a full-glass details panel using professional `InOutQuad` easing.
*   **New Google Icon Packs**: Added three variations of Google Weather style icon sets (**v1, v2, v3**) for better customization.
*   **Refined Button Styling**: Implemented a "Pill Group" design for header buttons with consistent inner/outer corner radii and 4px spacing.
*   **Expanded Localization**: Now supports **20 languages** with refined translations for Turkish, Azerbaijani, Indonesian, and more.
*   **Infrastructure Refactor**: Extracted weather metrics into `WeatherDetailsView.qml` for perfect consistency between Wide and Large modes.
*   **Glassmorphism UI**: Improved the expanded overlay with better transparency and readability.

### 🔧 Improvements & Fixes
*   Syncing layout animations across all responsive modes.
*   Fixed click-to-close behavior in expanded views to be more intuitive.
*   Added professional GitHub-style documentation in `weather/README.md`.

### 📦 Installation
```bash
kpackagetool6 -t Plasma/Applet --upgrade com.mcc45tr.mweather-v1.1.0.plasmoid
```

---
*Maintained with ❤️ by MCC45TR*
