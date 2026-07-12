#!/usr/bin/env python3
"""Repeatable parser/merge microbenchmark for 0/500/1500 RSS entries."""

from __future__ import annotations

import importlib.util
import argparse
import contextlib
import io
import json
from pathlib import Path
import statistics
import tempfile
import time


ROOT = Path(__file__).parents[1]
MODULE = ROOT / "contents/tools/rss_sync.py"
SPEC = importlib.util.spec_from_file_location("rss_sync", MODULE)
rss_sync = importlib.util.module_from_spec(SPEC)
assert SPEC.loader
SPEC.loader.exec_module(rss_sync)


def timed(function, repeats: int = 7) -> tuple[float, float]:
    samples = []
    for _ in range(repeats):
        started = time.perf_counter()
        function()
        samples.append((time.perf_counter() - started) * 1000)
    ordered = sorted(samples)
    return statistics.median(samples), ordered[max(0, int(len(ordered) * 0.95) - 1)]


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true", help="fail when a bounded operation exceeds 2 seconds")
    args = parser.parse_args()
    worst = 0.0
    for count in (0, 500, 1500):
        xml = "<rss><channel>" + "".join(
            f"<item><title>Entry {i}</title><link>https://example.com/{i}</link>"
            f"<pubDate>Mon, 01 Jan 2024 00:{i % 60:02d}:00 +0000</pubDate></item>"
            for i in range(count)
        ) + "</channel></rss>"
        parse_p50, parse_p95 = timed(lambda: rss_sync.parse_rss(xml, "Bench", "https://example.com/feed", max(1, count)))
        with tempfile.TemporaryDirectory() as directory:
            cache = Path(directory)
            values = [{"display": f"Entry {i}", "rawDate": "2024-01-01T00:00:00Z"} for i in range(count)]
            for source in range(min(30, (count + 49) // 50)):
                chunk = values[source * 50:(source + 1) * 50]
                (cache / f"source_{source}.json").write_text(json.dumps(chunk), encoding="utf-8")
            def merge_silently():
                with contextlib.redirect_stdout(io.StringIO()):
                    rss_sync.merge_cache(cache)
            merge_p50, merge_p95 = timed(merge_silently)
        worst = max(worst, parse_p95, merge_p95)
        print(f"entries={count:4d} parse_p50={parse_p50:8.2f}ms parse_p95={parse_p95:8.2f}ms "
              f"merge_p50={merge_p50:8.2f}ms merge_p95={merge_p95:8.2f}ms")
    if args.check and worst > 2000:
        raise SystemExit(f"performance budget exceeded: {worst:.2f}ms > 2000ms")


if __name__ == "__main__":
    main()
