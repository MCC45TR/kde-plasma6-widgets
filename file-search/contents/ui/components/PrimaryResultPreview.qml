import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

// Primary Result Preview Component (Calculator, Unit Conversions, etc.)
Rectangle {
    id: root
    
    // Required properties
    required property var resultsModel
    required property int resultCount
    required property string searchText
    required property color accentColor
    required property color textColor
    
    // Signals
    signal resultClicked(var idx, string display, string decoration, string category)
    
    height: visible ? 64 : 0
    visible: searchText.length > 0 && isPrimaryResult
    color: Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.15)
    radius: 10
    border.width: 1
    border.color: Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.3)
    
    Behavior on height { NumberAnimation { duration: 150 } }
    
    property bool isPrimaryResult: {
        if (resultCount === 0 || !resultsModel) return false
        var firstCat = resultsModel.data(resultsModel.index(0, 0), resultsModel.CategoryRole) || ""
        // Detect calculator, unit converter, currency converter categories
        return firstCat.indexOf("Calculate") >= 0 || 
               firstCat.indexOf("Hesapla") >= 0 ||
               firstCat.indexOf("Unit") >= 0 ||
               firstCat.indexOf("Birim") >= 0 ||
               firstCat.indexOf("Currency") >= 0 ||
               firstCat.indexOf("Döviz") >= 0
    }
    
    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        spacing: 14
        
        // Calculator Icon
        Rectangle {
            Layout.preferredWidth: 40
            Layout.preferredHeight: 40
            radius: 8
            color: root.accentColor
            
            Kirigami.Icon {
                anchors.centerIn: parent
                width: 24
                height: 24
                source: "accessories-calculator"
                color: "white"
            }
        }
        
        // Result Text
        Column {
            Layout.fillWidth: true
            spacing: 2
            
            Text {
                text: (root.resultCount > 0 && root.resultsModel) ? 
                      root.resultsModel.data(root.resultsModel.index(0, 0), Qt.DisplayRole) || "" : ""
                font.pixelSize: 22
                font.bold: true
                color: root.textColor
                elide: Text.ElideRight
                width: parent.width
            }
            
            Text {
                text: root.searchText
                font.pixelSize: 11
                color: Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.6)
                elide: Text.ElideRight
                width: parent.width
            }
        }
        
        // Copy/Run indicator
        Kirigami.Icon {
            Layout.preferredWidth: 20
            Layout.preferredHeight: 20
            source: "edit-copy"
            color: Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.5)
        }
    }
    
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        
        onEntered: root.color = Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.25)
        onExited: root.color = Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.15)
        
        onClicked: {
            if (root.resultCount > 0) {
                var idx = root.resultsModel.index(0, 0)
                var display = root.resultsModel.data(idx, Qt.DisplayRole) || ""
                var decoration = root.resultsModel.data(idx, Qt.DecorationRole) || "accessories-calculator"
                var category = root.resultsModel.data(idx, root.resultsModel.CategoryRole) || "Calculator"
                root.resultClicked(idx, display, decoration, category)
            }
        }
    }
}
