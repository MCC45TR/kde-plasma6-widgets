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
        
        color: root.isExpanded ? Qt.rgba(Kirigami.Theme.backgroundColor.r, Kirigami.Theme.backgroundColor.g, Kirigami.Theme.backgroundColor.b, 0.95) : (root.isHovered ? Kirigami.Theme.hoverColor : Kirigami.Theme.backgroundColor)
        radius: 12
        border.color: root.isExpanded ? Kirigami.Theme.highlightColor : Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.1)
        border.width: root.isExpanded ? 2 : 1
        
        Behavior on color { ColorAnimation { duration: Kirigami.Units.shortDuration } }
        Behavior on anchors.bottomMargin { NumberAnimation { duration: Kirigami.Units.shortDuration; easing.type: Easing.OutCubic } }

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
            height: root.cardSize
            opacity: root.isExpanded ? 1 : 0
            visible: opacity > 0
            anchors.top: parent.top
            
            Behavior on opacity { NumberAnimation { duration: Kirigami.Units.shortDuration } }
            
            Text {
                text: root.title
                anchors.centerIn: parent
                font.bold: true
                color: Kirigami.Theme.textColor
                font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 1.2
            }
            
            ToolButton {
                icon.name: "window-close"
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.margins: 15
                onClicked: root.toggleExpand()
            }
            
            Rectangle {
                width: parent.width - 40
                height: 1
                color: Kirigami.Theme.highlightColor
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                opacity: 0.3
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
            
            opacity: root.isExpanded ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: Kirigami.Units.shortDuration } }
            
            model: root.categoryModel
            
            delegate: Item {
                width: innerGrid.cellWidth
                height: innerGrid.cellHeight
                
                required property int index
                required property string display
                required property var decoration
                
                property bool isHovered: itemHoverArea.containsMouse
                
                Rectangle {
                    anchors.fill: parent
                    color: Kirigami.Theme.highlightColor
                    opacity: isHovered ? 0.2 : 0
                    radius: Kirigami.Units.smallSpacing
                    Behavior on opacity { NumberAnimation { duration: Kirigami.Units.shortDuration } }
                }

                Column {
                    anchors.centerIn: parent
                    spacing: 5
                    width: parent.width
                    
                    Kirigami.Icon {
                        source: decoration
                        width: Kirigami.Units.iconSizes.medium
                        height: Kirigami.Units.iconSizes.medium
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
                    onClicked: {
                        if (root.categoryModel && root.categoryModel.trigger) {
                            root.categoryModel.trigger(index, "", null)
                            try { Plasmoid.expanded = false; } catch(e) {}
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
            
            Behavior on opacity { NumberAnimation { duration: Kirigami.Units.shortDuration } }

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
                    visible: root.categoryModel?.count > 0
                    property string modelDataDecoration: visible ? root.categoryModel.data(root.categoryModel.index(0, 0), Qt.DecorationRole) : ""
                    property string modelDataDisplay: visible ? root.categoryModel.data(root.categoryModel.index(0, 0), Qt.DisplayRole) : ""
                }

                Loader {
                    sourceComponent: itemDelegate
                    visible: root.categoryModel?.count > 1
                    property string modelDataDecoration: visible ? root.categoryModel.data(root.categoryModel.index(1, 0), Qt.DecorationRole) : ""
                    property string modelDataDisplay: visible ? root.categoryModel.data(root.categoryModel.index(1, 0), Qt.DisplayRole) : ""
                }

                Loader {
                    sourceComponent: itemDelegate
                    visible: root.categoryModel?.count > 2
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
                            visible: text !== "" && Plasmoid.configuration.showLabelsInTiles
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
        
        Behavior on opacity { NumberAnimation { duration: Kirigami.Units.shortDuration } }
    }
}
