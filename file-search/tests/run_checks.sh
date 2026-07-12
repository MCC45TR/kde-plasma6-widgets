#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT"

python3 -m unittest discover -s tests -p 'test_*.py' -v
python3 -m py_compile contents/tools/rss_sync.py tools/build_release.py tests/test_*.py
sh -n contents/tools/rss_sync.sh tests/run_checks.sh
python3 -m json.tool metadata.json >/dev/null
python3 tests/benchmark_rss.py --check

if command -v shellcheck >/dev/null 2>&1; then
    shellcheck contents/tools/rss_sync.sh tests/run_checks.sh
fi
if command -v xmllint >/dev/null 2>&1; then
    xmllint --noout contents/config/main.xml
    find contents/images -name '*.svg' -exec xmllint --noout {} +
fi
if command -v msgfmt >/dev/null 2>&1; then
    find translations -name '*.po' -exec msgfmt --check --check-format -o /dev/null {} \;
fi
qmlformat_bin=""
if command -v qmlformat >/dev/null 2>&1; then
    qmlformat_bin=$(command -v qmlformat)
elif test -x /usr/lib/qt6/bin/qmlformat; then
    qmlformat_bin=/usr/lib/qt6/bin/qmlformat
fi
if test -n "$qmlformat_bin"; then
    formatted=$(mktemp)
    if ! "$qmlformat_bin" tests/tst_QueryPolicy.qml >"$formatted" || ! cmp -s tests/tst_QueryPolicy.qml "$formatted"; then
        rm -f "$formatted"
        echo "tests/tst_QueryPolicy.qml is not qmlformat-clean" >&2
        exit 1
    fi
    rm -f "$formatted"
fi
if command -v qmllint >/dev/null 2>&1; then
    qmllint tests/tst_QueryPolicy.qml
elif test -x /usr/lib/qt6/bin/qmllint; then
    /usr/lib/qt6/bin/qmllint tests/tst_QueryPolicy.qml
fi
python3 tools/build_release.py
python3 tools/build_release.py --verify
unzip -t build/com.mcc45tr.filesearch-1.3.0.plasmoid

if command -v qmltestrunner6 >/dev/null 2>&1; then
    qmltestrunner6 -input tests/tst_QueryPolicy.qml
elif command -v qmltestrunner >/dev/null 2>&1; then
    qmltestrunner -input tests/tst_QueryPolicy.qml
fi
