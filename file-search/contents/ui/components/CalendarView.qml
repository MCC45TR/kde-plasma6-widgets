import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

ColumnLayout {
    id: calendarLayout

    property string monthLabel
    property var calendarCells: []
    property var weekdayLabels: []

    // Configurable colors/fonts
    property color textColor: Kirigami.Theme.textColor
    property color accentColor: Kirigami.Theme.highlightColor
    property color completedColor: Kirigami.Theme.disabledTextColor

    spacing: 6

    property int displayYear: 0
    property int currentMonthIndex: -1
    property var selectedDate
    signal dateSelected(date date)

    // --- HEADER ---
    Item {
        Layout.fillWidth: true
        Layout.preferredHeight: 30

        Text {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: monthLabel
            font.pixelSize: Math.round(Kirigami.Theme.defaultFont.pixelSize * 2)
            font.bold: true
            font.letterSpacing: 2
            color: calendarLayout.accentColor
        }

        Text {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: displayYear
            font.pixelSize: Math.round(Kirigami.Theme.defaultFont.pixelSize * 1.25)
            font.bold: true
            font.italic: true
            font.letterSpacing: 1
            color: calendarLayout.accentColor
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
                    font.family: Kirigami.Theme.smallFont.family
                    font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                    font.bold: true
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

                // --- TEXT ---
                Text {
                    anchors.centerIn: highlightRect
                    text: cellData.day
                    font.family: Kirigami.Theme.defaultFont.family
                    font.pixelSize: Kirigami.Theme.defaultFont.pixelSize
                    font.bold: cellData.isToday
                    color: cellData.isToday ? calendarLayout.textColor : Qt.alpha(calendarLayout.textColor, 0.7)
                    opacity: cellData.currentMonth ? 1 : 0.2
                }
            }
        }
    }
}
