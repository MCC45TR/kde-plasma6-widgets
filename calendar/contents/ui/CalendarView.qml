import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: calendarLayout
    
    property string monthLabel
    property var calendarCells: []
    property var weekdayLabels: []
    
    // Parent'tan alınacak renkler
    property color textColor: "#ffffff"
    property color accentColor: "#d71921"
    property color highlightedTextColor: "#ffffff"
    property color completedColor: "#808080"
    property string titleFont: "Sans Serif"

    spacing: 6

    property int displayYear: 0
    property int currentMonthIndex: -1
    property var selectedDate
    signal dateSelected(date date)

    // --- HEADER ---
    Item {
        Layout.fillWidth: true
        Layout.preferredHeight: 20 // Text yüksekliği kadar

        Text {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: monthLabel
            font.family: titleFont
            font.pixelSize: 24
            font.weight: Font.Bold
            font.letterSpacing: 2
            color: calendarLayout.accentColor
        }

        Text {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: displayYear
            font.family: titleFont
            font.pixelSize: 15
            font.weight: Font.Bold
            font.italic: true
            font.letterSpacing: 1
            color: calendarLayout.accentColor
            visible: currentMonthIndex === 0 || currentMonthIndex === 11
        }
    }

    // --- GRID ---
    // --- GRID CONTAINER ---
    Item {
        id: gridContainer
        Layout.fillWidth: true
        Layout.fillHeight: true
        
        GridLayout {
            id: calendarGrid
            anchors.fill: parent
            columns: 7
            columnSpacing: 0
            rowSpacing: 0

            // Weekday Labels
            Repeater {
                model: weekdayLabels
                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 30
                    Text {
                        anchors.centerIn: parent
                        text: modelData
                        font.family: "Roboto Condensed"
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                        color: calendarLayout.completedColor
                        opacity: 0.7
                    }
                }
            }

            // Days
            Repeater {
                id: dayRepeater
                model: calendarCells
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    property var cellData: modelData
                    // Expose date for finding the item later
                    property date date: cellData.date 

                    // --- HIGHLIGHT RECTANGLE (TODAY) ---
                    Rectangle {
                        id: highlightRect
                        anchors.centerIn: parent
                        
                        width: 24
                        height: 24
                        radius: 6
                        
                        color: calendarLayout.accentColor
                        visible: cellData.isToday
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            calendarLayout.dateSelected(cellData.date)
                        }
                    }

                    // --- TEXT ---
                    Text {
                        anchors.centerIn: parent
                        text: cellData.day
                        font.family: "Roboto Condensed"
                        font.pixelSize: 11
                        font.weight: cellData.isToday ? Font.Bold : Font.Normal
                        // Change text color if selected (handled below or via condition)
                        readonly property bool isSelected: {
                             if (!calendarLayout.selectedDate) return false
                             return cellData.date.getFullYear() === calendarLayout.selectedDate.getFullYear() &&
                                    cellData.date.getMonth() === calendarLayout.selectedDate.getMonth() &&
                                    cellData.date.getDate() === calendarLayout.selectedDate.getDate()
                        }

                        color: isSelected ? "white" : (cellData.isToday ? calendarLayout.highlightedTextColor : Qt.alpha(calendarLayout.textColor, 0.7))
                        opacity: cellData.currentMonth ? 1 : 0.2
                    }
                }
            }
        }
        
        // --- ANIMATED SELECTION RECT ---
        Rectangle {
            id: animatedSelectionRect
            width: 24
            height: 24
            radius: 6
            color: "#5e5ce6" 
            
            visible: calendarLayout.selectedDate !== null
            opacity: visible ? 1 : 0
            
            // Initial position (will be updated)
            x: 0
            y: 0
            
            Behavior on x { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
            Behavior on y { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
            Behavior on opacity { NumberAnimation { duration: 200 } }
            
            onVisibleChanged: {
                if (visible) gridContainer.updatePosition()
            }
        }
        
        function updatePosition() {
            if (!calendarLayout.selectedDate) return
            
            var selDate = calendarLayout.selectedDate
            var targetItem = null
            
            // Find the item corresponding to the selected date
            for (var i = 0; i < dayRepeater.count; i++) {
                var item = dayRepeater.itemAt(i)
                if (item && item.date) {
                    if (item.date.getFullYear() === selDate.getFullYear() &&
                        item.date.getMonth() === selDate.getMonth() &&
                        item.date.getDate() === selDate.getDate()) {
                        targetItem = item
                        break
                    }
                }
            }
            
            if (targetItem) {
                // Calculate center relative to container
                var centerX = targetItem.x + targetItem.width / 2
                var centerY = targetItem.y + targetItem.height / 2
                
                // Set rect to be centered
                animatedSelectionRect.x = centerX - animatedSelectionRect.width / 2
                animatedSelectionRect.y = centerY - animatedSelectionRect.height / 2
            }
        }
        
        // Trigger update when selectedDate changes or grid layout changes
        Connections {
            target: calendarLayout
            function onSelectedDateChanged() { gridContainer.updatePosition() }
        }
        // Also update if layout changes size
        onWidthChanged: updatePosition()
        onHeightChanged: updatePosition()
    }
}
