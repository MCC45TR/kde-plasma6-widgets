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
    property bool dateInView: false // Track if the selected date is visible in this specific view
    signal dateSelected(date date)

    // --- HEADER ---
    Item {
        Layout.fillWidth: true
        Layout.preferredHeight: 20 // Text yüksekliği kadar

        Text {
            anchors.left: parent.left
            // Align with the visual start of the first column's content (centered)
            // Column width is parent.width / 7. Center is at w/14.
            // Text content (like 'P' or '23') is centered. Assume approx half-width is 8px.
            anchors.leftMargin: Math.max(0, (parent.width / 7) / 2 - 8)
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
            anchors.rightMargin: Math.max(0, (parent.width / 7) / 2 - 8)
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
                    
                    MouseArea {
                        anchors.fill: parent
                        // Support both hover and click as the user interaction evolved
                        hoverEnabled: true 
                        onClicked: {
                            columnHighlighter.columnIndex = index
                            selectionTimer.restart()
                        }
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
                            // Reset column selection when a specific date is clicked
                            columnHighlighter.columnIndex = -1 
                            calendarLayout.selectedDate = cellData.date
                            calendarLayout.dateSelected(cellData.date)
                            selectionTimer.restart()
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

                        color: cellData.isToday ? calendarLayout.highlightedTextColor : (isSelected && selectionTimer.running && columnHighlighter.columnIndex === -1 ? calendarLayout.accentColor : Qt.alpha(calendarLayout.textColor, 0.7))
                        opacity: cellData.currentMonth ? 1 : 0.2
                    }
                }
            }
        }
        
        // --- ANIMATED SELECTION RECT ---
        Rectangle {
            id: animatedSelectionRect
            // Use this invisible Item to track state ("column" vs "date")
            // Reusing the id 'columnHighlighter' conceptually to store the index state, 
            // but the visual is THIS rect.
            Item {
                id: columnHighlighter
                property int columnIndex: -1
                onColumnIndexChanged: gridContainer.updatePosition()
            }

            width: 24
            height: 24
            radius: width / 2
            
            color: calendarLayout.accentColor 
            
            // Visible if opacity is > 0 to allow fade out animation
            visible: opacity > 0
            opacity: (selectionTimer.running && (columnHighlighter.columnIndex !== -1 || (calendarLayout.selectedDate !== null && calendarLayout.dateInView))) ? 0.2 : 0

            Timer {
                id: selectionTimer
                interval: 10000
            }
            
            // Initial position (will be updated)
            x: 0
            y: 0
            
            // Add animations for size changes too
            Behavior on x { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
            Behavior on y { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
            Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
            Behavior on height { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
            Behavior on opacity { NumberAnimation { duration: 400 } }
        }
        
        function updatePosition() {
            // Priority: Column Highlight > Date Highlight
            if (columnHighlighter.columnIndex !== -1) {
                // Column Highlight Mode
                var colWidth = calendarGrid.width / 7
                animatedSelectionRect.x = colWidth * columnHighlighter.columnIndex
                animatedSelectionRect.y = 0
                animatedSelectionRect.width = colWidth
                animatedSelectionRect.height = calendarGrid.height
                return
            }

            if (!calendarLayout.selectedDate) return
            
            // Date Highlight Mode
            var selDate = calendarLayout.selectedDate
            var targetItem = null
            calendarLayout.dateInView = false
            
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
                calendarLayout.dateInView = true
                // Reset to circle size
                var targetSize = 24
                animatedSelectionRect.width = targetSize
                animatedSelectionRect.height = targetSize

                // Calculate center relative to container
                var centerX = targetItem.x + targetItem.width / 2
                var centerY = targetItem.y + targetItem.height / 2
                
                // Set rect to be centered using fixed target size
                animatedSelectionRect.x = centerX - targetSize / 2
                animatedSelectionRect.y = centerY - targetSize / 2
            }
        }
        
        // Trigger update when selectedDate changes or grid layout changes
        Connections {
            target: calendarLayout
            function onSelectedDateChanged() { 
                gridContainer.updatePosition()
                selectionTimer.restart()
            }
        }
        // Also update if layout changes size
        onWidthChanged: updatePosition()
        onHeightChanged: updatePosition()
    }
}
