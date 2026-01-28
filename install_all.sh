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
)

BASE_DIR="/home/mcc45tr/Gitler/Projelerim/Plasma6Widgets"

# Arrays to hold targets
install_targets=()
test_target=""
use_prasmoid_build=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
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
