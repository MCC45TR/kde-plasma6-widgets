import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.kirigami as Kirigami

Item {
    id: root
    
    required property color textColor
    property color accentColor: Kirigami.Theme.highlightColor
    property color completedColor: Qt.alpha(root.textColor, 0.5)
    
    property string viewMode: "date" // "date" = Calendar Only, "clock" = Clock Only
    property bool showClock: true
    property bool showEvents: true
    
    // Timer to update time
    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: updateTime()
    }
    
    property string timeStr: ""
    property string dayStr: ""
    property string datePartStr: ""
    property string yearStr: ""
    
    function updateTime() {
        var now = new Date()
        timeStr = now.toLocaleTimeString(Qt.locale(), "HH:mm")
        dayStr = now.toLocaleDateString(Qt.locale(), "dddd")
        datePartStr = now.toLocaleDateString(Qt.locale(), "d MMMM")
        yearStr = now.toLocaleDateString(Qt.locale(), "yyyy")
        currentDate = now 
    }
    
    property var currentDate: new Date()
    
    Component.onCompleted: updateTime()

    // Font Loaders
    FontLoader { id: barlowMedium; source: "../../fonts/BarlowCondensed-Medium.ttf" }
    FontLoader { id: barlowLight; source: "../../fonts/BarlowCondensed-Light.ttf" }
    FontLoader { id: barlowLightItalic; source: "../../fonts/BarlowCondensed-LightItalic.ttf" }
    
    // --- CALENDAR LOGIC ---
    property var weekdayLabels: {
        var labels = []
        var firstDay = Qt.locale().firstDayOfWeek
        for (var i = 0; i < 7; ++i) {
            labels.push(Qt.locale().dayName((firstDay + i) % 7, 2))
        }
        return labels
    }
    
    function getCalendarData(monthOffset, baseDate) {
        var today = baseDate || new Date()
        var targetDate = new Date(today.getFullYear(), today.getMonth() + monthOffset, 1)
        var displayYear = targetDate.getFullYear()
        var displayMonth = targetDate.getMonth()
        var label = Qt.locale().monthName(displayMonth).toLocaleUpperCase(Qt.locale().name)

        var cells = []
        var firstOfMonth = new Date(displayYear, displayMonth, 1)
        var firstDayOfWeek = Qt.locale().firstDayOfWeek
        
        var currentDayNameIndex = firstOfMonth.getDay() 
        var startDay = (currentDayNameIndex - firstDayOfWeek + 7) % 7
        
        var daysInMonth = new Date(displayYear, displayMonth + 1, 0).getDate()
        var prevMonthLastDate = new Date(displayYear, displayMonth, 0).getDate()
        
        for (var i = 0; i < startDay; ++i) {
            var dayNum = prevMonthLastDate - startDay + 1 + i
            cells.push({ 
                day: String(dayNum), 
                currentMonth: false, 
                isToday: false,
                date: new Date(displayYear, displayMonth - 1, dayNum)
            })
        }

        for (var d = 1; d <= daysInMonth; ++d) {
            var checkDate = new Date(displayYear, displayMonth, d);
            var isToday = checkDate.getDate() === today.getDate() &&
                          checkDate.getMonth() === today.getMonth() &&
                          checkDate.getFullYear() === today.getFullYear();

            cells.push({ 
                day: String(d), 
                currentMonth: true, 
                isToday: isToday,
                date: checkDate
            })
        }

        var nextMonthDay = 1
        while (cells.length % 7 !== 0) {
            cells.push({ 
                day: String(nextMonthDay), 
                currentMonth: false, 
                isToday: false,
                date: new Date(displayYear, displayMonth + 1, nextMonthDay)
            })
            nextMonthDay++
        }

        return { label: label, cells: cells, year: displayYear, monthIndex: displayMonth }
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: 0
        color: Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.05)
        radius: 12
        
        // --- CLOCK ONLY VIEW ---
        Item {
            anchors.fill: parent
            anchors.margins: 12
            visible: root.viewMode === "clock"
            
            ColumnLayout {
                anchors.centerIn: parent
                width: Math.min(parent.width, 300)
                spacing: 0
                
                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 120 // Fixed height for time
                    
                    Text {
                        anchors.centerIn: parent
                        text: root.timeStr
                        
                        // Bigger clock
                        font.pixelSize: 80 
                        font.weight: Font.Light
                        font.italic: true
                        font.family: barlowLightItalic.name
                        color: root.textColor
                    }
                }

                Text {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter

                    text: root.dayStr
                    
                    font.pixelSize: 42
                    font.weight: Font.Medium
                    font.family: barlowMedium.name
                    color: root.textColor
                }

                Text {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter

                    text: root.datePartStr + " " + root.yearStr
                    
                    font.pixelSize: 24
                    font.weight: Font.Light
                    font.family: barlowLight.name
                    color: Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.85)
                }
            }
        }
        
        // --- CALENDAR ONLY VIEW ---
        Item {
            id: calendarContainer
            anchors.fill: parent
            anchors.margins: 20
            visible: root.viewMode === "date"
            
            // Adaptive Logic for Calendar Grid
            // Allow more columns if wide
            readonly property int columns: width >= 500 ? (width >= 800 ? 3 : 2) : 1
            readonly property int rows: height >= 400 ? 2 : 1
            readonly property int capacity: columns * rows
            
            GridLayout {
                anchors.centerIn: parent // Center the grid
                width: parent.width
                height: parent.height
                
                columns: calendarContainer.columns
                rows: calendarContainer.rows
                columnSpacing: 30
                rowSpacing: 30
                
                Repeater {
                    model: calendarContainer.capacity
                    
                    CalendarView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.maximumWidth: 350 // Don't stretch too much
                        Layout.maximumHeight: 300
                        Layout.alignment: Qt.AlignCenter
                        
                        property var monthData: root.getCalendarData(index, root.currentDate)
                        
                        monthLabel: monthData.label
                        displayYear: monthData.year
                        currentMonthIndex: monthData.monthIndex
                        calendarCells: monthData.cells
                        weekdayLabels: root.weekdayLabels
                        
                        textColor: root.textColor
                        accentColor: root.accentColor
                        completedColor: root.completedColor
                    }
                }
            }
        }
    }
}
