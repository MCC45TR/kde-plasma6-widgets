#!/bin/sh
# Thin launcher for the bounded RSS synchronizer. Keeping the network/parser
# implementation in Python makes it directly testable without starting Plasma.

set -eu

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)

if ! command -v python3 >/dev/null 2>&1; then
    echo "FAIL: python3 not found" >&2
    exit 1
fi

exec python3 "$SCRIPT_DIR/rss_sync.py" "$@"
