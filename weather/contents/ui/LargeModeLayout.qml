import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Item {
    id: largeLayout

    required property var weatherRoot

    readonly property real containerWidth: parent ? parent.width : 0
    readonly property real containerHeight: parent ? parent.height : 0

    property var currentWeather: weatherRoot.currentWeather
    property var forecastDaily: weatherRoot.forecastDaily
    property var forecastHourly: weatherRoot.forecastHourly
    property bool forecastMode: weatherRoot.forecastMode
    property bool largeDetailsOpen: weatherRoot.largeDetailsOpen
    property string location: weatherRoot.location

    function getWeatherIcon(item) { return weatherRoot.getWeatherIcon(item) }
    function getLocalizedDay(day) { return weatherRoot.getLocalizedDay(day) }

    Item {
        id: contentContainer
        anchors.fill: parent
        
        opacity: weatherRoot.showForecastDetails ? 0 : 1
        Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutQuad } }

        transform: Translate {
            y: weatherRoot.showForecastDetails ? -largeLayout.height : 0
            Behavior on y { NumberAnimation { duration: 350; easing.type: Easing.InOutQuart } }
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            Item {
                id: headerArea
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(largeLayout.height * 0.45, 200)

                readonly property real buttonsHeight: 38
                readonly property real iconMaxSize: Math.min(headerArea.height - buttonsHeight, headerArea.width * 0.4)

                Column {
                    id: leftInfoColumn
                    anchors.left: parent.left
                    anchors.top: parent.top
                    width: parent.width * 0.55
                    spacing: 2

                    Text {
                        text: currentWeather ? i18n(currentWeather.condition) : ""
                        color: Kirigami.Theme.textColor
                        font.family: weatherRoot.activeFont.family
                        font.pixelSize: Math.min(32, largeLayout.height * 0.08)
                        font.bold: true
                        elide: Text.ElideRight
                        width: parent.width
                    }

                    Text {
                        text: currentWeather ? currentWeather.location : location
                        color: Kirigami.Theme.textColor
                        font.family: weatherRoot.activeFont.family
                        font.pixelSize: Math.min(20, largeLayout.height * 0.05)
                        font.bold: true
                        opacity: 0.7
                        elide: Text.ElideRight
                        width: parent.width
                    }
                }

                Kirigami.Icon {
                    id: weatherIcon
                    anchors.right: parent.right
                    anchors.top: parent.top
                    width: Math.min(headerArea.iconMaxSize, parent.width * 0.45)
                    height: width
                    source: getWeatherIcon(currentWeather)
                    isMask: false
                    smooth: true
                }

                Text {
                    id: tempText
                    anchors.left: parent.left
                    anchors.bottom: parent.bottom
                    text: currentWeather ? currentWeather.temp + "°" : "--"
                    color: Kirigami.Theme.textColor
                    font.family: weatherRoot.activeFont.family
                    font.pixelSize: Math.min(100, largeLayout.height * 0.22)
                    font.bold: true
                    lineHeight: 0.85
                }

                Row {
                    id: headerButtons
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 4
                    spacing: 4

                    Rectangle {
                        id: detailsButton
                        width: detailsText.implicitWidth + 20
                        height: 28
                        radius: 14 * weatherRoot.radiusMultiplier
                        topRightRadius: 5
                        bottomRightRadius: 5
                        color: weatherRoot.showInnerBackgrounds ? Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.1) : "transparent"

                        Text {
                            id: detailsText
                            anchors.centerIn: parent
                            text: i18n("Details")
                            color: Kirigami.Theme.textColor
                            font.family: weatherRoot.activeFont.family
                            font.pixelSize: 12
                            font.bold: true
                        }

                        MouseArea {
                            id: detailsMouseArea
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                            onClicked: weatherRoot.largeDetailsOpen = true
                        }

                        Rectangle {
                            anchors.fill: parent
                            color: Kirigami.Theme.highlightColor
                            opacity: detailsMouseArea.containsMouse ? 0.1 : 0
                            radius: 14 * weatherRoot.radiusMultiplier
                            topRightRadius: 5
                            bottomRightRadius: 5
                            Behavior on opacity { NumberAnimation { duration: 150 } }
                        }
                    }

                    Rectangle {
                        width: toggleTextLarge.implicitWidth + 24
                        height: 28
                        radius: 14 * weatherRoot.radiusMultiplier
                        topLeftRadius: 5
                        bottomLeftRadius: 5
                        color: weatherRoot.showInnerBackgrounds ? Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.1) : "transparent"

                        Text {
                            id: toggleTextLarge
                            anchors.centerIn: parent
                            text: forecastMode ? i18n("Hourly Forecast") : i18n("Daily Forecast")
                            color: Kirigami.Theme.textColor
                            font.family: weatherRoot.activeFont.family
                            font.pixelSize: 12
                            font.bold: true
                        }

                        MouseArea {
                            id: toggleMouseAreaLarge
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                            onClicked: weatherRoot.forecastMode = !weatherRoot.forecastMode
                        }

                        Rectangle {
                            anchors.fill: parent
                            color: Kirigami.Theme.highlightColor
                            opacity: toggleMouseAreaLarge.containsMouse ? 0.1 : 0
                            radius: 14 * weatherRoot.radiusMultiplier
                            topLeftRadius: 5
                            bottomLeftRadius: 5
                            Behavior on opacity { NumberAnimation { duration: 150 } }
                        }
                    }
                }
            }

            GridView {
                id: largeForecastGrid
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                readonly property real minCardHeight: 100
                readonly property int visibleRows: Math.max(1, Math.floor(height / minCardHeight))
                cellHeight: height / visibleRows

                readonly property real minCardWidth: 70
                readonly property int cardsPerRow: Math.max(1, Math.floor(width / minCardWidth))
                cellWidth: width / cardsPerRow

                snapMode: GridView.SnapToRow
                boundsBehavior: Flickable.StopAtBounds
                flow: GridView.FlowLeftToRight

                model: forecastMode ? forecastHourly : forecastDaily

                delegate: ForecastItem {
                    required property var modelData
                    required property int index

                    width: largeForecastGrid.cellWidth - 4
                    height: largeForecastGrid.cellHeight - 4

                    label: forecastMode ? modelData.time : getLocalizedDay(modelData.day)
                    iconPath: getWeatherIcon(modelData)
                    temp: modelData.temp
                    isHourly: forecastMode
                    units: weatherRoot.units
                    showUnits: weatherRoot.showForecastUnits
                    fontFamily: weatherRoot.activeFont.family
                    showBackground: weatherRoot.showInnerBackgrounds
                    
                    forecastData: modelData
                    itemIndex: index
                    
                    onClicked: function(data, idx, cardRect) {
                        if (!forecastMode && idx > 0 && data.hasDetails) {
                            var globalPos = mapToItem(largeLayout, 0, 0)
                            weatherRoot.clickedCardRect = Qt.rect(globalPos.x, globalPos.y, width, height)
                            weatherRoot.selectedForecast = data
                            weatherRoot.showForecastDetails = true
                        }
                    }

                    radiusTL: 12 * weatherRoot.radiusMultiplier
                    radiusTR: 12 * weatherRoot.radiusMultiplier
                    radiusBL: 12 * weatherRoot.radiusMultiplier
                    radiusBR: 12 * weatherRoot.radiusMultiplier
                }
            }
        }
    }

    Rectangle {
        id: largeDetailsOverlay
        visible: false
        property var closedGeometry: Qt.rect(0, 0, 0, 0)

        Connections {
            target: weatherRoot
            function onLargeDetailsOpenChanged() {
                if (weatherRoot.largeDetailsOpen) {
                    var p = detailsButton.mapToItem(largeLayout, 0, 0)
                    largeDetailsOverlay.closedGeometry = Qt.rect(p.x, p.y, detailsButton.width, detailsButton.height)
                    largeDetailsOverlay.x = largeDetailsOverlay.closedGeometry.x
                    largeDetailsOverlay.y = largeDetailsOverlay.closedGeometry.y
                    largeDetailsOverlay.width = largeDetailsOverlay.closedGeometry.width
                    largeDetailsOverlay.height = largeDetailsOverlay.closedGeometry.height
                    largeDetailsOverlay.radius = 14 * weatherRoot.radiusMultiplier
                    largeDetailsOverlay.topLeftRadius = 14 * weatherRoot.radiusMultiplier
                    largeDetailsOverlay.bottomLeftRadius = 14 * weatherRoot.radiusMultiplier
                    largeDetailsOverlay.topRightRadius = 5 * weatherRoot.radiusMultiplier
                    largeDetailsOverlay.bottomRightRadius = 5 * weatherRoot.radiusMultiplier
                    largeDetailsOverlay.color = weatherRoot.showInnerBackgrounds ? Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.1) : "transparent"
                    largeDetailsOverlay.visible = true
                    expandAnim.start()
                } else {
                    collapseAnim.start()
                }
            }
        }

        ParallelAnimation {
            id: expandAnim
            NumberAnimation { target: largeDetailsOverlay; property: "x"; to: 0; duration: 200; easing.type: Easing.InOutQuad }
            NumberAnimation { target: largeDetailsOverlay; property: "y"; to: 0; duration: 200; easing.type: Easing.InOutQuad }
            NumberAnimation { target: largeDetailsOverlay; property: "width"; to: containerWidth; duration: 200; easing.type: Easing.InOutQuad }
            NumberAnimation { target: largeDetailsOverlay; property: "height"; to: containerHeight; duration: 200; easing.type: Easing.InOutQuad }
            NumberAnimation { target: largeDetailsOverlay; properties: "radius,topLeftRadius,bottomLeftRadius,topRightRadius,bottomRightRadius"; to: 20 * weatherRoot.radiusMultiplier; duration: 200; easing.type: Easing.InOutQuad }
            SequentialAnimation {
                PauseAnimation { duration: 50 }
                NumberAnimation { target: overlayFlickable; property: "opacity"; from: 0; to: 1; duration: 150 }
            }
        }

        ParallelAnimation {
            id: collapseAnim
            NumberAnimation { target: largeDetailsOverlay; property: "x"; to: largeDetailsOverlay.closedGeometry.x; duration: 200; easing.type: Easing.InOutQuad }
            NumberAnimation { target: largeDetailsOverlay; property: "y"; to: largeDetailsOverlay.closedGeometry.y; duration: 200; easing.type: Easing.InOutQuad }
            NumberAnimation { target: largeDetailsOverlay; property: "width"; to: largeDetailsOverlay.closedGeometry.width; duration: 200; easing.type: Easing.InOutQuad }
            NumberAnimation { target: largeDetailsOverlay; property: "height"; to: largeDetailsOverlay.closedGeometry.height; duration: 200; easing.type: Easing.InOutQuad }
            NumberAnimation { target: largeDetailsOverlay; properties: "radius,topLeftRadius,bottomLeftRadius"; to: 14 * weatherRoot.radiusMultiplier; duration: 200; easing.type: Easing.InOutQuad }
            NumberAnimation { target: largeDetailsOverlay; properties: "topRightRadius,bottomRightRadius"; to: 5 * weatherRoot.radiusMultiplier; duration: 200; easing.type: Easing.InOutQuad }
            NumberAnimation { target: overlayFlickable; property: "opacity"; to: 0; duration: 150 }
            onFinished: largeDetailsOverlay.visible = false
        }

        Flickable {
            id: overlayFlickable
            anchors.fill: parent
            anchors.margins: 12
            contentHeight: overlayContent.height
            contentWidth: width
            clip: true
            opacity: 0

            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded; width: 6 }

            MouseArea {
                anchors.fill: parent
                onClicked: weatherRoot.largeDetailsOpen = false
            }

            WeatherDetailsView {
                id: overlayContent
                width: parent.width
                weatherRoot: largeLayout.weatherRoot
            }
        }
    }

    Rectangle {
        id: forecastDetailsOverlayLarge
        width: parent.width
        height: parent.height
        radius: 20 * weatherRoot.radiusMultiplier
        color: Qt.rgba(Kirigami.Theme.backgroundColor.r, Kirigami.Theme.backgroundColor.g, Kirigami.Theme.backgroundColor.b, 0.98)
        z: 200
        clip: true

        transform: Translate {
            y: weatherRoot.showForecastDetails ? 0 : largeLayout.height
            Behavior on y { NumberAnimation { duration: 350; easing.type: Easing.InOutQuart } }
        }

        Timer {
            id: overlayAutoCloseTimerLarge
            interval: 5000
            repeat: false
            onTriggered: weatherRoot.showForecastDetails = false
        }

        Connections {
            target: weatherRoot
            function onShowForecastDetailsChanged() {
                if (weatherRoot.showForecastDetails) {
                    overlayAutoCloseTimerLarge.restart()
                } else {
                    overlayAutoCloseTimerLarge.stop()
                }
            }
        }

        property real contentOpacity: weatherRoot.showForecastDetails ? 1 : 0
        Behavior on contentOpacity { NumberAnimation { duration: 300; easing.type: Easing.OutQuad } }

        // Hover Listener
        MouseArea {
            anchors.fill: parent
            z: 1000
            hoverEnabled: true
            propagateComposedEvents: true
            onPressed: (mouse) => mouse.accepted = false
            onWheel: (wheel) => wheel.accepted = false
            onEntered: overlayAutoCloseTimerLarge.stop()
            onExited: if (weatherRoot.showForecastDetails) overlayAutoCloseTimerLarge.restart()
        }

        // Background Click Listener
        MouseArea {
            anchors.fill: parent
            onClicked: weatherRoot.showForecastDetails = false
            z: -1
        }

        Flickable {
            id: forecastFlickableLarge
            anchors.fill: parent
            contentWidth: width
            contentHeight: Math.max(forecastDetailsContentLarge.height, height)
            clip: true
            flickableDirection: Flickable.VerticalFlick
            boundsBehavior: Flickable.StopAtBounds
            opacity: forecastDetailsOverlayLarge.contentOpacity

            ScrollBar.vertical: ScrollBar { policy: forecastDetailsContentLarge.height > parent.height ? ScrollBar.AlwaysOn : ScrollBar.AlwaysOff; width: 6 }

            Item {
                width: parent.width
                height: forecastFlickableLarge.contentHeight
                
                MouseArea {
                    anchors.fill: parent
                    onClicked: weatherRoot.showForecastDetails = false
                }

                MouseArea {
                    anchors.fill: forecastDetailsContentLarge
                    onClicked: {}
                }

                ForecastDetailsView {
                    id: forecastDetailsContentLarge
                    width: parent.width
                    weatherRoot: largeLayout.weatherRoot
                    forecastData: weatherRoot.selectedForecast
                }
            }
        }
    }
}
