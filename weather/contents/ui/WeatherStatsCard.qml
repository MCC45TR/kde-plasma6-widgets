import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Rectangle {
    id: statsCard
    
    property string label: ""
    property string value: "--"
    property string emoji: ""
    property bool hasData: true
    property color valueColor: Kirigami.Theme.textColor
    property int valueFontSize: 15
    
    visible: hasData
    Layout.fillWidth: true
    Layout.preferredHeight: 45
    radius: 8
    color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.05)
    
    ColumnLayout {
        anchors.centerIn: parent
        spacing: 1
        
        Text {
            text: emoji ? emoji + " " + label : label
            color: Kirigami.Theme.textColor
            opacity: 0.6
            font.pixelSize: 9
            Layout.alignment: Qt.AlignHCenter
        }
        
        Text {
            text: value
            color: statsCard.valueColor
            font.pixelSize: statsCard.valueFontSize
            font.bold: true
            Layout.alignment: Qt.AlignHCenter
        }
    }
}
