// utils.js - Utility functions for File Search Widget

// UUID Generator - creates unique identifiers for history entries
function generateUUID() {
    return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
        var r = Math.random() * 16 | 0, v = c == 'x' ? r : (r & 0x3 | 0x8);
        return v.toString(16);
    });
}

// Format history timestamp for display
function formatHistoryTime(timestamp, trFunc) {
    if (!timestamp) return ""
    
    var now = new Date()
    var then = new Date(timestamp)
    var diffMs = now.getTime() - then.getTime()
    var diffDays = Math.floor(diffMs / (1000 * 60 * 60 * 24))
    
    var hours = then.getHours().toString().padStart(2, '0')
    var minutes = then.getMinutes().toString().padStart(2, '0')
    var timeStr = hours + ":" + minutes
    
    // Today
    if (now.toDateString() === then.toDateString()) {
        return (trFunc ? trFunc("Today") : "Today") + " " + timeStr
    }
    
    // Within last 6 days
    if (diffDays < 6) {
        return Qt.locale().dayName(then.getDay(), Locale.LongFormat) + " " + timeStr
    }
    
    // Older than 6 days
    return then.toLocaleDateString(Qt.locale(), Locale.ShortFormat) + " " + timeStr
}

// Detect source type from category
function detectSourceType(category, isApp, filePath) {
    if (isApp) {
        return "app"
    } else if (isPrimaryCategory(category)) {
        return "calculator"
    } else if (filePath && filePath.length > 0) {
        return "file"
    } else {
        return "krunner"
    }
}

// Check if category is a primary result (calculator, unit, currency)
function normalized(value) {
    return String(value || "").toLocaleLowerCase().replace(/\u0307/g, "")
}

function containsAny(value, terms) {
    var text = normalized(value)
    for (var i = 0; i < terms.length; i++) {
        if (text.indexOf(terms[i]) !== -1)
            return true
    }
    return false
}

function isDesktopEntry(value) {
    return normalized(value).endsWith(".desktop")
}

function getPathExtension(value) {
    var path = normalized(value).split(/[?#]/)[0]
    var slash = path.lastIndexOf("/")
    var dot = path.lastIndexOf(".")
    return dot > slash + 1 ? path.substring(dot + 1) : ""
}

// Milou category labels are localized by the desktop. Keep the unavoidable
// label fallback centralized, while preferring stable URL, match-id and icon
// signals everywhere a result object is available.
var APP_TERMS = [
    "application", "aplicación", "aplicacion", "aplicação", "aplicacao", "applicazione", "aplicație", "aplicatie",
    "anwendung", "toepassing", "aplikac", "sovellus", "sovelluk", "program", "uygulama", "tətbiq",
    "прилож", "програм", "εφαρμογ", "հավելված", "تطبيق", "برنامه", "ایپ", "অ্যাপ", "अनुप्रयोग", "앱", "애플리케이션", "アプリ", "应用"
]
var PRIMARY_TERMS = [
    "calcul", "calculator", "hesap", "unit", "birim", "currency", "döviz", "währung", "einheit", "rechner",
    "calculatrice", "unité", "devise", "calcol", "unità", "valuta", "calculadora", "unidad", "moneda",
    "kalkulator", "jednost", "walut", "калькуля", "единиц", "валют", "обчисл", "валют", "υπολογ", "μονάδ",
    "hesabl", "vahid", "валют", "حساب", "آلة حاسبة", "واحد", "ارز", "ماشین حساب", "واحد", "মুদ্রা", "गणना", "इकाई", "मुद्रा",
    "계산", "단위", "통화", "計算", "単位", "通貨", "计算", "单位", "货币"
]
var FILE_TERMS = [
    "file", "dosya", "datei", "fichier", "archivo", "ficheiro", "file", "bestand", "plik", "soubor", "tiedosto",
    "fil", "fișier", "fisier", "файл", "αρχείο", "fayl", "ملف", "فایل", "ফাইল", "फ़ाइल", "파일", "ファイル", "文件"
]
var DOCUMENT_TERMS = [
    "document", "belge", "dokument", "documento", "documente", "dokumen", "документ", "έγγραφο", "sənəd", "مستند", "سند", "নথি", "दस्तावेज", "문서", "ドキュメント", "文档"
]
var FOLDER_TERMS = [
    "folder", "place", "klasör", "yerler", "ordner", "orte", "dossier", "emplacement", "carpeta", "lugares", "pasta",
    "cartella", "map", "katalog", "složk", "kansio", "plats", "dosar", "locuri", "папк", "мест", "тека", "місц",
    "φάκελ", "yer", "qovluq", "مجلد", "پوشه", "ফোল্ডার", "फ़ोल्डर", "폴더", "フォルダー", "文件夹"
]
var IMAGE_TERMS = [
    "image", "picture", "photo", "resim", "görsel", "görüntü", "bild", "foto", "imagem", "immagine", "afbeeld", "obraz",
    "kuva", "imagine", "изображ", "зображ", "εικόν", "şəkil", "صورة", "تصویر", "ছবি", "चित्र", "이미지", "画像", "图像", "图片"
]
var WEB_TERMS = [
    "web", "browser", "bookmark", "internet", "yer imi", "lesezeichen", "navigateur", "signet", "marcador", "segnalibro",
    "bladwijzer", "zakład", "prohlížeč", "kirjanmerk", "bokmärke", "брауз", "заклад", "σελιδοδείκ", "əlfəcin", "متصفح", "نشانک", "বুকমার্ক", "ब्राउज़र", "북마크", "ブックマーク", "书签"
]
var RSS_TERMS = ["rss", "news", "haber", "nachricht", "actualit", "noticia", "notícia", "notizia", "nieuws", "wiadomo", "zpráv", "uutis", "nyheter", "știri", "новост", "новин", "ειδήσ", "xəbər", "أخبار", "خبر", "সংবাদ", "समाचार", "뉴스", "ニュース", "新闻"]

function isPrimaryCategory(category, decoration, matchId) {
    return containsAny(category, PRIMARY_TERMS)
        || containsAny(decoration, ["calculator", "accessories-calculator", "currency"])
        || containsAny(matchId, ["calculator", "unitconverter", "converter"])
}

// Check if category is file-related
function isFileCategory(category) {
    return containsAny(category, FILE_TERMS)
        || containsAny(category, DOCUMENT_TERMS)
        || containsAny(category, FOLDER_TERMS)
}

// Extract parent folder from file path
function getParentFolder(filePath) {
    if (!filePath) return ""
    var path = filePath.toString()
    if (path.startsWith("file://")) path = path.substring(7)
    var lastSlash = path.lastIndexOf("/")
    if (lastSlash > 0) {
        return path.substring(0, lastSlash)
    }
    return ""
}

// Get short parent name (just folder name, not full path)
function getShortParentName(filePath) {
    if (!filePath) return ""
    var path = filePath.toString()
    if (path.startsWith("file://")) path = path.substring(7)
    var lastSlash = path.lastIndexOf("/")
    if (lastSlash > 0) {
        var parentPath = path.substring(0, lastSlash)
        var parentSlash = parentPath.lastIndexOf("/")
        if (parentSlash >= 0) {
            return parentPath.substring(parentSlash + 1)
        }
        return parentPath
    }
    return ""
}

// Shell escape - wraps a string in single quotes with proper escaping.
// Prevents command injection when passing user-controlled values to shell commands.
// Single quotes prevent all interpretation except for embedded single quotes,
// which are handled by ending the quote, adding an escaped quote, and reopening.
function shellEscape(str) {
    if (str === undefined || str === null) return "''"
    return "'" + str.toString().replace(/'/g, "'\\''") + "'"
}

function isHttpUrl(value) {
    return /^https?:\/\//i.test(String(value || ""))
}

function isSafeExternalUrl(value) {
    var url = String(value || "").trim()
    return url.indexOf("/") === 0
        || /^file:\/\//i.test(url)
        || /^https?:\/\//i.test(url)
}

function decodeLocalPath(value) {
    var path = String(value || "")
    if (path.indexOf("file://") === 0) path = path.substring(7)
    try {
        path = decodeURIComponent(path)
    } catch (e) {
        // Keep the original path when it contains a malformed percent escape.
    }
    return path
}

// Centralized app category detection.
// Used by HistoryManager, TileDataManager, SearchPopup to avoid duplicated logic.
// Checks both English and Turkish category names and .desktop file indicators.
function isAppCategory(category, filePath, matchId, decoration) {
    if (isDesktopEntry(filePath) || isDesktopEntry(matchId))
        return true
    var icon = normalized(decoration)
    if (icon === "application-x-executable" || icon.indexOf("applications-") === 0 || icon.indexOf("system-settings") === 0 || icon.indexOf("preferences-") === 0)
        return true
    return containsAny(category, APP_TERMS)
}

function isFolderCategory(category, filePath, decoration) {
    var path = normalized(filePath)
    var icon = normalized(decoration)
    return path.endsWith("/") || icon.indexOf("folder") !== -1 || containsAny(category, FOLDER_TERMS)
}

function isFileLikeResult(category, filePath, matchId, decoration, extension) {
    var path = normalized(filePath)
    return path.indexOf("file://") === 0 || path.indexOf("/") === 0 || !!extension
        || isFileCategory(category) || isFolderCategory(category, filePath, decoration)
}

function matchesResultFilter(filter, category, filePath, matchId, decoration, extension) {
    var f = normalized(filter)
    var path = normalized(filePath)
    var icon = normalized(decoration)
    if (f === "docs")
        return containsAny(category, DOCUMENT_TERMS) || icon.indexOf("document") !== -1 || icon.indexOf("text") !== -1
            || ["txt", "md", "pdf", "odt", "doc", "docx", "rtf", "epub", "xls", "xlsx", "ods", "ppt", "pptx", "odp"].indexOf(normalized(extension)) !== -1
    if (f === "images")
        return containsAny(category, IMAGE_TERMS) || icon.indexOf("image") !== -1 || icon.indexOf("photo") !== -1
            || ["png", "jpg", "jpeg", "gif", "webp", "svg", "bmp", "tif", "tiff", "avif", "heic"].indexOf(normalized(extension)) !== -1
    if (f === "folders")
        return isFolderCategory(category, filePath, decoration)
    if (f === "apps")
        return isAppCategory(category, filePath, matchId, decoration)
    if (f === "files")
        return isFileLikeResult(category, filePath, matchId, decoration, extension)
            && !isAppCategory(category, filePath, matchId, decoration)
    if (f === "calculator")
        return isPrimaryCategory(category, decoration, matchId)
    if (f === "web")
        return path.indexOf("http://") === 0 || path.indexOf("https://") === 0 || path.indexOf("www") === 0
            || icon.indexOf("web") !== -1 || icon.indexOf("globe") !== -1 || containsAny(category, WEB_TERMS)
    if (f === "rss")
        return containsAny(category, RSS_TERMS) || icon.indexOf("news") !== -1 || normalized(matchId).indexOf("rss:") === 0
    return true
}

function getCategoryKind(category) {
    if (isPrimaryCategory(category)) return "primary"
    if (containsAny(category, APP_TERMS)) return "app"
    if (containsAny(category, DOCUMENT_TERMS)) return "document"
    if (containsAny(category, FOLDER_TERMS)) return "folder"
    if (containsAny(category, FILE_TERMS)) return "file"
    if (containsAny(category, WEB_TERMS)) return "web"
    if (containsAny(category, RSS_TERMS)) return "rss"
    if (containsAny(category, ["other", "diğer", "andere", "autre", "otro", "outro", "altro", "overig", "inne", "ostatní", "друг", "інш", "άλλ", "digər", "أخرى", "دیگر", "অন্যান্য", "अन्य", "기타", "その他", "其他"])) return "other"
    return "unknown"
}

function isWideCategory(category) {
    return isPrimaryCategory(category)
        || containsAny(category, ["date", "tarih", "datum", "fecha", "data", "дата", "ημερομην", "tarix", "تاريخ", "تاریخ", "তারিখ", "दिनांक", "날짜", "日付", "日期",
            "dictionary", "sözlük", "wörterbuch", "dictionnaire", "diccionario", "dicionário", "dizionario", "woordenboek", "słownik", "slovník", "словар", "словник", "قاموس", "فرهنگ", "শব্দকোষ", "शब्दकोश", "사전", "辞書", "词典",
            "shell", "command", "komut", "befehl", "commande", "comando", "polecen", "příkaz", "команд", "εντολ", "əmr", "أمر", "دستور", "কমান্ড", "कमांड", "명령", "コマンド", "命令",
            "man page", "kılavuz", "manual", "handbuch", "manuel", "manuale", "podręcznik", "справк", "довідк",
            "power", "güç", "energie", "energía", "energia", "alimentazione", "zasilanie", "napájení", "питан", "ισχύ", "güc", "طاقة", "توان", "বিদ্যুৎ", "पावर", "전원", "電源", "电源"])
}
