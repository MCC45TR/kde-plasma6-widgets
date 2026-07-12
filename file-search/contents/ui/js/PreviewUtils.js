.import "utils.js" as Utils

var IMAGE_EXTENSIONS = ["png", "jpg", "jpeg", "gif", "bmp", "webp", "svg", "ico", "tif", "tiff", "avif", "heic", "jxl", "exr"];
var VIDEO_EXTENSIONS = ["mp4", "mkv", "avi", "webm", "mov", "flv", "wmv", "mpg", "mpeg", "m4v", "3gp", "ogv"];
var AUDIO_EXTENSIONS = ["mp3", "flac", "ogg", "opus", "wav", "m4a", "aac", "wma", "aiff", "ape"];
var TEXT_EXTENSIONS = ["txt", "md", "log", "ini", "cfg", "conf", "json", "xml", "yml", "yaml", "qml", "js", "ts", "py", "cpp", "c", "cc", "h", "hpp", "sh"];
var DOCUMENT_EXTENSIONS = ["pdf", "ps", "eps", "dvi", "odt", "doc", "docx", "ppt", "pptx", "xls", "xlsx", "ods", "odp", "csv"];
var EBOOK_EXTENSIONS = ["epub", "mobi", "azw", "azw3", "fb2", "cbz", "cbr", "djvu", "djv"];
var CREATIVE_EXTENSIONS = ["kra", "ora", "xcf", "blend"];
var FONT_EXTENSIONS = ["ttf", "otf", "woff", "woff2", "pfb"];
var EXECUTABLE_EXTENSIONS = ["exe", "msi", "dll", "appimage"];
var APPLICATION_EXTENSIONS = ["desktop"];

function normalizeSettings(settings) {
    return {
        images: !!(settings && settings.images),
        videos: !!(settings && settings.videos),
        audio: !!(settings && settings.audio),
        text: !!(settings && settings.text),
        documents: !!(settings && settings.documents),
        ebooks: !!(settings && settings.ebooks),
        creative: !!(settings && settings.creative),
        folders: !!(settings && settings.folders),
        fonts: !!(settings && settings.fonts),
        executables: !!(settings && settings.executables),
        applications: !!(settings && settings.applications)
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

    try {
        value = decodeURIComponent(value);
    } catch (e) {
    }

    return value;
}

function toLocalFileUrl(urlOrPath) {
    var path = getLocalPreviewPath(urlOrPath);
    if (!path)
        return "";
    return "file://" + encodeURI(path).replace(/#/g, "%23").replace(/\?/g, "%3F");
}

function getExtension(pathOrUrl) {
    var path = getLocalPreviewPath(pathOrUrl);
    if (!path)
        return "";

    var lastSlash = path.lastIndexOf("/");
    var lastDot = path.lastIndexOf(".");
    if (lastDot <= lastSlash + 1)
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

function isAudioExtension(ext) {
    return containsExt(AUDIO_EXTENSIONS, ext);
}

function isTextExtension(ext) {
    return containsExt(TEXT_EXTENSIONS, ext);
}

function isDocumentExtension(ext) {
    return containsExt(DOCUMENT_EXTENSIONS, ext);
}

function isDocumentLikeExtension(ext) {
    return isDocumentExtension(ext) || isTextExtension(ext) || containsExt(EBOOK_EXTENSIONS, ext);
}

function previewKind(urlOrPath, category) {
    var ext = getExtension(urlOrPath);
    if (Utils.isFolderCategory(category, urlOrPath, ""))
        return "folders";
    if (isImageExtension(ext))
        return "images";
    if (isVideoExtension(ext))
        return "videos";
    if (isAudioExtension(ext))
        return "audio";
    if (isTextExtension(ext))
        return "text";
    if (isDocumentExtension(ext))
        return "documents";
    if (containsExt(EBOOK_EXTENSIONS, ext))
        return "ebooks";
    if (containsExt(CREATIVE_EXTENSIONS, ext))
        return "creative";
    if (containsExt(FONT_EXTENSIONS, ext))
        return "fonts";
    if (containsExt(EXECUTABLE_EXTENSIONS, ext))
        return "executables";
    if (containsExt(APPLICATION_EXTENSIONS, ext) || Utils.isAppCategory(category, urlOrPath, "", ""))
        return "applications";
    return "";
}

function isPreviewTypeEnabled(ext, settings, category, urlOrPath) {
    var normalized = normalizeSettings(settings);
    var kind = previewKind(urlOrPath || (ext ? "file." + ext : ""), category || "");
    return kind ? normalized[kind] === true : false;
}

function isPreviewAvailable(urlOrPath, category, settings) {
    var path = getLocalPreviewPath(urlOrPath);
    var isApplication = Utils.isAppCategory(category, urlOrPath, "", "");
    if (!path && !isApplication)
        return false;

    var kind = previewKind(path || urlOrPath, category);
    if (isApplication && !kind)
        kind = "applications";
    var normalized = normalizeSettings(settings);
    return !!kind && normalized[kind] === true;
}

function getThumbnailCacheSource(urlOrPath, thumbnailCacheBase) {
    var uri = toLocalFileUrl(urlOrPath);
    var base = toStringValue(thumbnailCacheBase);
    if (!uri || !base)
        return "";
    if (base.indexOf("file://") === 0)
        base = getLocalPreviewPath(base);
    if (base.charAt(base.length - 1) === "/")
        base = base.substring(0, base.length - 1);
    return "file://" + encodeURI(base + "/normal/" + Qt.md5(uri) + ".png").replace(/#/g, "%23").replace(/\?/g, "%3F");
}

function getPreviewSource(urlOrPath, previewEnabled, settings, thumbnailCacheBase, category) {
    if (!previewEnabled)
        return "";

    var path = getLocalPreviewPath(urlOrPath);
    if (!path)
        return "";

    var ext = getExtension(path);
    if (!isPreviewTypeEnabled(ext, settings, category, path))
        return "";

    if (isImageExtension(ext))
        return toLocalFileUrl(path);

    // Reuse a freedesktop cache entry immediately when Dolphin has already
    // generated one. FilePreviewSource requests a fresh KIO thumbnail in
    // parallel for every other enabled type.
    if (thumbnailCacheBase)
        return getThumbnailCacheSource(path, thumbnailCacheBase);

    return "";
}

function getFileTypeLabel(urlOrPath) {
    var ext = getExtension(urlOrPath);
    return ext ? ext.toUpperCase() : "";
}
