# File Search Widget (Plasma 6)

Advanced, keyboard-centric file search and launcher widget for KDE Plasma 6. Designed as a powerful alternative to KRunner, featuring file previews, smart navigation, and a modern modular architecture.

![File Finder Banner](https://placeholder-image-url.com) *This widget is comparable to Spotlight (macOS) or Raycast, but native to Plasma.*

## 🚀 Key Capabilities

### 🧠 Smart Query System
The widget goes beyond simple text matching. It understands context and KRunner query syntax:
*   **Direct Runner Access**: Use standard prefixes like `timeline:/today` (for recent files) or `#unicode` (for characters).
*   **Calculations & Unit Conv**: Queries starting with `=` or standard unit conversions are handled natively.
*   **System Commands**: Commands like `kill`, `sleep`, or `gg:` (web shortcuts) are recognized.
*   **Syntax Hinting**: The UI detects known prefixes and displays helpful inline hints to guide the user (e.g., showing available flags).

### ⌨️ Advanced Keyboard Navigation
Designed for "Hands on Keyboard" workflow:
*   **Smart Tile Navigation**: In Tile View, use `Arrow Keys` (↑↓←→) to navigate the grid naturally. Columns are remembered during vertical movement.
*   **Section Cycling**: `Tab` and `Shift+Tab` cycle focus between the Search Input, Results Area, and History/Actions.
*   **Instant Shortcuts**:
    *   `Ctrl + 1`: Switch to List View.
    *   `Ctrl + 2`: Switch to Tile View.
    *   `Ctrl + Space`: Toggle Instant Preview for the selected item.
    *   `Ctrl + Return`: Execute default action (e.g., open file).
*   **Focus Management**: Custom focus handling ensures the UI never loses focus state during async reloads.

### 👁️ Rich Previews
Enhance your search without opening files:
*   **Hover Tooltips**: Mouse over any file to see metadata (Type, Size, Modified Date, Parent Path).
*   **Visual Thumbnails**: Cached, high-performance thumbnail generation for images (PNG, JPG, WEBP, etc.).
*   **Expandable Text**: Long descriptions or paths are intelligently truncated but revealed on interaction.

### 🎨 Adaptive View Profiles
The widget adapts to different user types via the "Profiles" system in Settings:
1.  **Minimal**: Clean interface, no clutter, standard list view.
2.  **Power User**: Max information density, extra-wide mode, previews enabled, detailed history.
3.  **Developer**: Activates the **Debug Overlay** and **Telemetry**, showing render times, model counts, and latency stats.

---

## 🏗️ Technical Architecture

This widget represents a significant engineering effort to overcome standard QML limitations in Plasma widgets.

### 1. Modular Component System
Unlike monolithic widgets, File Search is broken down into isolated, reusable components:
*   `ResultsListView.qml`: Virtualized list rendering logic.
*   `ResultsTileView.qml`: Grid logic with custom keyboard navigation handlers.
*   `CompactView.qml`: Minimal launcher mode.
*   `PreviewPopup.qml`: Isolated overlay logic.
*   `QueryHints.qml`: Regex-based syntax analyzer.

### 2. Synchronous Localization (Legacy-Free)
We abandoned the old `i18n()` calls in favor of a robust, synchronous JavaScript module (`localization.js`):
*   **Zero Latency**: Translations are loaded instantly on init.
*   **Hot-Swapping**: Language changes apply immediately without reloading the plasmoid.
*   **JSON Backend**: All 10 supported languages are stored in a structured JSON file, decoupled from QML logic.

### 3. Performance & Rendering
*   **Incremental Rendering**: Utilizes `Milou` with a limit of 50 items initially, but handles pagination internally to keep the UI fluid.
*   **Virtualization**: Both List and Tile views use QML's `ListView` and `GridView` virtualization. Only visible delegates are rendered.
*   **Lazy Loading**: Heavy components (like the Settings window or detailed Previews) are completely unloaded (`Loader` sourceComponent: null) when not in use to save memory.

### 4. Custom History Manager
A dedicated `HistoryManager.js` handles state persistence:
*   **Smart Scoring**: History isn't just FIFO. It remembers `matchId` and `runnerId` to prioritize exact matches you've launched before.
*   **Storage**: Persists data to standard config but serializes complex objects safely.

---

## 🛠️ Configuration

The widget exposes a comprehensive configuration schema:

| Tab | Settings |
| :--- | :--- |
| **Appearance** | View Profile (Minimal/Power/Dev), Icon Sizes, Grid Density. |
| **Search** | Algorithm tuning, History limits, Default Runners. |
| **Debug** | (Visible in Dev Profile) Toggle Overlays, Dump State to JSON. |
| **Help** | Built-in guide listing all shortcuts and features (Localized). |

---

## 🔧 Debugging & Telemetry

Enable the **Developer Profile** to access the overlay:
*   **Render Time**: Measures the ms taken to draw the result list.
*   **Latency**: Time between keystroke and query result.
*   **Index Source**: Shows which KRunner plugin provided the current result.
*   **Dump State**: A button in settings exports the current widget state (props, history, config) to a JSON file for bug reporting.
