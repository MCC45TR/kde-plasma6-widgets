import os
import subprocess
import re

# Comprehensive list of translations
# Dictionary format: msgid -> { lang_code -> translation }
translations = {
    "Next week %1": {
        "de": "Nächste Woche %1",
        "fr": "La semaine prochaine %1",
        "es": "La próxima semana %1",
        "it": "La prossima settimana %1",
        "tr": "Gelecek hafta %1",
        "ru": "На следующей неделе %1",
        "nl": "Volgende week %1",
        "az": "Gələn həftə %1",
        "ja": "来週 %1",
        "zh": "下周 %1",
        "zh_CN": "下周 %1",
        "pl": "W przyszłym tygodniu %1",
        "uk": "Наступного тижня %1",
        "id": "Minggu depan %1",
        "ko": "다음 주 %1",
        "pt": "Próxima semana %1",
        "pt_BR": "Próxima semana %1",
        "ro": "Săptămâna viitoare %1",
        "hu": "Jövő héten %1",
        "cs": "Příští týden %1",
        "da": "Næste uge %1",
        "sv": "Nästa vecka %1",
        "fi": "Ensi viikolla %1",
        "no": "Neste uke %1",
        "el": "Την επόμενη εβδομάδα %1",
        "bg": "Следващата седмица %1",
        "ar": "الأسبوع القادم %1",
        "hi": "अगले सप्ताह %1",
        "he": "בשבוע הבא %1",
        "vi": "Tuần tới %1",
        "th": "สัปดาห์หน้า %1"
    },
    "2 weeks later %1": {
        "de": "2 Wochen später %1",
        "fr": "Dans 2 semaines %1",
        "es": "2 semanas después %1",
        "it": "2 settimane dopo %1",
        "tr": "2 hafta sonra %1",
        "ru": "Через 2 недели %1",
        "nl": "2 weken later %1",
        "az": "2 həftə sonra %1",
        "ja": "2週間後 %1",
        "zh": "2周后 %1",
        "zh_CN": "2周后 %1",
        "pl": "Za 2 tygodnie %1",
        "uk": "Через 2 тижні %1",
        "id": "2 minggu kemudian %1",
        "ko": "2주 후 %1",
        "pt": "2 semanas depois %1",
        "pt_BR": "2 semanas depois %1",
        "ro": "2 săptămâni mai târziu %1",
        "hu": "2 héttel később %1",
        "cs": "O 2 týdny později %1",
        "da": "2 uger senere %1",
        "sv": "2 veckor senare %1",
        "fi": "2 viikon kuluttua %1",
        "no": "2 uker senere %1",
        "el": "2 εβδομάδες αργότερα %1",
        "bg": "2 седмици по-късно %1",
        "ar": "بعد أسبوعين %1",
        "hi": "2 सप्ताह बाद %1",
        "he": "בעוד שבועיים %1",
        "vi": "2 tuần sau %1",
        "th": "2 สัปดาห์ต่อมา %1"
    },
    "Tap to close": {
        "de": "Zum Schließen tippen",
        "fr": "Appuyez pour fermer",
        "es": "Toque para cerrar",
        "it": "Tocca per chiudere",
        "tr": "Kapatmak için dokunun",
        "ru": "Нажмите, чтобы закрыть",
        "nl": "Tik om te sluiten",
        "az": "Bağlamaq üçün toxunun",
        "ja": "タップして閉じる",
        "zh": "点击关闭",
        "zh_CN": "点击关闭",
        "pl": "Dotknij, aby zamknąć",
        "uk": "Торкніться, щоб закрити",
        "id": "Ketuk untuk menutup",
        "ko": "닫으려면 탭하세요",
        "pt": "Toque para fechar",
        "pt_BR": "Toque para fechar",
        "ro": "Atingeți pentru a închide",
        "hu": "Érintse meg a bezáráshoz",
        "cs": "Klepnutím zavřete",
        "da": "Tryk for at lukke",
        "sv": "Tryck för att stänga",
        "fi": "Sulje napauttamalla",
        "no": "Trykk for å lukke",
        "el": "Πατήστε για κλείσιμο",
        "bg": "Докоснете, за да затворите",
        "ar": "اضغط للإغلاق",
        "hi": "बंद करने के लिए टैप करें",
        "he": "הקש לסגירה",
        "vi": "Chạm để đóng",
        "th": "แตะเพื่อปิด"
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
                
                simple_lang = lang_code.split('_')[0]
                
                with open(po_path, "r", encoding="utf-8") as f:
                    content = f.read()
                
                new_content = content
                updates_made = False
                
                for msgid, trans_dict in translations.items():
                    target_trans = None
                    if lang_code in trans_dict:
                        target_trans = trans_dict[lang_code]
                    elif simple_lang in trans_dict:
                        target_trans = trans_dict[simple_lang]
                    
                    if target_trans:
                        # 1. Check if msgid exists but has empty msgstr
                        # This matches: msgid "Next week %1" [whitespace] msgstr ""
                        pattern_empty = re.compile(f'msgid "{re.escape(msgid)}"\s+msgstr ""')
                        
                        if pattern_empty.search(new_content):
                            # print(f"Filling empty translation for '{msgid}' in {lang_code}")
                            new_content = pattern_empty.sub(f'msgid "{msgid}"\nmsgstr "{target_trans}"', new_content)
                            updates_made = True
                        
                        # 2. Check if msgid does NOT exist at all
                        elif f'msgid "{msgid}"' not in new_content:
                            new_content += f'\n\nmsgid "{msgid}"\nmsgstr "{target_trans}"\n'
                            updates_made = True
                        
                        # If it exists and is not empty, we leave it alone (preserve manual changes)

                if updates_made:
                    with open(po_path, "w", encoding="utf-8") as f:
                        f.write(new_content)
                    print(f"Updated {po_path}")
                    
                    # Compile to .mo
                    mo_path = po_path.replace(".po", ".mo")
                    try:
                        subprocess.run(["msgfmt", "-o", mo_path, po_path], check=True)
                        # print(f"Compiled {mo_path}")
                    except Exception:
                        pass

if __name__ == "__main__":
    print("Starting comprehensive translation update...")
    update_po_files()
    print("Finished.")
