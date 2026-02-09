import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.kirigami as Kirigami

Item {
    id: smallLayout

    required property var weatherRoot

    property var currentWeather: weatherRoot.currentWeather
    property string location: weatherRoot.location

    function getWeatherIcon(item) { return weatherRoot.getWeatherIcon(item) }
    
    Timer {
        id: autoReturnTimer
        interval: 5000
        repeat: false
        onTriggered: swipeView.currentIndex = 0
    }

    SwipeView {
        id: swipeView
        anchors.fill: parent
        clip: true

        // PAGE 1: Current Weather
        Item {
            ColumnLayout {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.margins: 10 // Page 1 margin
                spacing: 0
                width: parent.width * 0.6

                Text {
                    text: currentWeather ? i18n(currentWeather.condition) : ""
                    color: Kirigami.Theme.textColor
                    font.family: weatherRoot.activeFont.family
                    font.pixelSize: Math.max(16, Math.min(24, smallLayout.height * 0.12))
                    wrapMode: Text.WordWrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
                Text {
                    text: currentWeather ? currentWeather.location : location
                    color: Kirigami.Theme.textColor
                    font.family: weatherRoot.activeFont.family
                    font.pixelSize: Math.max(14, Math.min(20, smallLayout.height * 0.1))
                    font.bold: true
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }

            Image {
                source: getWeatherIcon(currentWeather)
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.rightMargin: 10 // Page 1 margin
                anchors.topMargin: 0   // Compensate for icon padding
                width: parent.width * 0.5
                height: width
                sourceSize.width: width * 2
                sourceSize.height: height * 2
                fillMode: Image.PreserveAspectFit
                smooth: true
            }

            Text {
                id: smallTemp
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                anchors.leftMargin: 10
                anchors.bottomMargin: -5
                text: currentWeather ? currentWeather.temp : "--"
                color: Kirigami.Theme.textColor
                font.family: weatherRoot.activeFont.family
                font.pixelSize: smallLayout.height * 0.45
                font.bold: true
                lineHeight: 0.8
            }

            ColumnLayout {
                anchors.left: smallTemp.right
                anchors.leftMargin: 5
                anchors.top: smallTemp.top
                anchors.topMargin: smallTemp.font.pixelSize * 0.2 // Visual alignment for cap height
                spacing: 2

                Rectangle {
                    Layout.alignment: Qt.AlignLeft
                    width: smallLayout.height * 0.12
                    height: width
                    radius: width / 2
                    color: "transparent"
                    border.color: Kirigami.Theme.textColor
                    border.width: smallLayout.height * 0.025 // Thicker border (approx 3-4px depending on size)
                }

                RowLayout {
                    spacing: 2
                    Text { text: "▲"; color: Kirigami.Theme.positiveTextColor; font.pixelSize: Math.max(12, smallLayout.height * 0.08); font.bold: true }
                    Text { text: currentWeather ? currentWeather.temp_max + "°" : "--"; color: Kirigami.Theme.textColor; font.pixelSize: Math.max(12, smallLayout.height * 0.08); font.bold: true }
                }

                RowLayout {
                    spacing: 2
                    Text { text: "▼"; color: Kirigami.Theme.negativeTextColor; font.pixelSize: Math.max(12, smallLayout.height * 0.08); font.bold: true }
                    Text { text: currentWeather ? currentWeather.temp_min + "°" : "--"; color: Kirigami.Theme.textColor; font.pixelSize: Math.max(12, smallLayout.height * 0.08); font.bold: true }
                }
            }
            
            // Navigation Button
            Rectangle {
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: 10
                width: 24
                height: 24
                radius: width / 2
                color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.1)
                
                Kirigami.Icon {
                    anchors.centerIn: parent
                    width: 16
                    height: 16
                    source: "media-playback-start"
                    color: Kirigami.Theme.textColor
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        swipeView.currentIndex = 1
                        autoReturnTimer.restart()
                    }
                }
            }
        }

        // PAGE 2: Daily Forecast using new reusable component
        Item {
            DailyForecastView {
                anchors.fill: parent
                anchors.margins: 10
                weatherRoot: smallLayout.weatherRoot
                
                // Layout params for 1x2 grid (2 vertical tiles)
                cellWidth: width
                cellHeight: height / 2
                
                // Appearance for Small Mode
                showUnits: false
                showBackground: true
                itemSpacing: 4  // Match wide mode's card spacing
                edgeMargins: 0
                flushEdges: true
                isHorizontalLayout: true
                isHourly: false // Explicitly set to daily mode for small view
                // Model inherited from DailyForecastView (weatherRoot.forecastDaily)
            }
            
            // Hover detection for auto-return
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.NoButton // Let clicks pass through to GridView
                onEntered: autoReturnTimer.stop()
                onExited: autoReturnTimer.restart()
            }
        }
    }
    

}
