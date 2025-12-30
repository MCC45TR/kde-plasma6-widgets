import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2

ColumnLayout {
    id: eventsRoot
    spacing: 10

    property var eventsModel: []
    property int extraEventsCount: 0
    property color accentColor: "#d71921"
    property string titleFont: "Sans Serif"
    property string bodyFont: "Sans Serif"
    property color textColor: "white"
    property bool isHorizontalLayout: false // false: 1x2 (Side), true: 2x2 (Bottom Wide)

    // Header
    // Header (Side Mode Only)
    Text {
        visible: !isHorizontalLayout
        text: "Etkinlikler"
        font.family: titleFont 
        font.pixelSize: 14
        font.weight: Font.Bold
        font.letterSpacing: 2
        color: Qt.alpha(eventsRoot.textColor, 0.3) 
        Layout.alignment: Qt.AlignLeft
    }

    // Events List
    ColumnLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 6

        Repeater {
            model: eventsModel
            delegate: Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.max(20, eventTitleText.contentHeight + 20) // Dinamik yükseklik: min 20px (Saat/Dakika sığması için)
                radius: 10
                color: eventsRoot.accentColor

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 6
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 12

                    // Time Column 
                    // Side Mode: Stacked (Hour top, Minute bottom)
                    Column {
                        visible: !isHorizontalLayout || eventTitleText.lineCount > 1
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 2 

                        // Start Hour
                        Text {
                            text: modelData.startTime.split(":")[0] 
                            color: "white"
                            font.family: titleFont
                            font.pixelSize: 18
                            font.weight: Font.Normal
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                        // Start Minute
                        Text {
                            text: (modelData.startTime.indexOf(":") !== -1) ? modelData.startTime.split(":")[1] : "00" 
                            color: Qt.alpha("white", 0.7) 
                            font.family: titleFont
                            font.pixelSize: 18
                            font.weight: Font.Normal
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }
                    
                    // Wide Mode: Horizontal (HH:MM)
                    Text {
                        visible: isHorizontalLayout && eventTitleText.lineCount <= 1
                        Layout.alignment: Qt.AlignVCenter
                        text: modelData.startTime
                        color: "white"
                        font.family: titleFont
                        font.pixelSize: 22 // Same as original hours
                        font.weight: Font.Normal
                    }

                    // Text Column
                    Text {
                        id: eventTitleText
                        Layout.fillWidth: true
                        Layout.preferredWidth: 0 
                        // Layout.fillHeight: true // Removed to allow contentHeight to drive parent height
                        text: modelData.title
                        color: "white"
                        font.family: bodyFont
                        font.pixelSize: 12
                        wrapMode: Text.WordWrap
                        elide: Text.ElideRight
                        maximumLineCount: 3
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }
        }
        
        // Placeholder if no events
        Text {
            visible: eventsModel.length === 0
            Layout.fillWidth: true
            Layout.fillHeight: true
            font.family: titleFont 
            text: "Bugün için bir etkinlik\nkaydı yok"
            font.pixelSize: 14
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            Layout.alignment: Qt.AlignCenter
            color: Qt.alpha(eventsRoot.textColor, 0.5)
        }
    }

    // "+X Etkinlik Daha" Button (Side Mode)
    Rectangle {
        visible: extraEventsCount > 0 && !isHorizontalLayout
        Layout.preferredWidth: extraEventsText.contentWidth + 30
        Layout.preferredHeight: 30
        radius: 10
        color: eventsRoot.accentColor

        Text {
            id: extraEventsText
            anchors.centerIn: parent
            text: "+" + extraEventsCount + " Etkinlik Daha Var"
            color: "white"
            font.family: titleFont
            font.pixelSize: 12
        }
    }
    
    // Wide Mode Footer Area ("+X More" Left, "Etkinlikler" Right)
    RowLayout {
        visible: isHorizontalLayout
        Layout.fillWidth: true
        Layout.preferredHeight: 40
        
        // Actually, let's just make the button.
        Rectangle {
             visible: extraEventsCount > 0
             Layout.preferredWidth: extraEventsTextWide.contentWidth + 20
             Layout.preferredHeight: 30
             radius: 10
             color: eventsRoot.accentColor
             
             Text {
                id: extraEventsTextWide
                anchors.centerIn: parent
                text: "+" + extraEventsCount + " Etkinlik Daha Var"
                color: "white"
                font.family: titleFont
                font.pixelSize: 12
             }
        }
        
        Item { Layout.fillWidth: true } // Spacer
        
        // Large Italic "Etkinlikler" Label
        Text {
            visible: eventsModel.length > 0
            text: "Etkinlikler"
            font.family: titleFont
            font.pixelSize: 28 // Larger
            font.italic: true
            font.weight: Font.Normal
            color: Qt.alpha(eventsRoot.textColor, 0.2)
            Layout.alignment: Qt.AlignBottom
        }
    }

    // Spacer to push content up
    Item {
        Layout.fillHeight: true
    }
}
