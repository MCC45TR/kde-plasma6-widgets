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
    
    // KCM Configuration Properties (must match main.xml)
    property string cfg_categorySettings
    property int cfg_searchAlgorithm
    property int cfg_minResults
    property int cfg_maxResults
    property bool cfg_smartResultLimit
    
    // Internal state management
    property var categorySettings
    
    // Load settings when config property changes or init
    onCfg_categorySettingsChanged: {
        categorySettings = CategoryManager.loadCategorySettings(cfg_categorySettings || "{}")
        refreshLists()
    }
    
    Component.onCompleted: {
        // Initial load
        categorySettings = CategoryManager.loadCategorySettings(cfg_categorySettings || "{}")
        refreshLists()
    }

    // Other settings - unique items only
    property var uniqueCategories: [
        { name: "Applications", nameKey: "applications", icon: "applications-all" },
        { name: "Files", nameKey: "files", icon: "folder-documents" },
        { name: "Documents", nameKey: "documents", icon: "x-office-document" },
        { name: "Folders", nameKey: "folders", icon: "folder" },
        { name: "Web", nameKey: "web", icon: "internet-web-browser" },
        { name: "Calculator", nameKey: "calculator", icon: "accessories-calculator" }
    ]
    
    // Filtered lists
    property var separateCategories: []
    property var combinedCategories: []
    
    function refreshLists() {
        var cats = uniqueCategories.slice()
        
        // Split into two groups
        var separate = []
        var combined = []
        
        // Ensure categorySettings is valid object
        var currentSettings = categorySettings || {}
        
        for(var i=0; i<cats.length; i++) {
            if (CategoryManager.isCategoryMerged(currentSettings, cats[i].name)) {
                combined.push(cats[i])
            } else {
                separate.push(cats[i])
            }
        }
        
        // Sort separate by priority
        separate.sort(function(a, b) {
            return CategoryManager.getCategoryPriority(currentSettings, a.name) - CategoryManager.getCategoryPriority(currentSettings, b.name)
        })
        
        // Sort combined by priority (internal order)
        combined.sort(function(a, b) {
            return CategoryManager.getCategoryPriority(currentSettings, a.name) - CategoryManager.getCategoryPriority(currentSettings, b.name)
        })
        
        separateCategories = separate
        combinedCategories = combined
        
        rebuildModels()
    }
    
    function saveSettings() {
        // Update the Config Property which Plasma saves
        cfg_categorySettings = CategoryManager.saveCategorySettings(categorySettings)
        refreshLists() // Refresh visualization
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

        // Algorithm & Limits Settings
        GroupBox {
            title: tr("algorithm_settings")
            Layout.fillWidth: true
            
            GridLayout {
                columns: 2
                rowSpacing: 10
                columnSpacing: 12
                
                // Search Algorithm
                Label { 
                    text: tr("search_algorithm") + ":" 
                    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                }
                ComboBox {
                    model: [tr("alg_fuzzy"), tr("alg_exact"), tr("alg_starts_with")]
                    currentIndex: configCategories.cfg_searchAlgorithm
                    onActivated: {
                        configCategories.cfg_searchAlgorithm = currentIndex
                    }
                    Layout.fillWidth: true
                }
                
                // Result Limits
                Label { 
                    text: tr("result_limits") + ":" 
                    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                }
                RowLayout {
                    spacing: 8
                    
                    Label { text: tr("min_results") }
                    SpinBox {
                        from: 1; to: 20
                        value: configCategories.cfg_minResults
                        onValueModified: configCategories.cfg_minResults = value
                    }
                    
                    Item { width: 10 } // Spacer
                    
                    Label { text: tr("max_results") }
                    SpinBox {
                        from: 5; to: 100
                        value: configCategories.cfg_maxResults
                        onValueModified: configCategories.cfg_maxResults = value
                    }
                }
                
                // Smart Limit
                Label { 
                    text: tr("smart_limit_toggle") + ":" 
                    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                }
                CheckBox {
                    text: tr("smart_limit_desc")
                    checked: configCategories.cfg_smartResultLimit
                    onCheckedChanged: configCategories.cfg_smartResultLimit = checked
                }
            }
        }
        
        // Main Content Area with ScrollView
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            
            ColumnLayout {
                width: parent.width
                spacing: 20
                
                // --- SEPARATE SECTION ---
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    
                    Label {
                        text: tr("separate_section")
                        font.bold: true
                        color: Kirigami.Theme.highlightColor
                    }
                    
                    Label {
                        text: tr("drag_instruction")
                        font.pixelSize: 11
                        opacity: 0.6
                        Layout.bottomMargin: 4
                    }

                    // Headers
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12
                        Layout.leftMargin: 8
                        
                        Label { text: tr("category_visibility"); font.bold: true; Layout.preferredWidth: 30 }
                        Label { text: ""; Layout.preferredWidth: 22 }
                        Label { text: tr("category"); font.bold: true; Layout.fillWidth: true }
                        Label { text: tr("category_priority"); font.bold: true; Layout.preferredWidth: 80 }
                        Label { text: ""; Layout.preferredWidth: 64 }
                    }

                    ListView {
                        id: separateListView
                        Layout.fillWidth: true
                        Layout.preferredHeight: contentHeight
                        interactive: false // Let outer ScrollView handle scrolling
                        
                        model: ListModel { id: separateModel }
                        
                        delegate: categoryDelegate
                    }
                
                    // Drop Area for returning from Combined
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 40
                        color: dropAreaSeparate.containsDrag ? Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.2) : "transparent"
                        radius: 4
                        border.width: 1
                        border.color: Qt.rgba(1,1,1,0.1)
                        border.style: Text.DashLine
                        visible: configCategories.draggingCategory && configCategories.draggingIsMerged
                        
                        Label {
                            anchors.centerIn: parent
                            text: "Move back to Separate"
                            opacity: 0.7
                        }
                        
                        DropArea {
                            id: dropAreaSeparate
                            anchors.fill: parent
                            onDropped: (drag) => {
                                moveToSeparate(drag.source.catName)
                            }
                        }
                    }
                }
                
                // --- COMBINED SECTION ---
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    
                    Label {
                        text: tr("combined_section")
                        font.bold: true
                        color: Kirigami.Theme.activeTextColor
                    }
                    
                    Label {
                        text: tr("combined_desc")
                        font.pixelSize: 11
                        opacity: 0.6
                        Layout.bottomMargin: 4
                    }
                    
                    // Drop Area for moving to Combined
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 40
                        color: dropAreaCombined.containsDrag ? Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.2) : "transparent"
                        radius: 4
                        border.width: 1
                        border.color: Qt.rgba(1,1,1,0.1)
                        border.style: Text.DashLine
                        visible: configCategories.draggingCategory && !configCategories.draggingIsMerged
                        
                        Label {
                            anchors.centerIn: parent
                            text: "Drop here to Combine"
                            opacity: 0.7
                        }
                        
                        DropArea {
                            id: dropAreaCombined
                            anchors.fill: parent
                            onDropped: (drag) => {
                                moveToCombined(drag.source.catName)
                            }
                        }
                    }

                    ListView {
                        id: combinedListView
                        Layout.fillWidth: true
                        Layout.preferredHeight: contentHeight
                        interactive: false
                        
                        model: ListModel { id: combinedModel }
                        
                        delegate: categoryDelegate
                    }
                }
            }
        }
        
        property bool draggingCategory: false
        property bool draggingIsMerged: false
        
        // SHARED DELEGATE
        Component {
            id: categoryDelegate
            Rectangle {
                id: dragDelegate
                width: ListView.view.width
                height: 44
                color: dragArea.drag.active ? Kirigami.Theme.highlightColor : (dragArea.containsMouse ? Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.1) : "transparent")
                radius: 4
                border.color: dragArea.drag.active ? Kirigami.Theme.highlightColor : "transparent"
                border.width: 1
                
                property string catName: model.catName
                property bool isMerged: model.isMerged
                property int listIndex: index // Store index to avoid binding issues
                
                Drag.active: dragArea.drag.active
                Drag.source: dragDelegate
                Drag.hotSpot.x: width / 2
                Drag.hotSpot.y: height / 2
                
                // We need z-index high when dragging
                z: dragArea.drag.active ? 100 : 1

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
                    
                    // Priority display (only meaningful for separate lists sorting)
                    Label {
                        text: isMerged ? "-" : "#" + (index + 1)
                        font.bold: true
                        opacity: 0.6
                        Layout.preferredWidth: 40
                        horizontalAlignment: Text.AlignCenter
                    }
                    
                    // Move buttons (only within own list)
                    Button {
                        icon.name: "arrow-up"
                        flat: true
                        visible: !isMerged // Sorting mainly for top list
                        enabled: index > 0
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 32
                        onClicked: moveItem(model.catName, -1)
                    }
                    
                    Button {
                        icon.name: "arrow-down"
                        flat: true
                        visible: !isMerged
                        enabled: index < ListView.view.count - 1
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 32
                        onClicked: moveItem(model.catName, 1)
                    }
                    
                    // Move to other section button
                    Button {
                        icon.name: isMerged ? "arrow-up-double" : "arrow-down-double"
                        flat: true
                        tooltip: isMerged ? "Move to Separate" : "Move to Combined"
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 32
                        onClicked: {
                            if (isMerged) moveToSeparate(model.catName);
                            else moveToCombined(model.catName);
                        }
                    }
                }
                
                MouseArea {
                    id: dragArea
                    anchors.fill: parent
                    hoverEnabled: true
                    drag.target: dragDelegate
                    drag.axis: Drag.YAxis
                    
                    onPressed: {
                        configCategories.draggingCategory = true
                        configCategories.draggingIsMerged = model.isMerged
                    }
                    
                    onReleased: {
                        configCategories.draggingCategory = false
                        if (drag.active) {
                            dragDelegate.Drag.drop()
                            // Reorder within own list if dropped there
                             // Logic for reordering is tricky with just OnReleased. 
                             // We rely on DropArea in the list or the move buttons for standard reorder.
                        }
                    }
                }
            }
        }
        
        function rebuildModels() {
            separateModel.clear()
            for (var i = 0; i < separateCategories.length; i++) {
                separateModel.append({
                    "catName": separateCategories[i].name,
                    "catNameKey": separateCategories[i].nameKey,
                    "catIcon": separateCategories[i].icon,
                    "isMerged": false
                })
            }
            
            combinedModel.clear()
            for (var j = 0; j < combinedCategories.length; j++) {
                combinedModel.append({
                    "catName": combinedCategories[j].name,
                    "catNameKey": combinedCategories[j].nameKey,
                    "catIcon": combinedCategories[j].icon,
                    "isMerged": true
                })
            }
        }
        
        function moveToCombined(name) {
            configCategories.categorySettings = CategoryManager.setCategoryMerged(configCategories.categorySettings, name, true)
            saveSettings()
        }
        
        function moveToSeparate(name) {
            configCategories.categorySettings = CategoryManager.setCategoryMerged(configCategories.categorySettings, name, false)
            saveSettings()
        }
        
        function moveItem(name, direction) {
            // Find current list info
             var list = CategoryManager.isCategoryMerged(categorySettings, name) ? combinedCategories : separateCategories
             
             // This simple move logic assumes 'list' matches the visual order which is sort-by-priority
             // We need to swap priorities using CategoryManager logic
             if (direction === -1) {
                 configCategories.categorySettings = CategoryManager.moveCategoryUp(configCategories.categorySettings, name, list.map(c => c.name))
             } else {
                configCategories.categorySettings = CategoryManager.moveCategoryDown(configCategories.categorySettings, name, list.map(c => c.name))
             }
             saveSettings()
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
