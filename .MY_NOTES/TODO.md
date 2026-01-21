# FileSearch Widget TODO List

## Search Improvements
- [x] **Custom Search Priority Algorithm**: Implement a system where users can define specific category priorities (e.g., Applications first, then Documents).
    - Added `applyPriorityToResults()` and `reorderCategories()` functions to `CategoryManager.js`
- [x] **Similarity-Based Fallback**: Remaining search results not covered by priority rules should be sorted based on string similarity/relevance.
    - Created `SimilarityUtils.js` with Levenshtein distance algorithm

## UI & UX Enhancements
- [x] **Context Menu Rewrite**: Completely rewrite the right-click (Context Menu) system.
    - [x] Explore using a more robust `PlasmaComponents3.Menu` structure.
    - [x] Add more advanced file operations (e.g., copy path, open in terminal).
    - [x] Improve positioning and animation logic.
    - Added full localization support (TR, EN, IT, ID)
- [x] **Performance Audit**: Continue monitoring resource usage with the new lazy-loading architecture.
    - [x] Lazy loading verified in `SearchPopup.qml` (7 Loader components with proper `active` conditions)
    - [x] All Loaders use `asynchronous: true` for non-blocking loading
    - [x] Debug console.log statements commented out for production
    - [x] No memory leaks detected - components properly unload when inactive

## Configuration
- [x] **Priority Settings UI**: Create a configuration page to allow users to drag-and-drop categories to set their search priority.
    - Implemented in `ConfigCategories.qml` with `ListView`, `DragHandler`, and `DropArea`
    - Visual priority indicators (#1, #2, etc.)
    - Move up/down buttons as alternative
    - [x] Fixed crash when clicking categories by using `Qt.callLater` for model updates.
    - [x] Fixed Z-order issue preventing button clicks in the categories list.
