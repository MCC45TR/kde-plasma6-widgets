import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

// Small Mode Layout Component
Item {
    id: smallLayout
    
    required property var weatherRoot
    
    // Aliases for cleaner access
    property var currentWeather: weatherRoot.currentWeather
    property string location: weatherRoot.location
    
    function tr(key) { return weatherRoot.tr(key) }
    function getWeatherIcon(item) { return weatherRoot.getWeatherIcon(item) }

    // 1. Top Left: Condition & Location
    ColumnLayout {
        anchors.left: parent.left
        anchors.top: parent.top
        spacing: 0
        width: parent.width * 0.6

        Text {
            text: currentWeather ? tr("condition_" + currentWeather.condition.toLowerCase().replace(/ /g, "_")) : ""
            color: Kirigami.Theme.textColor
            font.family: "Roboto Condensed"
            font.pixelSize: Math.max(16, Math.min(24, smallLayout.height * 0.12))
            wrapMode: Text.WordWrap
            maximumLineCount: 2
            elide: Text.ElideRight
            Layout.fillWidth: true
        }
        Text {
            text: currentWeather ? currentWeather.location : location
            color: Kirigami.Theme.textColor
            font.family: "Roboto Condensed"
            font.pixelSize: Math.max(14, Math.min(20, smallLayout.height * 0.1))
            font.bold: true
            elide: Text.ElideRight
            Layout.fillWidth: true
        }
    }

    // 2. Top Right: Big Icon
    Image {
        source: getWeatherIcon(currentWeather)
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.topMargin: -5
        width: parent.width * 0.5
        height: width
        sourceSize.width: width * 2
        sourceSize.height: height * 2
        fillMode: Image.PreserveAspectFit
        smooth: true
    }

    // 3. Bottom Left: Big Temperature
    Text {
        id: smallTemp
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.bottomMargin: -10
        text: currentWeather ? currentWeather.temp : "--"
        color: Kirigami.Theme.textColor
        font.family: "Roboto Condensed"
        font.pixelSize: smallLayout.height * 0.45
        font.bold: true
        lineHeight: 0.8
    }

    // 4. Bottom Middle: High/Low Stats
    ColumnLayout {
        anchors.left: smallTemp.right
        anchors.leftMargin: 5
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 10
        spacing: 2

        Text {
            text: "°"
            color: Kirigami.Theme.textColor
            font.pixelSize: smallLayout.height * 0.2
            font.bold: true
            Layout.alignment: Qt.AlignHCenter
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
}
