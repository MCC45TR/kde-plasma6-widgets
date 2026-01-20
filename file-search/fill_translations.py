import os
import re

locale_dir = "contents/locale"

# Translations dictionary
# Structure: { key: { lang_code: translation } }
translations = {
    "Weather View (weather:)": {
        "az": "Hava Görünüşü (hava:)",
        "cs": "Zobrazení počasí (počasí:)",
        "el": "Προβολή Καιρού (καιρός:)",
        "fa": "نمای آب و هوا (آب و هوا:)",
        "hi": "मौसम दृश्य (मौसम:)",
        "id": "Tampilan Cuaca (cuaca:)",
        "ja": "天気予報 (天気:)",
        "ro": "Vizualizare Meteo (vreme:)",
        "tr": "Hava Durumu Görünümü (hava:)",
        "zh": "天气视图 (天气:)",
        "bn": "আবহাওয়া দৃশ্য (আবহাওয়া:)",
        "de": "Wetteransicht (Wetter:)",
        "es": "Vista del Clima (clima:)",
        "fr": "Vue météo (météo : )",
        "hy": "Եղանակի տեսք (եղանակ:)",
        "it": "Vista Meteo (meteo:)",
        "pt": "Visualização do Tempo (tempo:)",
        "ru": "Просмотр погоды (погода:)",
        "ur": "موسم کا منظر (موسم:)"
    },
    "Enable Weather Prefix": {
        "az": "Hava Prefiksini Aktivləşdir",
        "cs": "Povolit prefix počasí",
        "el": "Ενεργοποίηση Προθέματος Καιρού",
        "fa": "فعال کردن پیشوند آب و هوا",
        "hi": "मौसम उपसर्ग सक्षम करें",
        "id": "Aktifkan Awalan Cuaca",
        "ja": "天気プレフィックスを有効にする",
        "ro": "Activează Prefixul Meteo",
        "tr": "Hava Durumu Önekini Etkinleştir",
        "zh": "启用天气前缀",
        "bn": "আবহাওয়া উপসর্গ सक्षम করুন",
        "de": "Wetter-Präfix aktivieren",
        "es": "Habilitar prefijo del clima",
        "fr": "Activer le préfixe météo",
        "hy": "Միացնել եղանակի նախածանցը",
        "it": "Abilita prefisso meteo",
        "pt": "Ativar prefixo de tempo",
        "ru": "Включить префикс погоды",
        "ur": "موسم کا سابقہ فعال کریں"
    },
    "Use System Units": {
        "az": "Sistem Vahidlərindən İstifadə Et",
        "cs": "Použít systémové jednotky",
        "el": "Χρήση Μονάδων Συστήματος",
        "fa": "استفاده از واحدهای سیستم",
        "hi": "सिस्टम इकाइयों का उपयोग करें",
        "id": "Gunakan Satuan Sistem",
        "ja": "システム単位を使用",
        "ro": "Utilizați unitățile de sistem",
        "tr": "Sistem Birimlerini Kullan",
        "zh": "使用系统单位",
        "bn": "সিস্টem ইউনিট ব্যবহার করুন",
        "de": "Systemeinheiten verwenden",
        "es": "Usar unidades del sistema",
        "fr": "Utiliser les unités du système",
        "hy": "Օգտագործել համակարգի միավորները",
        "it": "Usa unità di sistema",
        "pt": "Usar unidades do sistema",
        "ru": "Использовать системные единицы",
        "ur": "سسٹم یونٹس استعمال کریں"
    },
    "Refresh Interval:": {
        "az": "Yeniləmə Aralığı:",
        "cs": "Interval obnovení:",
        "el": "Διάστημα Ανανέωσης:",
        "fa": "فاصله بروزرسانی:",
        "hi": "ताज़ा अंतराल:",
        "id": "Interval Penyegaran:",
        "ja": "更新間隔:",
        "ro": "Interval de actualizare:",
        "tr": "Yenileme Sıklığı:",
        "zh": "刷新间隔：",
        "bn": "রিফ্রেশ বিরতি:",
        "de": "Aktualisierungsintervall:",
        "es": "Intervalo de actualización:",
        "fr": "Intervalle d'actualisation :",
        "hy": "Թարմացման ինտերվալ:",
        "it": "Intervallo di aggiornamento:",
        "pt": "Intervalo de atualização:",
        "ru": "Интервал обновления:",
        "ur": "تازہ کاری کا وقفہ:"
    },
    "Every Search": {
        "az": "Hər Axtarışda",
        "cs": "Při každém hledání",
        "el": "Σε Κάθε Αναζήτηση",
        "fa": "هر جستجو",
        "hi": "हर खोज",
        "id": "Setiap Pencarian",
        "ja": "検索ごと",
        "ro": "La fiecare căutare",
        "tr": "Her Aramada",
        "zh": "每次搜索",
        "bn": "প্রতি অনুসন্ধানে",
        "de": "Bei jeder Suche",
        "es": "En cada búsqueda",
        "fr": "À chaque recherche",
        "hy": "Յուրաքանչյուր որոնում",
        "it": "Ogni ricerca",
        "pt": "A cada pesquisa",
        "ru": "При каждом поиске",
        "ur": "ہر تلاش پر"
    },
    "15 Minutes": {
        "az": "15 Dəqiqə",
        "cs": "15 minut",
        "el": "15 Λεπτά",
        "fa": "۱۵ دقیقه",
        "hi": "15 मिनट",
        "id": "15 Menit",
        "ja": "15分",
        "ro": "15 minute",
        "tr": "15 Dakika",
        "zh": "15 分钟",
        "bn": "১৫ মিনিট",
        "de": "15 Minuten",
        "es": "15 Minutos",
        "fr": "15 Minutes",
        "hy": "15 րոպե",
        "it": "15 Minuti",
        "pt": "15 Minutos",
        "ru": "15 минут",
        "ur": "15 منٹ"
    },
    "30 Minutes": {
        "az": "30 Dəqiqə",
        "cs": "30 minut",
        "el": "30 Λεπτά",
        "fa": "۳۰ دقیقه",
        "hi": "30 मिनट",
        "id": "30 Menit",
        "ja": "30分",
        "ro": "30 minute",
        "tr": "30 Dakika",
        "zh": "30 分钟",
        "bn": "৩০ মিনিট",
        "de": "30 Minuten",
        "es": "30 Minutos",
        "fr": "30 Minutes",
        "hy": "30 րոպե",
        "it": "30 Minuti",
        "pt": "30 Minutos",
        "ru": "30 минут",
        "ur": "30 منٹ"
    },
    "1 Hour": {
        "az": "1 Saat",
        "cs": "1 hodina",
        "el": "1 Ώρα",
        "fa": "۱ ساعت",
        "hi": "1 घंटा",
        "id": "1 Jam",
        "ja": "1時間",
        "ro": "1 oră",
        "tr": "1 Saat",
        "zh": "1 小时",
        "bn": "১ ঘণ্টা",
        "de": "1 Stunde",
        "es": "1 Hora",
        "fr": "1 Heure",
        "hy": "1 ժամ",
        "it": "1 Ora",
        "pt": "1 Hora",
        "ru": "1 час",
        "ur": "1 گھنٹہ"
    },
    "(If time since last update > interval)": {
        "az": "(Əgər son yenilənmədən keçən vaxt > interval)",
        "cs": "(Pokud čas od poslední aktualizace > interval)",
        "el": "(Εάν ο χρόνος από την τελευταία ενημέρωση > διάστημα)",
        "fa": "(اگر زمان از آخرین بروزرسانی > فاصله)",
        "hi": "(यदि अंतिम अद्यतन के बाद का समय > अंतराल)",
        "id": "(Jika waktu sejak pembaruan terakhir > interval)",
        "ja": "(前回の更新からの時間 > 間隔の場合)",
        "ro": "(Dacă timpul de la ultima actualizare > interval)",
        "tr": "(Eğer son güncellemeden geçen süre > aralık)",
        "zh": "（如果自上次更新以来的时间 > 间隔）",
        "bn": "(যদি শেষ আপডেটের পর থেকে সময় > বিরতি)",
        "de": "(Wenn Zeit seit letzter Aktualisierung > Intervall)",
        "es": "(Si el tiempo desde la última actualización > intervalo)",
        "fr": "(Si le temps écoulé depuis la dernière mise à jour > intervalle)",
        "hy": "(Եթե վերջին թարմացումից անցած ժամանակը > ինտերվալ)",
        "it": "(Se il tempo dall'ultimo aggiornamento > intervallo)",
        "pt": "(Se o tempo desde a última atualização > intervalo)",
        "ru": "(Если время с последнего обновления > интервал)",
        "ur": "(اگر آخری اپ ڈیٹ کے بعد کا وقت > وقفہ)"
    }
}

def process_po_file(lang, filepath):
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            lines = f.readlines()
        
        new_lines = []
        current_msgid = None
        
        for i, line in enumerate(lines):
            line_str = line.strip()
            
            if line_str.startswith('msgid "'):
                current_msgid = line_str[7:-1] # Extract text inside quotes
                new_lines.append(line)
            elif line_str.startswith('msgstr ""'):
                # Found an empty translation
                if current_msgid and current_msgid in translations:
                    trans_map = translations[current_msgid]
                    if lang in trans_map:
                        replacement = f'msgstr "{trans_map[lang]}"\n'
                        new_lines.append(replacement)
                        print(f"[{lang}] Filled: '{current_msgid}' -> '{trans_map[lang]}'")
                    else:
                        new_lines.append(line) # No translation found for this lang
                else:
                    new_lines.append(line)
                current_msgid = None # Reset
            else:
                new_lines.append(line)
                
        with open(filepath, 'w', encoding='utf-8') as f:
            f.writelines(new_lines)
            
    except Exception as e:
        print(f"Error processing {lang}: {e}")

# Iterate over languages
if os.path.exists(locale_dir):
    for lang in os.listdir(locale_dir):
        po_path = os.path.join(locale_dir, lang, "LC_MESSAGES", "plasma_applet_com.mcc45tr.filesearch.po")
        if os.path.exists(po_path):
            process_po_file(lang, po_path)

print("Translation fill complete.")
