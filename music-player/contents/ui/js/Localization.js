// Localization.js - Dil yönetimi için yardımcı fonksiyonlar

// Inline fallback for instant display (before JSON loads)
var defaultLocales = {
    "en": { "no_media_playing": "No Media Playing", "prev_track": "Previous", "next_track": "Next" },
    "tr": { "no_media_playing": "Çalan Medya Yok", "prev_track": "Önceki", "next_track": "Sonraki" }
}

function loadLocales(callback) {
    var xhr = new XMLHttpRequest()
    xhr.open("GET", "../localization.json")
    xhr.onreadystatechange = function() {
        if (xhr.readyState === XMLHttpRequest.DONE) {
            if (xhr.status === 200 || xhr.status === 0) {
                try {
                    var locales = JSON.parse(xhr.responseText)
                    callback(locales)
                } catch (e) {
                    console.log("Error parsing localization.json: " + e)
                    callback(defaultLocales)
                }
            } else {
                callback(defaultLocales)
            }
        }
    }
    xhr.send()
}

function translate(locales, currentLocale, key) {
    if (locales[currentLocale] && locales[currentLocale][key]) {
        return locales[currentLocale][key]
    }
    if (locales["en"] && locales["en"][key]) {
        return locales["en"][key]
    }
    return key
}
