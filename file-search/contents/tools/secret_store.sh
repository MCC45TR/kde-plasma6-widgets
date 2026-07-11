#!/bin/sh

ACTION="$1"
ENTRY="$2"
ENCODED_VALUE="$3"
FOLDER="com.mcc45tr.filesearch"
WALLET="kdewallet"

case "$ENTRY" in
    weatherApiKey|weatherApiKey2) ;;
    *) echo "Unsupported secret entry" >&2; exit 2 ;;
esac

if ! command -v kwallet-query >/dev/null 2>&1; then
    echo "KWallet is unavailable" >&2
    exit 3
fi

case "$ACTION" in
    read)
        kwallet-query -f "$FOLDER" -r "$ENTRY" "$WALLET" 2>/dev/null
        ;;
    write)
        printf '%s' "$ENCODED_VALUE" | base64 -d | kwallet-query -f "$FOLDER" -w "$ENTRY" "$WALLET" >/dev/null
        ;;
    *)
        echo "Unsupported action" >&2
        exit 2
        ;;
esac
