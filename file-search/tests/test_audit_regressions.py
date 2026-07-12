from __future__ import annotations

import json
import gettext
from pathlib import Path
import re
import unittest


ROOT = Path(__file__).parents[1]


def read(relative: str) -> str:
    return (ROOT / relative).read_text(encoding="utf-8")


class AuditRegressionTests(unittest.TestCase):
    def test_desktop_keeps_single_custom_background_frame(self):
        main = read("contents/ui/main.qml")
        popup = read("contents/ui/components/SearchPopup.qml")
        self.assertIn("PlasmaCore.Types.NoBackground", main)
        self.assertNotIn("PlasmaCore.Types.StandardBackground", main)
        desktop_background = popup[popup.index("// Desktop background keeps"):popup.index("function cycleFocusSection")]
        self.assertIn("radius: 12", desktop_background)
        self.assertIn("border.width: 1", desktop_background)
        self.assertIn("color: popupRoot.bgColor", desktop_background)
        self.assertIn("opacity: 0.95", desktop_background)

    def test_process_bridge_is_locale_independent_and_bounded(self):
        # The earlier KRunner/Milou relay selected results by localized
        # category names ("command"/"shell"), so every process silently failed
        # with exit -1 on non-English systems. The plasma5support executable
        # engine is the supported, locale-independent bridge in Plasma 6.
        runner = read("contents/ui/components/AsyncProcess.qml")
        self.assertIn("org.kde.plasma.plasma5support as Plasma5Support", runner)
        self.assertIn('engine: "executable"', runner)
        self.assertNotIn("import org.kde.milou", runner)
        self.assertNotIn("Milou.ResultsModel", runner)
        self.assertIn("maximumOutputChars", runner)
        self.assertIn("timeoutMs", runner)
        other_sources = "\n".join(
            path.read_text(encoding="utf-8")
            for path in (ROOT / "contents").rglob("*.qml")
            if path.name != "AsyncProcess.qml"
        )
        self.assertNotIn("org.kde.plasma.plasma5support", other_sources)

    def test_all_config_pages_accept_shared_panel_properties(self):
        for name in ("ConfigCategories.qml", "ConfigRSS.qml", "ConfigDebug.qml", "ConfigHelp.qml"):
            page = read("contents/ui/config/" + name)
            for prop, prop_type in (
                ("cfg_panelWidthStep", "int"),
                ("cfg_panelWidthStepDefault", "int"),
                ("cfg_panelContentOpacity", "int"),
                ("cfg_panelContentOpacityDefault", "int"),
                ("cfg_panelOrientationAutomatic", "bool"),
                ("cfg_panelOrientationAutomaticDefault", "bool"),
                ("cfg_panelOrientation", "int"),
                ("cfg_panelOrientationDefault", "int"),
            ):
                self.assertIn("property " + prop_type + " " + prop, page)
        general = read("contents/ui/config/ConfigGeneral.qml")
        self.assertNotIn("previewCurrentLabel.text =", general)
        self.assertNotIn("previewSwitchAnim", general)

    def test_filter_chip_font_is_not_assigned_twice(self):
        components = "\n".join(path.read_text(encoding="utf-8") for path in (ROOT / "contents/ui/components").glob("*.qml"))
        self.assertNotRegex(components, r"font:\s*Kirigami\.Theme\.[A-Za-z]+Font\s*\n\s*font\.")
        self.assertNotRegex(components, r"font\s*:[^;\n}]+;[^\n}]*font\.")
        self.assertNotRegex(components, r"font\.[A-Za-z]+\s*:[^;\n}]+;[^\n}]*font\s*:")
        chips = read("contents/ui/components/FilterChips.qml")
        self.assertIn("font.bold: chip.isActive", chips)

    def test_panel_width_is_stepped_and_icon_matches_text(self):
        schema = read("contents/config/main.xml")
        config = read("contents/ui/config/ConfigGeneral.qml")
        main = read("contents/ui/main.qml")
        compact = read("contents/ui/components/CompactView.qml")
        self.assertIn('name="panelWidthStep"', schema)
        self.assertIn('name="panelContentOpacity"', schema)
        self.assertIn('name="panelOrientationAutomatic"', schema)
        self.assertIn('name="panelOrientation"', schema)
        self.assertRegex(schema, r'name="panelOrientationAutomatic"[\s\S]*?<default>true</default>')
        self.assertIn("to: 12", config)
        self.assertIn("stepSize: 1", config)
        self.assertIn("snapMode: Slider.SnapAlways", config)
        self.assertIn("maximumPanelWidth: panelThickness * 9", main)
        self.assertIn("minimumPanelWidth: 70", main)
        self.assertIn("PlasmaCore.Types.LeftEdge", main)
        self.assertIn("PlasmaCore.Types.RightEdge", main)
        self.assertIn("PanelLayoutUtils.effectivePlacement", main)
        self.assertIn("!isInPanel || Plasmoid.configuration.panelOrientationAutomatic !== false", main)
        self.assertIn("panelPlacement !== 0", main)
        self.assertIn("Layout.preferredHeight: isVerticalPanel ? baseWidth", main)
        self.assertIn("rotation: compactRoot.panelRotation", compact)
        self.assertIn("adaptivePlaceholder", compact)
        self.assertIn('"Search for files"', compact)
        self.assertIn("color: compactRoot.textColor", compact)
        self.assertNotIn("showSearchButtonBackground ? Kirigami.Theme.highlightedTextColor", compact)
        self.assertIn('i18nd("plasma_applet_com.mcc45tr.filesearch", "Text Input Mode")', config)
        self.assertIn('i18nd("plasma_applet_com.mcc45tr.filesearch", "Panel Orientation")', config)
        self.assertIn("visible: configGeneral.isInPanelConfiguration", config)
        self.assertIn("enabled: !automaticPanelOrientationCheck.checked", config)
        self.assertIn("visible: displayModeCombo.currentIndex === 1", config)
        mode_model = config[config.index("id: displayModeCombo"):config.index("id: panelWidthSlider")]
        self.assertNotIn("Medium Mode", mode_model)
        self.assertNotIn("Extra Wide Mode", mode_model)
        self.assertNotIn("Ultra Wide Mode", mode_model)
        self.assertIn("configDisplayMode === 0 ? 0 : 2", main)
        with (ROOT / "contents/locale/tr/LC_MESSAGES/plasma_applet_com.mcc45tr.filesearch.mo").open("rb") as handle:
            catalog = gettext.GNUTranslations(handle)
        self.assertEqual(catalog.gettext("Panel Width"), "Panel Genişliği")
        self.assertEqual(catalog.gettext("Text and Icon Opacity"), "Metin ve Simge Matlığı")

    def test_prefix_registry_is_shared_and_weather_alias_is_canonical(self):
        registry = read("contents/ui/js/PrefixRegistry.js")
        self.assertIn('{ canonical: "weather:", aliases: ["hava:"]', registry)
        for relative in (
            "contents/ui/components/SearchPopup.qml",
            "contents/ui/components/QueryHints.qml",
            "contents/ui/js/QueryPolicy.js",
        ):
            self.assertIn("PrefixRegistry", read(relative))
        self.assertNotIn('t === "hava:"', read("contents/ui/components/SearchPopup.qml"))

    def test_prefix_menu_is_a_single_strip_and_preserves_history(self):
        popup = read("contents/ui/components/SearchPopup.qml")
        hints = read("contents/ui/components/QueryHints.qml")
        history = read("contents/ui/components/HistoryTileView.qml")
        pinned = read("contents/ui/components/PinnedSection.qml")
        self.assertIn('readonly property bool isPrefixMenuOpen: searchText.trim() === ":"', popup)
        self.assertIn("searchText.length === 0 || popupRoot.isPrefixMenuOpen", popup)
        self.assertIn("!popupRoot.isPrefixMenuOpen", popup)
        self.assertIn("id: startupPrefixStrip", popup)
        self.assertIn("anchors.top: startupPrefixStrip.bottom", popup)
        self.assertIn("orientation: ListView.Horizontal", popup)
        self.assertIn("history grid below stays visible", popup)
        self.assertNotIn("Quick Commands", history)
        self.assertIn("gridSideInset", pinned)
        self.assertIn("Kirigami.Units.largeSpacing - Kirigami.Units.smallSpacing", pinned)
        self.assertIn("ListView {\n        id: prefixStrip", hints)
        self.assertIn("orientation: ListView.Horizontal", hints)
        self.assertIn("Kirigami.Units.gridUnit * 2.4", hints)
        self.assertNotIn("id: prefixGrid", hints)
        self.assertNotIn("Available Search Prefixes", hints)
        self.assertIn("text: modelData.label", popup)
        self.assertNotIn('text: modelData.label + "  " + modelData.prefix', popup)
        self.assertNotIn("icon.name: modelData.icon", popup[popup.index("id: startupPrefixStrip"):popup.index("// Result List View")])
        self.assertIn("text: modelData.hint", hints)
        prefix_delegate = hints[hints.index("id: prefixStrip"):hints.index("// Original Single Hint Content Layout")]
        self.assertNotIn("Kirigami.Icon", prefix_delegate)

    def test_prefix_selection_restores_input_focus_and_routes_filters(self):
        popup = read("contents/ui/components/SearchPopup.qml")
        registry = read("contents/ui/js/PrefixRegistry.js")
        self.assertIn("function selectPrefix(text)", popup)
        self.assertIn("searchBar.focusInput()", popup)
        self.assertIn("searchBar.cursorPosition = searchBar.text.length", popup)
        self.assertIn("PrefixRegistry.resultFilter", popup)
        self.assertIn('prefixFilter !== "All" ? prefixFilter : activeFilter', popup)
        for prefix_filter in ('canonical: "app:"', 'canonical: "documents:"', 'canonical: "images:"'):
            self.assertIn(prefix_filter, registry)

    def test_timeline_options_use_kio_machine_paths(self):
        hints = read("contents/ui/components/QueryHints.qml")
        self.assertIn('value: "timeline:/today"', hints)
        self.assertIn('value: "timeline:/calendar"', hints)
        self.assertIn('"-" + month', hints)
        self.assertIn('normalizedBase + isoDate', hints)
        for invalid_path in ("timeline:/yesterday", "timeline:/thisweek", "timeline:/thismonth"):
            self.assertNotIn(invalid_path, hints)

    def test_weather_ui_strings_use_widget_domain_and_turkish_is_complete(self):
        for relative in (
            "contents/ui/components/LargeModeLayout.qml",
            "contents/ui/components/WideModeLayout.qml",
        ):
            source = read(relative)
            self.assertNotRegex(source, r'i18n\("(?:Daily|Hourly) Forecast"\)')
            self.assertIn('i18nd("plasma_applet_com.mcc45tr.filesearch"', source)

        tr = read("translations/tr.po")
        required = {
            "Daily Forecast": "Günlük Tahmin", "Hourly Forecast": "Saatlik Tahmin",
            "umbrella": "şemsiye", "gloves": "eldiven", "heavy coat": "kalın mont",
            "coat": "mont", "sweater": "kazak", "sunglasses": "güneş gözlüğü",
            "windbreaker": "rüzgârlık", "Weather Info": "Hava Durumu Bilgisi",
            "Weather Frequency": "Hava Durumu Sıklığı",
        }
        for msgid, msgstr in required.items():
            self.assertIn(f'msgid "{msgid}"\nmsgstr "{msgstr}"', tr)

        with (ROOT / "contents/locale/tr/LC_MESSAGES/plasma_applet_com.mcc45tr.filesearch.mo").open("rb") as handle:
            catalog = gettext.GNUTranslations(handle)
        for msgid, msgstr in required.items():
            self.assertEqual(catalog.gettext(msgid), msgstr)

    def test_disabled_prefix_policy_guards_query_and_run(self):
        popup = read("contents/ui/components/SearchPopup.qml")
        self.assertIn("if (!isQueryAllowed(text))", popup)
        self.assertIn("if (!isQueryAllowed(query))", popup)
        self.assertEqual(popup.count("resultsModel.run("), 1)
        policy = read("contents/ui/js/QueryPolicy.js")
        registry = read("contents/ui/js/PrefixRegistry.js")
        for prefix in ("shell", "kill", "spell", "unit", "timeline:/", "gg:", "dd:"):
            self.assertIn(prefix, registry)
        self.assertIn("PrefixRegistry.isAllowed", policy)

    def test_rss_presets_and_sync_are_https_only(self):
        config = read("contents/ui/config/ConfigRSS.qml")
        preset_block = config[config.index("readonly property var presetSources"):config.index("function isPresetSelected")]
        self.assertNotIn("http://", preset_block)
        self.assertIn("Only HTTPS RSS URLs are allowed", config)
        sync = read("contents/tools/rss_sync.py")
        self.assertIn('allowed = {"https"}', sync)
        self.assertIn("MAX_RESPONSE_BYTES", sync)
        self.assertIn("ValidatingRedirectHandler", sync)
        launcher = read("contents/tools/rss_sync.sh")
        fallback = read("contents/tools/rss_sync_fallback.sh")
        self.assertIn("rss_sync_fallback.sh", launcher)
        self.assertIn("--proto '=https'", fallback)
        self.assertIn("resolve_public_address", fallback)

    def test_secrets_do_not_cross_process_arguments(self):
        self.assertFalse((ROOT / "contents/tools/secret_store.sh").exists())
        self.assertFalse((ROOT / "contents/ui/js/SecretStore.js").exists())
        store = read("contents/ui/components/KWalletStore.qml")
        self.assertIn("DBus.SessionBus.asyncCall", store)
        self.assertNotIn("executable", store.lower())

    def test_user_text_dbus_operations_are_typed(self):
        logic = read("contents/ui/components/LogicController.qml")
        self.assertIn("DBus.SessionBus.asyncCall", logic)
        self.assertIn('"ShowItems"', logic)
        self.assertIn('"setClipboardContents"', logic)
        for legacy_command in ("dbus-send --session", "xclip -selection", "wl-copy", "kioclient openProperties"):
            self.assertNotIn(legacy_command, logic)

    def test_startup_work_is_feature_gated(self):
        logic = read("contents/ui/components/LogicController.qml")
        schema = read("contents/config/main.xml")
        completed = logic[logic.index("Component.onCompleted"):logic.index("Connections {", logic.index("Component.onCompleted"))]
        self.assertIn("rssEnabled || rssSources.length > 0", completed)
        self.assertIn("if (rssEnabled && rssSources.length > 0)", completed)
        self.assertNotIn("ensureManAvailability", completed)
        weather_entry = schema[schema.index('name="weatherEnabled"'):schema.index('name="weatherUnits"')]
        self.assertIn("<default>false</default>", weather_entry)

    def test_real_previews_context_actions_and_drag_payloads(self):
        preview = read("contents/ui/js/PreviewUtils.js")
        primary = read("contents/ui/components/PrimaryResultPreview.qml")
        popup = read("contents/ui/components/SearchPopup.qml")
        menu = read("contents/ui/components/HistoryContextMenu.qml")
        logic = read("contents/ui/components/LogicController.qml")
        results_list = read("contents/ui/components/ResultsListView.qml")
        results_tile = read("contents/ui/components/ResultsTileView.qml")
        pinned = read("contents/ui/components/PinnedSection.qml")

        self.assertIn("getThumbnailCacheSource", preview)
        self.assertIn('"/normal/" + Qt.md5(uri) + ".png"', preview)
        self.assertIn("flatSortedData: tileData.flatSortedData", popup)
        self.assertIn("previewSource.length > 0", primary)
        self.assertIn("source: root.previewSource", primary)
        self.assertIn('text/uri-list', results_list)
        self.assertIn('text/uri-list', results_tile)
        self.assertIn('text/uri-list', pinned)
        self.assertIn('"Open With..."', menu)
        self.assertIn('"Search Again"', menu)
        self.assertIn('"Copy File Name"', menu)
        self.assertIn('"Copy Folder Path"', menu)
        self.assertIn('"Copy Link"', menu)
        self.assertIn('"Rename"', menu)
        self.assertIn('"Create Copy"', menu)
        self.assertIn('"Share / Send via KDE Connect..."', menu)
        self.assertIn('"Remove This Application from History"', menu)
        self.assertIn("function openWith(url)", logic)
        self.assertIn("function renameLocalFile(url)", logic)
        self.assertIn("function duplicateLocalFile(url)", logic)
        self.assertIn("function shareItem(url)", logic)
        self.assertIn("function removeApplicationFromHistory(item)", logic)
        self.assertIn("Qt.openUrlExternally(url.toString())", logic)
        self.assertIn("function openContainingFolder(url)", logic)

    def test_render_hot_paths_are_bounded(self):
        tile_data = read("contents/ui/components/TileDataManager.qml")
        match = re.search(r"itemMetadataCacheLimit:\s*(\d+)", tile_data)
        self.assertIsNotNone(match)
        self.assertGreaterEqual(int(match.group(1)), 1500)
        self.assertIn("itemMetadataCacheKeys[itemMetadataCacheHead++]", tile_data)
        self.assertIn("interval: 24", tile_data)
        results = read("contents/ui/components/ResultsListView.qml")
        self.assertNotIn("mapToItem(resultsListRoot", results)
        pinned = read("contents/ui/components/PinnedSection.qml")
        self.assertIn("reuseItems: true", pinned)
        self.assertIn("maxVisibleTileRows", pinned)
        for history_view in ("HistoryListView.qml", "HistoryTileView.qml"):
            history = read("contents/ui/components/" + history_view)
            self.assertIn("isCollapsed ? [] : modelData.items", history)
            self.assertRegex(history, r"sourceComponent: (?:PlasmaComponents\.)?ToolTip")

    def test_weather_coalesces_and_cancels(self):
        view = read("contents/ui/components/WeatherView.qml")
        service = read("contents/ui/components/WeatherService.js")
        self.assertIn("interval: 300", view)
        self.assertIn("requestGeneration", view)
        self.assertIn("activeRequest.cancel()", view)
        self.assertIn("requests[i].abort()", service)
        self.assertIn("controller.cancelled", service)

    def test_keyboard_activation_uses_sorted_view_identity(self):
        popup = read("contents/ui/components/SearchPopup.qml")
        results = read("contents/ui/components/ResultsListView.qml")
        self.assertIn("function activateCurrentResult()", popup)
        self.assertGreaterEqual(popup.count("activateCurrentResult();"), 2)
        self.assertIn("function activateCurrentItem()", results)
        self.assertIn("var data = flatSortedData[currentIndex]", results)
        self.assertIn("data.index !== undefined", results)
        self.assertNotIn("currentIndex: resultsListLoader.active ?", popup)

    def test_search_settings_and_rss_relevance_are_enforced(self):
        popup = read("contents/ui/components/SearchPopup.qml")
        tile_data = read("contents/ui/components/TileDataManager.qml")
        similarity = read("contents/ui/js/SimilarityUtils.js")
        for setting in ("searchAlgorithm", "minResults", "smartResultLimit"):
            self.assertIn(setting + ":", popup)
            self.assertIn("property " + ("bool" if setting == "smartResultLimit" else "int") + " " + setting, tile_data)
            self.assertIn(setting, similarity)
        self.assertIn("normalTitle.indexOf(lowerSearch)", tile_data)
        self.assertIn("normalContent.indexOf(lowerSearch)", tile_data)
        self.assertIn("advancedResultScore", similarity)
        self.assertIn("boundedDamerauDistance", similarity)
        self.assertIn("tokenCoverageScore", similarity)
        self.assertIn("_normalizedUrl", tile_data)

    def test_kio_previews_and_discover_fallback_are_integrated(self):
        preview = read("contents/ui/js/PreviewUtils.js")
        resolver = read("contents/ui/components/FilePreviewSource.qml")
        logic = read("contents/ui/components/LogicController.qml")
        thumbnailer = read("contents/tools/thumbnailer.sh")
        popup = read("contents/ui/components/SearchPopup.qml")
        tile_data = read("contents/ui/components/TileDataManager.qml")
        config = read("contents/ui/config/ConfigGeneral.qml")
        for key in ("audio", "ebooks", "creative", "folders", "fonts", "executables"):
            self.assertIn(key, preview)
            self.assertIn(f'key: "{key}"', config)
        self.assertIn("requestFileThumbnail", resolver)
        self.assertIn("thumbnailMaxConcurrentRequests", logic)
        self.assertIn('cat "thumbnail:$thumbnail_path"', thumbnailer)
        self.assertIn("89504e470d0a1a0a", thumbnailer)
        self.assertIn("ensureDiscoverAvailability", popup)
        self.assertIn("plasma-discover --search", logic)
        self.assertIn("hasStrongApplicationMatch", tile_data)
        self.assertIn('index: -2', tile_data)

    def test_live_category_reload_and_shared_classification(self):
        logic = read("contents/ui/components/LogicController.qml")
        history = read("contents/ui/js/HistoryManager.js")
        categories = read("contents/ui/js/CategoryManager.js")
        utils = read("contents/ui/js/utils.js")
        self.assertIn("function onCategorySettingsChanged()", logic)
        self.assertIn('.import "utils.js" as Utils', history)
        self.assertIn('.import "utils.js" as Utils', categories)
        self.assertNotIn("function detectSourceType", history)
        self.assertIn("function matchesResultFilter", utils)
        self.assertIn("function isDesktopEntry", utils)

    def test_rss_timestamps_and_weather_cache_are_persistent(self):
        logic = read("contents/ui/components/LogicController.qml")
        main = read("contents/ui/main.qml")
        weather = read("contents/ui/components/WeatherService.js")
        self.assertIn("persistRssSources();", logic)
        self.assertIn('weatherCachePath: weatherCacheBase + "/cache.json"', logic)
        self.assertIn("function saveWeatherCache(value)", logic)
        self.assertIn("controller.saveWeatherCache(result)", main)
        self.assertNotIn("forceRefresh", weather)
        self.assertEqual(weather.count("DEFAULT_FORECAST_DAYS"), 3)

    def test_tile_surfaces_share_plasma_native_visual_language(self):
        header = read("contents/ui/components/CategoryHeader.qml")
        pinned = read("contents/ui/components/PinnedSection.qml")
        native_menu = read("contents/ui/components/NativeContextMenu.qml")
        history_menu = read("contents/ui/components/HistoryContextMenu.qml")
        history = read("contents/ui/components/HistoryTileView.qml")
        history_list = read("contents/ui/components/HistoryListView.qml")
        results = read("contents/ui/components/ResultsTileView.qml")
        compact = read("contents/ui/components/CompactView.qml")
        self.assertIn("PlasmaComponents.ToolButton", header)
        for source in (pinned, history, history_list, results):
            self.assertIn("CategoryHeader {", source)
        self.assertNotIn('"Recent Searches"', history)
        self.assertNotIn('"Recent Searches"', history_list)
        self.assertIn('actionIcon: index === 0 ? "edit-clear-history"', history)
        self.assertIn("readonly property real textWidth: tileWidth", history)
        self.assertIn("maximumLineCount: 1", history)
        self.assertIn("maximumLineCount: 1", pinned)
        self.assertIn("PlasmaExtras.Highlight", history)
        self.assertIn("PlasmaExtras.Highlight", results)
        self.assertIn("Kirigami.Theme.highlightedTextColor", results)
        self.assertIn("NativeContextMenu {", pinned)
        self.assertIn('"Move to Top"', pinned)
        self.assertIn('"Move Left"', pinned)
        self.assertIn('"Move Right"', pinned)
        self.assertIn("PlasmaExtras.Menu", native_menu)
        self.assertIn("NativeContextMenu {", history_menu)
        self.assertNotIn("PlasmaComponents.Menu", pinned)
        self.assertNotIn("PlasmaComponents.Menu", history_menu)
        for source in (pinned, history, history_list):
            self.assertRegex(source, r"\.popup\([^,]+,\s*mouse\.x,\s*mouse\.y\)")
        self.assertNotRegex(compact, r"on(?:Entered|Exited):[^\n]*\.color\s*=")

    def test_component_fonts_follow_system_theme(self):
        components = ROOT / "contents/ui/components"
        fixed_pixels = []
        foreign_controls = []
        quick_controls_imports = []
        for path in components.glob("*.qml"):
            source = path.read_text(encoding="utf-8")
            if "import QtQuick.Controls" in source:
                quick_controls_imports.append(path.name)
            for match in re.finditer(r"font\.pixelSize:\s*\d+", source):
                fixed_pixels.append(f"{path.name}:{match.group(0)}")
            for match in re.finditer(r"(?<![\w.])(Menu|MenuItem|MenuSeparator|ToolTip|ScrollBar|ScrollView|Button|ToolButton|BusyIndicator)\s*\{", source):
                foreign_controls.append(f"{path.name}:{match.group(1)}")
        self.assertEqual(fixed_pixels, [])
        self.assertEqual(foreign_controls, [])
        self.assertEqual(quick_controls_imports, [])

    def test_search_surfaces_use_readable_system_font_sizes(self):
        main = read("contents/ui/main.qml")
        self.assertIn("uiFontFamily: Kirigami.Theme.defaultFont.family", main)
        self.assertNotIn("BarlowCondensed-Medium.ttf", main)
        self.assertIn("Math.max(Kirigami.Theme.defaultFont.pixelSize", main)

        for name in (
            "HistoryListView.qml", "HistoryTileView.qml", "PinnedSection.qml",
            "PrimaryResultPreview.qml", "ResultsListView.qml", "ResultsTileView.qml",
            "PowerView.qml",
        ):
            source = read("contents/ui/components/" + name)
            self.assertNotIn("Kirigami.Theme.smallFont", source, name)

    def test_dead_payload_is_removed(self):
        self.assertFalse((ROOT / "contents/fonts/BarlowCondensed-Light.ttf").exists())
        self.assertFalse((ROOT / "contents/fonts/BarlowCondensed-LightItalic.ttf").exists())
        for locale in ("az", "bn", "cs", "de", "el"):
            base = ROOT / "contents/locale" / locale / "LC_MESSAGES"
            self.assertFalse((base / "com.mcc45tr.file-search.mo").exists())
            self.assertFalse((base / "plasma_applet_com.mcc45tr.file-search.mo").exists())

    def test_version_and_release_evidence_agree(self):
        version = json.loads(read("metadata.json"))["KPlugin"]["Version"]
        self.assertEqual(version, "1.3.1")
        if (ROOT / "release/source-manifest.json").exists():
            manifest = json.loads(read("release/source-manifest.json"))
            self.assertEqual(manifest["version"], version)


if __name__ == "__main__":
    unittest.main()
