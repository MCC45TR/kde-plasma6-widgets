import QtQuick
import org.kde.kirigami as Kirigami
import "../js/PlayerData.js" as PlayerData

// AppBadge.qml - Uygulama ikonu rozeti (pill veya kare şeklinde) - Expandable
Rectangle {
    id: badge
    
    // Properties (with defaults for Loader compatibility)
    property string playerIdentity: ""
    property string iconSource: "multimedia-player"
    
    property var playersModel: null
    property var onSwitchPlayer: function(id) {}
    
    // Optional properties
    property bool pillMode: false
    property bool iconOnlyMode: false // When true, shows only icons in expanded view
    property real iconSize: 16
    
    // State
    property bool expanded: false
    
    // Filtered unique players list
    ListModel { id: uniquePlayersModel }
    
    // Refresh unique players when expanded or model changes
    function refreshUniquePlayers() {
        uniquePlayersModel.clear()
        if (!playersModel) return
        
        var seen = {}
        var count = playersModel.rowCount()
        for (var i = 0; i < count; i++) {
            playersModel.currentIndex = i
            var player = playersModel.currentPlayer
            if (player && player.identity) {
                var prettyName = PlayerData.getPrettyName(player.identity)
                var lowerName = prettyName.toLowerCase()
                
                // Skip duplicates and current player
                if (seen[lowerName]) continue
                if (player.identity === badge.playerIdentity) continue
                
                seen[lowerName] = true
                uniquePlayersModel.append({
                    rawName: player.identity,
                    prettyName: prettyName,
                    iconName: PlayerData.getPlayerIcon(player.identity)
                })
            }
        }
    }
    
    onExpandedChanged: if (expanded) refreshUniquePlayers()
    
    // Computed properties
    readonly property real headerHeight: pillMode ? (iconSize + 9) : (iconSize * 1.25)
    readonly property real headerWidth: pillMode ? (badgeRow.implicitWidth + 16 + 5 + 4) : headerHeight
    
    // Calculate expanded header height (for wrapping text)
    readonly property real expandedHeaderHeight: expanded ? Math.max(headerHeight, headerTextMetrics.height + 10) : headerHeight
    
    // Calculate list height - smaller in iconOnlyMode
    readonly property int listItemCount: uniquePlayersModel.count
    readonly property real itemHeight: iconOnlyMode ? headerHeight : 36
    readonly property real listHeight: listItemCount * itemHeight + itemHeight /* General Item */

    width: iconOnlyMode ? headerWidth : (expanded ? Math.max(headerWidth, 180) : headerWidth)
    height: expanded ? (headerHeight + 1 + listHeight + (iconOnlyMode ? 5 : 10)) : headerHeight
    
    Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutQuad } }
    Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutQuad } }
    
    radius: headerHeight / 2
    
    // Use solid background color - not transparent
    color: {
        var bg = Kirigami.Theme.backgroundColor
        return Qt.rgba(bg.r, bg.g, bg.b, 1.0)
    }
    
    visible: playerIdentity !== ""
    z: expanded ? 100 : 20
    clip: true
    
    // Border for visibility against dark backgrounds
    border.width: 1
    border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.2)

    // Text metrics for header
    TextMetrics {
        id: headerTextMetrics
        font.pixelSize: 14
        font.bold: true
        text: PlayerData.getPrettyName(badge.playerIdentity)
    }

    Column {
        id: mainCol
        width: parent.width
        spacing: 0
        
        // Header (Current Player) - Click to toggle
        Item {
            id: headerItem
            width: parent.width
            height: badge.expandedHeaderHeight
            
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    if (badge.playersModel) {
                         badge.expanded = !badge.expanded
                    }
                }
            }
            
            Item {
                id: badgeRow
                anchors.fill: parent
                
                // Icon centered in iconOnlyMode, left-aligned otherwise
                Item {
                    id: iconContainer
                    width: badge.iconSize
                    height: parent.height
                    anchors.centerIn: badge.iconOnlyMode ? parent : undefined
                    anchors.left: badge.iconOnlyMode ? undefined : parent.left
                    anchors.leftMargin: badge.iconOnlyMode ? 0 : ((badge.headerWidth - badge.iconSize) / 2)
                    anchors.verticalCenter: badge.iconOnlyMode ? undefined : parent.verticalCenter
                    
                    // Current icon with fade animation
                    Kirigami.Icon {
                        id: badgeIcon
                        anchors.centerIn: parent
                        anchors.verticalCenterOffset: badge.pillMode ? -1 : 0
                        width: badge.iconSize
                        height: width
                        source: badge.iconSource
                        opacity: 1
                        
                        Behavior on opacity {
                            NumberAnimation { duration: 150; easing.type: Easing.InOutQuad }
                        }
                    }
                    
                    // Previous icon for crossfade effect
                    Kirigami.Icon {
                        id: previousIcon
                        anchors.centerIn: parent
                        anchors.verticalCenterOffset: badge.pillMode ? -1 : 0
                        width: badge.iconSize
                        height: width
                        source: ""
                        opacity: 0
                        
                        Behavior on opacity {
                            NumberAnimation { duration: 150; easing.type: Easing.InOutQuad }
                        }
                    }
                    
                    // Track icon changes for crossfade
                    property string lastIconSource: badge.iconSource
                    
                    Connections {
                        target: badge
                        function onIconSourceChanged() {
                            if (iconContainer.lastIconSource !== badge.iconSource && iconContainer.lastIconSource !== "") {
                                // Set previous icon to old source
                                previousIcon.source = iconContainer.lastIconSource
                                previousIcon.opacity = 1
                                badgeIcon.opacity = 0
                                
                                // Fade transition
                                crossfadeTimer.restart()
                            }
                            iconContainer.lastIconSource = badge.iconSource
                        }
                    }
                    
                    Timer {
                        id: crossfadeTimer
                        interval: 50
                        onTriggered: {
                            badgeIcon.opacity = 1
                            previousIcon.opacity = 0
                        }
                    }
                }
                
                // Text Item - only visible when not iconOnlyMode
                Item {
                    anchors.left: iconContainer.right
                    anchors.leftMargin: 6
                    anchors.right: expandArrow.left
                    anchors.rightMargin: 6
                    height: parent.height
                    visible: (badge.pillMode || badge.expanded) && !badge.iconOnlyMode
                    
                    Text {
                        id: badgeText
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width
                        text: PlayerData.getPrettyName(badge.playerIdentity)
                        color: Kirigami.Theme.textColor
                        font.pixelSize: 14
                        font.bold: true
                        wrapMode: badge.expanded ? Text.WordWrap : Text.NoWrap
                        elide: badge.expanded ? Text.ElideNone : Text.ElideRight
                        maximumLineCount: badge.expanded ? 2 : 1
                    }
                }
                
                // Expand Icon
                Item {
                    id: expandArrow
                    width: 16
                    anchors.right: parent.right
                    anchors.rightMargin: 10
                    height: parent.height
                    visible: badge.playersModel && (badge.pillMode || badge.expanded) && !badge.iconOnlyMode
                    
                    Kirigami.Icon {
                        anchors.centerIn: parent
                        width: 12
                        height: 12
                        source: badge.expanded ? "arrow-up" : "arrow-down"
                        opacity: 0.7
                    }
                }
            }
        }
        
        // Separator
        Rectangle {
            id: separator
            width: parent.width - 20
            anchors.horizontalCenter: parent.horizontalCenter
            height: 1
            color: Kirigami.Theme.textColor
            opacity: 0.15
            visible: badge.expanded
        }
        
        // "General" (Auto) Item
        Item {
            id: generalItem
            width: badge.width
            height: badge.itemHeight
            visible: badge.expanded
            
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    badge.onSwitchPlayer("") // Empty string -> General/Auto
                    badge.expanded = false
                }
                hoverEnabled: true
                onEntered: generalBg.opacity = 0.1
                onExited: generalBg.opacity = 0
                
                Rectangle {
                    id: generalBg
                    anchors.fill: parent
                    color: Kirigami.Theme.textColor
                    opacity: 0
                }
            }
            
            Item {
                anchors.fill: parent
                anchors.leftMargin: badge.iconOnlyMode ? 0 : 10
                anchors.rightMargin: badge.iconOnlyMode ? 0 : 10
                
                Kirigami.Icon {
                    anchors.centerIn: badge.iconOnlyMode ? parent : undefined
                    anchors.verticalCenter: badge.iconOnlyMode ? undefined : parent.verticalCenter
                    anchors.left: badge.iconOnlyMode ? undefined : parent.left
                    width: badge.iconOnlyMode ? badge.iconSize : 20
                    height: width
                    source: "audio-card"
                }
                
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 30
                    text: i18n("General")
                    color: Kirigami.Theme.textColor
                    font.pixelSize: 13
                    elide: Text.ElideRight
                    width: parent.width - 40
                    font.italic: true
                    visible: !badge.iconOnlyMode
                }
            }
        }

        // List of other players (unique, filtered)
        Repeater {
            id: playersRepeater
            model: badge.expanded ? uniquePlayersModel : null
            
            delegate: Item {
                width: badge.width
                height: badge.itemHeight
                
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        badge.onSwitchPlayer(model.rawName)
                        badge.expanded = false
                    }
                    hoverEnabled: true
                    onEntered: bg.opacity = 0.1
                    onExited: bg.opacity = 0
                    
                    Rectangle {
                        id: bg
                        anchors.fill: parent
                        color: Kirigami.Theme.textColor
                        opacity: 0
                    }
                }
                
                Item {
                    anchors.fill: parent
                    anchors.leftMargin: badge.iconOnlyMode ? 0 : 10
                    anchors.rightMargin: badge.iconOnlyMode ? 0 : 10
                    
                    Kirigami.Icon {
                        anchors.centerIn: badge.iconOnlyMode ? parent : undefined
                        anchors.verticalCenter: badge.iconOnlyMode ? undefined : parent.verticalCenter
                        anchors.left: badge.iconOnlyMode ? undefined : parent.left
                        width: badge.iconOnlyMode ? badge.iconSize : 20
                        height: width
                        source: model.iconName
                    }
                    
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 30
                        text: model.prettyName
                        color: Kirigami.Theme.textColor
                        font.pixelSize: 13
                        elide: Text.ElideRight
                        width: parent.width - 40
                        visible: !badge.iconOnlyMode
                    }
                }
            }
        }
    }
}
