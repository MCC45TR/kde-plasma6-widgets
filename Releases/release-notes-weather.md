### Release Tag
v1.1.2

### Release Title
Weather v1.1.2 - Layout Polish & JS Localization

### Release Notes
This update finalizes the layout adjustments and solves the localization loading issue permanently.

### 🚀 Improvements
*   **Localization Fix**: Switched from JSON/XHR to a pure **JS-based localization** (`localization.js`) method. This bypasses browser/QML file access restrictions, ensuring translations load reliably on all systems.
*   **Layout Polish**: Added a subtle spacing (4px) between the header buttons (Details/Daily) and the forecast grid in Large Mode for better visual separation.
*   **Code Cleanup**: Removed obsolete inline fallback logic in favor of the robust JS import method.

### 📦 Installation
1.  Download **`com.mcc45tr.weather-v1.1.2.plasmoid`**.
2.  Install via terminal:
    ```bash
    kpackagetool6 -t Plasma/Applet --upgrade com.mcc45tr.weather-v1.1.2.plasmoid
    ```

---

### Release Tag
v1.1.1

### Release Title
Weather v1.1.1 - UI Polish & Fixes

### Release Notes
## ⛅ Weather Widget v1.1.1 - Minor Polish Update

This release brings layout improvements for the Large Mode header and reinforces localization reliability.

### ✨ Improvements
*   **Large Mode Header Layout**:
    *   Temperature is now prominently displayed above the forecast cards on the left side.
    *   Weather icon size is optimized to grow within limits, ensuring no overlap with header buttons.
    *   Improved spacing and visual hierarchy.
*   **Localization Robustness**:
    *   Added inline fallback localizations for English and Turkish to ensure text is always displayed even if the JSON file fails to load.
    *   Fixed `loadLocales` logic to properly merge external JSON translations with built-in fallbacks.
    *   Added missing day name translations (`mon`, `tue`, etc.) into the fallback set.
*   **Optimized Codebase**:
    *   Refactored `main.qml` into modular components (`SmallModeLayout`, `WideModeLayout`, `LargeModeLayout`) for better maintainability and performance.

### 📦 Installation
1.  Download **`com.mcc45tr.weather-v1.1.1.plasmoid`**.
2.  Install via terminal:
    ```bash
    kpackagetool6 -t Plasma/Applet --upgrade com.mcc45tr.weather-v1.1.1.plasmoid
    ```

---
*Maintained by MCC45TR*
