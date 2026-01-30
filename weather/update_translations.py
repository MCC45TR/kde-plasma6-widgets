import os
import subprocess
import re

# Comprehensive list of translations
# Dictionary format: msgid -> { lang_code -> translation }
translations = {
    # --- Days (Full and Short) ---
    "Monday": {"de": "Montag", "fr": "Lundi", "es": "Lunes", "it": "Lunedì", "tr": "Pazartesi", "ru": "Понедельник", "nl": "Maandag", "az": "Bazar ertəsi", "ja": "月曜日", "zh": "星期一", "ro": "Luni", "hu": "Hétfő", "cs": "Pondělí", "pt": "Segunda-feira"},
    "Tuesday": {"de": "Dienstag", "fr": "Mardi", "es": "Martes", "it": "Martedì", "tr": "Salı", "ru": "Вторник", "nl": "Dinsdag", "az": "Çərşənbə axşamı", "ja": "火曜日", "zh": "星期二", "ro": "Marți", "hu": "Kedd", "cs": "Úterý", "pt": "Terça-feira"},
    "Wednesday": {"de": "Mittwoch", "fr": "Mercredi", "es": "Miércoles", "it": "Mercoledì", "tr": "Çarşamba", "ru": "Среда", "nl": "Woensdag", "az": "Çərşənbə", "ja": "水曜日", "zh": "星期三", "ro": "Miercuri", "hu": "Szerda", "cs": "Středa", "pt": "Quarta-feira"},
    "Thursday": {"de": "Donnerstag", "fr": "Jeudi", "es": "Jueves", "it": "Giovedì", "tr": "Perşembe", "ru": "Четверг", "nl": "Donderdag", "az": "Cümə axşamı", "ja": "木曜日", "zh": "星期四", "ro": "Joi", "hu": "Csütörtök", "cs": "Čtvrtek", "pt": "Quinta-feira"},
    "Friday": {"de": "Freitag", "fr": "Vendredi", "es": "Viernes", "it": "Venerdì", "tr": "Cuma", "ru": "Пятница", "nl": "Vrijdag", "az": "Cümə", "ja": "金曜日", "zh": "星期五", "ro": "Vineri", "hu": "Péntek", "cs": "Pátek", "pt": "Sexta-feira"},
    "Saturday": {"de": "Samstag", "fr": "Samedi", "es": "Sábado", "it": "Sabato", "tr": "Cumartesi", "ru": "Суббота", "nl": "Zaterdag", "az": "Şənbə", "ja": "土曜日", "zh": "星期六", "ro": "Sâmbătă", "hu": "Szombat", "cs": "Sobota", "pt": "Sábado"},
    "Sunday": {"de": "Sonntag", "fr": "Dimanche", "es": "Domingo", "it": "Domenica", "tr": "Pazar", "ru": "Воскресенье", "nl": "Zondag", "az": "Bazar", "ja": "日曜日", "zh": "星期日", "ro": "Duminică", "hu": "Vasárnap", "cs": "Neděle", "pt": "Domingo"},
    "Mon": {"tr": "Pzt", "de": "Mo", "fr": "Lun", "es": "Lun", "ru": "Пн"},
    "Tue": {"tr": "Sal", "de": "Di", "fr": "Mar", "es": "Mar", "ru": "Вт"},
    "Wed": {"tr": "Çar", "de": "Mi", "fr": "Mer", "es": "Mié", "ru": "Ср"},
    "Thu": {"tr": "Per", "de": "Do", "fr": "Jeu", "es": "Jue", "ru": "Чт"},
    "Fri": {"tr": "Cum", "de": "Fr", "fr": "Ven", "es": "Vie", "ru": "Пт"},
    "Sat": {"tr": "Cmt", "de": "Sa", "fr": "Sam", "es": "Sáb", "ru": "Сб"},
    "Sun": {"tr": "Paz", "de": "So", "fr": "Dim", "es": "Dom", "ru": "Вс"},
    "Today": {"tr": "Bugün", "de": "Heute", "fr": "Aujourd'hui", "es": "Hoy", "it": "Oggi", "ru": "Сегодня"},

    # --- Weather Conditions ---
    "Clear": {"tr": "Açık", "de": "Klar", "fr": "Clair", "es": "Despejado", "it": "Sereno", "ru": "Ясно"},
    "Mainly Clear": {"tr": "Çoğunlukla Açık", "de": "Überwiegend klar", "fr": "Principalement clair", "es": "Mayormente despejado", "ru": "Преимущественно ясно"},
    "Partly Cloudy": {"tr": "Parçalı Bulutlu", "de": "Teilweise bewölkt", "fr": "Partiellement nuageux", "es": "Parcialmente nublado", "ru": "Переменная облачность"},
    "Overcast": {"tr": "Kapalı", "de": "Bedeckt", "fr": "Couvert", "es": "Cubierto", "ru": "Пасмурно"},
    "Fog": {"tr": "Sisli", "de": "Nebel", "fr": "Brouillard", "es": "Niebla", "ru": "Туман"},
    "Drizzle": {"tr": "Çiseleme", "de": "Nieselregen", "fr": "Bruine", "es": "Llovizna", "ru": "Морось"},
    "Freezing Drizzle": {"tr": "Dondurucu Çiseleme", "de": "Gefrierender Nieselregen", "fr": "Bruine verglaçante", "es": "Llovizna congelante", "ru": "Ледяная морось"},
    "Rain": {"tr": "Yağmurlu", "de": "Regen", "fr": "Pluie", "es": "Lluvia", "ru": "Дождь"},
    "Freezing Rain": {"tr": "Dondurucu Yağmur", "de": "Gefrierender Regen", "fr": "Pluie verglaçante", "es": "Lluvia gélida", "ru": "Ледяной дождь"},
    "Snow": {"tr": "Karlı", "de": "Schnee", "fr": "Neige", "es": "Nieve", "ru": "Снег"},
    "Snow Grains": {"tr": "Kar Taneleri", "de": "Griesel", "fr": "Neige en grains", "es": "Cencellada", "ru": "Снежная крупа"},
    "Rain Showers": {"tr": "Sağanak Yağış", "de": "Regenschauer", "fr": "Averses de pluie", "es": "Chubascos", "ru": "Ливневый дождь"},
    "Snow Showers": {"tr": "Kar Sağanağı", "de": "Schneeschauer", "fr": "Averses de neige", "es": "Chubascos снега", "ru": "Ливневый снег"},
    "Thunderstorm": {"tr": "Gök Gürültülü Fırtına", "de": "Gewitter", "fr": "Orage", "es": "Tormenta", "ru": "Гроза"},
    "Thunderstorm with Hail": {"tr": "Dolu ile Gök Gürültülü Fırtına", "de": "Gewitter mit Hagel", "fr": "Orage avec grêle", "es": "Tormenta con granizo", "ru": "Гроза с градом"},
    "Cloudy": {"tr": "Bulutlu", "de": "Bewölkt", "fr": "Nuageux", "es": "Nublado", "ru": "Облачно"},
    "Unknown": {"tr": "Bilinmiyor", "de": "Unbekannt", "fr": "Inconnu", "es": "Desconocido", "ru": "Неизвестно"},

    # --- UI Elements & Labels ---
    "Feels like": {"tr": "Hissedilen", "de": "Gefühlt", "fr": "Ressenti", "es": "Sensación", "ru": "Ощущается как"},
    "Precipitation": {"tr": "Yağış", "de": "Niederschlag", "fr": "Précipitations", "es": "Precipitación", "ru": "Осадки"},
    "Pressure": {"tr": "Basınç", "de": "Luftdruck", "fr": "Pression", "es": "Presión", "ru": "Давление"},
    "Dew Point": {"tr": "Çiy Noktası", "de": "Taupunkt", "fr": "Point de rosée", "es": "Punto de rocío", "ru": "Точка росы"},
    "Cloud Cover": {"tr": "Bulutluluk", "de": "Bewölkung", "fr": "Couverture nuageuse", "es": "Nubosidad", "ru": "Облачность"},
    "Wind Direction": {"tr": "Rüzgar Yönü", "de": "Windrichtung", "fr": "Direction du vent", "es": "Dirección del viento", "ru": "Направление ветра"},
    "Humidity": {"tr": "Nem", "de": "Luftfeuchtigkeit", "fr": "Humidité", "es": "Humedad", "ru": "Влажность"},
    "Visibility": {"tr": "Görünürlük", "de": "Sichtweite", "fr": "Visibilité", "es": "Visibilidad", "ru": "Видимость"},
    "Wind Speed": {"tr": "Rüzgar Hızı", "de": "Windgeschwindigkeit", "fr": "Vitesse du vent", "es": "Velocidad del viento", "ru": "Скорость ветра"},
    "UV Index": {"tr": "UV İndeksi", "de": "UV-Index", "fr": "Indice UV", "es": "Índice UV", "ru": "УФ-индекс"},
    "Rain Chance": {"tr": "Yağmur Olasılığı", "de": "Regenwahrscheinlichkeit", "fr": "Chance de pluie", "es": "Probabilidad de lluvia", "ru": "Вероятность дождя"},
    "Sunrise": {"tr": "Gün Doğumu", "de": "Sonnenaufgang", "fr": "Lever du soleil", "es": "Amanecer", "ru": "Восход"},
    "Sunset": {"tr": "Gün Batımı", "de": "Sonnenuntergang", "fr": "Coucher du soleil", "es": "Закат", "ru": "Закат"},
    "Daily Forecast": {"tr": "Günlük Tahmin", "de": "Tagesvorhersage", "fr": "Prévisions quotidiennes", "es": "Pronóstico diario", "ru": "Дневной прогноз"},
    "Hourly Forecast": {"tr": "Saatlik Tahmin", "de": "Stündliche Vorhersage", "fr": "Prévisions horaires", "es": "Pronóstico по часам", "ru": "Почасовой прогноз"},
    "Loading weather data...": {"tr": "Hava durumu verileri yükleniyor...", "de": "Wetterdaten werden geladen...", "fr": "Chargement...", "es": "Cargando...", "ru": "Загрузка данных..."},
    "Refresh": {"tr": "Yenile", "de": "Aktualisieren", "fr": "Actualiser", "es": "Actualizar", "ru": "Обновить"},
    "Tap to close": {"tr": "Kapatmak için dokunun", "de": "Zum Schließen tippen", "fr": "Appuyez pour fermer", "es": "Toque para cerrar", "ru": "Нажмите, чтобы закрыть"},
    "Click to close": {"tr": "Kapatmak için tıklayın", "de": "Zum Schließen klicken", "fr": "Cliquez pour fermer", "es": "Haga clic para cerrar", "ru": "Нажмите, чтобы закрыть"},
    "Next week %1": {"tr": "Gelecek hafta %1", "de": "Nächste Woche %1", "fr": "La semaine prochaine %1", "es": "La próxima semana %1"},
    "2 weeks later %1": {"tr": "2 hafta sonra %1", "de": "2 Wochen später %1", "fr": "Dans 2 semaines %1", "es": "2 semanas después %1"},

    # --- Directions ---
    "N": {"tr": "K", "de": "N", "fr": "N", "es": "N", "ru": "С"},
    "S": {"tr": "G", "de": "S", "fr": "S", "es": "S", "ru": "Ю"},
    "E": {"tr": "D", "de": "O", "fr": "E", "es": "E", "ru": "В"},
    "W": {"tr": "B", "de": "W", "fr": "O", "es": "O", "ru": "З"},
    "NE": {"tr": "KD", "de": "NO", "fr": "NE", "es": "NE", "ru": "СВ"},
    "NW": {"tr": "KB", "de": "NW", "fr": "NO", "es": "NO", "ru": "СЗ"},
    "SE": {"tr": "GD", "de": "SO", "fr": "SE", "es": "SE", "ru": "ЮВ"},
    "SW": {"tr": "GB", "de": "SW", "fr": "SO", "es": "SO", "ru": "ЮЗ"},
    
    # --- Full Directions ---
    "North": {"tr": "Kuzey", "de": "Nord", "fr": "Nord", "es": "Norte", "ru": "Север"},
    "North East": {"tr": "Kuzeydoğu", "de": "Nordost", "fr": "Nord-Est", "es": "Noreste", "ru": "Северо-восток"},
    "East": {"tr": "Doğu", "de": "Ost", "fr": "Est", "es": "Este", "ru": "Восток"},
    "South East": {"tr": "Güneydoğu", "de": "Südost", "fr": "Sud-Est", "es": "Sureste", "ru": "Юго-восток"},
    "South": {"tr": "Güney", "de": "Süd", "fr": "Sud", "es": "Sur", "ru": "Юг"},
    "South West": {"tr": "Güneybatı", "de": "Südwest", "fr": "Sud-Ouest", "es": "Suroeste", "ru": "Юго-запад"},
    "West": {"tr": "Batı", "de": "West", "fr": "Ouest", "es": "Oeste", "ru": "Запад"},
    "North West": {"tr": "Kuzeybatı", "de": "Nordwest", "fr": "Nord-Ouest", "es": "Noroeste", "ru": "Северо-запад"},

    # --- Config Settings ---
    "Appearance": {"tr": "Görünüm", "de": "Erscheinungsbild", "fr": "Apparence", "es": "Apariencia"},
    "Weather Provider": {"tr": "Hava Durumu Sağlayıcısı", "de": "Wetterdienst", "fr": "Fournisseur météo", "es": "Proveedor"},
    "API Keys": {"tr": "API Anahtarları", "de": "API-Schlüssel", "fr": "Clés API", "es": "Claves API"},
    "Location": {"tr": "Konum", "de": "Standort", "fr": "Emplacement", "es": "Ubicación"},
    "Settings": {"tr": "Ayarlar", "de": "Einstellungen", "fr": "Paramètres", "es": "Configuración"},
    "Units:": {"tr": "Birimler:", "de": "Einheiten:", "es": "Unidades:"},
    "Refresh Interval:": {"tr": "Yenileme Aralığı:", "de": "Intervall:", "es": "Intervalo:"},
    "Layout Mode:": {"tr": "Düzen Modu:", "de": "Layout-Modus:", "es": "Modo de diseño:"},
    "Select the visual style for weather icons.": {"tr": "Hava durumu ikonları için görsel stili seçin.", "de": "Wählen Sie den visuellen Stil.", "fr": "Sélectionnez le style visuel.", "es": "Selecciona el estilo visual."},
    "Select the visual style for weather icons. (Note: older packs like v1/v2 may have missing icons for some conditions)": {"tr": "Hava durumu ikonları için görsel stili seçin. (Not: v1/v2 gibi eski paketlerde bazı durumlar için eksik ikonlar olabilir)", "de": "Wählen Sie den visuellen Stil. (Hinweis: ältere Pakete können unvollständig sein)", "es": "Selecciona el estilo visual. (Nota: los paquetes antiguos pueden tener iconos faltantes)"},
    "You can use City name, 'City,Country Code' or Zip Code.": {"tr": "Şehir adı, 'Şehir,Ülke Kodu' veya Posta Kodu kullanabilirsiniz.", "de": "Sie können Stadtname, 'Stadt,Länderkürzel' oder Postleitzahl verwenden.", "es": "Puedes usar el nombre de la ciudad, 'Ciudad,Código de país' o código postal."},
    "Location will be auto-detected based on your IP address.": {"tr": "Konum, IP adresinize göre otomatik olarak tespit edilecektir.", "de": "Der Standort wird automatisch anhand Ihrer IP-Adresse erkannt.", "es": "La ubicación se detectará automáticamente según su dirección IP."},
    "Icon Pack:": {"tr": "İkon Paketi:", "de": "Symbolpaket:", "es": "Iconos:"},
    "Widget Margin:": {"tr": "Kenar Boşluğu:", "de": "Widget-Rand:", "es": "Margen:"},
    "Corner Radius:": {"tr": "Köşe Yuvarlama:", "de": "Eckenradius:", "es": "Radio de esquina:"},
    "Normal": {"tr": "Normal", "de": "Normal", "es": "Normal"},
    "Small": {"tr": "Küçük", "de": "Klein", "es": "Pequeño"},
    "Large": {"tr": "Büyük", "de": "Groß", "es": "Grande"},
    "Wide": {"tr": "Geniş", "de": "Breit", "es": "Ancho"},
    "Automatic": {"tr": "Otomatik", "de": "Automatisch", "es": "Automático"},
    "Square": {"tr": "Kare", "de": "Quadratisch", "es": "Cuadrado"},
    "Simple Panel": {"tr": "Sade Panel", "de": "Einfach", "es": "Simple"},
    "Detailed Panel": {"tr": "Detaylı Panel", "de": "Detailliert", "es": "Detallado"},
    "Background Opacity:": {"tr": "Arkaplan Opaklığı:", "de": "Deckkraft:", "es": "Opacidad:"},
    "0% (No Backgrounds)": {"tr": "0% (Arkaplan Yok)", "de": "0% (Kein Hintergrund)", "es": "0% (Sin fondo)"},
    "Use Default System Font": {"tr": "Sistem Yazı Tipini Kullan", "de": "Systemschrift verwenden", "es": "Usar fuente del sistema"},
    "Show Units in Forecast": {"tr": "Tahminde Birimleri Göster", "de": "Einheiten anzeigen", "es": "Mostrar unidades"},
}

base_dir = "/home/mcc45tr/Gitler/Projelerim/Plasma6Widgets/weather/contents/translations"

def update_po_files():
    for root, dirs, files in os.walk(base_dir):
        for file in files:
            if file.endswith(".po"):
                po_path = os.path.join(root, file)
                lang_code = os.path.splitext(file)[0] # e.g. az.po -> az
                
                if lang_code == "template":
                    continue
                    
                simple_lang = lang_code.split('_')[0]
                
                with open(po_path, "r", encoding="utf-8") as f:
                    content = f.read()
                
                new_content = content
                updates_made = False
                
                for msgid, trans_dict in translations.items():
                    target_trans = trans_dict.get(lang_code) or trans_dict.get(simple_lang)
                    
                    # Pattern for msgid followed by empty msgstr
                    pattern_empty = re.compile(rf'msgid "{re.escape(msgid)}"\s+msgstr ""')
                    
                    if pattern_empty.search(new_content):
                        if target_trans:
                            new_content = pattern_empty.sub(f'msgid "{msgid}"\nmsgstr "{target_trans}"', new_content)
                            updates_made = True
                    elif f'msgid "{msgid}"' not in new_content:
                        trans_str = target_trans if target_trans else ""
                        new_content += f'\n\nmsgid "{msgid}"\nmsgstr "{trans_str}"\n'
                        updates_made = True

                if updates_made:
                    with open(po_path, "w", encoding="utf-8") as f:
                        f.write(new_content)
                    print(f"Updated {po_path}")

if __name__ == "__main__":
    print("Starting master translation update in translations/ folder...")
    update_po_files()
    print("Finished.")
