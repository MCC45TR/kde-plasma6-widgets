#!/bin/sh
# Python-free RSS synchronizer for minimal Linux/Plasma installations.
# Requires curl plus the standard base utilities shipped by mainstream distros.

set -eu

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
AWK_SCRIPT=$SCRIPT_DIR/rss_sync_fallback.awk
MAX_RESPONSE_BYTES=5242880
MAX_CACHE_FILE_BYTES=2097152
MAX_COMBINED_ENTRIES=1500

fail() {
    echo "FAIL: $*"
    exit 1
}

need_command() {
    command -v "$1" >/dev/null 2>&1 || fail "$1 is required when python3 is unavailable"
}

normalize_cache_dir() {
    cache_dir=$(printf '%s' "$1" | sed 's#^file:/*#/#')
    test -n "$cache_dir" || fail "empty cache directory"
    test ! -L "$cache_dir" || fail "unsafe cache directory"
    mkdir -p -- "$cache_dir" || fail "cannot create cache directory"
    test -d "$cache_dir" && test ! -L "$cache_dir" || fail "unsafe cache directory"
    chmod 700 "$cache_dir" 2>/dev/null || true
}

cache_key() {
    # Matches the historical 32-bit Java/Python string hash for ASCII URLs.
    # Feed URLs should already be percent-encoded by the configuration UI.
    LC_ALL=C printf '%s' "$1" | od -An -tu1 | awk '
        { for (i = 1; i <= NF; i++) value = (value * 31 + $i) % 4294967296 }
        END {
            if (value >= 2147483648) value -= 4294967296
            if (value < 0) value = -value
            printf "%.0f", value
        }'
}

url_host() {
    case $1 in
        https://*) authority=${1#https://} ;;
        *) return 1 ;;
    esac
    authority=${authority%%/*}
    authority=${authority%%\?*}
    authority=${authority%%\#*}
    test -n "$authority" || return 1
    case $authority in *@*) return 1 ;; esac

    case $authority in
        \[*\]) host=${authority#\[}; host=${host%\]} ;;
        \[*\]:443) host=${authority#\[}; host=${host%\]:443} ;;
        *:443) host=${authority%:443} ;;
        *:*) return 1 ;;
        *) host=$authority ;;
    esac
    test -n "$host" || return 1
    case $host in *[!A-Za-z0-9.:_-]*) return 1 ;; esac
    printf '%s\n' "$host"
}

resolve_public_address() {
    host=$1
    addresses=$(getent ahosts "$host" 2>/dev/null || getent hosts "$host" 2>/dev/null || true)
    test -n "$addresses" || return 1
    printf '%s\n' "$addresses" | awk '
        function public4(ip, p, n, a) {
            n = split(ip, a, ".")
            if (n != 4) return 0
            for (p = 1; p <= 4; p++)
                if (a[p] !~ /^[0-9]+$/ || a[p] < 0 || a[p] > 255) return 0
            if (a[1] == 0 || a[1] == 10 || a[1] == 127 || a[1] >= 224) return 0
            if (a[1] == 100 && a[2] >= 64 && a[2] <= 127) return 0
            if (a[1] == 169 && a[2] == 254) return 0
            if (a[1] == 172 && a[2] >= 16 && a[2] <= 31) return 0
            if (a[1] == 192 && (a[2] == 168 || (a[2] == 0 && (a[3] == 0 || a[3] == 2)))) return 0
            if (a[1] == 198 && (a[2] == 18 || a[2] == 19 || (a[2] == 51 && a[3] == 100))) return 0
            if (a[1] == 203 && a[2] == 0 && a[3] == 113) return 0
            return 1
        }
        function public6(ip, lower) {
            lower = tolower(ip)
            # Conservatively admit only global-unicast space and reject the
            # documentation prefix. This also rejects loopback, ULA and link-local.
            return lower ~ /^[23][0-9a-f]*:/ && lower !~ /^2001:db8:/ && lower !~ /^2001:([0-9a-f]|[0-9a-f][0-9a-f]):/
        }
        {
            ip = $1
            if (index(ip, ":")) ok = public6(ip)
            else ok = public4(ip)
            if (!ok) bad = 1
            if (ok && first == "") first = ip
        }
        END {
            if (bad || first == "") exit 1
            print first
        }'
}

fetch_feed() {
    current_url=$1
    body_file=$2
    header_file=$3
    redirects=0

    while :; do
        test "${#current_url}" -le 2048 || fail "URL is too long"
        host=$(url_host "$current_url") || fail "only credential-free HTTPS feeds on port 443 are allowed"
        address=$(resolve_public_address "$host") || fail "private, local, reserved, or unresolved feed addresses are not allowed"
        case $address in *:*) pinned_address=[$address] ;; *) pinned_address=$address ;; esac

        : >"$header_file"
        : >"$body_file"
        if ! status=$(curl --silent --show-error --noproxy '*' \
                --proto '=https' --connect-timeout 10 --max-time 30 \
                --max-filesize "$MAX_RESPONSE_BYTES" \
                --resolve "$host:443:$pinned_address" \
                --user-agent 'MFileFinder/1.3 (+https://github.com/MCC45TR/Plasma6Widgets)' \
                --header 'Accept: application/rss+xml, application/atom+xml, application/xml;q=0.9, */*;q=0.8' \
                --header 'Accept-Encoding: identity' \
                --dump-header "$header_file" --output "$body_file" \
                --write-out '%{http_code}' "$current_url"); then
            fail "feed download failed"
        fi

        test "$(wc -c <"$body_file")" -le "$MAX_RESPONSE_BYTES" || fail "feed exceeds the response size limit"
        test "$(wc -c <"$header_file")" -le 65536 || fail "feed response headers are too large"
        content_encoding=$(awk 'tolower($1) == "content-encoding:" { $1=""; sub(/^ /, ""); sub(/\r$/, ""); print tolower($0); exit }' "$header_file")
        case $content_encoding in ''|identity) ;; *) fail "compressed feed bodies are not accepted by the shell fallback" ;; esac

        case $status in
            2??) return 0 ;;
            301|302|303|307|308)
                redirects=$((redirects + 1))
                test "$redirects" -le 5 || fail "too many feed redirects"
                location=$(awk 'tolower($1) == "location:" { $1=""; sub(/^ /, ""); sub(/\r$/, ""); print; exit }' "$header_file")
                case $location in https://*) current_url=$location ;; *) fail "feed redirect must use an absolute HTTPS URL" ;; esac
                ;;
            *) fail "feed returned HTTP $status" ;;
        esac
    done
}

atomic_replace() {
    source_file=$1
    target_file=$2
    chmod 600 "$source_file"
    mv -f -- "$source_file" "$target_file"
}

merge_cache() {
    records=$(mktemp "$cache_dir/.rss-records.XXXXXX") || fail "cannot create merge workspace"
    sorted=$(mktemp "$cache_dir/.rss-sorted.XXXXXX") || { rm -f "$records"; fail "cannot create merge workspace"; }
    combined=$(mktemp "$cache_dir/.combined.json.XXXXXX") || { rm -f "$records" "$sorted"; fail "cannot create merge workspace"; }
    decoded=$(mktemp "$cache_dir/.rss-decoded.XXXXXX") || { rm -f "$records" "$sorted" "$combined"; fail "cannot create merge workspace"; }
    trap 'rm -f "$records" "$sorted" "$combined" "$decoded"' EXIT HUP INT TERM
    : >"$records"

    count=0
    for source_file in "$cache_dir"/source_*.json; do
        test -f "$source_file" || continue
        test ! -L "$source_file" || continue
        test "$(wc -c <"$source_file")" -le "$MAX_CACHE_FILE_BYTES" || continue
        count=$((count + 1))
        test "$count" -le 30 || break
        if base64 -d "$source_file" >"$decoded" 2>/dev/null; then
            RSS_FALLBACK_MODE=objects awk -f "$AWK_SCRIPT" "$decoded" >>"$records" || true
        fi
    done

    LC_ALL=C sort -t '	' -k1,1r "$records" >"$sorted"
    awk -F '	' -v limit="$MAX_COMBINED_ENTRIES" '
        BEGIN { printf "[" }
        {
            first_tab = index($0, "\t")
            rest = substr($0, first_tab + 1)
            second_tab = index(rest, "\t")
            duplicate_id = substr(rest, 1, second_tab - 1)
            object = substr(rest, second_tab + 1)
            if (duplicate_id != "" && seen[duplicate_id]++) next
            if (written >= limit) next
            if (written++) printf ","
            printf "%s", object
        }
        END { print "]" }
    ' "$sorted" >"$combined"
    atomic_replace "$combined" "$cache_dir/combined.json"
    rm -f "$records" "$sorted" "$decoded"
    trap - EXIT HUP INT TERM
    echo "MERGE: SUCCESS"
}

for utility in awk base64 chmod curl getent mkdir mktemp mv od sed sort tr wc; do
    need_command "$utility"
done
test -r "$AWK_SCRIPT" || fail "shell fallback parser is missing"

if test "$#" -eq 2 && test "$1" = "--merge"; then
    normalize_cache_dir "$2"
    merge_cache
    exit 0
fi

test "$#" -eq 4 || fail "usage: rss_sync_fallback.sh <cache_dir> <url> <name> <max_entries>"
normalize_cache_dir "$1"
url=$2
source_name=$3
case $4 in ''|*[!0-9]*) fail "invalid entry limit" ;; esac
max_entries=$4
test "$max_entries" -ge 1 || max_entries=1
test "$max_entries" -le 50 || max_entries=50

key=$(cache_key "$url")
target=$cache_dir/source_$key.json
body=$(mktemp "$cache_dir/.rss-body.XXXXXX") || fail "cannot create download workspace"
headers=$(mktemp "$cache_dir/.rss-headers.XXXXXX") || { rm -f "$body"; fail "cannot create download workspace"; }
json=$(mktemp "$cache_dir/.rss-json.XXXXXX") || { rm -f "$body" "$headers"; fail "cannot create parser workspace"; }
encoded=$(mktemp "$cache_dir/.source_$key.json.XXXXXX") || { rm -f "$body" "$headers" "$json"; fail "cannot create cache workspace"; }
count_file=$(mktemp "$cache_dir/.rss-count.XXXXXX") || { rm -f "$body" "$headers" "$json" "$encoded"; fail "cannot create parser workspace"; }
trap 'rm -f "$body" "$headers" "$json" "$encoded" "$count_file"' EXIT HUP INT TERM

echo "FETCHING: START"
fetch_feed "$url" "$body" "$headers"
echo "FETCHING: OK"
echo "PARSING: START"
RSS_FALLBACK_MODE=parse RSS_SOURCE_NAME=$source_name RSS_SOURCE_URL=$url \
    RSS_MAX_ENTRIES=$max_entries RSS_COUNT_FILE=$count_file \
    awk -f "$AWK_SCRIPT" "$body" >"$json" || fail "XML parse failed"
entry_count=$(sed -n '1p' "$count_file")
case $entry_count in ''|*[!0-9]*) fail "XML parse failed" ;; esac
echo "PARSING: OK ($entry_count items)"
base64 <"$json" | tr -d '\n' >"$encoded"
test "$(wc -c <"$encoded")" -le "$MAX_CACHE_FILE_BYTES" || fail "parsed feed exceeds the cache size limit"
atomic_replace "$encoded" "$target"
rm -f "$body" "$headers" "$json" "$count_file"
trap - EXIT HUP INT TERM
echo "SAVING: $entry_count entries saved OK"
echo "SUCCESS"
