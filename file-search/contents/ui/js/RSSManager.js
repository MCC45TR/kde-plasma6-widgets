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

function getSourceFilePath(url, baseCachePath) {
    if (!url) return ""
    var hash = 0
    for (var i = 0; i < url.length; i++) {
        hash = ((hash << 5) - hash) + url.charCodeAt(i)
        hash |= 0
    }
    return baseCachePath + "/source_" + Math.abs(hash) + ".json"
}
