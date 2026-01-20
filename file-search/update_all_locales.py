import os

locale_dir = "/home/mcc45tr/Gitler/Projelerim/Plasma6Widgets/file-search/contents/locale"

# List of all key strings used in the QML that need translation
keys_to_add = [
    "Scan for boot entries",
    "Hibernate",
    "Sleep",
    "Reboot",
    "Shutdown",
    "Lock Screen",
    "Log Out",
    "Switch User",
    "Save Session",
    "(Press again to hibernate)",
    "(Press again to sleep)",
    "(Press again to reboot)",
    "(Press again to shutdown)",
    "(Press again to log out)",
    "(Press again to switch)",
    "Panel Appearance",
    "Button Mode (Icon only)",
    "Medium Mode (Text)",
    "Wide Mode (Search Bar)",
    "Extra Wide Mode",
    "Show boot options in Reboot button",
    "Enable File Previews",
    "Show/Hide Previews",
    "Edge Appearance",
    "Round corners",
    "Slightly round",
    "Less round",
    "Square corners",
    "(Swap partition size is smaller than RAM or no swap found)",
    "Note: Systemd boot is required for this feature",
    "Result Count",
    "Priority Ranking",
    "Show Together",
    "Corner Roundness",
    "Square",
    "Slightly Rounded",
    "Moderately Rounded",
    "Fully Rounded"
]

# We will update ALL languages including TR to ensure consistency, 
# though we won't overwrite existing translations, just append missing msgids.

for lang in os.listdir(locale_dir):
    po_file_path = os.path.join(locale_dir, lang, "LC_MESSAGES", "plasma_applet_com.mcc45tr.filesearch.po")
    if not os.path.exists(po_file_path):
        continue
        
    print(f"Processing {lang}...")
    
    try:
        with open(po_file_path, "r", encoding="utf-8") as f:
            content = f.read()
            
        with open(po_file_path, "a", encoding="utf-8") as f:
            for key in keys_to_add:
                # Basic check to avoid duplicates (msguniq will clean up anyway but good to avoid large appends)
                if f'msgid "{key}"' not in content:
                    f.write(f'\nmsgid "{key}"\nmsgstr ""\n')
                    
    except Exception as e:
        print(f"Error processing {lang}: {e}")
