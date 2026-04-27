import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.kirigami as Kirigami

Item {
    id: filterChipsRoot
    
    property color textColor
    property color accentColor
    property color bgColor
    property string activeFilter: "All"
    property bool breezeStyle: false
    
    signal filterSelected(string filterName)
    
    implicitHeight: 32

    // Internal keys → Display names mapping
    // Internal keys are always English, UI display uses i18nd()
    readonly property var filterModel: [
        { key: "All",     label: i18nd("plasma_applet_com.mcc45tr.filesearch", "All") },
        { key: "Apps",    label: i18nd("plasma_applet_com.mcc45tr.filesearch", "Apps") },
        { key: "Docs",    label: i18nd("plasma_applet_com.mcc45tr.filesearch", "Docs") },
        { key: "Images",  label: i18nd("plasma_applet_com.mcc45tr.filesearch", "Images") },
        { key: "Folders", label: i18nd("plasma_applet_com.mcc45tr.filesearch", "Folders") },
        { key: "Web",     label: i18nd("plasma_applet_com.mcc45tr.filesearch", "Web") },
        { key: "RSS",     label: "RSS" }
    ]
    
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
            x: (rowLayout.width < parent.width) ? (parent.width - rowLayout.width) / 2 : 0
            
            Behavior on x { NumberAnimation { duration: 150 } }
            
            Repeater {
                model: filterChipsRoot.filterModel
                delegate: Rectangle {
                    id: chip
                    width: chipText.implicitWidth + 24
                    height: 24
                    radius: 12
                    
                    property bool isActive: modelData.key === filterChipsRoot.activeFilter
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
                        text: modelData.label
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
                            filterChipsRoot.filterSelected(modelData.key)
                        }
                    }
                }
            }
        }
    }
}
