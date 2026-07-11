# Browser Search Widget - TODO

Future features and improvements roadmap.

## 🚀 Phase 1: Core Improvements
- [ ] **Smart Browser Detection**: Detect default browser and use correct incognito/history commands
  - Firefox: `firefox --private-window`
  - Chrome/Chromium: `google-chrome --incognito`
  - Brave: `brave --incognito`
- [ ] **Search Suggestions**: Show autocomplete suggestions while typing
- [ ] **Search History**: Keep local search history with quick access

## 🎨 Phase 2: UI/UX Enhancements
- [ ] **Animation**: Add smooth animations for button interactions
- [ ] **Theme Support**: Better dark/light mode adaptation
- [ ] **Compact/Expanded Toggle**: Smooth transition animation
- [ ] **Custom Icons**: Allow users to select custom icons for buttons
- [ ] **Keyboard Shortcuts**: Global keyboard shortcuts for quick search

## ⚙️ Phase 3: Configuration
- [ ] **Search Engine Selection UI**: Visual config panel with engine logos
- [ ] **Custom Search Engines**: Add/remove custom search engines
- [ ] **Quick Access Bookmarks**: Pin favorite sites as quick access buttons
- [ ] **Browser Selection**: Override system default browser

## 🔗 Phase 4: Integration
- [ ] **KRunner Integration**: Use Milou for search suggestions
- [ ] **Bookmark Import**: Import bookmarks from browsers
- [ ] **Tab Management**: Show open tabs from running browsers (D-Bus)
- [ ] **Quick Commands**: Support for `!g`, `!ddg`, `!w` bang commands

## 🌍 Phase 5: Localization
- [ ] **RTL Support**: Right-to-left layout for Arabic, Hebrew, Persian
- [ ] **Locale-aware Defaults**: Auto-select search engine based on locale

## 🐛 Known Issues
- [ ] Incognito command needs browser-specific implementation
- [ ] History URL only works for Chromium-based browsers
