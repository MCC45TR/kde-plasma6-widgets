import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.kirigami as Kirigami

// FileTypeFilterBar - Displays file type filter chips below pinned items
// Filters: All, Images, Videos, Documents, Apps, Folders
Item {
    id: filterBarRoot
    
    // Required properties
    property color textColor: Kirigami.Theme.textColor
    property color accentColor: Kirigami.Theme.highlightColor
    property color bgColor: Kirigami.Theme.backgroundColor
    
    // Current active filter (empty = all)
    property string activeFilter: ""
    
    // Signal when filter changes
    signal filterChanged(string filter)
    
    // Filter definitions
    property var filters: [
        { id: "", label: i18n("All"), icon: "view-list-icons" },
        { id: "image", label: i18n("Images"), icon: "image-x-generic" },
        { id: "video", label: i18n("Videos"), icon: "video-x-generic" },
        { id: "document", label: i18n("Documents"), icon: "x-office-document" },
        { id: "application", label: i18n("Apps"), icon: "applications-other" },
        { id: "folder", label: i18n("Folders"), icon: "folder" }
    ]
    
    // File extensions for each category
    readonly property var imageExtensions: ["png", "jpg", "jpeg", "gif", "bmp", "webp", "svg", "ico", "tiff", "raw", "heic"]
    readonly property var videoExtensions: ["mp4", "mkv", "avi", "webm", "mov", "wmv", "flv", "m4v", "mpg", "mpeg"]
    readonly property var documentExtensions: ["pdf", "doc", "docx", "xls", "xlsx", "ppt", "pptx", "odt", "ods", "odp", "txt", "rtf", "md"]
    
    // Check if a URL matches the current filter
    function matchesFilter(url, category) {
        if (activeFilter === "") return true
        
        var urlStr = (url || "").toString().toLowerCase()
        var cat = (category || "").toString().toLowerCase()
        
        switch (activeFilter) {
            case "image":
                return imageExtensions.some(ext => urlStr.endsWith("." + ext))
            case "video":
                return videoExtensions.some(ext => urlStr.endsWith("." + ext))
            case "document":
                return documentExtensions.some(ext => urlStr.endsWith("." + ext))
            case "application":
                return cat.indexOf("application") >= 0 || 
                       cat.indexOf("uygulamalar") >= 0 || 
                       urlStr.endsWith(".desktop")
            case "folder":
                return cat.indexOf("folder") >= 0 || 
                       cat.indexOf("klasör") >= 0 ||
                       (urlStr.startsWith("file://") && !urlStr.includes("."))
            default:
                return true
        }
    }
    
    implicitHeight: 32
    
    // Filter chips row
    Row {
        id: filterRow
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6
        
        Repeater {
            model: filterBarRoot.filters
            
            Rectangle {
                id: filterChip
                width: chipContent.width + 16
                height: 26
                radius: 13
                
                property bool isActive: filterBarRoot.activeFilter === modelData.id
                
                color: isActive ? 
                    Qt.rgba(filterBarRoot.accentColor.r, filterBarRoot.accentColor.g, filterBarRoot.accentColor.b, 0.2) :
                    Qt.rgba(filterBarRoot.textColor.r, filterBarRoot.textColor.g, filterBarRoot.textColor.b, 0.08)
                
                border.width: isActive ? 1 : 0
                border.color: filterBarRoot.accentColor
                
                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on border.width { NumberAnimation { duration: 150 } }
                
                Row {
                    id: chipContent
                    anchors.centerIn: parent
                    spacing: 4
                    
                    Kirigami.Icon {
                        width: 14
                        height: 14
                        source: modelData.icon
                        color: filterChip.isActive ? filterBarRoot.accentColor : filterBarRoot.textColor
                        anchors.verticalCenter: parent.verticalCenter
                        opacity: filterChip.isActive ? 1.0 : 0.7
                    }
                    
                    Text {
                        text: modelData.label
                        color: filterChip.isActive ? filterBarRoot.accentColor : filterBarRoot.textColor
                        font.pixelSize: 11
                        font.weight: filterChip.isActive ? Font.DemiBold : Font.Normal
                        anchors.verticalCenter: parent.verticalCenter
                        opacity: filterChip.isActive ? 1.0 : 0.8
                    }
                }
                
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    
                    onClicked: {
                        filterBarRoot.activeFilter = modelData.id
                        filterBarRoot.filterChanged(modelData.id)
                    }
                    
                    onEntered: {
                        if (!filterChip.isActive) {
                            filterChip.color = Qt.rgba(filterBarRoot.textColor.r, filterBarRoot.textColor.g, filterBarRoot.textColor.b, 0.15)
                        }
                    }
                    
                    onExited: {
                        if (!filterChip.isActive) {
                            filterChip.color = Qt.rgba(filterBarRoot.textColor.r, filterBarRoot.textColor.g, filterBarRoot.textColor.b, 0.08)
                        }
                    }
                }
            }
        }
    }
    
    // Clear filter button (visible when filter is active)
    Rectangle {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: 24
        height: 24
        radius: 12
        visible: filterBarRoot.activeFilter !== ""
        color: Qt.rgba(filterBarRoot.textColor.r, filterBarRoot.textColor.g, filterBarRoot.textColor.b, 0.1)
        
        Kirigami.Icon {
            anchors.centerIn: parent
            width: 14
            height: 14
            source: "edit-clear"
            color: filterBarRoot.textColor
            opacity: 0.7
        }
        
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                filterBarRoot.activeFilter = ""
                filterBarRoot.filterChanged("")
            }
        }
        
        opacity: 0
        Behavior on opacity { NumberAnimation { duration: 200 } }
        Component.onCompleted: opacity = 1
    }
}
