var IMAGE_EXTENSIONS = ["png", "jpg", "jpeg", "gif", "bmp", "webp", "svg", "ico", "tiff"];
var VIDEO_EXTENSIONS = ["mp4", "mkv", "avi", "webm", "mov", "flv", "wmv", "mpg", "mpeg", "m4v"];
var TEXT_EXTENSIONS = ["txt", "md", "log", "ini", "cfg", "conf", "json", "xml", "yml", "yaml", "qml", "js", "ts", "py", "cpp", "c", "cc", "h", "hpp", "sh", "desktop"];
var DOCUMENT_EXTENSIONS = ["pdf", "odt", "doc", "docx", "ppt", "pptx", "xls", "xlsx", "ods", "odp", "csv", "cbz", "epub"];

function normalizeSettings(settings) {
    return {
        images: !!(settings && settings.images),
        videos: !!(settings && settings.videos),
        text: !!(settings && settings.text),
        documents: !!(settings && settings.documents)
    };
}

function toStringValue(value) {
    if (value === undefined || value === null)
        return "";
    return value.toString ? value.toString() : String(value);
}

function isLocalFileUrl(urlOrPath) {
    var value = toStringValue(urlOrPath);
    return value.indexOf("file://") === 0 || value.indexOf("/") === 0;
}

function getLocalPreviewPath(urlOrPath) {
    var value = toStringValue(urlOrPath);
    if (!isLocalFileUrl(value))
        return "";

    if (value.indexOf("file://") === 0)
        value = value.substring(7);

    var queryIndex = value.indexOf("?");
    if (queryIndex !== -1)
        value = value.substring(0, queryIndex);

    var fragmentIndex = value.indexOf("#");
    if (fragmentIndex !== -1)
        value = value.substring(0, fragmentIndex);

    try {
        value = decodeURIComponent(value);
    } catch (e) {
    }

    return value;
}

function getExtension(pathOrUrl) {
    var path = getLocalPreviewPath(pathOrUrl);
    if (!path)
        return "";

    var lastSlash = path.lastIndexOf("/");
    var lastDot = path.lastIndexOf(".");
    if (lastDot <= lastSlash)
        return "";

    return path.substring(lastDot + 1).toLowerCase();
}

function containsExt(list, ext) {
    return list.indexOf(ext) !== -1;
}

function isImageExtension(ext) {
    return containsExt(IMAGE_EXTENSIONS, ext);
}

function isVideoExtension(ext) {
    return containsExt(VIDEO_EXTENSIONS, ext);
}

function isTextExtension(ext) {
    return containsExt(TEXT_EXTENSIONS, ext);
}

function isDocumentExtension(ext) {
    return containsExt(DOCUMENT_EXTENSIONS, ext);
}

function isDocumentLikeExtension(ext) {
    return isDocumentExtension(ext) || isTextExtension(ext);
}

function isPreviewTypeEnabled(ext, settings) {
    var normalized = normalizeSettings(settings);
    if (!ext)
        return false;
    if (isImageExtension(ext))
        return normalized.images;
    if (isVideoExtension(ext))
        return normalized.videos;
    if (isTextExtension(ext))
        return normalized.text;
    if (isDocumentExtension(ext))
        return normalized.documents;
    return false;
}

function getPreviewSource(urlOrPath, previewEnabled, settings) {
    if (!previewEnabled)
        return "";

    var path = getLocalPreviewPath(urlOrPath);
    if (!path)
        return "";

    var ext = getExtension(path);
    if (!isPreviewTypeEnabled(ext, settings))
        return "";

    return "image://preview/" + path;
}

function getFileTypeLabel(urlOrPath) {
    var ext = getExtension(urlOrPath);
    return ext ? ext.toUpperCase() : "";
}
