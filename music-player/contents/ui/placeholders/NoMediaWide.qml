import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Item {
    property string noMediaText: ""
    property bool hasPlayer: false

    ColumnLayout {
        anchors.centerIn: parent
        width: parent.width * 0.8
        
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
    }
}
