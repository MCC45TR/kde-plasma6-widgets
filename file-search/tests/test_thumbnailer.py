from __future__ import annotations

import base64
import os
from pathlib import Path
import stat
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).parents[1]
SCRIPT = ROOT / "contents" / "tools" / "thumbnailer.sh"
PNG = base64.b64decode(
    "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII="
)


class ThumbnailerTests(unittest.TestCase):
    def test_generates_valid_atomic_png_and_reuses_fresh_cache(self):
        with tempfile.TemporaryDirectory() as directory:
            workspace = Path(directory)
            source = workspace / "document.txt"
            source.write_text("preview me", encoding="utf-8")
            fake_bin = workspace / "bin"
            fake_bin.mkdir()
            fake_client = fake_bin / "kioclient6"
            payload = base64.b64encode(PNG).decode("ascii")
            fake_client.write_text(
                f"#!/bin/sh\nprintf '%s' '{payload}' | base64 -d\n",
                encoding="utf-8",
            )
            fake_client.chmod(0o755)
            env = os.environ.copy()
            env["PATH"] = str(fake_bin) + os.pathsep + env["PATH"]
            cache = workspace / "cache"

            first = subprocess.run(
                ["sh", str(SCRIPT), str(source), str(cache), "abc123"],
                text=True, capture_output=True, env=env,
            )
            self.assertEqual(first.returncode, 0, first.stdout + first.stderr)
            target = cache / "abc123.png"
            self.assertEqual(target.read_bytes(), PNG)
            self.assertEqual(stat.S_IMODE(target.stat().st_mode), 0o600)
            self.assertFalse(list(cache.glob(".abc123.*")))

            fake_client.write_text("#!/bin/sh\nexit 77\n", encoding="utf-8")
            second = subprocess.run(
                ["sh", str(SCRIPT), str(source), str(cache), "abc123"],
                text=True, capture_output=True, env=env,
            )
            self.assertEqual(second.returncode, 0, second.stdout + second.stderr)
            self.assertIn("READY:", second.stdout)

    def test_rejects_non_local_sources_and_unsafe_keys(self):
        with tempfile.TemporaryDirectory() as directory:
            cache = Path(directory) / "cache"
            for source, key in (("https://example.com/a", "abc"), ("/tmp/no-file", "../escape")):
                completed = subprocess.run(
                    ["sh", str(SCRIPT), source, str(cache), key],
                    text=True, capture_output=True,
                )
                self.assertNotEqual(completed.returncode, 0)
