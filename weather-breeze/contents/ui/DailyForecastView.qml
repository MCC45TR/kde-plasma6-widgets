import QtQuick
import org.kde.kirigami as Kirigami

GridView {
    id: root

    required property var weatherRoot
    
    property bool useTodayLabel: false

    // Properties to customize appearance per view
    property bool isHourly: false
    property bool showUnits: true
    property bool showBackground: true
    property real cornerRadius: 10 * weatherRoot.radiusMultiplier
    property real itemSpacing: 0
    property real edgeMargins: 0
    property bool isHorizontalLayout: false
    property bool flushEdges: false
    
    // Default model auto-switches based on mode, but can be overridden
    model: isHourly ? weatherRoot.forecastHourly : weatherRoot.forecastDaily

    // Layout behavior
    snapMode: GridView.SnapToRow
    boundsBehavior: Flickable.StopAtBounds
    clip: true
    
    anchors.margins: edgeMargins

    delegate: ForecastItem {
        required property var modelData
        required property int index

        width: Math.max(1, root.cellWidth - root.itemSpacing)
        height: Math.max(1, root.cellHeight - root.itemSpacing)

        // Data bindings
        label: {
            if (root.isHourly) return modelData.time
            if (root.useTodayLabel && index === 0) return i18n("Today")
            return root.weatherRoot.getLocalizedDay(modelData.day)
        }
        iconPath: root.weatherRoot.getWeatherIcon(modelData)
        // Daily forecasts use the maximum; hourly forecasts use the current temperature.
        temp: root.isHourly ? Math.round(modelData.temp) : Math.round(modelData.temp_max)
        
        isHourly: root.isHourly
        units: root.weatherRoot.units
        showUnits: root.showUnits
        fontFamily: root.weatherRoot.activeFont.family
        showBackground: root.showBackground
        isHorizontalLayout: root.isHorizontalLayout
        
        forecastData: modelData
        itemIndex: index
        
        onForecastClicked: function(data, idx, cardRect) {
            root.itemClicked(data, idx, cardRect)
        }
    }
    
    signal itemClicked(var data, int index, rect cardRect)
}
