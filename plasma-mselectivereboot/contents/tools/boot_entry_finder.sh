#!/bin/bash
# boot_entry_finder.sh
# Combined script to detect bootloader and find boot entries
# ALWAYS outputs a JSON object with: { "bootloader": "...", "entries": [...] }

# --- 1. DETECTION LOGIC ---
detect_bootloader() {
    # 1. Check for systemd-boot (UEFI and specific entry selected)
    if [ -d /sys/firmware/efi/efivars ] && (ls /sys/firmware/efi/efivars/LoaderEntrySelected-* 2>/dev/null | grep -q .); then
        echo "systemd-boot"
        return 0
    fi

    # 2. Check for Limine
    if command -v limine-list >/dev/null 2>&1 || [ -f /boot/limine.conf ] || [ -f /boot/limine/limine.conf ] || [ -f /boot/limine.cfg ]; then
        echo "limine"
        return 0
    fi

    # 3. Check for GRUB
    if [ -f /boot/grub/grub.cfg ] || [ -f /boot/grub2/grub.cfg ] || [ -f /boot/grub/grub.conf ]; then
        echo "grub"
        return 0
    fi

    # 4. Fallback systemd-boot
    if command -v bootctl >/dev/null 2>&1 && bootctl status >/dev/null 2>&1; then
        echo "systemd-boot"
        return 0
    fi

    echo "unknown"
    return 1
}

# --- 2. GRUB LOGIC ---
find_grub_cfg() {
    local search_paths=("/boot/grub/grub.cfg" "/boot/grub2/grub.cfg")
    for path in "${search_paths[@]}"; do
        if [ -f "$path" ]; then echo "$path"; return 0; fi
    done
    return 1
}

get_grub_json() {
    local cfg="$1"
    awk '
    BEGIN { print "["; first = 1; level = 0; submenu_id = ""; submenu_title = "" }
    function escape(str) {
        gsub(/\\/, "\\\\", str); gsub(/"/, "\\\"", str); gsub(/\x09/, "\\t", str);
        gsub(/\x0A/, "\\n", str); gsub(/\x0D/, "\\r", str); return str
    }
    /^[\t ]*submenu / {
        match($0, /submenu[ \t]+('\''[^'\'']+'\''|"[^"]+"|[^ \t{]+)/, m_title)
        title = m_title[1]; gsub(/^[\047"]|[\047"]$/, "", title)
        id = title; if (match($0, /--id[ \t]+('\''[^'\'']+'\''|"[^"]+"|[^ \t{]+)/, m_id)) {
            id = m_id[1]; gsub(/^[\047"]|[\047"]$/, "", id)
        }
        submenu_title = title; submenu_id = id; level++; next
    }
    /^[\t ]*menuentry / {
        match($0, /menuentry[ \t]+('\''[^'\'']+'\''|"[^"]+"|[^ \t{]+)/, m_title)
        title = m_title[1]; gsub(/^[\047"]|[\047"]$/, "", title)
        id = title; if (match($0, /--id[ \t]+('\''[^'\'']+'\''|"[^"]+"|[^ \t{]+)/, m_id)) {
            id = m_id[1]; gsub(/^[\047"]|[\047"]$/, "", id)
            if (level > 0 && submenu_id != "") id = submenu_id ">" id
        } else if (level > 0 && submenu_title != "") {
            id = submenu_title ">" title
        }
        if (!first) { print "," }; first = 0
        printf "  {\"id\": \"%s\", \"title\": \"%s\"}", escape(id), escape(title)
        next
    }
    /^[\t ]*\}/ { if (level > 0) { level--; if (level == 0) { submenu_id = ""; submenu_title = "" } } }
    END { print "\n]" }
    ' "$cfg"
}

# --- 3. LIMINE LOGIC ---
find_limine_cfg() {
    local search_paths=("/boot/limine.conf" "/boot/limine/limine.conf" "/limine.conf" "/boot/limine.cfg" "/boot/limine/limine.cfg")
    for path in "${search_paths[@]}"; do
        if [ -f "$path" ]; then echo "$path"; return 0; fi
    done
    for mnt in /boot/efi /efi /boot /boot/EFI /efi/EFI; do
        [ -f "$mnt/limine/limine.conf" ] && echo "$mnt/limine/limine.conf" && return 0
        [ -f "$mnt/EFI/limine/limine.conf" ] && echo "$mnt/EFI/limine/limine.conf" && return 0
        [ -f "$mnt/limine.conf" ] && echo "$mnt/limine.conf" && return 0
    done
    find /boot /efi -maxdepth 3 -name "limine.conf" -o -name "limine.cfg" 2>/dev/null | head -n 1
}

get_limine_json() {
    # Try limine-list first
    if command -v limine-list >/dev/null 2>&1; then
        RAW_OUT=$(limine-list 2>/dev/null)
        if [ -n "$RAW_OUT" ]; then
            echo "["
            FIRST=1; INDEX=0
            while IFS= read -r line; do
                [[ "$line" =~ "Entries" ]] && continue
                [[ -z "$(echo "$line" | xargs)" ]] && continue
                TITLE=$(echo "$line" | sed 's/^[ \t]*[0-9]\+:[ \t]*//' | sed 's/^[ \t]*\[[0-9]\+\][ \t]*//' | sed 's/^[^a-zA-Z0-9(]*//' | xargs)
                [ -z "$TITLE" ] && continue
                [ $FIRST -eq 0 ] && echo ","
                printf "  {\"id\": \"%d\", \"title\": \"%s\"}" "$INDEX" "$TITLE"
                FIRST=0; INDEX=$((INDEX + 1))
            done <<< "$RAW_OUT"
            echo -e "\n]"
            return 0
        fi
    fi
    # Fallback to cfg parsing
    CFG=$(find_limine_cfg)
    if [ -n "$CFG" ] && [ -r "$CFG" ]; then
        awk '
        BEGIN { print "["; first = 1 }
        function escape(str) { gsub(/\\/, "\\\\", str); gsub(/"/, "\\\"", str); return str }
        /^:/ || /^INTERFACE=/ {
            if ($0 ~ /^:/) title = substr($0, 2); else title = substr($0, index($0, "=") + 1)
            gsub(/^[ \t]+|[ \t]+$/, "", title)
            if (length(title) == 0) next
            if (!first) { print "," }; first = 0
            printf "  {\"id\": \"%s\", \"title\": \"%s\"}", escape(title), escape(title)
            next
        }
        END { print "\n]" }
        ' "$CFG"
    else
        echo "[]"
        return 1
    fi
}

# --- MAIN EXECUTION ---
# Usage: boot_entry_finder.sh [bootloader_hint]
TARGET=${1}
if [ -z "$TARGET" ]; then
    TARGET=$(detect_bootloader)
fi

echo -n "{ \"bootloader\": \"$TARGET\", \"entries\": "

case "$TARGET" in
    "systemd-boot")
        if command -v bootctl >/dev/null 2>&1; then
            # Embed the bootctl output as a partial JSON document.
            bootctl list --json=short || echo "[]"
        else
            echo "[]"
        fi
        ;;
    "grub")
        CFG=$(find_grub_cfg)
        if [ -n "$CFG" ] && [ -r "$CFG" ]; then
            get_grub_json "$CFG"
        else
            echo "[]"
        fi
        ;;
    "limine")
        get_limine_json || echo "[]"
        ;;
    *)
        echo "[]"
        ;;
esac

echo " }"
exit 0
