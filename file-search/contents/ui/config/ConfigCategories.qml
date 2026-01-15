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
    
    // Known categories (static list for config)
    property var knownCategories: [
        { name: "Applications", nameKey: "applications", icon: "applications-all" },
        { name: "Uygulamalar", nameKey: "applications", icon: "applications-all" },
        { name: "Files", nameKey: "files", icon: "folder-documents" },
        { name: "Dosyalar", nameKey: "files", icon: "folder-documents" },
        { name: "Documents", nameKey: "documents", icon: "x-office-document" },
        { name: "Belgeler", nameKey: "documents", icon: "x-office-document" },
        { name: "Folders", nameKey: "folders", icon: "folder" },
        { name: "Klasörler", nameKey: "folders", icon: "folder" },
        { name: "Web", nameKey: "web", icon: "internet-web-browser" },
        { name: "Calculator", nameKey: "calculator", icon: "accessories-calculator" },
        { name: "Hesap Makinesi", nameKey: "calculator", icon: "accessories-calculator" }
    ]
    
    function saveSettings() {
        Plasmoid.configuration.categorySettings = CategoryManager.saveCategorySettings(categorySettings)
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
        
        // Category list
        Kirigami.FormLayout {
            Layout.fillWidth: true
            
            Repeater {
                model: configCategories.knownCategories.filter(function(cat, idx, arr) {
                    // Remove duplicates (keep only first occurrence based on nameKey)
                    for (var i = 0; i < idx; i++) {
                        if (arr[i].nameKey === cat.nameKey) return false
                    }
                    return true
                })
                
                delegate: RowLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    
                    // Visibility checkbox
                    CheckBox {
                        id: visibilityCheck
                        checked: CategoryManager.isCategoryVisible(configCategories.categorySettings, modelData.name)
                        
                        onCheckedChanged: {
                            configCategories.categorySettings = CategoryManager.setCategoryVisibility(
                                configCategories.categorySettings, 
                                modelData.name, 
                                checked
                            )
                            configCategories.saveSettings()
                        }
                    }
                    
                    // Category icon
                    Kirigami.Icon {
                        source: CategoryManager.getEffectiveIcon(configCategories.categorySettings, modelData.name, modelData.icon)
                        Layout.preferredWidth: 22
                        Layout.preferredHeight: 22
                    }
                    
                    // Category name
                    Label {
                        text: tr(modelData.nameKey) || modelData.name
                        Layout.fillWidth: true
                    }
                    
                    // Priority spinbox
                    SpinBox {
                        from: 1
                        to: 100
                        value: CategoryManager.getCategoryPriority(configCategories.categorySettings, modelData.name)
                        
                        onValueModified: {
                            configCategories.categorySettings = CategoryManager.setCategoryPriority(
                                configCategories.categorySettings,
                                modelData.name,
                                value
                            )
                            configCategories.saveSettings()
                        }
                        
                        ToolTip.visible: hovered
                        ToolTip.text: tr("priority_tooltip")
                    }
                    
                    // Custom icon button
                    Button {
                        icon.name: "preferences-desktop-icons"
                        flat: true
                        
                        onClicked: iconDialog.open()
                        
                        ToolTip.visible: hovered
                        ToolTip.text: tr("custom_icon")
                        
                        Dialog {
                            id: iconDialog
                            title: tr("select_icon")
                            modal: true
                            standardButtons: Dialog.Ok | Dialog.Cancel
                            
                            property string selectedIcon: ""
                            
                            GridLayout {
                                columns: 6
                                rowSpacing: 8
                                columnSpacing: 8
                                
                                Repeater {
                                    model: [
                                        "applications-all", "folder", "folder-documents",
                                        "folder-download", "folder-music", "folder-pictures",
                                        "folder-videos", "x-office-document", "text-x-generic",
                                        "image-x-generic", "video-x-generic", "audio-x-generic",
                                        "internet-web-browser", "accessories-calculator", "utilities-terminal",
                                        "preferences-system", "help-contents", "star-shape"
                                    ]
                                    
                                    delegate: Button {
                                        Layout.preferredWidth: 48
                                        Layout.preferredHeight: 48
                                        flat: true
                                        
                                        Kirigami.Icon {
                                            anchors.centerIn: parent
                                            source: modelData
                                            width: 32
                                            height: 32
                                        }
                                        
                                        background: Rectangle {
                                            color: iconDialog.selectedIcon === modelData 
                                                ? Kirigami.Theme.highlightColor 
                                                : (parent.hovered ? Kirigami.Theme.hoverColor : "transparent")
                                            radius: 4
                                        }
                                        
                                        onClicked: iconDialog.selectedIcon = modelData
                                    }
                                }
                            }
                            
                            onAccepted: {
                                if (selectedIcon.length > 0) {
                                    configCategories.categorySettings = CategoryManager.setCategoryIcon(
                                        configCategories.categorySettings,
                                        modelData.name,
                                        selectedIcon
                                    )
                                    configCategories.saveSettings()
                                }
                            }
                        }
                    }
                    
                    // Move up button
                    Button {
                        icon.name: "arrow-up"
                        flat: true
                        enabled: index > 0
                        
                        onClicked: {
                            var allCats = configCategories.knownCategories.map(function(c) { return c.name })
                            configCategories.categorySettings = CategoryManager.moveCategoryUp(
                                configCategories.categorySettings,
                                modelData.name,
                                allCats
                            )
                            configCategories.saveSettings()
                        }
                    }
                    
                    // Move down button
                    Button {
                        icon.name: "arrow-down"
                        flat: true
                        enabled: index < configCategories.knownCategories.length - 1
                        
                        onClicked: {
                            var allCats = configCategories.knownCategories.map(function(c) { return c.name })
                            configCategories.categorySettings = CategoryManager.moveCategoryDown(
                                configCategories.categorySettings,
                                modelData.name,
                                allCats
                            )
                            configCategories.saveSettings()
                        }
                    }
                }
            }
        }
        
        Item { Layout.fillHeight: true }
        
        // Info box
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: infoColumn.implicitHeight + 16
            color: Kirigami.Theme.highlightColor
            opacity: 0.1
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
                    text: tr("category_info_desc")
                    opacity: 0.8
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
            }
        }
    }
}
