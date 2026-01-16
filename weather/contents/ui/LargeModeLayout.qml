import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

// Large Mode Layout Component
Item {
    id: largeLayout
    
    required property var weatherRoot
    
    // Use parent dimensions for overlay (parent is the Loader's parent - mainRect)
    readonly property real containerWidth: parent ? parent.width : 0
    readonly property real containerHeight: parent ? parent.height : 0
    
    // Aliases
    property var currentWeather: weatherRoot.currentWeather
    property var forecastDaily: weatherRoot.forecastDaily
    property var forecastHourly: weatherRoot.forecastHourly
    property bool forecastMode: weatherRoot.forecastMode
    property bool largeDetailsOpen: weatherRoot.largeDetailsOpen
    property string location: weatherRoot.location
    
    function tr(key) { return weatherRoot.tr(key) }
    function getWeatherIcon(item) { return weatherRoot.getWeatherIcon(item) }
    function getLocalizedDay(day) { return weatherRoot.getLocalizedDay(day) }

    // Content Container (fades when details open)
    Item {
        id: contentContainer
        anchors.fill: parent
        opacity: largeDetailsOpen ? 0 : 1
        Behavior on opacity { NumberAnimation { duration: 200 } }

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            // HEADER AREA - Split into left info and right icon sections
            Item {
                id: headerArea
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(largeLayout.height * 0.45, 200)
                
                // Calculate available space for icon (should not overlap buttons)
                readonly property real buttonsHeight: 38 // 28px button + 10px margin
                readonly property real iconMaxSize: Math.min(headerArea.height - buttonsHeight, headerArea.width * 0.4)

                // Left Column: Condition, Location
                Column {
                    id: leftInfoColumn
                    anchors.left: parent.left
                    anchors.top: parent.top
                    width: parent.width * 0.55
                    spacing: 2

                    Text {
                        text: currentWeather ? tr("condition_" + currentWeather.condition.toLowerCase().replace(/ /g, "_")) : ""
                        color: Kirigami.Theme.textColor
                        font.family: "Roboto Condensed"
                        font.pixelSize: Math.min(32, largeLayout.height * 0.08)
                        font.bold: true
                        elide: Text.ElideRight
                        width: parent.width
                    }

                    Text {
                        text: currentWeather ? currentWeather.location : location
                        color: Kirigami.Theme.textColor
                        font.family: "Roboto Condensed"
                        font.pixelSize: Math.min(20, largeLayout.height * 0.05)
                        font.bold: true
                        opacity: 0.7
                        elide: Text.ElideRight
                        width: parent.width
                    }
                }

                // Right side: Weather Icon (bounded size)
                Image {
                    id: weatherIcon
                    anchors.right: parent.right
                    anchors.top: parent.top
                    // Icon size: grows with widget but stops at limit
                    width: Math.min(headerArea.iconMaxSize, parent.width * 0.45)
                    height: width
                    source: getWeatherIcon(currentWeather)
                    sourceSize.width: width * 2
                    sourceSize.height: height * 2
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                }

                // Temperature - Positioned at bottom-left, aligned above forecast cards
                Text {
                    id: tempText
                    anchors.left: parent.left
                    anchors.bottom: parent.bottom
                    text: currentWeather ? currentWeather.temp + "°" : "--"
                    color: Kirigami.Theme.textColor
                    font.family: "Roboto Condensed"
                    font.pixelSize: Math.min(100, largeLayout.height * 0.22)
                    font.bold: true
                    lineHeight: 0.85
                }

                // Header Buttons - Bottom right, below icon
                Row {
                    id: headerButtons
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    spacing: 4

                    Rectangle {
                        id: detailsButton
                        width: detailsText.implicitWidth + 20
                        height: 28
                        radius: 14
                        topRightRadius: 5
                        bottomRightRadius: 5
                        color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.1)

                        Text {
                            id: detailsText
                            anchors.centerIn: parent
                            text: tr("details")
                            color: Kirigami.Theme.textColor
                            font.family: "Roboto Condensed"
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
                            radius: 14
                            topRightRadius: 5
                            bottomRightRadius: 5
                            Behavior on opacity { NumberAnimation { duration: 150 } }
                        }
                    }

                    Rectangle {
                        width: toggleTextLarge.implicitWidth + 24
                        height: 28
                        radius: 14
                        topLeftRadius: 5
                        bottomLeftRadius: 5
                        color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.1)

                        Text {
                            id: toggleTextLarge
                            anchors.centerIn: parent
                            text: forecastMode ? tr("hourly_forecast") : tr("daily_forecast")
                            color: Kirigami.Theme.textColor
                            font.family: "Roboto Condensed"
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
                            radius: 14
                            topLeftRadius: 5
                            bottomLeftRadius: 5
                            Behavior on opacity { NumberAnimation { duration: 150 } }
                        }
                    }
                }
            }

            // FORECAST GRID
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

                    radiusTL: 12
                    radiusTR: 12
                    radiusBL: 12
                    radiusBR: 12
                }
            }
        }
    }

    // Details Overlay
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
                    largeDetailsOverlay.radius = 14
                    largeDetailsOverlay.topLeftRadius = 14
                    largeDetailsOverlay.bottomLeftRadius = 14
                    largeDetailsOverlay.topRightRadius = 5
                    largeDetailsOverlay.bottomRightRadius = 5
                    largeDetailsOverlay.color = Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.1)
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
            NumberAnimation { target: largeDetailsOverlay; properties: "radius,topLeftRadius,bottomLeftRadius,topRightRadius,bottomRightRadius"; to: 20; duration: 200; easing.type: Easing.InOutQuad }
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
            NumberAnimation { target: largeDetailsOverlay; properties: "radius,topLeftRadius,bottomLeftRadius"; to: 14; duration: 200; easing.type: Easing.InOutQuad }
            NumberAnimation { target: largeDetailsOverlay; properties: "topRightRadius,bottomRightRadius"; to: 5; duration: 200; easing.type: Easing.InOutQuad }
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
}
