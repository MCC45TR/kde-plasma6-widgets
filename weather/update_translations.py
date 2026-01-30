import os
import subprocess

# Define the new translation terms and known translations
translations = {
    "Next week %1": {
        "de": "Nächste Woche %1",
        "fr": "La semaine prochaine %1",
        "es": "La próxima semana %1",
        "it": "La prossima settimana %1",
        "tr": "Gelecek hafta %1",
        "ru": "На следующей неделе %1",
        "nl": "Volgende week %1",
    },
    "2 weeks later %1": {
        "de": "2 Wochen später %1",
        "fr": "Dans 2 semaines %1",
        "es": "2 semanas después %1",
        "it": "2 settimane dopo %1",
        "tr": "2 hafta sonra %1",
        "ru": "Через 2 недели %1",
        "nl": "2 weken later %1",
    },
    "Tap to close": {
        "de": "Zum Schließen tippen",
        "fr": "Appuyez pour fermer",
        "es": "Toque para cerrar",
        "it": "Tocca per chiudere",
        "tr": "Kapatmak için dokunun",
        "ru": "Нажмите, чтобы закрыть",
        "nl": "Tik om te sluiten",
    }
}

base_dir = "/home/mcc45tr/Gitler/Projelerim/Plasma6Widgets/weather/contents/locale"

def update_po_files():
    # Walk through the locale directory
    for root, dirs, files in os.walk(base_dir):
        for file in files:
            if file.endswith(".po"):
                po_path = os.path.join(root, file)
                lang_code = os.path.basename(os.path.dirname(os.path.dirname(po_path))) # locale/tr/LC_MESSAGES -> tr
                
                # Check formatting of the lang_code (handle de_DE etc)
                simple_lang = lang_code.split('_')[0]
                
                with open(po_path, "r", encoding="utf-8") as f:
                    content = f.read()
                
                updates_made = False
                new_content = content
                
                for msgid, trans_dict in translations.items():
                    if f'msgid "{msgid}"' not in content:
                        print(f"Adding '{msgid}' to {lang_code}...")
                        
                        translation = ""
                        # Try exact match first, then simple lang match
                        if lang_code in trans_dict:
                            translation = trans_dict[lang_code]
                        elif simple_lang in trans_dict:
                            translation = trans_dict[simple_lang]
                        
                        # Append to file content
                        new_content += f'\n\nmsgid "{msgid}"\nmsgstr "{translation}"\n'
                        updates_made = True
                
                if updates_made:
                    with open(po_path, "w", encoding="utf-8") as f:
                        f.write(new_content)
                    print(f"Updated {po_path}")
                
                # Compile to .mo
                mo_path = po_path.replace(".po", ".mo")
                try:
                    subprocess.run(["msgfmt", "-o", mo_path, po_path], check=True)
                    print(f"Compiled {mo_path}")
                except subprocess.CalledProcessError as e:
                    print(f"Error compiling {po_path}: {e}")
                except FileNotFoundError:
                    print("msgfmt not found. Skipping compilation.")

if __name__ == "__main__":
    print("Starting translation update...")
    update_po_files()
    print("Finished.")
