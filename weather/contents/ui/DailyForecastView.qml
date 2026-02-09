import QtQuick
import QtQuick.Controls
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

        // Grid position calculations (used for both position and radius)
        readonly property int cols: Math.max(1, Math.floor(root.width / root.cellWidth))
        readonly property int row: Math.floor(index / cols)
        readonly property int col: index % cols
        readonly property int totalRows: Math.ceil(root.count / cols)
        
        readonly property bool isFirstCol: col === 0
        readonly property bool isLastCol: col === cols - 1 || index === root.count - 1
        readonly property bool isFirstRow: row === 0
        readonly property bool isLastRow: row === totalRows - 1

        // Position and size with optional flush edges
        readonly property real leftGap: (root.flushEdges && isFirstCol) ? 0 : root.itemSpacing / 2
        readonly property real rightGap: (root.flushEdges && isLastCol) ? 0 : root.itemSpacing / 2
        readonly property real topGap: (root.flushEdges && isFirstRow) ? 0 : root.itemSpacing / 2
        readonly property real bottomGap: (root.flushEdges && isLastRow) ? 0 : root.itemSpacing / 2
        
        x: leftGap
        y: topGap
        width: root.cellWidth - leftGap - rightGap
        height: root.cellHeight - topGap - bottomGap

        // Data bindings
        label: {
            if (root.isHourly) return modelData.time
            if (root.useTodayLabel && index === 0) return i18n("Today")
            return root.weatherRoot.getLocalizedDay(modelData.day)
        }
        iconPath: root.weatherRoot.getWeatherIcon(modelData)
        // For daily, we typically show max temp. For hourly, just temp.
        temp: root.isHourly ? Math.round(modelData.temp) : Math.round(modelData.temp_max)
        
        isHourly: root.isHourly
        units: root.weatherRoot.units
        showUnits: root.showUnits
        fontFamily: root.weatherRoot.activeFont.family
        showBackground: root.showBackground
        isHorizontalLayout: root.isHorizontalLayout
        
        forecastData: modelData
        itemIndex: index
        
        // Click Handling
        onClicked: function(data, idx, cardRect) {
            root.itemClicked(data, idx, cardRect)
        }

        // Radius Logic styling
        readonly property real innerRadius: 5 * root.weatherRoot.radiusMultiplier

        radiusTL: ((isFirstRow && isFirstCol) ? root.cornerRadius : innerRadius)
        radiusTR: ((isFirstRow && isLastCol) ? root.cornerRadius : innerRadius)
        radiusBL: ((isLastRow && isFirstCol) ? root.cornerRadius : innerRadius)
        radiusBR: ((isLastRow && isLastCol) ? root.cornerRadius : innerRadius)
    }
    
    signal itemClicked(var data, int index, rect cardRect)
}
