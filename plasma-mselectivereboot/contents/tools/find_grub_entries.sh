#!/bin/bash
# find_grub_entries.sh
# Safely parses grub.cfg to construct JSON output for plasma-mselectivereboot
# Includes submenu and BTRFS snapshots support

# Function to search for grub.cfg
find_grub_cfg() {
    local search_paths=(
        "/boot/grub/grub.cfg"
        "/boot/grub2/grub.cfg"
    )
    
    # Try direct paths first
    for path in "${search_paths[@]}"; do
        if [ -f "$path" ]; then
            echo "$path"
            return 0
        fi
    done

    # Fallback: Find on common EFI partitions (though usually they just stub to /boot/grub)
    if [ -d "/boot/efi/EFI" ]; then
        found=$(find "/boot/efi/EFI" -name "grub.cfg" 2>/dev/null | head -n 1)
        if [ -n "$found" ] && grep -q "configfile" "$found"; then
            # Extract real path from stub
            real_path=$(grep -oP "configfile \K.*" "$found" | sed -e 's/(\$root)//' -e "s/'//g" -e 's/"//g' | xargs | tr -d '\r')
            if [ -f "$real_path" ]; then
                echo "$real_path"
                return 0
            elif [ -f "/boot$real_path" ]; then
                echo "/boot$real_path"
                return 0
            fi
        elif [ -n "$found" ]; then
            echo "$found"
            return 0
        fi
    fi
    return 1
}

# The actual awk parser for GRUB menu and submenus
# This robust awk script handles nesting and extracts IDs properly
parse_grub() {
    local cfg="$1"
    awk '
    BEGIN {
        print "["
        first = 1
        level = 0
        submenu_id = ""
        submenu_title = ""
    }
    
    # helper function to escape JSON strings
    function escape(str) {
        gsub(/\\/, "\\\\", str)
        gsub(/"/, "\\\"", str)
        gsub(/\x09/, "\\t", str)
        gsub(/\x0A/, "\\n", str)
        gsub(/\x0D/, "\\r", str)
        return str
    }

    # Match submenu start
    /^[\t ]*submenu / {
        match($0, /submenu[ \t]+('\''[^'\'']+'\''|"[^"]+"|[^ \t{]+)/, m_title)
        title = m_title[1]
        gsub(/^[\047"]|[\047"]$/, "", title)
        
        id = title
        if (match($0, /--id[ \t]+('\''[^'\'']+'\''|"[^"]+"|[^ \t{]+)/, m_id)) {
            id = m_id[1]
            gsub(/^[\047"]|[\047"]$/, "", id)
        }
        
        submenu_title = title
        submenu_id = id
        level++
        next
    }

    # Match menuentry
    /^[\t ]*menuentry / {
        match($0, /menuentry[ \t]+('\''[^'\'']+'\''|"[^"]+"|[^ \t{]+)/, m_title)
        title = m_title[1]
        gsub(/^[\047"]|[\047"]$/, "", title)
        
        # Determine ID
        id = title
        if (match($0, /--id[ \t]+('\''[^'\'']+'\''|"[^"]+"|[^ \t{]+)/, m_id)) {
            id = m_id[1]
            gsub(/^[\047"]|[\047"]$/, "", id)
            if (level > 0 && submenu_id != "") {
                id = submenu_id ">" id
            }
        } else {
             if (level > 0 && submenu_title != "") {
                id = submenu_title ">" title
            }
        }

        # Format output
        if (!first) { print "," }
        first = 0
        printf "  {\"id\": \"%s\", \"title\": \"%s\"}", escape(id), escape(title)
        
        next
    }

    # Match closing brace (rudimentary level tracking)
    /^[\t ]*\}/ {
        if (level > 0) {
            level--
            if (level == 0) {
                submenu_id = ""
                submenu_title = ""
            }
        }
    }
    
    END {
        print "\n]"
    }
    ' "$cfg"
}

# Main execution
GRUB_CFG=$(find_grub_cfg)

if [ -z "$GRUB_CFG" ]; then
    echo "[]"
    exit 1
fi

if [ ! -r "$GRUB_CFG" ]; then
    # if we cannot read it (permissions), try sudo or output empty
    # For now, just output empty with an error message to stderr
    echo "Cannot read $GRUB_CFG - requires root?" >&2
    echo "[]"
    exit 1
fi

parse_grub "$GRUB_CFG"
exit 0
