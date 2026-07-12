#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT"
QML_FILES=$(find contents tests -name '*.qml' | sort)
QML_TEST_FILES=$(find tests -name 'tst_*.qml' | sort)

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
    for file in $QML_FILES; do
        formatted=$(mktemp)
        if ! "$qmlformat_bin" "$file" >"$formatted" || ! cmp -s "$file" "$formatted"; then
            rm -f "$formatted"
            echo "$file is not qmlformat-clean" >&2
            exit 1
        fi
        rm -f "$formatted"
    done
fi
qmllint_bin=""
if command -v qmllint >/dev/null 2>&1; then
    qmllint_bin=$(command -v qmllint)
elif test -x /usr/lib/qt6/bin/qmllint; then
    qmllint_bin=/usr/lib/qt6/bin/qmllint
fi
if test -n "$qmllint_bin"; then
    "$qmllint_bin" -I contents/ui -I contents/ui/components $QML_FILES
fi
python3 tools/build_release.py
python3 tools/build_release.py --verify
PACKAGE_VERSION=$(python3 -c 'import json; print(json.load(open("metadata.json", encoding="utf-8"))["KPlugin"]["Version"])')
unzip -t "build/com.mcc45tr.filesearch-${PACKAGE_VERSION}.plasmoid"

qmltestrunner_bin=""
if command -v qmltestrunner6 >/dev/null 2>&1; then
    qmltestrunner_bin=$(command -v qmltestrunner6)
elif command -v qmltestrunner >/dev/null 2>&1; then
    qmltestrunner_bin=$(command -v qmltestrunner)
fi
if test -n "$qmltestrunner_bin"; then
    for test_file in $QML_TEST_FILES; do
        "$qmltestrunner_bin" -input "$test_file"
    done
fi
