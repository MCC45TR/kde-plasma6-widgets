#!/bin/bash

# Array of widget directories
widgets=(
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
"gemini-chat"
)

BASE_DIR="/home/mcc45tr/Gitler/Projelerim/Plasma6Widgets"

echo "Starting installation of Plasma 6 Widgets..."

for widget in "${widgets[@]}"; do
    TARGET_DIR="$BASE_DIR/$widget"
    if [ -d "$TARGET_DIR" ]; then
        echo "Processing $widget..."
        cd "$TARGET_DIR" || continue
        
        # Extract Plugin ID from metadata.json to find install path using python for reliability
        PLUGIN_ID=$(python3 -c "import json; print(json.load(open('metadata.json'))['KPlugin']['Id'])" 2>/dev/null)
        
        if [ -n "$PLUGIN_ID" ]; then
            INSTALL_PATH="$HOME/.local/share/plasma/plasmoids/$PLUGIN_ID"
            # Force remove existing to avoid update/structure errors
            if [ -d "$INSTALL_PATH" ]; then
                echo "  -> Removing existing old version..."
                rm -rf "$INSTALL_PATH"
            fi
        fi

        if kpackagetool6 --type Plasma/Applet --install . > /dev/null 2>&1; then
             echo "  -> Installed successfully."
        else
             echo "  -> Failed to install."
             # Show error log if failed for debugging
             kpackagetool6 --type Plasma/Applet --install .
        fi
    else
        echo "Directory $widget not found, skipping."
    fi
done

echo "All widgets processed."

# If an argument is provided, try to launch that widget for testing
if [ -n "$1" ]; then
    TEST_WIDGET="$1"
    METADATA_PATH="$BASE_DIR/$TEST_WIDGET/metadata.json"
    
    if [ -f "$METADATA_PATH" ]; then
        TEST_ID=$(python3 -c "import json; print(json.load(open('$METADATA_PATH'))['KPlugin']['Id'])" 2>/dev/null)
        if [ -n "$TEST_ID" ]; then
            echo "Launching test for $TEST_WIDGET ($TEST_ID)..."
            echo "Press Ctrl+C to stop the test."
            plasmawindowed "$TEST_ID"
        else
            echo "Could not find Plugin ID for $TEST_WIDGET"
        fi
    else
        echo "Widget directory '$TEST_WIDGET' not found or missing metadata.json."
        echo "Usage: ./install_all.sh [widget-directory-name]"
    fi
fi
