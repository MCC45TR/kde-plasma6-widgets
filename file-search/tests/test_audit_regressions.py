from __future__ import annotations

import json
from pathlib import Path
import re
import unittest


ROOT = Path(__file__).parents[1]


def read(relative: str) -> str:
    return (ROOT / relative).read_text(encoding="utf-8")


class AuditRegressionTests(unittest.TestCase):
    def test_disabled_prefix_policy_guards_query_and_run(self):
        popup = read("contents/ui/components/SearchPopup.qml")
        self.assertIn("if (!isQueryAllowed(text))", popup)
        self.assertIn("if (!isQueryAllowed(query))", popup)
        self.assertEqual(popup.count("resultsModel.run("), 1)
        policy = read("contents/ui/js/QueryPolicy.js")
        for prefix in ("shell", "kill", "spell", "unit", "timeline:/", "gg:", "dd:"):
            self.assertIn(prefix, policy)

    def test_rss_presets_and_sync_are_https_only(self):
        config = read("contents/ui/config/ConfigRSS.qml")
        preset_block = config[config.index("readonly property var presetSources"):config.index("function isPresetSelected")]
        self.assertNotIn("http://", preset_block)
        self.assertIn("Only HTTPS RSS URLs are allowed", config)
        sync = read("contents/tools/rss_sync.py")
        self.assertIn('allowed = {"https"}', sync)
        self.assertIn("MAX_RESPONSE_BYTES", sync)
        self.assertIn("ValidatingRedirectHandler", sync)

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
        completed = logic[logic.index("Component.onCompleted"):logic.index("Connections {", logic.index("Component.onCompleted"))]
        self.assertIn("rssEnabled || rssSources.length > 0", completed)
        self.assertNotIn("ensureManAvailability", completed)

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
            self.assertIn("sourceComponent: ToolTip", history)

    def test_weather_coalesces_and_cancels(self):
        view = read("contents/ui/components/WeatherView.qml")
        service = read("contents/ui/components/WeatherService.js")
        self.assertIn("interval: 300", view)
        self.assertIn("requestGeneration", view)
        self.assertIn("activeRequest.cancel()", view)
        self.assertIn("requests[i].abort()", service)
        self.assertIn("controller.cancelled", service)

    def test_dead_payload_is_removed(self):
        self.assertFalse((ROOT / "contents/fonts/BarlowCondensed-Light.ttf").exists())
        self.assertFalse((ROOT / "contents/fonts/BarlowCondensed-LightItalic.ttf").exists())
        for locale in ("az", "bn", "cs", "de", "el"):
            base = ROOT / "contents/locale" / locale / "LC_MESSAGES"
            self.assertFalse((base / "com.mcc45tr.file-search.mo").exists())
            self.assertFalse((base / "plasma_applet_com.mcc45tr.file-search.mo").exists())

    def test_version_and_release_evidence_agree(self):
        version = json.loads(read("metadata.json"))["KPlugin"]["Version"]
        self.assertEqual(version, "1.3.0")
        if (ROOT / "release/source-manifest.json").exists():
            manifest = json.loads(read("release/source-manifest.json"))
            self.assertEqual(manifest["version"], version)


if __name__ == "__main__":
    unittest.main()
