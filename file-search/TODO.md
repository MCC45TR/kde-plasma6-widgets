# FileSearch Widget TODO List

## Search Improvements
- [ ] **Custom Search Priority Algorithm**: Implement a system where users can define specific category priorities (e.g., Applications first, then Documents).
- [ ] **Similarity-Based Fallback**: Remaining search results not covered by priority rules should be sorted based on string similarity/relevance.

## UI & UX Enhancements
- [ ] **Context Menu Rewrite**: Completely rewrite the right-click (Context Menu) system.
    - [ ] Explore using a more robust `PlasmaComponents3.Menu` structure.
    - [ ] Add more advanced file operations (e.g., copy path, open in terminal).
    - [ ] Improve positioning and animation logic.
- [ ] **Performance Audit**: Continue monitoring resource usage with the new lazy-loading architecture.

## Configuration
- [ ] **Priority Settings UI**: Create a configuration page to allow users to drag-and-drop categories to set their search priority.
