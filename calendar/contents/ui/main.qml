import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore

PlasmoidItem {
    id: root

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    preferredRepresentation: fullRepresentation

    // Load fonts
    FontLoader {
        id: ndotFont
        source: "../fonts/ndot.ttf"
    }
    FontLoader {
        id: ntypeFont
        source: "../fonts/ntype82-regular.otf"
    }
    FontLoader {
        id: robotoFont
        source: "../fonts/roboto.ttf"
    }

    // Renkler - KDE Plasma Theme entegrasyonu
    property color bgColor: PlasmaCore.Theme.backgroundColor
    property color textColor: PlasmaCore.Theme.textColor
    property color accentColor: PlasmaCore.Theme.highlightColor
    property color completedColor: Qt.alpha(PlasmaCore.Theme.textColor, 0.5)
    property color separatorColor: Qt.alpha(PlasmaCore.Theme.textColor, 0.2)
    
    // Takvim Verileri Helpers
    property var today: new Date()
    property var selectedDate: null // Nullable for toggle state

    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: {
            today = new Date()
            // SwipeView içindeki sayfalar binding ile güncellenecek
        }
    }

    function getCalendarData(monthOffset) {
        var targetDate = new Date(today.getFullYear(), today.getMonth() + monthOffset, 1)
        var displayYear = targetDate.getFullYear()
        var displayMonth = targetDate.getMonth()
        var label = Qt.locale().monthName(displayMonth).toUpperCase()

        var cells = []
        var firstOfMonth = new Date(displayYear, displayMonth, 1)
        var firstDayOfWeek = Qt.locale().firstDayOfWeek
        // JS Date.getDay(): 0=Sun, 1=Mon, ..., 6=Sat
        // Qt firstDayOfWeek: 0=Sun, 1=Mon, ..., 6=Sat
        
        // Calculate offset based on first day of week
        var currentDayNameIndex = firstOfMonth.getDay() // 0-6 (Sun-Sat)
        var startDay = (currentDayNameIndex - firstDayOfWeek + 7) % 7
        
        var daysInMonth = new Date(displayYear, displayMonth + 1, 0).getDate()

        // Previous month days
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

        // Days of month
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

        // Fill remaining grid to keep 7 columns
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


    fullRepresentation: Item {
        Layout.preferredWidth: 400
        Layout.preferredHeight: 240
        Layout.minimumWidth: 200
        Layout.minimumHeight: 200
        Layout.maximumWidth: 400
        Layout.maximumHeight: 420
        
        Layout.fillWidth: true 
        Layout.fillHeight: true

        Rectangle {
            id: background
            anchors.fill: parent
            radius: 20
            anchors.margins: 10
            color: root.bgColor
            opacity: 1
            
            // Görünüm Modunu Belirle
            readonly property bool showTwoColumns: width >= 380
            readonly property bool showTwoRows: height > 350

            // Calendar 2 Visibility: Show if 2 Columns
            readonly property bool showSecondCalendar: showTwoColumns
            
            // Grid Capacity for paging
            readonly property int gridCapacity: (showSecondCalendar ? 2 : 1) * (showTwoRows ? 2 : 1)

            // --- SWIPE VIEW (SAYFALAMA) ---
            QQC2.SwipeView {
                id: swipeView
                anchors.fill: parent
                // Arkaplanın marginlerine göre içerik de marginli olsun ancak
                // clip parent'ta yapıldığı için burada padding verelim.
                topPadding: 17
                bottomPadding: 17
                leftPadding: 17
                rightPadding: 17
                
                clip: true
                orientation: Qt.Vertical
                currentIndex: 6 // 0. index = -6. ay. 6. index = 0. ay (Bugün)
                spacing: 60 // Sayfalar arası boşluk

                // -6 aydan +12 aya kadar toplam 19 sayfa
                Repeater {
                    model: 19
                    Item {
                        id: pageItem
                        // SwipeView elemanı olarak sayfa
                        // Her sayfa kendi offsetini hesaplar
                        property int baseOffset: (index - 6) * background.gridCapacity
                        
                        property var month1: root.getCalendarData(baseOffset)
                        property var month2: root.getCalendarData(baseOffset + 1)
                        // Month 3:
                        // Normal 2x2: offset + 2
                        // 2x2 Events: Not shown (Events View) - but strictly speaking we don't need it.
                        // Side Events: Not shown.
                        property var month3: root.getCalendarData(baseOffset + (background.showSecondCalendar ? 2 : 1))
                        property var month4: root.getCalendarData(baseOffset + (background.showSecondCalendar ? 3 : 2))

                        ColumnLayout {
                            anchors.fill: parent
                            spacing: 5 

                            // --- 1. SATIR (Month 1 & Month 2) ---
                            RowLayout {
                                Layout.fillWidth: true
                                Layout.fillHeight: !background.isWideEventsMode
                                Layout.preferredHeight: background.isWideEventsMode ? (background.extraEventsCount > 0 ? 160 : 200) : 1
                                spacing: 10

                                // Cal 1
                                CalendarView {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    Layout.preferredWidth: 1
                                    Layout.preferredHeight: 1
                                    
                                    monthLabel: pageItem.month1.label
                                    titleFont: "Roboto Condensed"
                                    displayYear: pageItem.month1.year
                                    currentMonthIndex: pageItem.month1.monthIndex
                                    calendarCells: pageItem.month1.cells
                                    textColor: root.textColor
                                    accentColor: root.accentColor
                                    completedColor: root.completedColor
                                    selectedDate: root.selectedDate
                                    onDateSelected: (date) => {
                                        if (root.selectedDate && date.getTime() === root.selectedDate.getTime()) {
                                            root.selectedDate = null
                                        } else {
                                            root.selectedDate = date
                                        }
                                    }
                                }

                                // Dikey Ayırıcı (Calendar 1 ile Calendar 2 arasında)
                                Rectangle {
                                    visible: background.showSecondCalendar
                                    Layout.fillHeight: true
                                    width: 1
                                    color: root.separatorColor
                                }

                                // Cal 2
                                CalendarView {
                                    visible: background.showSecondCalendar
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    Layout.preferredWidth: 1
                                    Layout.preferredHeight: 1
                                    
                                    monthLabel: pageItem.month2.label
                                    titleFont: "Roboto Condensed"
                                    displayYear: pageItem.month2.year
                                    currentMonthIndex: pageItem.month2.monthIndex
                                    calendarCells: pageItem.month2.cells
                                    textColor: root.textColor
                                    accentColor: root.accentColor
                                    completedColor: root.completedColor
                                    selectedDate: root.selectedDate
                                    onDateSelected: (date) => {
                                        if (root.selectedDate && date.getTime() === root.selectedDate.getTime()) {
                                            root.selectedDate = null
                                        } else {
                                            root.selectedDate = date
                                        }
                                    }
                                }
                            }

                            // --- YATAY AYIRICI ---
                            RowLayout {
                                visible: background.showTwoRows
                                Layout.fillWidth: true
                                height: 1
                                spacing: 20
                                Layout.preferredHeight: 0 // Minimal height

                                // Sol Çizgi
                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredWidth: 1
                                    height: 1
                                    color: root.separatorColor
                                }

                                // Orta Boşluk (Dikey çizgi hizası)
                                Rectangle {
                                    visible: background.showTwoColumns
                                    width: 1
                                    height: 1
                                    color: "transparent"
                                }

                                // Sağ Çizgi
                                Rectangle {
                                    visible: background.showTwoColumns
                                    Layout.fillWidth: true
                                    Layout.preferredWidth: 1
                                    height: 1
                                    color: root.separatorColor
                                }
                            }

                            // --- 2. SATIR (Month 3 & Month 4) ---
                            RowLayout {
                                visible: background.showTwoRows && !background.isWideEventsMode
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                Layout.preferredHeight: 1 // Weight 1 if visible
                                spacing: 20

                                // Cal 3
                                CalendarView {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    Layout.preferredWidth: 1
                                    Layout.preferredHeight: 1

                                    monthLabel: pageItem.month3.label
                                    titleFont: "Roboto Condensed"
                                    displayYear: pageItem.month3.year
                                    currentMonthIndex: pageItem.month3.monthIndex
                                    calendarCells: pageItem.month3.cells
                                    textColor: root.textColor
                                    accentColor: root.accentColor
                                    completedColor: root.completedColor
                                    selectedDate: root.selectedDate
                                    onDateSelected: (date) => {
                                        if (root.selectedDate && date.getTime() === root.selectedDate.getTime()) {
                                            root.selectedDate = null
                                        } else {
                                            root.selectedDate = date
                                        }
                                    }
                                }

                                // Dikey Ayırıcı 2
                                Rectangle {
                                    visible: background.showTwoColumns
                                    Layout.fillHeight: true
                                    width: 1
                                    color: root.separatorColor
                                }

                                // Cal 4
                                CalendarView {
                                    visible: background.showSecondCalendar
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    Layout.preferredWidth: 1
                                    Layout.preferredHeight: 1

                                    monthLabel: pageItem.month4.label
                                    titleFont: "Roboto Condensed"
                                    displayYear: pageItem.month4.year
                                    currentMonthIndex: pageItem.month4.monthIndex
                                    calendarCells: pageItem.month4.cells
                                    textColor: root.textColor
                                    accentColor: root.accentColor
                                    completedColor: root.completedColor
                                    selectedDate: root.selectedDate
                                    onDateSelected: (date) => {
                                        if (root.selectedDate && date.getTime() === root.selectedDate.getTime()) {
                                            root.selectedDate = null
                                        } else {
                                            root.selectedDate = date
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Mouse wheel support for page navigation
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.NoButton
                z: 5
                onWheel: (wheel) => {
                    if (wheel.angleDelta.y < 0) {
                        swipeView.incrementCurrentIndex()
                    } else if (wheel.angleDelta.y > 0) {
                        swipeView.decrementCurrentIndex()
                    }
                }
            }
        // --- BUGÜN BUTTON ---
            Rectangle {
                id: todayButton
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.topMargin: 10
                anchors.rightMargin: 15
                width: todayText.contentWidth + 16
                height: 26
                radius: 6
                color: root.accentColor
                z: 100 // Üstte kalmasını sağlar
                
                // Bugün sayfasındaysak (index 6) gizle, değilse göster
                opacity: swipeView.currentIndex === 6 ? 0 : 1
                visible: opacity > 0 // Görünmezken tıklamayı engelle (optional optimization)
                
                Behavior on opacity {
                    NumberAnimation { duration: 350 }
                }

                Text {
                    id: todayText
                    anchors.centerIn: parent
                    text: "BUGÜN"
                    font.family: "Sans Serif"
                    font.pixelSize: 11
                    font.weight: Font.Bold
                    color: root.textColor
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.selectedDate = null // Clear selection
                        swipeView.currentIndex = 6 // Index 6 is "Bugün" (offset 0)
                    }
                }
            }
        }
    }
}
