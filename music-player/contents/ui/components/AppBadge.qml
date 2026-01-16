import QtQuick
import org.kde.kirigami as Kirigami

// AppBadge.qml - Uygulama ikonu rozeti (pill veya kare şeklinde)
Rectangle {
    id: badge
    
    // Properties (with defaults for Loader compatibility)
    property string playerIdentity: ""
    property string iconSource: "multimedia-player"
    
    // Optional properties
    property bool pillMode: false
    property real iconSize: 16
    
    // Computed properties
    height: pillMode ? (iconSize + 9) : (iconSize * 1.25)
    width: pillMode ? (badgeRow.implicitWidth + 16 + 5 + 4) : height
    
    radius: height / 2
    color: Kirigami.Theme.backgroundColor
    opacity: 1
    visible: playerIdentity !== ""
    z: 20
    
    Row {
        id: badgeRow
        anchors.centerIn: parent
        anchors.horizontalCenterOffset: badge.pillMode ? -4 : 0
        height: parent.height
        spacing: 6
        
        Item {
            width: badgeIcon.width
            height: parent.height
            
            Kirigami.Icon {
                id: badgeIcon
                anchors.centerIn: parent
                anchors.verticalCenterOffset: badge.pillMode ? -1 : 0
                width: badge.iconSize
                height: width
                source: badge.iconSource
            }
        }
        
        Item {
            width: badgeText.implicitWidth
            height: parent.height
            visible: badge.pillMode
            
            Text {
                id: badgeText
                anchors.centerIn: parent
                text: badge.playerIdentity || ""
                color: Kirigami.Theme.textColor
                font.pixelSize: 14
                font.bold: true
            }
        }
    }
}
