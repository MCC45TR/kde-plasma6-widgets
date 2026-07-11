var B64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/="

function encodeUtf8(value) {
    var input = unescape(encodeURIComponent(String(value || "")))
    var output = ""
    for (var i = 0; i < input.length; i += 3) {
        var a = input.charCodeAt(i)
        var hasB = i + 1 < input.length
        var hasC = i + 2 < input.length
        var b = hasB ? input.charCodeAt(i + 1) : 0
        var c = hasC ? input.charCodeAt(i + 2) : 0
        output += B64.charAt(a >> 2)
        output += B64.charAt(((a & 3) << 4) | (b >> 4))
        output += hasB ? B64.charAt(((b & 15) << 2) | (c >> 6)) : "="
        output += hasC ? B64.charAt(c & 63) : "="
    }
    return output
}
