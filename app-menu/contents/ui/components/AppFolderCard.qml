import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid

Item {
    id: root

    required property var categoryModel
    required property string title
    required property real iconSize
    required property real smallIconSize
    required property real cardSize
    required property int categoryIndex
    
    property bool isExpanded: false
    property real parentWidth: 0
    signal toggleExpand()

    property bool breezeStyle: typeof(Plasmoid) !== 'undefined' ? (Plasmoid.configuration.breezeStyle ?? true) : true
    property int animDuration: typeof(Plasmoid) !== 'undefined' ? (Plasmoid.configuration.animationSpeed ?? 200) : 200
    property int configIconSize: typeof(Plasmoid) !== 'undefined' ? (Plasmoid.configuration.iconSize ?? 48) : 48
    property bool configShowLabels: typeof(Plasmoid) !== 'undefined' ? (Plasmoid.configuration.showLabelsInTiles ?? true) : true

    // Grid sizing calculations
    property real cellW: Kirigami.Units.gridUnit * 6
    property real cellH: cellW + 30
    property int gridCols: Math.max(1, Math.floor((parentWidth - 40) / cellW))
    property int gridRows: categoryModel ? Math.ceil(categoryModel.count / gridCols) : 0
    property real gridContentHeight: gridRows * cellH

    // Total expanded height calculation
    property real expandedHeight: cardSize + 40 + gridContentHeight

    // The dimensions of this specific delegate bounds
    width: isExpanded ? parentWidth : cardSize
    height: isExpanded ? expandedHeight : cardSize + 30

    // Prevent implicit animations from glitching when layout shrinks
    clip: true

    property bool isHovered: hoverArea.containsMouse

    Rectangle {
        id: bg
        anchors.fill: parent
        // When collapsed, the rectangle is square (doesn't cover the title)
        anchors.bottomMargin: root.isExpanded ? 0 : 30
        
        color: root.isExpanded || root.isHovered
            ? (breezeStyle ? Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.2) : Kirigami.Theme.hoverColor)
            : (breezeStyle ? "transparent" : Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.05))
        radius: 12
        border.color: breezeStyle ? Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.3) : "transparent"
        border.width: breezeStyle ? 1 : 0
        
        Behavior on color { ColorAnimation { duration: animDuration } }
        Behavior on anchors.bottomMargin { NumberAnimation { duration: animDuration; easing.type: Easing.InOutQuad } }

        MouseArea {
            id: hoverArea
            anchors.fill: parent
            hoverEnabled: true
            onClicked: {
                if (root.categoryModel && root.categoryModel.count > 0) {
                     root.toggleExpand()
                }
            }
        }

        // --- Expanded State Content ---
        
        // Custom Close Button and Title
        Item {
            id: headerArea
            width: parent.width
            height: 40 // Thinner header
            opacity: root.isExpanded ? 1 : 0
            visible: opacity > 0
            anchors.top: parent.top
            
            Behavior on opacity { NumberAnimation { duration: animDuration } }
            
            Text {
                text: root.title
                anchors.left: parent.left
                anchors.leftMargin: 20
                anchors.verticalCenter: parent.verticalCenter
                font.bold: true
                color: Kirigami.Theme.textColor
                font.pixelSize: Kirigami.Theme.defaultFont.pixelSize
            }
            
            ToolButton {
                icon.name: "window-close"
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.margins: 10
                implicitWidth: 24
                implicitHeight: 24
                onClicked: root.toggleExpand()
            }
            
            Rectangle {
                width: parent.width - 40
                height: 1
                color: Kirigami.Theme.highlightColor
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                opacity: 0.15
            }
        }

        // Inner Grid (Expanded mode)
        GridView {
            id: innerGrid
            width: parent.width - 40
            height: root.gridContentHeight
            anchors.top: headerArea.bottom
            anchors.topMargin: Kirigami.Units.largeSpacing
            anchors.horizontalCenter: parent.horizontalCenter
            
            interactive: false // Height fits all items
            cellWidth: root.cellW
            cellHeight: root.cellH
            
            opacity: 1
            visible: root.isExpanded || closeTimer.running
            
            property bool closeTimerRunning: closeTimer.running
            Timer {
                id: closeTimer
                interval: root.animDuration
            }
            Connections {
                target: root
                function onIsExpandedChanged() {
                    if (!root.isExpanded) closeTimer.restart()
                    else closeTimer.stop()
                }
            }
            
            model: root.categoryModel
            
            delegate: Item {
                width: innerGrid.cellWidth
                height: innerGrid.cellHeight
                
                id: staggeredItem
                required property int index
                required property string display
                required property var decoration
                
                property bool isHovered: itemHoverArea.containsMouse
                
                // --- Animation Logic for Transition from Collapsed to Expanded ---
                readonly property bool isInitialItem: index < 3
                
                property real startX: {
                    if (!isInitialItem) return 0
                    var W = (root.cardSize - 30) / 2
                    var col = index % 2
                    var collX = (root.width / 2) + (col === 0 ? -5 - W/2 : 5 + W/2)
                    var expGridCol = index % root.gridCols
                    var expX = 20 + expGridCol * root.cellW + root.cellW/2
                    return collX - expX
                }
                
                property real startY: {
                    if (!isInitialItem) return 0
                    var W = (root.cardSize - 30) / 2
                    var row = Math.floor(index / 2)
                    var collY = (root.cardSize / 2) + (row === 0 ? -5 - W/2 : 5 + W/2)
                    var expGridRow = Math.floor(index / root.gridCols)
                    var expY = 40 + Kirigami.Units.largeSpacing + expGridRow * root.cellH + root.cellH/2
                    return collY - expY
                }

                property real startScale: isInitialItem ? ((root.cardSize - 30) / 2) / root.cellW : 1.0

                opacity: root.isExpanded ? 1 : (isInitialItem ? 1 : 0)
                
                Behavior on opacity {
                    enabled: !isInitialItem
                    SequentialAnimation {
                        PauseAnimation { duration: root.isExpanded ? Math.max(0, (index - 3) * 30) : 0 }
                        NumberAnimation { duration: 300; easing.type: Easing.InOutQuad }
                    }
                }
                
                transform: [
                    Translate {
                        x: root.isExpanded ? 0 : staggeredItem.startX
                        y: root.isExpanded ? 0 : staggeredItem.startY
                        Behavior on x { NumberAnimation { duration: root.animDuration; easing.type: Easing.InOutQuad } }
                        Behavior on y { NumberAnimation { duration: root.animDuration; easing.type: Easing.InOutQuad } }
                    },
                    Scale {
                        origin.x: staggeredItem.width / 2
                        origin.y: staggeredItem.height / 2
                        xScale: root.isExpanded ? 1.0 : staggeredItem.startScale
                        yScale: root.isExpanded ? 1.0 : staggeredItem.startScale
                        Behavior on xScale { NumberAnimation { duration: root.animDuration; easing.type: Easing.InOutQuad } }
                        Behavior on yScale { NumberAnimation { duration: root.animDuration; easing.type: Easing.InOutQuad } }
                    }
                ]

                Rectangle {
                    anchors.fill: parent
                    color: isHovered 
                        ? (breezeStyle ? Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.2) : Kirigami.Theme.highlightColor)
                        : "transparent"
                    opacity: 1
                    border.width: 0 // Remove borders as requested
                    radius: Kirigami.Units.smallSpacing
                    Behavior on color { ColorAnimation { duration: animDuration } }
                }

                Column {
                    anchors.centerIn: parent
                    spacing: 5
                    width: parent.width
                    
                    Kirigami.Icon {
                        source: decoration
                        width: root.configIconSize
                        height: width
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    
                    Text {
                        text: display
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.Wrap
                        maximumLineCount: 2
                        elide: Text.ElideRight
                        color: Kirigami.Theme.textColor
                        font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                    }
                }
                
                MouseArea {
                    id: itemHoverArea
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: (mouse) => {
                        if (mouse.button === Qt.RightButton) {
                            localContextMenu.actionItem = {
                                display: display,
                                decoration: decoration,
                                matchId: display, // App name
                                category: root.title,
                                triggerFunc: function() {
                                    if (root.categoryModel && root.categoryModel.trigger) {
                                        root.categoryModel.trigger(index, "", null)
                                        try { Plasmoid.expanded = false; } catch(e) {}
                                    }
                                }
                            };
                            localContextMenu.popup();
                        } else {
                            if (root.categoryModel && root.categoryModel.trigger) {
                                root.categoryModel.trigger(index, "", null)
                                try { Plasmoid.expanded = false; } catch(e) {}
                            }
                        }
                    }
                }
            }
        }

        // --- Collapsed State Content ---
        
        Item {
            id: collapsedContent
            width: root.cardSize
            height: root.cardSize
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            opacity: root.isExpanded ? 0 : 1
            visible: opacity > 0
            
            Behavior on opacity { NumberAnimation { duration: animDuration } }

            Grid {
                anchors.centerIn: parent
                columns: 2
                spacing: 10
                
                Component {
                    id: itemDelegate
                    Item {
                        width: (root.cardSize - 30) / 2
                        height: width
                        
                        Column {
                            anchors.centerIn: parent
                            spacing: 2
                            width: parent.width
                            
                            Kirigami.Icon {
                                anchors.horizontalCenter: parent.horizontalCenter
                                source: modelDataDecoration
                                width: root.iconSize
                                height: root.iconSize
                            }

                            Text {
                                text: modelDataDisplay
                                width: parent.width
                                horizontalAlignment: Text.AlignHCenter
                                elide: Text.ElideRight
                                font.pixelSize: Kirigami.Theme.smallFont.pixelSize * 0.8
                                color: Kirigami.Theme.textColor
                                maximumLineCount: 1
                                visible: text !== "" && Plasmoid.configuration.showLabelsInTiles
                            }
                        }
                    }
                }

                Loader {
                    sourceComponent: itemDelegate
                    visible: root.categoryModel?.count > 0 && !(root.isExpanded || innerGrid.closeTimerRunning)
                    property string modelDataDecoration: visible ? root.categoryModel.data(root.categoryModel.index(0, 0), Qt.DecorationRole) : ""
                    property string modelDataDisplay: visible ? root.categoryModel.data(root.categoryModel.index(0, 0), Qt.DisplayRole) : ""
                }

                Loader {
                    sourceComponent: itemDelegate
                    visible: root.categoryModel?.count > 1 && !(root.isExpanded || innerGrid.closeTimerRunning)
                    property string modelDataDecoration: visible ? root.categoryModel.data(root.categoryModel.index(1, 0), Qt.DecorationRole) : ""
                    property string modelDataDisplay: visible ? root.categoryModel.data(root.categoryModel.index(1, 0), Qt.DisplayRole) : ""
                }

                Loader {
                    sourceComponent: itemDelegate
                    visible: root.categoryModel?.count > 2 && !(root.isExpanded || innerGrid.closeTimerRunning)
                    property string modelDataDecoration: visible ? root.categoryModel.data(root.categoryModel.index(2, 0), Qt.DecorationRole) : ""
                    property string modelDataDisplay: visible ? root.categoryModel.data(root.categoryModel.index(2, 0), Qt.DisplayRole) : ""
                }

                Item {
                    width: (root.cardSize - 30) / 2
                    height: width
                    visible: root.categoryModel?.count > 3
                    
                    Column {
                        anchors.centerIn: parent
                        spacing: 2
                        width: parent.width
                        visible: root.categoryModel?.count <= 4 && root.categoryModel?.count > 3

                        Kirigami.Icon {
                            anchors.horizontalCenter: parent.horizontalCenter
                            source: parent.visible ? root.categoryModel.data(root.categoryModel.index(3, 0), Qt.DecorationRole) : ""
                            width: root.iconSize
                            height: root.iconSize
                        }
                        
                        Text {
                            text: parent.visible ? root.categoryModel.data(root.categoryModel.index(3, 0), Qt.DisplayRole) : ""
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                            font.pixelSize: Kirigami.Theme.smallFont.pixelSize * 0.8
                            color: Kirigami.Theme.textColor
                            maximumLineCount: 1
                            visible: text !== "" && root.configShowLabels
                        }
                    }
                    
                    Grid {
                        anchors.centerIn: parent
                        visible: root.categoryModel?.count > 4
                        columns: 2
                        spacing: 2
                        
                        Repeater {
                            model: 4
                            delegate: Kirigami.Icon {
                                required property int index
                                property int itemIndex: 3 + index
                                visible: root.categoryModel?.count > itemIndex
                                source: visible ? root.categoryModel.data(root.categoryModel.index(itemIndex, 0), Qt.DecorationRole) : ""
                                width: root.smallIconSize
                                height: root.smallIconSize
                            }
                        }
                    }
                }
            }
        }
    }
    
    // External Title below the card when collapsed
    Text {
        id: externalTitle
        text: root.title
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        opacity: root.isExpanded ? 0 : 1
        visible: opacity > 0
        
        font.bold: true
        color: Kirigami.Theme.textColor
        font.pixelSize: Kirigami.Theme.defaultFont.pixelSize
        elide: Text.ElideRight
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        
        Behavior on opacity { NumberAnimation { duration: animDuration } }
    }
    
    AppContextMenu {
        id: localContextMenu
    }
}
