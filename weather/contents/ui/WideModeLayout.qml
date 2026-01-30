import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

RowLayout {
    id: wideLayout
    spacing: 8

    required property var weatherRoot

    property var currentWeather: weatherRoot.currentWeather
    property var forecastDaily: weatherRoot.forecastDaily
    property var forecastHourly: weatherRoot.forecastHourly
    property bool forecastMode: weatherRoot.forecastMode
    property string location: weatherRoot.location

    function getWeatherIcon(item) { return weatherRoot.getWeatherIcon(item) }
    function getLocalizedDay(day) { return weatherRoot.getLocalizedDay(day) }

    Rectangle {
        id: currentSection
        property bool isExpanded: false

        readonly property real normalWidth: contentLayout.implicitWidth + 20
        readonly property real normalHeight: wideLayout.height
        readonly property real expandedWidth: wideLayout.width
        readonly property real expandedHeight: wideLayout.height

        Layout.fillHeight: !isExpanded
        Layout.preferredWidth: isExpanded ? expandedWidth : normalWidth
        Layout.preferredHeight: isExpanded ? expandedHeight : -1
        z: isExpanded ? 100 : 0
        radius: (isExpanded ? 15 : 10) * weatherRoot.radiusMultiplier
        color: weatherRoot.showInnerBackgrounds ? Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.1) : "transparent"

        Timer {
            id: autoCloseTimer
            interval: 5000
            onTriggered: if (currentSection.isExpanded) currentSection.isExpanded = false
        }

        Behavior on Layout.preferredWidth { NumberAnimation { duration: 200; easing.type: Easing.InOutQuad } }
        Behavior on radius { NumberAnimation { duration: 200; easing.type: Easing.InOutQuad } }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                currentSection.isExpanded = !currentSection.isExpanded
                currentSection.isExpanded ? autoCloseTimer.restart() : autoCloseTimer.stop()
            }
            onEntered: if (currentSection.isExpanded) autoCloseTimer.stop()
            onExited: if (currentSection.isExpanded) autoCloseTimer.restart()
        }

        ColumnLayout {
            id: contentLayout
            anchors.fill: parent
            anchors.margins: 10
            spacing: 2
            visible: !currentSection.isExpanded
            opacity: currentSection.isExpanded ? 0 : 1
            Behavior on opacity { NumberAnimation { duration: 150 } }

            Item { Layout.fillHeight: true }

            Kirigami.Icon {
                source: getWeatherIcon(currentWeather)
                readonly property real availableHeight: parent.height
                Layout.preferredHeight: conditionText.lineCount > 1 ? availableHeight * 0.2 : availableHeight * 0.25
                Layout.preferredWidth: Layout.preferredHeight
                Layout.alignment: Qt.AlignHCenter
                isMask: false
                smooth: true
            }

            Text {
                id: conditionText
                text: currentWeather ? i18n(currentWeather.condition) : ""
                color: Kirigami.Theme.textColor
                opacity: 0.8
                font.family: weatherRoot.activeFont.family
                font.pixelSize: Math.max(10, Math.min(14, wideLayout.height * 0.08))
                Layout.alignment: Qt.AlignHCenter
                wrapMode: Text.WordWrap
                Layout.maximumWidth: parent.width - 10
                horizontalAlignment: Text.AlignHCenter
                maximumLineCount: 2
                elide: Text.ElideRight
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 0
                Text {
                    text: currentWeather ? currentWeather.temp : "--"
                    color: Kirigami.Theme.textColor
                    font.family: weatherRoot.activeFont.family
                    font.bold: true
                    font.pixelSize: conditionText.lineCount > 1 ? wideLayout.height * 0.2 : wideLayout.height * 0.25
                }
                Text {
                    text: "°"
                    color: Kirigami.Theme.textColor
                    font.family: weatherRoot.activeFont.family
                    font.bold: true
                    font.pixelSize: conditionText.lineCount > 1 ? wideLayout.height * 0.15 : wideLayout.height * 0.18
                    Layout.alignment: Qt.AlignTop
                    Layout.topMargin: wideLayout.height * 0.01
                }
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 8
                RowLayout {
                    spacing: 1
                    Text { text: "▲"; color: Kirigami.Theme.positiveTextColor; font.pixelSize: Math.max(9, Math.min(12, wideLayout.height * 0.07)); font.bold: true }
                    Text { text: currentWeather ? currentWeather.temp_max + "°" : "--"; color: Kirigami.Theme.textColor; font.pixelSize: Math.max(9, Math.min(12, wideLayout.height * 0.07)); font.bold: true }
                }
                RowLayout {
                    spacing: 1
                    Text { text: "▼"; color: Kirigami.Theme.negativeTextColor; font.pixelSize: Math.max(9, Math.min(12, wideLayout.height * 0.07)); font.bold: true }
                    Text { text: currentWeather ? currentWeather.temp_min + "°" : "--"; color: Kirigami.Theme.textColor; font.pixelSize: Math.max(9, Math.min(12, wideLayout.height * 0.07)); font.bold: true }
                }
            }

            Item { Layout.fillHeight: true }
        }

        Flickable {
            id: expandedFlickable
            anchors.fill: parent
            anchors.margins: 10
            visible: currentSection.isExpanded
            opacity: currentSection.isExpanded ? 1 : 0
            contentWidth: width
            contentHeight: expandedContent.height
            clip: true
            flickableDirection: Flickable.VerticalFlick
            boundsBehavior: Flickable.StopAtBounds

            Behavior on opacity { NumberAnimation { duration: 150 } }
            ScrollBar.vertical: ScrollBar { policy: expandedContent.height > expandedFlickable.height ? ScrollBar.AlwaysOn : ScrollBar.AlwaysOff; width: 6 }

            WheelHandler {
                target: expandedFlickable
                orientation: Qt.Vertical
                acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                onWheel: (wheel) => {
                    expandedFlickable.contentY -= wheel.angleDelta.y * 0.5
                    expandedFlickable.contentY = Math.max(0, Math.min(expandedFlickable.contentY, expandedFlickable.contentHeight - expandedFlickable.height))
                }
            }

            MouseArea {
                anchors.fill: parent
                propagateComposedEvents: true
                onClicked: { currentSection.isExpanded = false; autoCloseTimer.stop() }
            }

            WeatherDetailsView {
                id: expandedContent
                width: expandedFlickable.width
                weatherRoot: wideLayout.weatherRoot
            }
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.preferredWidth: wideLayout.width * 0.55
        Layout.minimumWidth: 150
        spacing: 4
        clip: true

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Text {
                text: currentWeather ? currentWeather.location : location
                color: Kirigami.Theme.textColor
                font.family: weatherRoot.activeFont.family
                font.bold: true
                font.pixelSize: Math.min(22, wideLayout.width * 0.09)
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Rectangle {
                Layout.alignment: Qt.AlignRight | Qt.AlignTop
                Layout.preferredWidth: toggleText.implicitWidth + 24
                Layout.preferredHeight: 28
                radius: 14 * weatherRoot.radiusMultiplier
                color: weatherRoot.showInnerBackgrounds ? Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.1) : "transparent"

                Text {
                    id: toggleText
                    anchors.centerIn: parent
                    text: forecastMode ? i18n("Hourly Forecast") : i18n("Daily Forecast")
                    color: Kirigami.Theme.textColor
                    font.family: weatherRoot.activeFont.family
                    font.pixelSize: 11
                    font.bold: true
                }

                MouseArea {
                    id: toggleMouseArea
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: weatherRoot.forecastMode = !weatherRoot.forecastMode
                }

                Rectangle {
                    anchors.fill: parent
                    color: Kirigami.Theme.highlightColor
                    opacity: toggleMouseArea.containsMouse ? 0.1 : 0
                    radius: parent.radius
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                }
            }
        }

        GridView {
            id: forecastGrid
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: 80
            clip: true

            readonly property real minCardWidth: 70
            readonly property real minCardHeight: 100
            readonly property int cardsPerRow: Math.max(1, Math.floor(width / minCardWidth))
            readonly property int visibleRows: Math.max(1, Math.floor(height / minCardHeight))
            readonly property real actualCardWidth: width / cardsPerRow
            readonly property real actualCardHeight: height / visibleRows

            cellWidth: actualCardWidth
            cellHeight: actualCardHeight
            snapMode: GridView.SnapToRow
            boundsBehavior: Flickable.StopAtBounds
            flow: GridView.FlowLeftToRight

            model: forecastMode ? forecastHourly : forecastDaily

            delegate: ForecastItem {
                required property var modelData
                required property int index

                width: forecastGrid.cellWidth - 4
                height: forecastGrid.cellHeight - 4

                label: forecastMode ? modelData.time : getLocalizedDay(modelData.day)
                iconPath: getWeatherIcon(modelData)
                temp: modelData.temp
                isHourly: forecastMode
                units: weatherRoot.units
                showUnits: weatherRoot.showForecastUnits
                fontFamily: weatherRoot.activeFont.family
                showBackground: weatherRoot.showInnerBackgrounds

                readonly property int cols: Math.max(1, Math.floor(forecastGrid.width / forecastGrid.cellWidth))
                readonly property int row: Math.floor(index / cols)
                readonly property int col: index % cols
                readonly property int totalRows: Math.ceil(forecastGrid.count / cols)

                radiusTL: ((row === 0 && col === 0) ? 24 : 10) * weatherRoot.radiusMultiplier
                radiusTR: ((row === 0 && (col === cols - 1 || index === forecastGrid.count - 1)) ? 24 : 10) * weatherRoot.radiusMultiplier
                radiusBL: ((row === totalRows - 1 && col === 0) ? 24 : 10) * weatherRoot.radiusMultiplier
                radiusBR: ((row === totalRows - 1 && (col === cols - 1 || index === forecastGrid.count - 1)) ? 24 : 10) * weatherRoot.radiusMultiplier
            }
        }
    }
}
