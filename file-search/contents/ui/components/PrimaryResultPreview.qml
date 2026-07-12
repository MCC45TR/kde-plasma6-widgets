import QtQuick
import QtQuick.Layouts
import QtCore
import org.kde.kirigami as Kirigami
import "../js/PreviewUtils.js" as PreviewUtils
import "../js/utils.js" as Utils

// Primary Result Preview Component (Calculator, Unit Conversions, and files)
Rectangle {
    id: root

    // Required properties
    required property var resultsModel
    required property int resultCount
    required property string searchText
    required property color accentColor
    required property color textColor
    property var flatSortedData: []
    property bool previewEnabled: true
    property var previewSettings: ({})
    readonly property string thumbnailCacheBase: Utils.decodeLocalPath(StandardPaths.writableLocation(StandardPaths.HomeLocation)) + "/.cache/thumbnails"

    // Signals
    signal resultClicked(int idx, string display, string decoration, string category, string matchId, string filePath)

    height: visible ? (previewSource.length > 0 ? 92 : 64) : 0
    visible: searchText.length > 0 && (isPrimaryResult || previewSource.length > 0)
    color: Qt.rgba(accentColor.r, accentColor.g, accentColor.b, resultMouse.containsMouse ? 0.25 : 0.15)
    radius: 10
    border.width: 1
    border.color: Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.3)

    Behavior on height { NumberAnimation { duration: 150 } }

    readonly property var firstItem: flatSortedData && flatSortedData.length > 0 ? flatSortedData[0] : null
    readonly property string firstDisplay: firstItem ? (firstItem.display || "") : firstModelData(Qt.DisplayRole, "")
    readonly property string firstDecoration: firstItem ? (firstItem.decoration || "application-x-executable") : firstModelData(Qt.DecorationRole, "application-x-executable")
    readonly property string firstCategory: firstItem ? (firstItem.category || "Other") : firstModelData(resultsModel && resultsModel.CategoryRole !== undefined ? resultsModel.CategoryRole : Qt.UserRole, "Other")
    readonly property string firstMatchId: firstItem ? (firstItem.duplicateId || firstItem.display || "") : firstModelData(resultsModel && resultsModel.DuplicateRole !== undefined ? resultsModel.DuplicateRole : Qt.UserRole, firstDisplay)
    readonly property string firstFilePath: firstItem ? (firstItem.url || "") : ""
    readonly property int firstResultIndex: firstItem && firstItem.index !== undefined ? firstItem.index : 0
    readonly property string previewSource: PreviewUtils.getPreviewSource(firstFilePath, previewEnabled, previewSettings, thumbnailCacheBase)

    function firstModelData(role, fallback) {
        if (resultCount === 0 || !resultsModel || role === undefined)
            return fallback;
        var value = resultsModel.data(resultsModel.index(0, 0), role);
        return value === undefined || value === null ? fallback : value.toString();
    }

    property bool isPrimaryResult: {
        if (resultCount === 0 || !resultsModel) return false
        var firstIndex = resultsModel.index(0, 0)
        var firstCat = resultsModel.data(firstIndex, resultsModel.CategoryRole) || ""
        var decoration = resultsModel.data(firstIndex, Qt.DecorationRole) || ""
        var matchId = resultsModel.data(firstIndex, resultsModel.DuplicateRole) || ""
        return Utils.isPrimaryCategory(firstCat, decoration, matchId)
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        spacing: 14

        // Calculator Icon
        Rectangle {
            Layout.preferredWidth: previewSource.length > 0 ? 68 : 40
            Layout.preferredHeight: previewSource.length > 0 ? 68 : 40
            radius: 8
            color: root.accentColor
            clip: true

            Kirigami.Icon {
                anchors.centerIn: parent
                width: 24
                height: 24
                source: root.previewSource.length > 0 ? root.firstDecoration : "accessories-calculator"
                color: Kirigami.Theme.highlightedTextColor
                visible: previewImage.status !== Image.Ready
            }

            Image {
                id: previewImage
                anchors.fill: parent
                anchors.margins: 1
                source: root.previewSource
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: true
                sourceSize.width: Math.max(1, width)
                sourceSize.height: Math.max(1, height)
                visible: source.length > 0 && status === Image.Ready
            }
        }

        // Result Text
        Column {
            Layout.fillWidth: true
            spacing: 2

            Text {
                text: root.firstDisplay
                font.pixelSize: root.previewSource.length > 0
                    ? Math.round(Kirigami.Theme.defaultFont.pixelSize * 1.25)
                    : Math.round(Kirigami.Theme.defaultFont.pixelSize * 2)
                font.bold: true
                color: root.textColor
                elide: Text.ElideRight
                width: parent.width
            }

            Text {
                text: root.previewSource.length > 0
                    ? Utils.decodeLocalPath(root.firstFilePath).replace(/^\/home\/[^\/]+\//, "")
                    : root.searchText
                font.family: Kirigami.Theme.defaultFont.family
                font.pixelSize: Kirigami.Theme.defaultFont.pixelSize
                color: Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.6)
                elide: Text.ElideRight
                width: parent.width
            }
        }

        // Copy/Run indicator
        Kirigami.Icon {
            Layout.preferredWidth: 20
            Layout.preferredHeight: 20
            source: "edit-copy"
            color: Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.5)
        }
    }

    MouseArea {
        id: resultMouse
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true

        onClicked: {
            if (root.resultCount > 0) {
                root.resultClicked(root.firstResultIndex, root.firstDisplay, root.firstDecoration, root.firstCategory, root.firstMatchId, root.firstFilePath)
            }
        }
    }
}
