#!/bin/sh
# Generate a bounded local-file preview through KDE's installed KIO thumbnailers.

set -eu

fail() {
    echo "FAIL: $*"
    exit 1
}

test "$#" -eq 3 || fail "usage: thumbnailer.sh <source> <cache_dir> <cache_key>"
source_path=$1
cache_dir=$2
cache_key=$3

case $source_path in /*) ;; *) fail "source must be an absolute local path" ;; esac
case $cache_key in ''|*[!0-9a-f]*) fail "invalid cache key" ;; esac
test "${#cache_key}" -le 64 || fail "invalid cache key"
test -r "$source_path" || fail "source is not readable"
test ! -L "$cache_dir" || fail "unsafe preview cache directory"
mkdir -p -- "$cache_dir"
test -d "$cache_dir" && test ! -L "$cache_dir" || fail "unsafe preview cache directory"
chmod 700 "$cache_dir" 2>/dev/null || true

target=$cache_dir/$cache_key.png
if test -s "$target" && test "$target" -nt "$source_path"; then
    echo "READY:$target"
    exit 0
fi

if command -v kioclient6 >/dev/null 2>&1; then
    kio_client=kioclient6
elif command -v kioclient >/dev/null 2>&1; then
    kio_client=kioclient
else
    fail "KIO thumbnail support is not installed"
fi

temporary=$(mktemp "$cache_dir/.$cache_key.XXXXXX") || fail "cannot create preview workspace"
trap 'rm -f "$temporary"' EXIT HUP INT TERM

# QUrl treats these bytes as URL delimiters. Encode them without requiring a
# scripting-language runtime; ordinary spaces are handled by QUrl itself.
thumbnail_path=$(printf '%s' "$source_path" | sed -e 's/%/%25/g' -e 's/#/%23/g' -e 's/?/%3F/g')
if command -v timeout >/dev/null 2>&1; then
    timeout 20 "$kio_client" --noninteractive cat "thumbnail:$thumbnail_path" >"$temporary" || fail "KIO could not generate a preview"
else
    "$kio_client" --noninteractive cat "thumbnail:$thumbnail_path" >"$temporary" || fail "KIO could not generate a preview"
fi

test -s "$temporary" || fail "KIO returned an empty preview"
test "$(wc -c <"$temporary")" -le 10485760 || fail "generated preview is too large"
signature=$(od -An -tx1 -N8 "$temporary" | tr -d ' \n')
test "$signature" = "89504e470d0a1a0a" || fail "KIO returned an invalid preview"
chmod 600 "$temporary"
mv -f -- "$temporary" "$target"
trap - EXIT HUP INT TERM
echo "READY:$target"
