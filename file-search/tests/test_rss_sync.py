from __future__ import annotations

import base64
import importlib.util
import json
import os
from pathlib import Path
import stat
import subprocess
import tempfile
import unittest
from unittest import mock


MODULE_PATH = Path(__file__).parents[1] / "contents" / "tools" / "rss_sync.py"
SPEC = importlib.util.spec_from_file_location("rss_sync", MODULE_PATH)
rss_sync = importlib.util.module_from_spec(SPEC)
assert SPEC.loader
SPEC.loader.exec_module(rss_sync)


class FakeResponse:
    def __init__(self, chunks: list[bytes], content_length: str | None = None):
        self._chunks = list(chunks)
        self.headers = {} if content_length is None else {"Content-Length": content_length}

    def read(self, _size: int) -> bytes:
        return self._chunks.pop(0) if self._chunks else b""


class RssSyncTests(unittest.TestCase):
    def test_rejects_non_https_and_credentials(self):
        with self.assertRaises(rss_sync.SyncError):
            rss_sync.validate_remote_url("http://example.com/feed", resolve=False)
        with self.assertRaises(rss_sync.SyncError):
            rss_sync.validate_remote_url("https://user:pass@example.com/feed", resolve=False)

    def test_rejects_private_dns_answers(self):
        answer = [(2, 1, 6, "", ("127.0.0.1", 443))]
        with mock.patch.object(rss_sync.socket, "getaddrinfo", return_value=answer):
            with self.assertRaises(rss_sync.SyncError):
                rss_sync.validate_public_host("feed.example", 443)

    def test_redirect_policy_revalidates_scheme_and_address(self):
        handler = rss_sync.ValidatingRedirectHandler()
        with self.assertRaises(rss_sync.SyncError):
            handler.redirect_request(None, None, 302, "Found", {}, "http://example.com/feed")
        answer = [(2, 1, 6, "", ("10.0.0.4", 443))]
        with mock.patch.object(rss_sync.socket, "getaddrinfo", return_value=answer):
            with self.assertRaises(rss_sync.SyncError):
                handler.redirect_request(None, None, 302, "Found", {}, "https://feed.example/private")

    def test_enforces_declared_and_streamed_body_limits(self):
        too_large = str(rss_sync.MAX_RESPONSE_BYTES + 1)
        with self.assertRaises(rss_sync.SyncError):
            rss_sync.read_bounded_response(FakeResponse([], too_large))
        chunks = [b"x" * rss_sync.MAX_RESPONSE_BYTES, b"y"]
        with self.assertRaises(rss_sync.SyncError):
            rss_sync.read_bounded_response(FakeResponse(chunks))

    def test_rejects_entities_and_excessive_depth(self):
        with self.assertRaises(rss_sync.SyncError):
            rss_sync.parse_rss('<!DOCTYPE rss [<!ENTITY x "boom">]><rss/>', "Feed", "https://example.com", 10)
        with self.assertRaises(rss_sync.SyncError):
            rss_sync.parse_rss(" " * 5000 + '<!DOCTYPE rss><rss/>', "Feed", "https://example.com", 10)
        nested = "<rss>" + "<x>" * 65 + "</x>" * 65 + "</rss>"
        with self.assertRaises(rss_sync.SyncError):
            rss_sync.parse_rss(nested, "Feed", "https://example.com", 10)

    def test_parser_caps_entries_fields_and_cross_origin_images(self):
        items = []
        for index in range(20):
            items.append(
                "<item>"
                f"<title>{'T' * 500}{index}</title>"
                f"<link>https://example.com/{index}</link>"
                "<description><![CDATA[<img src='https://tracker.example/pixel'>Body]]></description>"
                "</item>"
            )
        entries = rss_sync.parse_rss("<rss><channel>" + "".join(items) + "</channel></rss>", "Feed", "https://example.com/feed", 7)
        self.assertEqual(len(entries), 7)
        self.assertLessEqual(len(entries[0]["display"]), rss_sync.MAX_TITLE_CHARS)
        self.assertEqual(entries[0]["imageUrl"], "")

    def test_merge_is_bounded_sorted_and_atomic(self):
        with tempfile.TemporaryDirectory() as directory:
            cache = Path(directory)
            older = [{"display": "old", "rawDate": "Mon, 01 Jan 2024 00:00:00 +0000"}]
            newer = [{"display": "new", "rawDate": "2025-01-01T00:00:00Z"}]
            for index, value in enumerate((older, newer)):
                encoded = base64.b64encode(json.dumps(value).encode()).decode()
                (cache / f"source_{index}.json").write_text(encoded, encoding="utf-8")
            self.assertEqual(rss_sync.merge_cache(cache), 0)
            combined = json.loads((cache / "combined.json").read_text(encoding="utf-8"))
            self.assertEqual([entry["display"] for entry in combined], ["new", "old"])
            self.assertEqual(stat.S_IMODE((cache / "combined.json").stat().st_mode), 0o600)
            self.assertFalse(list(cache.glob(".combined.json.*")))

    def test_failed_parse_preserves_last_known_good_source_and_meta(self):
        with tempfile.TemporaryDirectory() as directory:
            cache = Path(directory)
            target = rss_sync.source_path(cache, "https://example.com/feed")
            target.write_text("last-known-good", encoding="utf-8")
            fetched = ("<rss><broken>", {"etag": '"v2"', "last_modified": ""})
            with mock.patch.object(rss_sync, "fetch_feed", return_value=fetched), self.assertRaises(rss_sync.SyncError):
                rss_sync.sync_source(cache, "https://example.com/feed", "Feed", "10")
            self.assertEqual(target.read_text(encoding="utf-8"), "last-known-good")
            self.assertFalse(rss_sync.meta_path(cache, "https://example.com/feed").exists())

    def test_not_modified_keeps_cache_and_succeeds(self):
        with tempfile.TemporaryDirectory() as directory:
            cache = Path(directory)
            target = rss_sync.source_path(cache, "https://example.com/feed")
            target.write_text("cached-entries", encoding="utf-8")
            with mock.patch.object(rss_sync, "fetch_feed", return_value=(None, {"etag": '"v1"'})) as fetch:
                self.assertEqual(rss_sync.sync_source(cache, "https://example.com/feed", "Feed", "10"), 0)
            self.assertEqual(target.read_text(encoding="utf-8"), "cached-entries")
            fetch.assert_called_once()

    def test_conditional_request_sends_stored_validators(self):
        meta = {"etag": 'W/"abc"', "last_modified": "Mon, 01 Jan 2024 00:00:00 GMT"}
        request = rss_sync.build_feed_request("https://example.com/feed", meta)
        self.assertEqual(request.get_header("If-none-match"), 'W/"abc"')
        self.assertEqual(request.get_header("If-modified-since"), "Mon, 01 Jan 2024 00:00:00 GMT")
        self.assertEqual(request.get_header("Accept-encoding"), "gzip")
        bare = rss_sync.build_feed_request("https://example.com/feed", {})
        self.assertIsNone(bare.get_header("If-none-match"))
        self.assertIsNone(bare.get_header("If-modified-since"))

    def test_gzip_bodies_are_decoded_and_bombs_are_rejected(self):
        import gzip

        body = "<rss><channel><item><title>ok</title></item></channel></rss>".encode()
        self.assertEqual(rss_sync.decode_body(gzip.compress(body), "gzip"), body)
        self.assertEqual(rss_sync.decode_body(body, ""), body)
        with self.assertRaises(rss_sync.SyncError):
            rss_sync.decode_body(b"not gzip", "gzip")
        with self.assertRaises(rss_sync.SyncError):
            rss_sync.decode_body(b"anything", "br")
        bomb = gzip.compress(b"\0" * (rss_sync.MAX_RESPONSE_BYTES + 1024))
        with self.assertRaises(rss_sync.SyncError):
            rss_sync.decode_body(bomb, "gzip")

    def test_parse_and_merge_deduplicate_by_id(self):
        xml = (
            "<rss><channel>"
            "<item><title>One</title><link>https://example.com/a</link></item>"
            "<item><title>One again</title><link>https://example.com/a</link></item>"
            "<item><title>Two</title><link>https://example.com/b</link></item>"
            "</channel></rss>"
        )
        entries = rss_sync.parse_rss(xml, "Feed", "https://example.com/feed", 10)
        self.assertEqual([entry["url"] for entry in entries], ["https://example.com/a", "https://example.com/b"])

        with tempfile.TemporaryDirectory() as directory:
            cache = Path(directory)
            shared = {"display": "shared", "duplicateId": "rss:x", "rawDate": "2024-01-01T00:00:00Z"}
            newer = {"display": "shared-newer", "duplicateId": "rss:x", "rawDate": "2025-01-01T00:00:00Z"}
            (cache / "source_0.json").write_text(json.dumps([shared]), encoding="utf-8")
            (cache / "source_1.json").write_text(json.dumps([newer]), encoding="utf-8")
            self.assertEqual(rss_sync.merge_cache(cache), 0)
            combined = json.loads((cache / "combined.json").read_text(encoding="utf-8"))
            self.assertEqual([entry["display"] for entry in combined], ["shared-newer"])

    def test_http_meta_roundtrip_is_bounded_and_ignored_when_invalid(self):
        with tempfile.TemporaryDirectory() as directory:
            cache = Path(directory)
            url = "https://example.com/feed"
            self.assertEqual(rss_sync.load_http_meta(cache, url), {})
            rss_sync.meta_path(cache, url).write_text(json.dumps({"etag": "E" * 9000}), encoding="utf-8")
            self.assertEqual(rss_sync.load_http_meta(cache, url), {})
            rss_sync.meta_path(cache, url).write_text('{"etag": "\\"v1\\"", "last_modified": "yesterday"}', encoding="utf-8")
            self.assertEqual(
                rss_sync.load_http_meta(cache, url),
                {"etag": '"v1"', "last_modified": "yesterday"},
            )
            self.assertNotIn("meta_", str(rss_sync.source_path(cache, url)))


class ShellFallbackTests(unittest.TestCase):
    root = MODULE_PATH.parents[2]
    launcher = root / "contents" / "tools" / "rss_sync.sh"
    parser = root / "contents" / "tools" / "rss_sync_fallback.awk"

    def test_parser_handles_rss_and_atom_without_python(self):
        xml = (
            '<rss><channel><item><title>One &amp; Two</title>'
            '<link>https://example.com/one</link><description><![CDATA[<b>Hello</b>]]></description>'
            '</item></channel></rss>'
        )
        with tempfile.TemporaryDirectory() as directory:
            count = Path(directory) / "count"
            env = os.environ.copy()
            env.update({
                "RSS_FALLBACK_MODE": "parse",
                "RSS_SOURCE_NAME": "Fallback Feed",
                "RSS_SOURCE_URL": "https://example.com/feed",
                "RSS_MAX_ENTRIES": "10",
                "RSS_COUNT_FILE": str(count),
            })
            completed = subprocess.run(
                ["awk", "-f", str(self.parser)], input=xml, text=True,
                capture_output=True, env=env, check=True,
            )
            entries = json.loads(completed.stdout)
            self.assertEqual(count.read_text(encoding="utf-8").strip(), "1")
            self.assertEqual(entries[0]["display"], "One & Two")
            self.assertEqual(entries[0]["description"], "Hello")

            rejected = subprocess.run(
                ["awk", "-f", str(self.parser)],
                input='<!DOCTYPE rss [<!ENTITY x "boom">]><rss/>', text=True,
                capture_output=True, env=env,
            )
            self.assertNotEqual(rejected.returncode, 0)

    def test_launcher_uses_shell_fallback_for_fetch_and_atomic_cache(self):
        with tempfile.TemporaryDirectory() as directory:
            workspace = Path(directory)
            fake_bin = workspace / "bin"
            fake_bin.mkdir()
            fake_getent = fake_bin / "getent"
            fake_getent.write_text("#!/bin/sh\necho '93.184.216.34 STREAM example.com'\n", encoding="utf-8")
            fake_curl = fake_bin / "curl"
            fake_curl.write_text(
                """#!/bin/sh
header=
output=
while test \"$#\" -gt 0; do
    case $1 in
        --dump-header) header=$2; shift 2 ;;
        --output) output=$2; shift 2 ;;
        --silent|--show-error) shift ;;
        --noproxy|--proto|--connect-timeout|--max-time|--max-filesize|--resolve|--user-agent|--header|--write-out) shift 2 ;;
        *) shift ;;
    esac
done
printf 'HTTP/1.1 200 OK\\r\\nContent-Type: application/rss+xml\\r\\n\\r\\n' >\"$header\"
printf '%s' '<rss><channel><item><title>Fallback Works</title><link>https://example.com/item</link></item></channel></rss>' >\"$output\"
printf '200'
""",
                encoding="utf-8",
            )
            fake_getent.chmod(0o755)
            fake_curl.chmod(0o755)
            env = os.environ.copy()
            env["PATH"] = str(fake_bin) + os.pathsep + env["PATH"]
            env["MFILESEARCH_FORCE_SHELL_FALLBACK"] = "1"
            cache = workspace / "cache"
            completed = subprocess.run(
                ["sh", str(self.launcher), str(cache), "https://example.com/feed", "Feed", "10"],
                text=True, capture_output=True, env=env,
            )
            self.assertEqual(completed.returncode, 0, completed.stdout + completed.stderr)
            self.assertIn("SUCCESS", completed.stdout)
            source = rss_sync.source_path(cache, "https://example.com/feed")
            entries = json.loads(base64.b64decode(source.read_bytes()))
            self.assertEqual(entries[0]["display"], "Fallback Works")
            self.assertEqual(stat.S_IMODE(source.stat().st_mode), 0o600)

    def test_shell_fallback_rejects_private_resolution_before_curl(self):
        with tempfile.TemporaryDirectory() as directory:
            workspace = Path(directory)
            fake_bin = workspace / "bin"
            fake_bin.mkdir()
            marker = workspace / "curl-was-called"
            (fake_bin / "getent").write_text("#!/bin/sh\necho '127.0.0.1 STREAM localhost'\n", encoding="utf-8")
            (fake_bin / "curl").write_text(f"#!/bin/sh\ntouch '{marker}'\nexit 1\n", encoding="utf-8")
            (fake_bin / "getent").chmod(0o755)
            (fake_bin / "curl").chmod(0o755)
            env = os.environ.copy()
            env["PATH"] = str(fake_bin) + os.pathsep + env["PATH"]
            env["MFILESEARCH_FORCE_SHELL_FALLBACK"] = "1"
            completed = subprocess.run(
                ["sh", str(self.launcher), str(workspace / "cache"), "https://example.com/feed", "Feed", "10"],
                text=True, capture_output=True, env=env,
            )
            self.assertNotEqual(completed.returncode, 0)
            self.assertIn("private, local, reserved", completed.stdout)
            self.assertFalse(marker.exists())


if __name__ == "__main__":
    unittest.main()
