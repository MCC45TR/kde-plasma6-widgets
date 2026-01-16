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
