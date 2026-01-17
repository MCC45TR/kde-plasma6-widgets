import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

// Import localization
import "../js/localization.js" as LocalizationData
import "../js/CategoryManager.js" as CategoryManager

KCM.SimpleKCM {
    id: configCategories
    
    // Localization
    property var locales: LocalizationData.data
    property string currentLocale: Qt.locale().name.substring(0, 2)
    
    function tr(key) {
        if (locales[currentLocale] && locales[currentLocale][key]) {
            return locales[currentLocale][key]
        }
        if (locales["en"] && locales["en"][key]) {
            return locales["en"][key]
        }
        return key
    }
    
    // Category settings from config
    property var categorySettings: CategoryManager.loadCategorySettings(Plasmoid.configuration.categorySettings || "{}")
    
    // Known categories (static list for config) - unique items only
    property var uniqueCategories: [
        { name: "Applications", nameKey: "applications", icon: "applications-all" },
        { name: "Files", nameKey: "files", icon: "folder-documents" },
        { name: "Documents", nameKey: "documents", icon: "x-office-document" },
        { name: "Folders", nameKey: "folders", icon: "folder" },
        { name: "Web", nameKey: "web", icon: "internet-web-browser" },
        { name: "Calculator", nameKey: "calculator", icon: "accessories-calculator" }
    ]
    
    // Sorted category list model
    property var sortedCategories: {
        var cats = uniqueCategories.slice()
        return cats.sort(function(a, b) {
            var prioA = CategoryManager.getCategoryPriority(categorySettings, a.name)
            var prioB = CategoryManager.getCategoryPriority(categorySettings, b.name)
            return prioA - prioB
        })
    }
    
    function saveSettings() {
        Plasmoid.configuration.categorySettings = CategoryManager.saveCategorySettings(categorySettings)
    }
    
    function refreshSortedCategories() {
        var cats = uniqueCategories.slice()
        sortedCategories = cats.sort(function(a, b) {
            var prioA = CategoryManager.getCategoryPriority(categorySettings, a.name)
            var prioB = CategoryManager.getCategoryPriority(categorySettings, b.name)
            return prioA - prioB
        })
    }
    
    ColumnLayout {
        anchors.fill: parent
        spacing: 16
        
        // Header
        Label {
            text: tr("category_settings")
            font.bold: true
            font.pixelSize: 16
        }
        
        Label {
            text: tr("category_settings_desc")
            opacity: 0.7
            font.pixelSize: 12
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }
        
        // Column headers
        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            Layout.leftMargin: 8
            
            Label {
                text: tr("category_visibility")
                font.bold: true
                Layout.preferredWidth: 30
            }
            
            Label {
                text: ""
                Layout.preferredWidth: 22
            }
            
            Label {
                text: tr("category")
                font.bold: true
                Layout.fillWidth: true
            }
            
            Label {
                text: tr("category_priority")
                font.bold: true
                Layout.preferredWidth: 80
            }
            
            Label {
                text: ""
                Layout.preferredWidth: 100
            }
        }
        
        // Category list with drag-and-drop support
        ListView {
            id: categoryListView
            Layout.fillWidth: true
            Layout.preferredHeight: contentHeight + 20
            Layout.maximumHeight: 400
            clip: true
            spacing: 4
            
            model: ListModel {
                id: categoryModel
            }
            
            Component.onCompleted: rebuildModel()
            
            function rebuildModel() {
                categoryModel.clear()
                var sorted = configCategories.sortedCategories
                for (var i = 0; i < sorted.length; i++) {
                    categoryModel.append({
                        "catName": sorted[i].name,
                        "catNameKey": sorted[i].nameKey,
                        "catIcon": sorted[i].icon,
                        "catIndex": i
                    })
                }
            }
            
            moveDisplaced: Transition {
                NumberAnimation { properties: "y"; duration: 200; easing.type: Easing.OutQuad }
            }
            
            delegate: Rectangle {
                id: dragDelegate
                width: categoryListView.width
                height: 44
                color: dragArea.drag.active ? Kirigami.Theme.highlightColor : (dragArea.containsMouse ? Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.1) : "transparent")
                radius: 4
                border.color: dragArea.drag.active ? Kirigami.Theme.highlightColor : "transparent"
                border.width: 1
                
                property int visualIndex: index
                
                Drag.active: dragArea.drag.active
                Drag.source: dragDelegate
                Drag.hotSpot.x: width / 2
                Drag.hotSpot.y: height / 2
                
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 12
                    
                    // Drag handle
                    Kirigami.Icon {
                        source: "handle-sort"
                        Layout.preferredWidth: 16
                        Layout.preferredHeight: 16
                        opacity: 0.5
                    }
                    
                    // Visibility checkbox
                    CheckBox {
                        id: visibilityCheck
                        checked: CategoryManager.isCategoryVisible(configCategories.categorySettings, model.catName)
                        
                        onCheckedChanged: {
                            configCategories.categorySettings = CategoryManager.setCategoryVisibility(
                                configCategories.categorySettings, 
                                model.catName, 
                                checked
                            )
                            configCategories.saveSettings()
                        }
                    }
                    
                    // Category icon
                    Kirigami.Icon {
                        source: CategoryManager.getEffectiveIcon(configCategories.categorySettings, model.catName, model.catIcon)
                        Layout.preferredWidth: 22
                        Layout.preferredHeight: 22
                    }
                    
                    // Category name
                    Label {
                        text: configCategories.tr(model.catNameKey) || model.catName
                        Layout.fillWidth: true
                    }
                    
                    // Priority display
                    Label {
                        text: "#" + (index + 1)
                        font.bold: true
                        opacity: 0.6
                        Layout.preferredWidth: 40
                        horizontalAlignment: Text.AlignCenter
                    }
                    
                    // Move up button
                    Button {
                        icon.name: "arrow-up"
                        flat: true
                        enabled: index > 0
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 32
                        
                        onClicked: {
                            if (index > 0) {
                                categoryModel.move(index, index - 1, 1)
                                applyNewOrder()
                            }
                        }
                    }
                    
                    // Move down button
                    Button {
                        icon.name: "arrow-down"
                        flat: true
                        enabled: index < categoryModel.count - 1
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 32
                        
                        onClicked: {
                            if (index < categoryModel.count - 1) {
                                categoryModel.move(index, index + 1, 1)
                                applyNewOrder()
                            }
                        }
                    }
                }
                
                MouseArea {
                    id: dragArea
                    anchors.fill: parent
                    hoverEnabled: true
                    drag.target: dragDelegate
                    drag.axis: Drag.YAxis
                    
                    onReleased: {
                        if (drag.active) {
                            applyNewOrder()
                        }
                        dragDelegate.Drag.drop()
                    }
                }
                
                DropArea {
                    anchors.fill: parent
                    
                    onEntered: (drag) => {
                        var sourceVisualIndex = drag.source.visualIndex
                        var targetVisualIndex = dragDelegate.visualIndex
                        
                        if (sourceVisualIndex !== targetVisualIndex) {
                            categoryModel.move(sourceVisualIndex, targetVisualIndex, 1)
                        }
                    }
                }
            }
            
            function applyNewOrder() {
                var orderedNames = []
                for (var i = 0; i < categoryModel.count; i++) {
                    orderedNames.push(categoryModel.get(i).catName)
                }
                configCategories.categorySettings = CategoryManager.reorderCategories(
                    configCategories.categorySettings, 
                    orderedNames
                )
                configCategories.saveSettings()
            }
        }
        
        Item { Layout.fillHeight: true }
        
        // Info box
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: infoColumn.implicitHeight + 16
            color: Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.1)
            radius: 8
            
            ColumnLayout {
                id: infoColumn
                anchors.fill: parent
                anchors.margins: 8
                spacing: 4
                
                Label {
                    text: "ℹ️ " + tr("category_info_title")
                    font.bold: true
                }
                
                Label {
                    text: tr("category_info_desc") + "\n\n" + tr("priority_tooltip")
                    opacity: 0.8
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
            }
        }
    }
}
