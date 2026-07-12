#!/bin/sh
# Prefer the fully featured Python synchronizer, but keep RSS usable on minimal
# Plasma installations through the POSIX shell fallback.

set -eu

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)

if command -v python3 >/dev/null 2>&1 &&
        test "${MFILESEARCH_FORCE_SHELL_FALLBACK:-0}" != "1"; then
    exec python3 "$SCRIPT_DIR/rss_sync.py" "$@"
fi

exec sh "$SCRIPT_DIR/rss_sync_fallback.sh" "$@"
