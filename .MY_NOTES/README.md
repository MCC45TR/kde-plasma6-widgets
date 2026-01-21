# File Search Widget (Plasma 6)

Advanced, keyboard-centric file search and launcher widget for KDE Plasma 6. Designed as a powerful alternative to KRunner, featuring file previews, smart navigation, and a modern modular architecture.

![File Finder Banner](https://placeholder-image-url.com) *This widget is comparable to Spotlight (macOS) or Raycast, but native to Plasma.*

## 🚀 Key Capabilities

### 🌍 Localized Interaction (20 Languages)
Fully localized UI including search hints, button labels, and configuration menus. Supported languages: `en`, `tr`, `de`, `fr`, `es`, `it`, `nl`, `pl`, `pt`, `ru`, `ja`, `zh`, `ko`, `uk`, `hi`, `ar`, `sv`, `da`, `fi`, `no`.

### 🧠 Smart Query System & Interactive Hints
The widget goes beyond simple text matching. It understands context and provides interactive feedback:
*   **Interactive Prefix Buttons**: Typing prefixes like `timeline:/` dynamically reveals actionable buttons (e.g., "Today", "This Week") for quick filtering.
*   **Direct Runner Access**: Use standard prefixes like `timeline:/today`, `file:/`, `man:/` (checks installation).
*   **Syntax Hinting**: The UI detects known prefixes and displays helpful inline hints or warnings (e.g., if `man` is missing).
*   **Calculations & Commands**: Natively handles `=` calculations and system commands (`kill`, `sleep`, `gg:`).

### ⌨️ Advanced Keyboard Navigation
Designed for "Hands on Keyboard" workflow:
*   **Smart Tile Navigation**: In Tile View, use `Arrow Keys` (↑↓←→) to navigate the grid naturally. Columns are remembered during vertical movement.
*   **Section Cycling**: `Tab` and `Shift+Tab` cycle focus between the Search Input, Results Area, and History/Actions.
*   **Instant Shortcuts**:
    *   `Ctrl + 1`: Switch to List View.
    *   `Ctrl + 2`: Switch to Tile View.
    *   `Ctrl + Space`: Toggle Instant Preview for the selected item.
    *   `Ctrl + Return`: Execute default action (e.g., open file).

### 👁️ Rich Previews & Pinning
*   **Pinning System**: Right-click to pin favorite files or apps to the top of the list. Pinned items persist across sessions.
*   **Hover Tooltips**: Mouse over any file to see metadata (Type, Size, Modified Date, Parent Path).
*   **Visual Thumbnails**: Cached, high-performance thumbnail generation.

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
*   `PinnedSection.qml`: Manages pinned favorite items.
*   `ConfigCategories.qml`: Drag-and-drop category management with merged groups.
*   `QueryHints.qml`: Interactive regex-based syntax analyzer with signals.

### 2. Synchronous Localization (Legacy-Free)
We abandoned the old `i18n()` calls in favor of a robust, synchronous JavaScript module (`localization.js`):
*   **Zero Latency**: Translations are loaded instantly on init.
*   **Hot-Swapping**: Language changes apply immediately without reloading the plasmoid.
*   **JSON Backend**: All 20 supported languages are stored in a structured JSON object.

### 3. Performance & Rendering
*   **Incremental Rendering**: Utilizes `Milou` with pagination handling.
*   **Virtualization**: Both List and Tile views use QML's `ListView` and `GridView` virtualization.
*   **Lazy Loading**: Heavy components (Settings, detailed Previews) are unloaded when not in use.

### 4. Custom History & Category Manager
*   **Category Logic**: Custom `CategoryManager.js` allows "Merging" categories (showing them together) while keeping others "Separate" and prioritized.
*   **Smart Scoring**: History remembers `matchId` and `runnerId` to prioritize exact matches.

---

## 🛠️ Configuration

The widget exposes a comprehensive configuration schema:

| Tab | Settings |
| :--- | :--- |
| **Appearance** | View Profile (Minimal/Power/Dev), Icon Sizes, Grid Density. |
| **Search** | Default Runners (check/uncheck). |
| **Categories** | **New**: Drag-and-drop ordering. Group categories into "Prioritized" (top) or "Merged" (bottom). Toggle visibility per category. Search Algorithm (Fuzzy/Exact/StartsWith) and Result Limits. |
| **Debug** | (Visible in Dev Profile) Toggle Overlays, Dump State to JSON. |
| **Help** | Built-in guide listing all shortcuts and features (Localized). |

---

## 🔧 Debugging & Telemetry

Enable the **Developer Profile** to access the overlay:
*   **Render Time**: Measures the ms taken to draw the result list.
*   **Latency**: Time between keystroke and query result.
*   **Index Source**: Shows which KRunner plugin provided the current result.
*   **Dump State**: A button in settings exports the current widget state (props, history, config) to a JSON file for bug reporting.
