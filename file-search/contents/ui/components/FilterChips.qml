import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.kirigami as Kirigami

Item {
    id: filterChipsRoot
    
    property color textColor
    property color accentColor
    property color bgColor
    property string activeFilter: "Tümü"
    property bool breezeStyle: false
    
    signal filterSelected(string filterName)
    
    implicitHeight: 32
    
    Flickable {
        anchors.fill: parent
        contentWidth: rowLayout.width
        contentHeight: height
        clip: true
        interactive: contentWidth > width
        
        Row {
            id: rowLayout
            spacing: 8
            padding: 4
            
            Repeater {
                model: ["Tümü", "Uygulamalar", "Belgeler", "Resimler", "Klasörler", "Web"]
                delegate: Rectangle {
                    id: chip
                    width: chipText.implicitWidth + 24
                    height: 24
                    radius: 12
                    
                    property bool isActive: modelData === filterChipsRoot.activeFilter
                    property bool isHovered: chipMouseArea.containsMouse
                    
                    color: filterChipsRoot.breezeStyle ? 
                           (isHovered ? Qt.rgba(filterChipsRoot.accentColor.r, filterChipsRoot.accentColor.g, filterChipsRoot.accentColor.b, 0.1) : "transparent") :
                           (isActive ? filterChipsRoot.accentColor : 
                                   (isHovered ? Qt.rgba(filterChipsRoot.accentColor.r, filterChipsRoot.accentColor.g, filterChipsRoot.accentColor.b, 0.2) : 
                                               Qt.rgba(filterChipsRoot.textColor.r, filterChipsRoot.textColor.g, filterChipsRoot.textColor.b, 0.1)))
                    
                    border.width: filterChipsRoot.breezeStyle ? 1 : 0
                    border.color: filterChipsRoot.breezeStyle ? 
                                 (isActive ? filterChipsRoot.accentColor : Qt.rgba(filterChipsRoot.textColor.r, filterChipsRoot.textColor.g, filterChipsRoot.textColor.b, 0.3)) :
                                 "transparent"
                    
                    Text {
                        id: chipText
                        anchors.centerIn: parent
                        text: modelData
                        color: filterChipsRoot.breezeStyle ?
                               (chip.isActive ? filterChipsRoot.accentColor : filterChipsRoot.textColor) :
                               (chip.isActive ? Kirigami.Theme.backgroundColor : filterChipsRoot.textColor)
                        font.pixelSize: 12
                        font.weight: chip.isActive ? Font.Bold : Font.Normal
                    }
                    
                    MouseArea {
                        id: chipMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            filterChipsRoot.filterSelected(modelData)
                        }
                    }
                }
            }
        }
    }
}
