import pathlib
import unittest


ROOT = pathlib.Path(__file__).resolve().parents[1]


class RuntimeLifetimeRegressions(unittest.TestCase):
    def test_completed_weather_requests_are_released(self):
        source = (ROOT / "contents/ui/components/WeatherService.js").read_text(
            encoding="utf-8"
        )
        self.assertIn("xhr.onloadend = function ()", source)
        self.assertIn("controller.requests.splice(index, 1)", source)
        self.assertIn("xhr.onreadystatechange = null", source)

    def test_plasma_layout_keys_are_accepted_by_config_pages(self):
        source = (ROOT / "contents/ui/config/ConfigGeneral.qml").read_text(
            encoding="utf-8"
        )
        for key in ("cfg_expanding", "cfg_length"):
            self.assertIn("property", source)
            self.assertIn(key, source)
            self.assertIn(key + "Default", source)


if __name__ == "__main__":
    unittest.main()
