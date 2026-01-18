// IconMapper.js - Web URL'leri için sistem ikon eşleştirmesi
/**
 * IconMapper.js
 * Bilinen web siteleri ve servisler için yüksek kaliteli sistem ikonları sağlar.
 * Düşük çözünürlüklü favicon yerine ikon paketinden uygun simgeleri kullanır.
 */

// Domain -> Sistem ikon adı eşleştirmesi
// Freedesktop/Papirus/Tela gibi ikon paketlerinde bulunan ikonlar
var knownSites = {
    // Arama Motorları
    "google.com": "google",
    "www.google.com": "google",
    "duckduckgo.com": "duckduckgo",
    "www.duckduckgo.com": "duckduckgo",
    "bing.com": "web-browser",
    "www.bing.com": "web-browser",
    "yahoo.com": "web-browser",
    "www.yahoo.com": "web-browser",

    // Sosyal Medya
    "facebook.com": "facebook",
    "www.facebook.com": "facebook",
    "twitter.com": "twitter",
    "www.twitter.com": "twitter",
    "x.com": "twitter",
    "instagram.com": "instagram",
    "www.instagram.com": "instagram",
    "linkedin.com": "linkedin",
    "www.linkedin.com": "linkedin",
    "reddit.com": "reddit",
    "www.reddit.com": "reddit",
    "discord.com": "discord",
    "www.discord.com": "discord",
    "telegram.org": "telegram",
    "web.telegram.org": "telegram",
    "whatsapp.com": "whatsapp",
    "web.whatsapp.com": "whatsapp",

    // Video / Medya
    "youtube.com": "youtube",
    "www.youtube.com": "youtube",
    "youtu.be": "youtube",
    "netflix.com": "netflix",
    "www.netflix.com": "netflix",
    "twitch.tv": "twitch",
    "www.twitch.tv": "twitch",
    "spotify.com": "spotify",
    "open.spotify.com": "spotify",
    "soundcloud.com": "soundcloud",
    "www.soundcloud.com": "soundcloud",

    // Geliştirici / Teknik
    "github.com": "github",
    "www.github.com": "github",
    "gitlab.com": "gitlab",
    "www.gitlab.com": "gitlab",
    "stackoverflow.com": "stackoverflow",
    "www.stackoverflow.com": "stackoverflow",
    "bitbucket.org": "bitbucket",
    "www.bitbucket.org": "bitbucket",
    "npmjs.com": "npm",
    "www.npmjs.com": "npm",

    // Bilgi / Referans
    "wikipedia.org": "wikipedia",
    "en.wikipedia.org": "wikipedia",
    "tr.wikipedia.org": "wikipedia",
    "de.wikipedia.org": "wikipedia",

    // E-posta
    "gmail.com": "gmail",
    "mail.google.com": "gmail",
    "outlook.com": "ms-outlook",
    "outlook.live.com": "ms-outlook",

    // Bulut / Depolama
    "drive.google.com": "google-drive",
    "dropbox.com": "dropbox",
    "www.dropbox.com": "dropbox",
    "onedrive.com": "onedrive",
    "onedrive.live.com": "onedrive",

    // Alışveriş
    "amazon.com": "amazon",
    "www.amazon.com": "amazon",
    "amazon.de": "amazon",
    "amazon.co.uk": "amazon",
    "ebay.com": "web-browser",
    "www.ebay.com": "web-browser",

    // KDE / Linux
    "kde.org": "kde",
    "www.kde.org": "kde",
    "store.kde.org": "kde",
    "archlinux.org": "archlinux",
    "www.archlinux.org": "archlinux",
    "aur.archlinux.org": "archlinux",
    "ubuntu.com": "ubuntu",
    "www.ubuntu.com": "ubuntu",
    "fedoraproject.org": "fedora",
    "www.fedoraproject.org": "fedora",

    // Haber
    "bbc.com": "internet-web-browser",
    "www.bbc.com": "internet-web-browser",
    "cnn.com": "internet-web-browser",
    "www.cnn.com": "internet-web-browser"
};

// Fallback ikon (hiçbir eşleşme yoksa)
var fallbackIcon = "internet-web-browser";

/**
 * URL'den domain çıkarır
 * @param {string} url - Tam URL
 * @returns {string} - Domain adı (örn: "www.google.com")
 */
function extractDomain(url) {
    if (!url || typeof url !== 'string') return "";

    try {
        // "http://", "https://" veya "//" ile başlıyorsa kaldır
        var domain = url.replace(/^(https?:)?\/\//, "");

        // İlk "/" öncesini al (path'i kaldır)
        domain = domain.split("/")[0];

        // Port numarasını kaldır (varsa)
        domain = domain.split(":")[0];

        return domain.toLowerCase();
    } catch (e) {
        return "";
    }
}

/**
 * URL için uygun sistem ikonunu döndürür
 * @param {string} url - Sonucun URL'si
 * @param {string} originalDecoration - Orijinal ikon (fallback için)
 * @param {string} category - Sonuç kategorisi (Web kategorisi kontrolü için)
 * @returns {string} - Sistem ikon adı
 */
function getIconForUrl(url, originalDecoration, category) {
    // Sadece "Web" veya benzeri kategoriler için uygula
    var webCategories = ["Web", "Web Search", "Bookmarks", "Browser", "Web Bookmarks", "Yer İmleri"];
    var isWebCategory = webCategories.indexOf(category) !== -1;

    // URL http/https ile başlıyorsa veya kategori web ise işle
    var isWebUrl = url && (url.toString().startsWith("http://") || url.toString().startsWith("https://"));

    if (!isWebUrl && !isWebCategory) {
        // Web sonucu değilse orijinal ikonu kullan
        return originalDecoration || "application-x-executable";
    }

    var domain = extractDomain(url);

    if (!domain) {
        return originalDecoration || fallbackIcon;
    }

    // Tam domain eşleşmesi
    if (knownSites[domain]) {
        return knownSites[domain];
    }

    // www olmadan dene
    if (domain.startsWith("www.")) {
        var withoutWww = domain.substring(4);
        if (knownSites[withoutWww]) {
            return knownSites[withoutWww];
        }
    }

    // Alt domain kontrolü (örn: en.wikipedia.org -> wikipedia.org)
    var parts = domain.split(".");
    if (parts.length > 2) {
        var baseDomain = parts.slice(-2).join(".");
        if (knownSites[baseDomain]) {
            return knownSites[baseDomain];
        }
    }

    // Eşleşme yoksa, orijinal decoration doluysa onu kullan
    // Eğer orijinal boş veya QIcon() ise fallback kullan
    if (originalDecoration && originalDecoration !== "" && originalDecoration !== "QIcon()") {
        return originalDecoration;
    }

    return fallbackIcon;
}

/**
 * Decoration değerinin geçerli olup olmadığını kontrol eder
 * @param {string} decoration - İkon değeri
 * @returns {boolean}
 */
function isValidDecoration(decoration) {
    if (!decoration) return false;
    if (decoration === "") return false;
    if (decoration === "QIcon()") return false;
    if (decoration.startsWith("image://")) return true; // QML image provider
    return true;
}
