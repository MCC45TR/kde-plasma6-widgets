import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import "../js/CategoryManager.js" as CategoryManager

Kirigami.FormLayout {
    id: configCategories

    // Weather configuration
    property string cfg_weatherProvider
    property string cfg_weatherProviderDefault
    property string cfg_weatherLocationMode
    property string cfg_weatherLocationModeDefault
    property string cfg_weatherLocation
    property string cfg_weatherLocationDefault
    property string cfg_weatherApiKey
    property string cfg_weatherApiKeyDefault
    property string cfg_weatherApiKey2
    property string cfg_weatherApiKey2Default
    property int cfg_weatherUpdateTrigger
    property int cfg_weatherUpdateTriggerDefault
    // Shared configuration properties
    property bool cfg_showSearchButton
    property bool cfg_showSearchButtonDefault
    property bool cfg_showSearchButtonBackground
    property bool cfg_showSearchButtonBackgroundDefault
    property int cfg_scrollBarStyleDefault
    property int cfg_compactPinnedView
    property int cfg_compactPinnedViewDefault
    property int cfg_filterChipStyle
    property int cfg_filterChipStyleDefault
    property bool cfg_previewShowResults
    property bool cfg_previewShowResultsDefault
    property bool cfg_previewShowHistory
    property bool cfg_previewShowHistoryDefault
    property int cfg_previewInlineMode
    property int cfg_previewInlineModeDefault
    property int cfg_previewSize
    property int cfg_previewSizeDefault
    property bool cfg_prefixShellEnabled
    property bool cfg_prefixShellEnabledDefault
    property bool cfg_prefixTimelineEnabled
    property bool cfg_prefixTimelineEnabledDefault
    property bool cfg_prefixWebSearchEnabled
    property bool cfg_prefixWebSearchEnabledDefault
    property bool cfg_prefixKillEnabled
    property bool cfg_prefixKillEnabledDefault
    property bool cfg_prefixSpellEnabled
    property bool cfg_prefixSpellEnabledDefault
    property bool cfg_prefixUnitEnabled
    property bool cfg_prefixUnitEnabledDefault
    property bool cfg_rssEnabled
    property bool cfg_rssEnabledDefault
    property string cfg_rssSources
    property string cfg_rssSourcesDefault
    property int cfg_rssMaxEntries
    property int cfg_rssMaxEntriesDefault
    property int cfg_rssSyncInterval
    property int cfg_rssSyncIntervalDefault
    property string cfg_rssCache
    property string cfg_rssCacheDefault
    property double cfg_rssLastSyncAll
    property double cfg_rssLastSyncAllDefault
    property bool cfg_rssPlaceholderCycling
    property bool cfg_rssPlaceholderCyclingDefault
    property bool cfg_weatherPlaceholderCycling
    property bool cfg_weatherPlaceholderCyclingDefault
    property string cfg_weatherIconPack
    property string cfg_weatherIconPackDefault
    property string cfg_weatherViewMode
    property string cfg_weatherViewModeDefault
    property int cfg_rssFrequency
    property int cfg_rssFrequencyDefault
    property int cfg_weatherFrequency
    property int cfg_weatherFrequencyDefault
    property bool cfg_rssShowImages
    property bool cfg_rssShowImagesDefault
    property bool cfg_rssExpandableCards
    property bool cfg_rssExpandableCardsDefault
    property bool cfg_rssShowSource
    property bool cfg_rssShowSourceDefault
    property bool cfg_rssShowFullHeadline
    property bool cfg_rssShowFullHeadlineDefault
    property var titleDefault
    property int maxHistoryItems
    property int maxHistoryItemsDefault
    
    property string title: i18nd("plasma_applet_com.mcc45tr.filesearch", "Search")
    
    // KCM Configuration Properties (must match main.xml)
    property string cfg_categorySettings
    property int cfg_searchAlgorithm
    property int cfg_minResults
    property int cfg_maxResults
    property bool cfg_smartResultLimit
    
    // Missing Config Properties (Added to silence warnings)
    property int cfg_searchAlgorithmDefault
    property int cfg_minResultsDefault
    property int cfg_maxResultsDefault
    property bool cfg_smartResultLimitDefault
    property string cfg_categorySettingsDefault

    property string cfg_pinnedItems
    property string cfg_pinnedItemsDefault
    property bool cfg_prefixDateShowClock
    property bool cfg_prefixDateShowClockDefault
    property bool cfg_prefixDateShowEvents
    property bool cfg_prefixDateShowEventsDefault
    property bool cfg_prefixPowerShowHibernate
    property bool cfg_prefixPowerShowHibernateDefault
    property bool cfg_prefixPowerShowSleep
    property bool cfg_prefixPowerShowSleepDefault
    property bool cfg_previewEnabled
    property bool cfg_previewEnabledDefault
    property string cfg_previewSettings
    property string cfg_previewSettingsDefault
    property string cfg_searchHistory
    property string cfg_searchHistoryDefault
    property bool cfg_showBootOptions
    property bool cfg_showBootOptionsDefault
    property bool cfg_showPinnedBar
    property bool cfg_showPinnedBarDefault
    property string cfg_telemetryData
    property string cfg_telemetryDataDefault
    property int cfg_userProfile
    property int cfg_userProfileDefault
    property int cfg_viewMode
    property int cfg_viewModeDefault
    property int cfg_iconSize
    property int cfg_iconSizeDefault
    property int cfg_listIconSize
    property int cfg_listIconSizeDefault
    property bool cfg_debugOverlay
    property bool cfg_debugOverlayDefault
    property int cfg_displayMode
    property int cfg_displayModeDefault

    // Missing non-default properties
    property bool cfg_autoMinimizePinned
    property string cfg_cachedBootEntries
    property int cfg_panelHeight
    property int cfg_panelRadius
    property int cfg_scrollBarStyle
    property string cfg_weatherCache
    property bool cfg_weatherEnabled
    property double cfg_weatherLastUpdate
    property int cfg_weatherRefreshInterval
    property string cfg_weatherUnits
    property bool cfg_weatherUseSystemUnits

    // Missing Defaults to silence warnings
    property bool cfg_autoMinimizePinnedDefault
    property string cfg_cachedBootEntriesDefault
    property int cfg_panelHeightDefault
    property int cfg_panelRadiusDefault
    property string cfg_weatherCacheDefault
    property bool cfg_weatherEnabledDefault
    property string cfg_weatherLastUpdateDefault
    property int cfg_weatherRefreshIntervalDefault
    property string cfg_weatherUnitsDefault
    property bool cfg_weatherUseSystemUnitsDefault
    
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
        
        // The list follows the same priority order used by the view.
        // Use CategoryManager so persisted and displayed ordering stay aligned.
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
        Kirigami.FormData.label: i18nd("plasma_applet_com.mcc45tr.filesearch", "Algorithm Settings")
    }
    
    ComboBox {
        id: algorithmCombo
        Kirigami.FormData.label: i18nd("plasma_applet_com.mcc45tr.filesearch", "Search Algorithm")
        model: [i18nd("plasma_applet_com.mcc45tr.filesearch", "Fuzzy Match"), i18nd("plasma_applet_com.mcc45tr.filesearch", "Exact Match"), i18nd("plasma_applet_com.mcc45tr.filesearch", "Starts With")]
        currentIndex: configCategories.cfg_searchAlgorithm
        onActivated: {
            configCategories.cfg_searchAlgorithm = currentIndex
        }
        Layout.fillWidth: true
    }
    
    // Smart Limit Checkbox
    CheckBox {
        id: smartLimitCheck
        Kirigami.FormData.label: i18nd("plasma_applet_com.mcc45tr.filesearch", "Dynamic Result Count")
        text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Automatically limit displayed results based on relevance score")
        checked: configCategories.cfg_smartResultLimit
        onCheckedChanged: configCategories.cfg_smartResultLimit = checked
    }
    
    // Min/Max Results (only when smart limit is off)
    RowLayout {
        Kirigami.FormData.label: i18nd("plasma_applet_com.mcc45tr.filesearch", "Result Limits")
        enabled: !configCategories.cfg_smartResultLimit
        opacity: enabled ? 1.0 : 0.5
        spacing: 12
        
        Label { text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Min Results") }
        SpinBox {
            id: minResultsSpin
            from: 1; to: 20
            value: configCategories.cfg_minResults || 3
            onValueModified: {
                configCategories.cfg_minResults = value
                if (maxResultsSpin.value < value) {
                    maxResultsSpin.value = value
                    configCategories.cfg_maxResults = value
                }
            }
        }
        
        Item { width: 10 }
        
        Label { text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Max Results") }
        SpinBox {
            id: maxResultsSpin
            from: 5; to: 100
            value: configCategories.cfg_maxResults || 20
            onValueModified: {
                configCategories.cfg_maxResults = value
                if (minResultsSpin.value > value) {
                    minResultsSpin.value = value
                    configCategories.cfg_minResults = value
                }
            }
        }
    }

    // --- Category Order Section ---
    Kirigami.Separator {
        Kirigami.FormData.isSection: true
        Kirigami.FormData.label: i18nd("plasma_applet_com.mcc45tr.filesearch", "Prioritized Categories")
    }
    
    Label {
        text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Use buttons to reorder categories or move between sections")
        font.pixelSize: 11
        opacity: 0.6
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
    }
    
    // Separate Categories List
    Item {
        Kirigami.FormData.label: i18nd("plasma_applet_com.mcc45tr.filesearch", "Priority")
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
                        
                        Label {
                            text: i18nd("plasma_applet_com.mcc45tr.filesearch", model.catName) || model.catName
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
                            ToolTip.text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Move to Combined")
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
        Kirigami.FormData.label: i18nd("plasma_applet_com.mcc45tr.filesearch", "Show Together (Merged)")
    }
    
    Label {
        text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Categories in this section will be grouped together")
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
        
        // Empty state
        Label {
            visible: combinedModel.count === 0
            text: i18nd("plasma_applet_com.mcc45tr.filesearch", "No combined categories")
            opacity: 0.5
            anchors.centerIn: parent
            z: 1 // Ensure it's on top if needed, though column is transparent usually
        }

        Column {
            id: combinedListColumn
            anchors.fill: parent
            spacing: 4
            
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
                            text: i18nd("plasma_applet_com.mcc45tr.filesearch", model.catName) || model.catName
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }
                        
                        // Move to separate button
                        Button {
                            icon.name: "arrow-up-double"
                            flat: true
                            ToolTip.text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Move to Separate")
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
        Kirigami.FormData.label: i18nd("plasma_applet_com.mcc45tr.filesearch", "Category Settings Information")
    }
    
    Label {
        text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Changes are applied immediately. Hidden categories will not appear in search results. Priority determines display order.") + "\n\n" + i18nd("plasma_applet_com.mcc45tr.filesearch", "Lower number = higher priority")
        opacity: 0.8
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
    }
}
