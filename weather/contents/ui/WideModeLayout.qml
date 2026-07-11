import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Item {
    id: wideLayoutContainer
    
    required property var weatherRoot

    property var currentWeather: weatherRoot.currentWeather
    property var forecastDaily: weatherRoot.forecastDaily
    property var forecastHourly: weatherRoot.forecastHourly
    property bool forecastMode: weatherRoot.forecastMode
    property string location: weatherRoot.location

    function getWeatherIcon(item) { return weatherRoot.getWeatherIcon(item) }
    function getLocalizedDay(day) { return weatherRoot.getLocalizedDay(day) }

    clip: true

    RowLayout {
        id: wideLayout
        anchors.fill: parent
        spacing: 8
        
        opacity: weatherRoot.showForecastDetails ? 0 : 1
        Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutQuad } }
        
        transform: Translate {
            y: weatherRoot.showForecastDetails ? -wideLayoutContainer.height : 0
            Behavior on y { NumberAnimation { duration: 350; easing.type: Easing.InOutQuart } }
        }

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
                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AlwaysOff; width: 0 }

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
                    weatherRoot: wideLayoutContainer.weatherRoot
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

            DailyForecastView {
                id: forecastGrid
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumHeight: 80

                weatherRoot: wideLayoutContainer.weatherRoot
                isHourly: forecastMode
                showUnits: weatherRoot.showForecastUnits
                showBackground: weatherRoot.showInnerBackgrounds
                cornerRadius: 24 * weatherRoot.radiusMultiplier
                itemSpacing: 4
                edgeMargins: 0

                readonly property real minCardWidth: 70
                readonly property real minCardHeight: 100
                readonly property int cardsPerRow: Math.max(1, Math.floor(width / minCardWidth))
                readonly property int visibleRows: Math.max(1, Math.floor(height / minCardHeight))

                cellWidth: width / cardsPerRow
                cellHeight: height / visibleRows
                flow: GridView.FlowLeftToRight

                onItemClicked: function(data, idx, cardRect) {
                    if (!forecastMode) {
                        if (idx === 0) {
                            currentSection.isExpanded = true
                            autoCloseTimer.restart()
                        } else if (data.hasDetails) {
                            weatherRoot.selectedForecast = data
                            weatherRoot.showForecastDetails = true
                        }
                    }
                }
            }
        }
    }

    Rectangle {
        id: forecastDetailsOverlay
        width: parent.width
        height: parent.height
        radius: 20 * weatherRoot.radiusMultiplier
        color: Qt.rgba(Kirigami.Theme.backgroundColor.r, Kirigami.Theme.backgroundColor.g, Kirigami.Theme.backgroundColor.b, weatherRoot.backgroundOpacity)
        z: 200
        clip: true

        transform: Translate {
            y: weatherRoot.showForecastDetails ? 0 : wideLayoutContainer.height
            Behavior on y { NumberAnimation { duration: 350; easing.type: Easing.InOutQuart } }
        }

        Timer {
            id: overlayAutoCloseTimer
            interval: 5000
            repeat: false
            onTriggered: weatherRoot.showForecastDetails = false
        }

        Connections {
            target: weatherRoot
            function onShowForecastDetailsChanged() {
                if (weatherRoot.showForecastDetails) {
                    overlayAutoCloseTimer.restart()
                } else {
                    overlayAutoCloseTimer.stop()
                }
            }
        }

        // Opacity of content: fade in slightly later
        property real contentOpacity: weatherRoot.showForecastDetails ? 1 : 0
        Behavior on contentOpacity { NumberAnimation { duration: 300; easing.type: Easing.OutQuad } }

        // Hover Listener for auto-close timer
        MouseArea {
            anchors.fill: parent
            z: 1000
            hoverEnabled: true
            propagateComposedEvents: true
            onPressed: (mouse) => mouse.accepted = false
            onWheel: (wheel) => wheel.accepted = false
            onEntered: overlayAutoCloseTimer.stop()
            onExited: if (weatherRoot.showForecastDetails) overlayAutoCloseTimer.restart()
        }

        // Background Click Listener (fallback if Flickable doesn't cover everything)
        MouseArea {
            anchors.fill: parent
            onClicked: weatherRoot.showForecastDetails = false
            z: -1
        }

        Flickable {
            id: forecastFlickable
            anchors.fill: parent
            contentWidth: width
            contentHeight: Math.max(forecastDetailsContent.height, height)
            clip: true
            flickableDirection: Flickable.VerticalFlick
            boundsBehavior: Flickable.StopAtBounds
            opacity: forecastDetailsOverlay.contentOpacity

            ScrollBar.vertical: ScrollBar { policy: forecastDetailsContent.height > parent.height ? ScrollBar.AlwaysOn : ScrollBar.AlwaysOff; width: 6 }

            Item {
                width: parent.width
                height: forecastFlickable.contentHeight
                
                // Click listener for empty space in Flickable
                MouseArea {
                    anchors.fill: parent
                    onClicked: weatherRoot.showForecastDetails = false
                }

                // Swallow clicks on content
                MouseArea {
                    anchors.fill: forecastDetailsContent
                    onClicked: {}
                }

                ForecastDetailsView {
                    id: forecastDetailsContent
                    width: parent.width
                    weatherRoot: wideLayoutContainer.weatherRoot
                    forecastData: weatherRoot.selectedForecast
                }
            }
        }
    }
}
