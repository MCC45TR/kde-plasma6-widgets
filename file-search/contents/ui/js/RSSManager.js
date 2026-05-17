/**
 * Shared RSS parsing and utility functions
 */

// Manual base64 implementation to avoid deprecated Qt.atob/Qt.btoa
var _b64chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=";

function _manualBtoa(input) {
    var output = "";
    for (var i = 0; i < input.length; i += 3) {
        var a = input.charCodeAt(i);
        var b = i + 1 < input.length ? input.charCodeAt(i + 1) : 0;
        var c = i + 2 < input.length ? input.charCodeAt(i + 2) : 0;

        output += _b64chars.charAt(a >> 2);
        output += _b64chars.charAt(((a & 3) << 4) | (b >> 4));
        output += (i + 1 < input.length) ? _b64chars.charAt(((b & 15) << 2) | (c >> 6)) : "=";
        output += (i + 2 < input.length) ? _b64chars.charAt(c & 63) : "=";
    }
    return output;
}

function _manualAtob(input) {
    input = input.replace(/\s/g, "").replace(/=+$/, "");
    var output = "";
    var bits = 0;
    var value = 0;
    for (var i = 0; i < input.length; i++) {
        var c = _b64chars.indexOf(input.charAt(i));
        if (c === -1 || c === 64) continue;
        value = (value << 6) | c;
        bits += 6;
        if (bits >= 8) {
            bits -= 8;
            output += String.fromCharCode((value >> bits) & 0xFF);
            value &= (1 << bits) - 1;
        }
    }
    return output;
}

function decodeBase64(str) {
    if (!str) return "";
    try {
        var decoded = _manualAtob(str);
        try {
            return decodeURIComponent(escape(decoded));
        } catch (e) {
            return decoded;
        }
    } catch (e) {
        console.warn("RSSManager: Failed to decode base64:", e);
        return "";
    }
}

function encodeBase64(str) {
    if (!str) return "";
    try {
        var encoded = unescape(encodeURIComponent(str));
        return _manualBtoa(encoded);
    } catch (e) {
        console.warn("RSSManager: Failed to encode base64:", e);
        return "";
    }
}

function unescapeHtml(text) {
    if (!text) return ""
    return text.replace(/&amp;/g, "&")
               .replace(/&lt;/g, "<")
               .replace(/&gt;/g, ">")
               .replace(/&quot;/g, '"')
               .replace(/&#039;/g, "'")
               .replace(/&apos;/g, "'")
               .replace(/&#x27;/g, "'")
               .replace(/&#x2F;/g, "/")
               .replace(/&nbsp;/g, " ")
               .replace(/&[#a-zA-Z0-9]+;/g, function(match) {
                   if (match.charAt(1) === '#') {
                       var code = match.charAt(2) === 'x' 
                           ? parseInt(match.substring(3), 16) 
                           : parseInt(match.substring(2))
                       return String.fromCharCode(code)
                   }
                   return match
               })
}

function parseRSS(xml, sourceName) {
    var entries = []
    var itemRegex = /<(item|entry)>([\s\S]*?)<\/(item|entry)>/gi
    var titleRegex = /<title>(?:<!\[CDATA\[)?([\s\S]*?)(?:\]\]>)?<\/title>/i
    var linkRegex = /<(link|guid|id)(?:[^>]*href=\"([^\"]+)\")?>(?:<!\[CDATA\[)?([\s\S]*?)(?:\]\]>)?<\/(?:link|guid|id)>/i
    var dateRegex = /<(pubDate|dc:date|updated|published)>(?:<!\[CDATA\[)?([\s\S]*?)(?:\]\]>)?<\/(pubDate|dc:date|updated|published)>/i
    var descRegex = /<(description|summary)>(?:<!\[CDATA\[)?([\s\S]*?)(?:\]\]>)?<\/(description|summary)>/i
    var contentRegex = /<(content:encoded|content)>(?:<!\[CDATA\[)?([\s\S]*?)(?:\]\]>)?<\/(content:encoded|content)>/i
    
    var imageRegex = /<(media:content|enclosure|img)[^>]*url=\"([^\"]+)\"[^>]*>/i
    var imageSrcRegex = /<img[^>]*src=\"([^\"]+)\"[^>]*>/i
    
    var match
    while ((match = itemRegex.exec(xml)) !== null) {
        var itemContent = match[2]
        var titleMatch = itemContent.match(titleRegex)
        var linkMatch = itemContent.match(linkRegex)
        var dateMatch = itemContent.match(dateRegex)
        var descMatch = itemContent.match(descRegex)
        var fullMatch = itemContent.match(contentRegex)
        
        var imageUrl = ""
        var imgMatch = itemContent.match(imageRegex)
        if (imgMatch) {
            imageUrl = imgMatch[2]
        } else {
            var imgSrMatch = itemContent.match(imageSrcRegex)
            if (imgSrMatch) imageUrl = imgSrMatch[1]
        }
        
        if (titleMatch) {
            var title = unescapeHtml(titleMatch[1].trim().replace(/<[^>]*>?/gm, ''))
            var link = ""
            if (linkMatch) {
                link = linkMatch[2] || linkMatch[3] || ""
                link = link.trim()
            }
            var dateStr = dateMatch ? dateMatch[2].trim() : ""
            var desc = descMatch ? unescapeHtml(descMatch[2].trim().replace(/<[^>]*>?/gm, '')) : ""
            var full = fullMatch ? unescapeHtml(fullMatch[2].trim().replace(/<[^>]*>?/gm, '')) : ""
            
            var indexedContent = (title + " " + desc + " " + full)
            
            // Fallback for image in description
            if (!imageUrl && descMatch) {
                var imgDescMatch = descMatch[2].match(imageSrcRegex)
                if (imgDescMatch) imageUrl = imgDescMatch[1]
            }

            entries.push({
                display: title,
                decoration: "news-subscribe",
                category: "RSS",
                url: link,
                subtext: sourceName + " | " + dateStr.replace(" +0000", "").replace("T", " ").split(".")[0],
                description: desc.length > 300 ? desc.substring(0, 300) + "..." : desc,
                fullContent: full || desc,
                imageUrl: imageUrl,
                indexedContent: indexedContent,
                duplicateId: "rss:" + link,
                rawDate: dateStr,
                index: -1
            })
        }
    }
    return entries
}

function getSourceFilePath(url, baseCachePath) {
    if (!url) return ""
    var hash = 0
    for (var i = 0; i < url.length; i++) {
        hash = ((hash << 5) - hash) + url.charCodeAt(i)
        hash |= 0
    }
    return baseCachePath + "/source_" + Math.abs(hash) + ".json"
}
