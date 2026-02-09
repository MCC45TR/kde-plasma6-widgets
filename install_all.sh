#!/bin/bash

# Array of all available widgets
available_widgets=(
"digital-clock"
"analog-clock"
"music-player"
"calendar"
"events"
"weather"
"battery"
"photos"
"spotify"
"world-clock"
"alarms"
"aur-updates"
"notes"
"control-center"
"system-monitor"
"plasma-advancedreboot"
"minimal-analog-clock"
"file-search"
"browser-search"
"app-menu"
"msi-control"
"AFAD-earthquick-reports"
)
# Get script directory (works on any computer)
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Help function
show_help() {
    cat << EOF
╔══════════════════════════════════════════════════════════════════╗
║              Plasma6 Widgets Installation Script                 ║
╚══════════════════════════════════════════════════════════════════╝

USAGE:
    ./install_all.sh [OPTIONS] [WIDGET...]

OPTIONS:
    -h, --help       Show this help message
    -t <widget>      Install and test widget with plasmawindowed
    --prasmoid       Run 'prasmoid build' before installation
    -l, --list       List all available widgets

EXAMPLES:
    ./install_all.sh                    # Install ALL widgets
    ./install_all.sh weather battery    # Install specific widgets
    ./install_all.sh -t msi-control     # Install and test msi-control
    ./install_all.sh --prasmoid weather # Build then install weather

AVAILABLE WIDGETS:
EOF
    printf '    • %s\n' "${available_widgets[@]}"
    echo ""
    exit 0
}

# List widgets function
list_widgets() {
    echo "Available widgets (${#available_widgets[@]} total):"
    echo "────────────────────────────────────────"
    printf '  %s\n' "${available_widgets[@]}"
    exit 0
}

# Arrays to hold targets
install_targets=()
test_target=""
use_prasmoid_build=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            ;;
        -l|--list)
            list_widgets
            ;;
        -t)
            if [ -n "$2" ]; then
                test_target="$2"
                install_targets+=("$2")
                shift # Remove -t
                shift # Remove argument
            else
                echo "Error: -t requires a widget directory name."
                exit 1
            fi
            ;;
        --prasmoid)
            use_prasmoid_build=true
            shift
            ;;
        *)
            install_targets+=("$1")
            shift
            ;;
    esac
done

# If no specific targets provided, install all
if [ ${#install_targets[@]} -eq 0 ]; then
    echo "No specific widgets provided. Installing ALL widgets..."
    install_targets=("${available_widgets[@]}")
else
    # Remove duplicates from install_targets potentially
    # (Simple bash way or ignore it, kpackagetool handles re-install fine)
    echo "Installing specific widgets: ${install_targets[*]}"
fi

echo "Starting installation..."

for widget in "${install_targets[@]}"; do
    TARGET_DIR="$BASE_DIR/$widget"
    
    # Check if directory exists
    if [ ! -d "$TARGET_DIR" ]; then
        echo "Error: Directory '$widget' not found in $BASE_DIR. Skipping."
        continue
    fi
    
    echo "Processing $widget..."
    cd "$TARGET_DIR" || continue

    if [ "$use_prasmoid_build" = true ]; then
        echo "  -> Running prasmoid build..."
        prasmoid build
    fi
    
    # Compile translations manually if present
    if [ -d "translations" ]; then
        echo "  -> Compiling translations..."
        # get plugin id for mo filename
        if [ -f "metadata.json" ]; then
             P_ID=$(python3 -c "import json; print(json.load(open('metadata.json'))['KPlugin']['Id'])" 2>/dev/null)
             MO_NAME="plasma_applet_${P_ID}.mo"
             
             for po_file in translations/*.po; do
                 lang=$(basename "$po_file" .po)
                 if [ "$lang" != "template" ]; then
                     mkdir -p "contents/locale/$lang/LC_MESSAGES"
                     msgfmt "$po_file" -o "contents/locale/$lang/LC_MESSAGES/$MO_NAME"
                 fi
             done
        fi
    fi
    
    # Extract Plugin ID from metadata.json
    PLUGIN_ID=""
    if [ -f "metadata.json" ]; then
        PLUGIN_ID=$(python3 -c "import json; print(json.load(open('metadata.json'))['KPlugin']['Id'])" 2>/dev/null)
    fi
    
    if [ -n "$PLUGIN_ID" ]; then
        INSTALL_PATH="$HOME/.local/share/plasma/plasmoids/$PLUGIN_ID"
        # Force remove existing to avoid update/structure errors
        if [ -d "$INSTALL_PATH" ]; then
            echo "  -> Removing existing old version..."
            rm -rf "$INSTALL_PATH"
        fi
    else
        echo "  -> Warning: Could not determine Plugin ID from metadata.json"
    fi

    # Install
    if kpackagetool6 --type Plasma/Applet --install . > /dev/null 2>&1; then
            echo "  -> Installed successfully."
            
            # Install notification config if it exists
            if ls contents/notifications/*.notifyrc >/dev/null 2>&1; then
                NOTIFY_DIR="$HOME/.local/share/knotifications6"
                mkdir -p "$NOTIFY_DIR"
                cp contents/notifications/*.notifyrc "$NOTIFY_DIR/"
                echo "  -> Installed notification config."
            fi
    else
            echo "  -> Failed to install."
            # Show error log if failed for debugging
            kpackagetool6 --type Plasma/Applet --install .
    fi
done

echo "Installation process finished."

# Run test if requested
if [ -n "$test_target" ]; then
    echo "----------------------------------------"
    echo "Launching test for: $test_target"
    
    TARGET_DIR="$BASE_DIR/$test_target"
    if [ -d "$TARGET_DIR" ]; then
        METADATA_PATH="$TARGET_DIR/metadata.json"
        if [ -f "$METADATA_PATH" ]; then
            TEST_ID=$(python3 -c "import json; print(json.load(open('$METADATA_PATH'))['KPlugin']['Id'])" 2>/dev/null)
            
            if [ -n "$TEST_ID" ]; then
                echo "Plugin ID: $TEST_ID"
                echo "Press Ctrl+C to stop the test."
                plasmawindowed "$TEST_ID"
            else
                echo "Error: Could not extract Plugin ID for testing."
            fi
        else
            echo "Error: metadata.json not found for $test_target."
        fi
    else
        echo "Error: Directory for $test_target not found."
    fi
fi