import QtQuick
import "../js/PreviewUtils.js" as PreviewUtils

QtObject {
    id: resolver

    required property var logic
    property string fileUrl: ""
    property string category: ""
    property bool active: false
    property var settings: ({})
    property string freedesktopThumbnailBase: ""
    property string source: ""
    property int requestGeneration: 0

    function refresh() {
        var generation = ++requestGeneration;
        source = "";
        if (!active || !PreviewUtils.isPreviewAvailable(fileUrl, category, settings))
            return;

        var immediate = PreviewUtils.getPreviewSource(fileUrl, true, settings, freedesktopThumbnailBase, category);
        var ext = PreviewUtils.getExtension(fileUrl);
        if (PreviewUtils.isImageExtension(ext)) {
            source = immediate;
            return;
        }

        // An existing freedesktop thumbnail can be painted while KIO checks or
        // regenerates the widget-owned cache entry.
        source = immediate;
        if (!logic || !logic.requestFileThumbnail)
            return;
        logic.requestFileThumbnail(fileUrl, function(path) {
            if (generation !== requestGeneration || !active)
                return;
            source = path ? PreviewUtils.toLocalFileUrl(path) + "?v=" + generation : "";
        });
    }

    onFileUrlChanged: refresh()
    onCategoryChanged: refresh()
    onActiveChanged: refresh()
    onSettingsChanged: refresh()
    Component.onDestruction: requestGeneration++
}
