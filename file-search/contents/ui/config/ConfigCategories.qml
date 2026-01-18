import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

// Import localization
import "../js/localization.js" as LocalizationData
import "../js/CategoryManager.js" as CategoryManager

// Use Kirigami.FormLayout for Plasma 6 config compatibility
Kirigami.FormLayout {
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
    property var categorySettings: ({})
    
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
        // Execute in next tick to avoid crashes when the delegate triggering this is destroyed
        Qt.callLater(() => {
            // Update the Config Property which Plasma saves
            cfg_categorySettings = CategoryManager.saveCategorySettings(categorySettings)
            refreshLists() // Refresh visualization
        })
    }
    
    // Model rebuild function
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
    
    // ListModels defined at root level for accessibility
    ListModel { id: separateModel }
    ListModel { id: combinedModel }

    // --- Algorithm Settings Section ---
    Kirigami.Separator {
        Kirigami.FormData.isSection: true
        Kirigami.FormData.label: tr("algorithm_settings")
    }
    
    ComboBox {
        id: algorithmCombo
        Kirigami.FormData.label: tr("search_algorithm")
        model: [tr("alg_fuzzy"), tr("alg_exact"), tr("alg_starts_with")]
        currentIndex: configCategories.cfg_searchAlgorithm
        onActivated: {
            configCategories.cfg_searchAlgorithm = currentIndex
        }
        Layout.fillWidth: true
    }
    
    // Smart Limit Checkbox
    CheckBox {
        id: smartLimitCheck
        Kirigami.FormData.label: tr("smart_limit_toggle")
        text: tr("smart_limit_desc")
        checked: configCategories.cfg_smartResultLimit
        onCheckedChanged: configCategories.cfg_smartResultLimit = checked
    }
    
    // Min/Max Results (only when smart limit is off)
    RowLayout {
        Kirigami.FormData.label: tr("result_limits")
        enabled: !configCategories.cfg_smartResultLimit
        opacity: enabled ? 1.0 : 0.5
        spacing: 12
        
        Label { text: tr("min_results") }
        SpinBox {
            from: 1; to: 20
            value: configCategories.cfg_minResults || 3
            onValueModified: configCategories.cfg_minResults = value
        }
        
        Item { width: 10 }
        
        Label { text: tr("max_results") }
        SpinBox {
            from: 5; to: 100
            value: configCategories.cfg_maxResults || 20
            onValueModified: configCategories.cfg_maxResults = value
        }
    }

    // --- Category Order Section ---
    Kirigami.Separator {
        Kirigami.FormData.isSection: true
        Kirigami.FormData.label: tr("separate_section")
    }
    
    Label {
        text: tr("drag_instruction")
        font.pixelSize: 11
        opacity: 0.6
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
    }
    
    // Separate Categories List
    Item {
        Kirigami.FormData.label: tr("category_priority")
        Layout.fillWidth: true
        Layout.preferredHeight: separateListColumn.implicitHeight + 20
        
        Column {
            id: separateListColumn
            anchors.fill: parent
            spacing: 4
            
            Repeater {
                model: separateModel
                
                delegate: Rectangle {
                    width: parent.width
                    height: 44
                    color: delegateMouse.containsMouse ? Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.1) : "transparent"
                    radius: 4
                    
                    MouseArea {
                        id: delegateMouse
                        anchors.fill: parent
                        hoverEnabled: true
                    }
                    
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        spacing: 12
                        
                        // Visibility checkbox
                        CheckBox {
                            id: visCheckSep
                            checked: CategoryManager.isCategoryVisible(configCategories.categorySettings, model.catName)
                            
                            onToggled: {
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
                            elide: Text.ElideRight
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
                            onClicked: moveItem(model.catName, -1)
                        }
                        
                        // Move down button
                        Button {
                            icon.name: "arrow-down"
                            flat: true
                            enabled: index < separateModel.count - 1
                            Layout.preferredWidth: 32
                            Layout.preferredHeight: 32
                            onClicked: moveItem(model.catName, 1)
                        }
                        
                        // Move to combined button
                        Button {
                            icon.name: "arrow-down-double"
                            flat: true
                            ToolTip.text: tr("move_to_combined")
                            ToolTip.visible: hovered
                            Layout.preferredWidth: 32
                            Layout.preferredHeight: 32
                            onClicked: moveToCombined(model.catName)
                        }
                    }
                }
            }
        }
    }

    // --- Combined Section ---
    Kirigami.Separator {
        Kirigami.FormData.isSection: true
        Kirigami.FormData.label: tr("combined_section")
    }
    
    Label {
        text: tr("combined_desc")
        font.pixelSize: 11
        opacity: 0.6
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
    }
    
    // Combined Categories List
    Item {
        Kirigami.FormData.label: " "
        Layout.fillWidth: true
        Layout.preferredHeight: Math.max(combinedListColumn.implicitHeight + 20, 60)
        
        Column {
            id: combinedListColumn
            anchors.fill: parent
            spacing: 4
            
            // Empty state
            Label {
                visible: combinedModel.count === 0
                text: tr("no_combined_categories")
                opacity: 0.5
                anchors.centerIn: parent
            }
            
            Repeater {
                model: combinedModel
                
                delegate: Rectangle {
                    width: parent.width
                    height: 44
                    color: combinedDelegateMouse.containsMouse ? Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.1) : "transparent"
                    radius: 4
                    
                    MouseArea {
                        id: combinedDelegateMouse
                        anchors.fill: parent
                        hoverEnabled: true
                    }
                    
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        spacing: 12
                        
                        // Visibility checkbox
                        CheckBox {
                            id: visCheckComb
                            checked: CategoryManager.isCategoryVisible(configCategories.categorySettings, model.catName)
                            
                            onToggled: {
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
                            elide: Text.ElideRight
                        }
                        
                        // Move to separate button
                        Button {
                            icon.name: "arrow-up-double"
                            flat: true
                            ToolTip.text: tr("move_to_separate")
                            ToolTip.visible: hovered
                            Layout.preferredWidth: 32
                            Layout.preferredHeight: 32
                            onClicked: moveToSeparate(model.catName)
                        }
                    }
                }
            }
        }
    }
    
    // Info box
    Kirigami.Separator {
        Kirigami.FormData.isSection: true
        Kirigami.FormData.label: tr("category_info_title")
    }
    
    Label {
        text: tr("category_info_desc") + "\n\n" + tr("priority_tooltip")
        opacity: 0.8
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
    }
}
