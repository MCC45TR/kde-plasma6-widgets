import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    preferredRepresentation: (Plasmoid.formFactor === PlasmaCore.Types.Horizontal || Plasmoid.formFactor === PlasmaCore.Types.Vertical) 
                           ? compactRepresentation 
                           : fullRepresentation

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

    // Renkler - Kirigami Theme entegrasyonu (NoBackground modunda doğru çalışır)
    property color bgColor: Kirigami.Theme.backgroundColor
    property color textColor: Kirigami.Theme.textColor
    property color accentColor: Kirigami.Theme.highlightColor
    property color highlightedTextColor: Kirigami.Theme.highlightedTextColor
    property color completedColor: Qt.alpha(Kirigami.Theme.textColor, 0.5)
    property color separatorColor: Qt.alpha(Kirigami.Theme.textColor, 0.2)
    
    // Panel Clock Configuration
    readonly property bool cfg_showSeconds: Plasmoid.configuration.showSeconds || false
    readonly property int cfg_timeFormatInfo: Plasmoid.configuration.timeFormat || 0
    readonly property int cfg_dateFormatInfo: Plasmoid.configuration.dateFormat || 0
    
    // Weekday labels - bir kez hesaplanır, CalendarView'lara iletilir
    property var weekdayLabels: {
        var labels = []
        var firstDay = Qt.locale().firstDayOfWeek
        for (var i = 0; i < 7; ++i) {
            labels.push(Qt.locale().dayName((firstDay + i) % 7, 2))
        }
        return labels
    }
    
    // Tarih seçimi toggle fonksiyonu
    function toggleDateSelection(date) {
        if (selectedDate && date.getTime() === selectedDate.getTime()) {
            selectedDate = null
        } else {
            selectedDate = date
        }
    }
    
    // Takvim Verileri Helpers
    property var today: new Date()
    property var selectedDate: null // Nullable for toggle state


    
    Timer {
        interval: root.cfg_showSeconds ? 1000 : 60000
        running: true
        repeat: true
        onTriggered: {
            today = new Date()
        }
    }

    function getFormattedTime() {
        var fmt = ""
        if (root.cfg_timeFormatInfo === 1) { // 12h
            fmt = root.cfg_showSeconds ? "hh:mm:ss AP" : "hh:mm AP"
        } else if (root.cfg_timeFormatInfo === 2) { // 24h
            fmt = root.cfg_showSeconds ? "HH:mm:ss" : "HH:mm"
        } else {
            // System Default
            fmt = Qt.locale().timeFormat(root.cfg_showSeconds ? Locale.LongFormat : Locale.ShortFormat)
        }
        return Qt.formatDateTime(today, fmt)
    }

    function getFormattedDate() {
        if (root.cfg_dateFormatInfo === 1) return Qt.formatDateTime(today, "dd.MM.yyyy")
        if (root.cfg_dateFormatInfo === 2) return Qt.formatDateTime(today, "dd/MM/yyyy")
        if (root.cfg_dateFormatInfo === 3) return Qt.formatDateTime(today, "yyyy-MM-dd")
        return Qt.formatDateTime(today, Qt.locale().dateFormat(Locale.ShortFormat))
    }

    function getCalendarData(monthOffset) {
        var targetDate = new Date(today.getFullYear(), today.getMonth() + monthOffset, 1)
        var displayYear = targetDate.getFullYear()
        var displayMonth = targetDate.getMonth()
        var label = Qt.locale().monthName(displayMonth).toLocaleUpperCase(Qt.locale().name)

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

    compactRepresentation: Item {
        id: compactRep
        
        // Fill the available panel height.
        Layout.preferredHeight: root.height
        Layout.fillHeight: true
        Layout.preferredWidth: Math.max(timeText.implicitWidth, dateText.implicitWidth) + 16
        
        Column {
            anchors.centerIn: parent
            spacing: -2
            
            Text {
                id: timeText
                text: root.getFormattedTime()
                font.family: robotoFont.name
                font.bold: true
                font.pixelSize: Math.round(compactRep.height * 0.52)
                color: root.textColor
                anchors.horizontalCenter: parent.horizontalCenter
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                renderType: Text.NativeRendering
            }
            Text {
                id: dateText
                text: root.getFormattedDate()
                font.family: robotoFont.name
                font.pixelSize: Math.round(compactRep.height * 0.33)
                color: Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.8)
                anchors.horizontalCenter: parent.horizontalCenter
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                renderType: Text.NativeRendering
            }
        }
        
        MouseArea {
            anchors.fill: parent
            onClicked: root.expanded = !root.expanded
        }
    }

    fullRepresentation: Item {
        id: fullRepItem
        readonly property double fontScale: Plasmoid.configuration.widgetScale > 0 ? Plasmoid.configuration.widgetScale : 1.0

        Layout.preferredWidth: Math.round(200 * fontScale)
        Layout.preferredHeight: Math.round(200 * fontScale)
        Layout.minimumWidth: Math.round(180 * fontScale)
        Layout.minimumHeight: Math.round(180 * fontScale)
        Layout.maximumWidth: Math.round(400 * fontScale)
        Layout.maximumHeight: Math.round(400 * fontScale)

        Layout.fillWidth: true
        Layout.fillHeight: true

        // Compute corner radius from mode string (mirrors weather widget logic)
        readonly property real computedRadius: {
            var mode = Plasmoid.configuration.cornerRadius || "normal"
            if (mode === "square") return 0
            if (mode === "small")  return 8
            return 20 // "normal"
        }

        // Compute background opacity:
        // -1.0 ("No Backgrounds") -> full transparent (alpha 0), content stays visible
        readonly property double bgOpacity: {
            var op = Plasmoid.configuration.backgroundOpacity
            if (op === -1.0) return 0.0
            return (op !== undefined) ? op : 1.0
        }

        Rectangle {
            id: background
            anchors.fill: parent
            radius: parent.computedRadius
            anchors.margins: Math.round((Plasmoid.configuration.edgeMargin !== undefined ? Plasmoid.configuration.edgeMargin : 10) * fullRepItem.fontScale)
            color: Qt.rgba(root.bgColor.r, root.bgColor.g, root.bgColor.b, parent.bgOpacity)
            
            // Görünüm Modunu Belirle (eşikler scale ile büyür)
            readonly property bool showTwoColumns: width >= Math.round(380 * fullRepItem.fontScale)
            readonly property bool showTwoRows: height > Math.round(350 * fullRepItem.fontScale)

            // Calendar 2 Visibility: Show if 2 Columns
            readonly property bool showSecondCalendar: showTwoColumns
            
            // Grid Capacity for paging
            readonly property int gridCapacity: (showSecondCalendar ? 2 : 1) * (showTwoRows ? 2 : 1)

            // --- SWIPE VIEW (SAYFALAMA) ---
            QQC2.SwipeView {
                id: swipeView
                anchors.fill: parent
                anchors.margins: Math.round((Plasmoid.configuration.contentPadding !== undefined ? Plasmoid.configuration.contentPadding : 10) * fullRepItem.fontScale)

                clip: true
                orientation: Qt.Vertical
                currentIndex: 6 // 0. index = -6. ay. 6. index = 0. ay (Bugün)
                spacing: Math.round(60 * fullRepItem.fontScale) // Sayfalar arası boşluk

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
                        property var month3: root.getCalendarData(baseOffset + (background.showSecondCalendar ? 2 : 1))
                        property var month4: root.getCalendarData(baseOffset + (background.showSecondCalendar ? 3 : 2))

                        ColumnLayout {
                            anchors.fill: parent
                            spacing: Math.round(5 * fullRepItem.fontScale)

                            // --- 1. SATIR (Month 1 & Month 2) ---
                            RowLayout {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                Layout.preferredHeight: 1
                                spacing: Math.round(10 * fullRepItem.fontScale)

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
                                    weekdayLabels: root.weekdayLabels
                                    fontScale: fullRepItem.fontScale
                                    textColor: root.textColor
                                    accentColor: root.accentColor
                                    highlightedTextColor: root.highlightedTextColor
                                    completedColor: root.completedColor
                                    selectedDate: root.selectedDate
                                    onDateSelected: (date) => root.toggleDateSelection(date)
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
                                    weekdayLabels: root.weekdayLabels
                                    fontScale: fullRepItem.fontScale
                                    textColor: root.textColor
                                    accentColor: root.accentColor
                                    highlightedTextColor: root.highlightedTextColor
                                    completedColor: root.completedColor
                                    selectedDate: root.selectedDate
                                    onDateSelected: (date) => root.toggleDateSelection(date)
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
                                visible: background.showTwoRows
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                Layout.preferredHeight: 1 // Weight 1 if visible
                                spacing: Math.round(20 * fullRepItem.fontScale)

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
                                    weekdayLabels: root.weekdayLabels
                                    fontScale: fullRepItem.fontScale
                                    textColor: root.textColor
                                    accentColor: root.accentColor
                                    highlightedTextColor: root.highlightedTextColor
                                    completedColor: root.completedColor
                                    selectedDate: root.selectedDate
                                    onDateSelected: (date) => root.toggleDateSelection(date)
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
                                    weekdayLabels: root.weekdayLabels
                                    fontScale: fullRepItem.fontScale
                                    textColor: root.textColor
                                    accentColor: root.accentColor
                                    highlightedTextColor: root.highlightedTextColor
                                    completedColor: root.completedColor
                                    selectedDate: root.selectedDate
                                    onDateSelected: (date) => root.toggleDateSelection(date)
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
                anchors.topMargin: Math.round(10 * fullRepItem.fontScale)
                anchors.rightMargin: Math.round(15 * fullRepItem.fontScale)
                width: todayText.contentWidth + Math.round(16 * fullRepItem.fontScale)
                height: Math.round(26 * fullRepItem.fontScale)
                radius: Math.round(6 * fullRepItem.fontScale)
                color: root.accentColor
                z: 100 // Üstte kalmasını sağlar

                // Bugün sayfasındaysak (index 6) gizle, değilse göster
                opacity: swipeView.currentIndex === 6 ? 0 : 1
                visible: opacity > 0 // Görünmezken tıklamayı engelle

                Behavior on opacity {
                    NumberAnimation { duration: 350 }
                }

                Text {
                    id: todayText
                    anchors.centerIn: parent
                    text: i18n("Today")
                    font.family: "Sans Serif"
                    font.pixelSize: Math.round(11 * fullRepItem.fontScale)
                    font.weight: Font.Bold
                    color: root.highlightedTextColor
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
