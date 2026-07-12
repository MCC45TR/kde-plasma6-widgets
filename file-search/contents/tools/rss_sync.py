#!/usr/bin/env python3
"""Bounded, HTTPS-only RSS fetcher and atomic cache merger.

CLI compatibility:
    rss_sync.py <cache_dir> <url> <name> <max_entries>
    rss_sync.py --merge <cache_dir>

HTTP can be enabled only for an explicit development fixture by setting
MFILESEARCH_ALLOW_INSECURE_HTTP=1. Plasma never sets that variable.
"""

from __future__ import annotations

import base64
import binascii
import datetime as dt
import email.utils
import hashlib
import html
import io
import ipaddress
import json
import os
from pathlib import Path
import re
import socket
import sys
import tempfile
import time
import urllib.parse
import urllib.request
import xml.etree.ElementTree as ET


MAX_RESPONSE_BYTES = 5 * 1024 * 1024
MAX_CACHE_FILE_BYTES = 2 * 1024 * 1024
MAX_COMBINED_ENTRIES = 1500
MAX_XML_DEPTH = 64
MAX_TITLE_CHARS = 300
MAX_DESCRIPTION_CHARS = 1000
MAX_CONTENT_CHARS = 20_000
MAX_INDEXED_CHARS = 25_000
MAX_URL_CHARS = 2048
MAX_SOURCE_NAME_CHARS = 128
MAX_DATE_CHARS = 128
READ_CHUNK_BYTES = 64 * 1024
SOCKET_TIMEOUT_SECONDS = 10
TOTAL_FETCH_SECONDS = 30
ALLOW_INSECURE_HTTP = os.environ.get("MFILESEARCH_ALLOW_INSECURE_HTTP") == "1"


class SyncError(RuntimeError):
    """Expected, user-facing synchronization failure."""


def bounded(value: object, limit: int) -> str:
    text = str(value or "")
    return text[:limit]


def normalize_cache_dir(value: str) -> Path:
    raw = re.sub(r"^file:/*", "/", value or "")
    if not raw:
        raise SyncError("empty cache directory")
    path = Path(raw).expanduser()
    path.mkdir(mode=0o700, parents=True, exist_ok=True)
    if path.is_symlink() or not path.is_dir():
        raise SyncError("unsafe cache directory")
    try:
        path.chmod(0o700)
    except OSError:
        pass
    return path


def validate_remote_url(value: str, *, resolve: bool = True) -> urllib.parse.ParseResult:
    if len(value or "") > MAX_URL_CHARS:
        raise SyncError("URL is too long")
    parsed = urllib.parse.urlparse(value)
    allowed = {"https"}
    if ALLOW_INSECURE_HTTP:
        allowed.add("http")
    if parsed.scheme.lower() not in allowed:
        raise SyncError("only HTTPS feeds are allowed")
    if not parsed.hostname or parsed.username or parsed.password:
        raise SyncError("invalid feed host")
    if parsed.port not in (None, 80, 443):
        raise SyncError("non-standard feed port is not allowed")
    if resolve:
        validate_public_host(parsed.hostname, parsed.port or (443 if parsed.scheme == "https" else 80))
    return parsed


def validate_public_host(host: str, port: int) -> None:
    try:
        addresses = socket.getaddrinfo(host, port, type=socket.SOCK_STREAM)
    except OSError as exc:
        raise SyncError(f"feed host lookup failed: {exc}") from exc
    if not addresses:
        raise SyncError("feed host has no address")
    for address in addresses:
        ip = ipaddress.ip_address(address[4][0])
        if not ip.is_global:
            raise SyncError("private, local, or reserved feed addresses are not allowed")


class ValidatingRedirectHandler(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):  # noqa: N802
        validate_remote_url(newurl)
        return super().redirect_request(req, fp, code, msg, headers, newurl)


def read_bounded_response(response) -> bytes:
    content_length = response.headers.get("Content-Length")
    if content_length:
        try:
            if int(content_length) > MAX_RESPONSE_BYTES:
                raise SyncError("feed exceeds the response size limit")
        except ValueError:
            raise SyncError("invalid Content-Length")

    deadline = time.monotonic() + TOTAL_FETCH_SECONDS
    chunks: list[bytes] = []
    total = 0
    while True:
        if time.monotonic() > deadline:
            raise SyncError("feed exceeded the total download deadline")
        chunk = response.read(min(READ_CHUNK_BYTES, MAX_RESPONSE_BYTES + 1 - total))
        if not chunk:
            break
        total += len(chunk)
        if total > MAX_RESPONSE_BYTES:
            raise SyncError("feed exceeds the response size limit")
        chunks.append(chunk)
    return b"".join(chunks)


def fetch_feed(url: str) -> str:
    validate_remote_url(url)
    request = urllib.request.Request(
        url,
        headers={"User-Agent": "MFileFinder/1.3 (+https://github.com/MCC45TR/Plasma6Widgets)"},
    )
    opener = urllib.request.build_opener(ValidatingRedirectHandler())
    with opener.open(request, timeout=SOCKET_TIMEOUT_SECONDS) as response:
        validate_remote_url(response.geturl())
        payload = read_bounded_response(response)
        charset = response.info().get_content_charset() or "utf-8"
    try:
        return payload.decode(charset)
    except (LookupError, UnicodeDecodeError):
        return payload.decode("utf-8", errors="replace")


def clean_html(raw_html: str) -> str:
    if not raw_html:
        return ""
    text = raw_html
    for marker in ("Devamını oku", "Haberin devamı", "Tıklayın", "İşte detaylar", "Read more", "Full story"):
        text = re.sub(re.escape(marker) + r".*", "", text, flags=re.IGNORECASE | re.DOTALL)
    text = re.sub(r"<[^>]{0,4096}>|&(?:[a-z0-9]+|#[0-9]{1,6}|#x[0-9a-f]{1,6});", " ", text, flags=re.I)
    return html.unescape(text).strip()


def local_name(tag: str) -> str:
    return tag.rsplit("}", 1)[-1].lower()


def deep_text(node: ET.Element, names: set[str]) -> str:
    for child in node.iter():
        if local_name(child.tag) in names:
            return "".join(child.itertext()).strip()
    return ""


def attr_value(node: ET.Element, names: set[str], attr: str) -> str:
    for child in node.iter():
        if local_name(child.tag) in names and child.get(attr):
            return child.get(attr, "")
    return ""


def normalize_date(value: str) -> str:
    value = bounded(value, MAX_DATE_CHARS)
    if not value:
        return ""
    for fmt in (
        "%a, %d %b %Y %H:%M:%S %z",
        "%a, %d %b %Y %H:%M:%S %Z",
        "%Y-%m-%dT%H:%M:%S%z",
        "%Y-%m-%dT%H:%M:%S.%f%z",
        "%Y-%m-%d %H:%M:%S",
        "%d.%m.%Y %H:%M:%S",
        "%Y/%m/%d %H:%M:%S",
    ):
        try:
            return dt.datetime.strptime(value, fmt).strftime("%Y-%m-%d %H:%M")
        except ValueError:
            pass
    return value.replace(" +0000", "").replace("T", " ").split(".")[0]


def safe_content_url(value: str, source_host: str, *, same_origin: bool = False) -> str:
    value = bounded(value, MAX_URL_CHARS).strip()
    if not value:
        return ""
    try:
        parsed = validate_remote_url(value, resolve=False)
    except (SyncError, ValueError):
        return ""
    if same_origin and parsed.hostname != source_host:
        return ""
    return value


def parse_entry(node: ET.Element, source_name: str, source_host: str) -> dict | None:
    title = bounded(clean_html(deep_text(node, {"title"})), MAX_TITLE_CHARS)
    link = deep_text(node, {"link", "guid"})
    if not link:
        link = attr_value(node, {"link"}, "href")
    link = safe_content_url(link, source_host)
    raw_date = bounded(deep_text(node, {"pubdate", "updated", "published", "date"}), MAX_DATE_CHARS)
    description_raw = bounded(deep_text(node, {"description", "summary"}), MAX_CONTENT_CHARS)
    content_raw = bounded(deep_text(node, {"encoded", "content"}), MAX_CONTENT_CHARS)
    description = bounded(clean_html(description_raw), MAX_DESCRIPTION_CHARS)
    full_content = bounded(clean_html(content_raw) or description, MAX_CONTENT_CHARS)
    if not title:
        title = bounded(description or "News", 50)
    if not title:
        return None

    image_url = attr_value(node, {"content", "enclosure", "thumbnail", "image"}, "url")
    if not image_url:
        image_match = re.search(r"<img[^>]{0,4096}src=[\"']([^\"']+)[\"']", description_raw + content_raw, re.I)
        image_url = image_match.group(1) if image_match else ""
    # Remote images are allowed only from the already-approved feed host. This
    # avoids turning arbitrary item metadata into a cross-host request primitive.
    image_url = safe_content_url(image_url, source_host, same_origin=True)
    indexed = bounded(f"{title} {description} {full_content}", MAX_INDEXED_CHARS)
    duplicate = link or hashlib.sha256(f"{title}\0{raw_date}".encode()).hexdigest()
    return {
        "display": title,
        "decoration": "news-subscribe",
        "category": "RSS",
        "url": link,
        "subtext": f"{source_name} | {normalize_date(raw_date)}",
        "description": description,
        "fullContent": full_content,
        "imageUrl": image_url,
        "sourceIcon": "",
        "indexedContent": indexed,
        "duplicateId": f"rss:{duplicate}",
        "rawDate": raw_date,
        "index": -1,
    }


def parse_rss(xml_text: str, source_name: str, source_url: str, max_entries: int) -> list[dict]:
    if re.search(r"<!\s*(?:DOCTYPE|ENTITY)\b", xml_text, flags=re.IGNORECASE):
        raise SyncError("DTD and entity declarations are not allowed")
    # Preserve compatibility with common malformed feeds, within the hard body cap.
    cleaned = re.sub(r"&(?!(?:amp|lt|gt|quot|apos|#\d+|#x[a-fA-F0-9]+);)", "&amp;", xml_text)
    source_host = urllib.parse.urlparse(source_url).hostname or ""
    source_name = bounded(source_name, MAX_SOURCE_NAME_CHARS)
    entries: list[dict] = []
    depth = 0
    try:
        for event, node in ET.iterparse(io.StringIO(cleaned), events=("start", "end")):
            if event == "start":
                depth += 1
                if depth > MAX_XML_DEPTH:
                    raise SyncError("XML nesting limit exceeded")
                continue
            if local_name(node.tag) in {"item", "entry"}:
                parsed = parse_entry(node, source_name, source_host)
                if parsed:
                    entries.append(parsed)
                node.clear()
                if len(entries) >= max_entries:
                    break
            depth -= 1
    except ET.ParseError as exc:
        raise SyncError(f"XML parse failed: {exc}") from exc
    return entries


def source_path(cache_dir: Path, url: str) -> Path:
    # Keep the historical name algorithm so existing QML cache lookups continue
    # to work; writes themselves are atomic and confined to the fixed cache dir.
    value = 0
    for char in url:
        value = ((value << 5) - value + ord(char)) & 0xFFFFFFFF
    if value > 0x7FFFFFFF:
        value -= 0x100000000
    return cache_dir / f"source_{abs(value)}.json"


def atomic_write(path: Path, text: str) -> None:
    fd, temp_name = tempfile.mkstemp(prefix=f".{path.name}.", dir=path.parent)
    try:
        os.fchmod(fd, 0o600)
        with os.fdopen(fd, "w", encoding="utf-8") as stream:
            stream.write(text)
            stream.flush()
            os.fsync(stream.fileno())
        os.replace(temp_name, path)
    except Exception:
        try:
            os.unlink(temp_name)
        except OSError:
            pass
        raise


def entry_timestamp(entry: dict) -> float:
    value = bounded(entry.get("rawDate", ""), MAX_DATE_CHARS)
    if not value:
        return 0
    try:
        return dt.datetime.fromisoformat(value.replace("Z", "+00:00")).timestamp()
    except (ValueError, OverflowError):
        try:
            parsed = email.utils.parsedate_to_datetime(value)
            return parsed.timestamp()
        except (TypeError, ValueError, OverflowError):
            return 0


def load_source_file(path: Path) -> list[dict]:
    if path.is_symlink() or path.stat().st_size > MAX_CACHE_FILE_BYTES:
        return []
    raw = path.read_text(encoding="utf-8").strip()
    try:
        raw = base64.b64decode(raw, validate=True).decode("utf-8")
    except (binascii.Error, ValueError, UnicodeDecodeError):
        pass
    try:
        value = json.loads(raw)
    except json.JSONDecodeError:
        return []
    if not isinstance(value, list):
        return []
    return [entry for entry in value[:50] if isinstance(entry, dict)]


def merge_cache(cache_dir: Path) -> int:
    combined: list[dict] = []
    for path in sorted(cache_dir.glob("source_*.json"))[:30]:
        try:
            combined.extend(load_source_file(path))
        except OSError:
            continue
    combined = combined[:MAX_COMBINED_ENTRIES]
    combined.sort(key=entry_timestamp, reverse=True)
    atomic_write(cache_dir / "combined.json", json.dumps(combined, ensure_ascii=False, separators=(",", ":")))
    print(f"MERGE: SUCCESS ({len(combined)} items)", flush=True)
    return 0


def sync_source(cache_dir: Path, url: str, name: str, max_entries_text: str) -> int:
    try:
        max_entries = max(1, min(50, int(max_entries_text)))
    except ValueError as exc:
        raise SyncError("invalid entry limit") from exc
    print("FETCHING: START", flush=True)
    xml_text = fetch_feed(url)
    print("FETCHING: OK", flush=True)
    print("PARSING: START", flush=True)
    entries = parse_rss(xml_text, name, url, max_entries)
    print(f"PARSING: OK ({len(entries)} items)", flush=True)
    encoded = base64.b64encode(json.dumps(entries, ensure_ascii=False, separators=(",", ":")).encode()).decode()
    atomic_write(source_path(cache_dir, url), encoded)
    print(f"SAVING: {len(entries)} entries saved OK", flush=True)
    print("SUCCESS", flush=True)
    return 0


def main(argv: list[str]) -> int:
    try:
        if len(argv) == 3 and argv[1] == "--merge":
            return merge_cache(normalize_cache_dir(argv[2]))
        if len(argv) != 5:
            raise SyncError("usage: rss_sync.py <cache_dir> <url> <name> <max_entries>")
        return sync_source(normalize_cache_dir(argv[1]), argv[2], argv[3], argv[4])
    except (SyncError, OSError, ValueError) as exc:
        print(f"FAIL: {exc}", flush=True)
        return 1


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
