import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: calendarLayout
    
    property string monthLabel
    property var calendarCells: []
    property var weekdayLabels: {
        var labels = []
        var firstDay = Qt.locale().firstDayOfWeek
        for (var i = 0; i < 7; ++i) {
            labels.push(Qt.locale().dayName((firstDay + i) % 7, 2))
        }
        return labels
    }
    
    // Parent'tan alınacak renkler
    property color textColor: "#ffffff"
    property color accentColor: "#d71921"
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
            opacity: 1 // Mat görünüm için
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
            opacity: 1
            visible: currentMonthIndex === 0 || currentMonthIndex === 11
        }
    }

    // --- GRID ---
    GridLayout {
        columns: 7
        columnSpacing: 0
        rowSpacing: 0
        Layout.fillWidth: true
        Layout.fillHeight: true

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
            model: calendarCells
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                property var cellData: modelData

                // --- HIGHLIGHT RECTANGLE ---
                Rectangle {
                    id: highlightRect
                    anchors.centerIn: parent
                    
                    width: 24
                    height: 24
                    radius: 6
                    
                    color: calendarLayout.accentColor
                    visible: cellData.isToday
                    opacity: 1 // Mat görünüm için
                }

                // --- SELECTION RECTANGLE ---
                Rectangle {
                    id: selectionRect
                    anchors.centerIn: parent
                    
                    width: 24
                    height: 24
                    radius: width / 2 // Tam daire
                    
                    color: calendarLayout.accentColor
                    visible: {
                        if (!calendarLayout.selectedDate) return false
                        return cellData.date.getFullYear() === calendarLayout.selectedDate.getFullYear() &&
                               cellData.date.getMonth() === calendarLayout.selectedDate.getMonth() &&
                               cellData.date.getDate() === calendarLayout.selectedDate.getDate()
                    }
                    opacity: 0.5
                }
                
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        calendarLayout.dateSelected(cellData.date)
                    }
                }

                // --- TEXT ---
                Text {
                    anchors.centerIn: highlightRect 
                    text: cellData.day
                    font.family: "Roboto Condensed"
                    font.pixelSize: 11
                    font.weight: cellData.isToday ? Font.Bold : Font.Normal
                    color: cellData.isToday ? calendarLayout.textColor : Qt.alpha(calendarLayout.textColor, 0.7)
                    opacity: cellData.currentMonth ? 1 : 0.2
                }
            }
        }
    }
}
