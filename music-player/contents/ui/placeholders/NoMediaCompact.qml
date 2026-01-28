import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Item {
    property string noMediaText: ""
    property bool hasPlayer: false

    property bool showText: true

    // Only show the placeholder image when there's no player
    // When there's a player but no art, the AlbumCover will show the play icon
    visible: !hasPlayer

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 2
        width: parent.width * 0.8
        visible: !hasPlayer

        Image {
            Layout.preferredWidth: parent.width * 0.5
            Layout.preferredHeight: Layout.preferredWidth
            Layout.alignment: Qt.AlignHCenter
            source: "../../images/album.png"
            fillMode: Image.PreserveAspectFit
            opacity: 0.8
            asynchronous: true
            sourceSize.width: 128
            sourceSize.height: 128
        }

        Text {
            text: noMediaText
            font.family: "Roboto Condensed"
            font.bold: true
            font.pixelSize: 16
            color: Kirigami.Theme.textColor
            Layout.alignment: Qt.AlignHCenter
            visible: showText
        }
    }
}
