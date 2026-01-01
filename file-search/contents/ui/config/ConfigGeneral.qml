import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

// Import localization data from parent directory
import "../js/localization.js" as LocalizationData

Kirigami.FormLayout {
    id: page
    
    // Bind to configuration
    property alias cfg_displayMode: modeCombo.currentIndex
    property alias cfg_viewMode: viewModeCombo.currentIndex
    
    // Mapped properties for icon sizes (handled manually to map index <-> value)
    property int cfg_iconSize
    property int cfg_listIconSize
    
    // --- Localization Logic ---
    property var locales: LocalizationData.data
    property string currentLocale: Qt.locale().name.substring(0, 2)

    function tr(key) {
        if (locales[currentLocale] && locales[currentLocale][key]) return locales[currentLocale][key]
        if (locales["en"] && locales["en"][key]) return locales["en"][key]
        return key 
    }
    // --- End Localization Logic ---
    
    // Icon size options
    readonly property var iconSizeModel: [16, 22, 32, 48, 64, 128]
    
    // Profile property
    property alias cfg_userProfile: profileCombo.currentIndex
    
    // Profile Selector
    Kirigami.Separator {
        Kirigami.FormData.isSection: true
        Kirigami.FormData.label: page.tr("profile") || "Profil"
    }
    
    ComboBox {
        id: profileCombo
        Kirigami.FormData.label: page.tr("user_profile") || "Kullanıcı Profili"
        model: [
            page.tr("profile_minimal") || "Minimal",
            page.tr("profile_developer") || "Developer",
            page.tr("profile_power_user") || "Power User"
        ]
        Layout.fillWidth: true
    }
    
    Label {
        text: {
            switch(profileCombo.currentIndex) {
                case 0: return page.tr("profile_minimal_desc") || "Basit arayüz, temel özellikler"
                case 1: return page.tr("profile_developer_desc") || "Debug sekmesi aktif, geliştirici özellikleri"
                case 2: return page.tr("profile_power_desc") || "Tüm özellikler aktif, gelişmiş ayarlar"
                default: return ""
            }
        }
        wrapMode: Text.Wrap
        Layout.fillWidth: true
        opacity: 0.7
        font.pixelSize: 11
    }
    
    Kirigami.Separator {
        Kirigami.FormData.isSection: true
        Kirigami.FormData.label: page.tr("appearance") || "Görünüm"
    }

    ComboBox {
        id: modeCombo
        Kirigami.FormData.label: page.tr("panel_view")
        model: [
            page.tr("button_mode"), 
            page.tr("medium_mode"), 
            page.tr("wide_mode"), 
            page.tr("extra_wide_mode")
        ]
        Layout.fillWidth: true
    }
    
    ComboBox {
        id: viewModeCombo
        Kirigami.FormData.label: page.tr("results_view")
        model: [page.tr("list_view"), page.tr("tile_view")]
        Layout.fillWidth: true
    }
    
    // List Icon Size Selector
    ComboBox {
        id: listIconSizeCombo
        Kirigami.FormData.label: page.tr("list_icon_size")
        model: ["16", "22", "32", "48", "64", "128"]
        Layout.fillWidth: true
        enabled: viewModeCombo.currentIndex === 0
        
        onCurrentIndexChanged: {
            if (currentIndex >= 0 && currentIndex < iconSizeModel.length) {
                cfg_listIconSize = iconSizeModel[currentIndex]
            }
        }
        
        Component.onCompleted: {
            for (var i = 0; i < iconSizeModel.length; i++) {
                if (iconSizeModel[i] === cfg_listIconSize) {
                    currentIndex = i
                    break
                }
            }
            if (currentIndex === -1) currentIndex = 1 // Default 22
        }
    }
    
    // Tile Icon Size Selector
    ComboBox {
        id: iconSizeCombo
        Kirigami.FormData.label: page.tr("tile_icon_size")
        model: ["16", "22", "32", "48", "64", "128"]
        Layout.fillWidth: true
        enabled: viewModeCombo.currentIndex === 1
        
        // Custom delegate with icon previews
        delegate: ItemDelegate {
            width: parent.width
            height: 40
            
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 12
                
                Rectangle {
                    Layout.preferredWidth: parseInt(modelData) > 32 ? 32 : parseInt(modelData)
                    Layout.preferredHeight: parseInt(modelData) > 32 ? 32 : parseInt(modelData)
                    radius: 4
                    color: iconSizeCombo.currentIndex === index ? Kirigami.Theme.highlightColor : "transparent"
                    
                    Kirigami.Icon {
                        anchors.centerIn: parent
                        width: Math.min(parseInt(modelData), 28)
                        height: width
                        source: "applications-other"
                        color: Kirigami.Theme.textColor
                    }
                }
                
                Text {
                    text: modelData + " px"
                    color: Kirigami.Theme.textColor
                    Layout.fillWidth: true
                }
            }
            
            highlighted: iconSizeCombo.highlightedIndex === index
            
            onClicked: {
                iconSizeCombo.currentIndex = index
            }
        }
        
        onCurrentIndexChanged: {
            if (currentIndex >= 0 && currentIndex < iconSizeModel.length) {
                cfg_iconSize = iconSizeModel[currentIndex]
            }
        }
        
        Component.onCompleted: {
            for (var i = 0; i < iconSizeModel.length; i++) {
                if (iconSizeModel[i] === cfg_iconSize) {
                    currentIndex = i
                    break
                }
            }
            if (currentIndex === -1) currentIndex = 3 // Default 48
        }
    }
    
    // Panel Preview
    Item {
        Kirigami.FormData.label: page.tr("panel_preview")
        Layout.fillWidth: true
        Layout.preferredHeight: 50
        
        // Button Mode Preview (circular icon only)
        Rectangle {
            id: buttonModePreview
            anchors.left: parent.left
            width: 36
            height: 36
            radius: width / 2
            color: Kirigami.Theme.backgroundColor
            border.width: 1
            border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.2)
            visible: modeCombo.currentIndex === 0
            
            Kirigami.Icon {
                anchors.centerIn: parent
                width: 18
                height: 18
                source: "plasma-search"
                color: Kirigami.Theme.textColor
            }
        }
        
        // Other Modes Preview (text + icon)
        Rectangle {
            anchors.left: parent.left
            // 1=Medium (70), 2=Wide (180), 3=Extra Wide (260)
            width: modeCombo.currentIndex === 1 ? 70 : (modeCombo.currentIndex === 3 ? 260 : 180)
            height: 36
            radius: height / 2
            color: Kirigami.Theme.backgroundColor
            border.width: 1
            border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.2)
            visible: modeCombo.currentIndex !== 0
            
            Behavior on width { NumberAnimation { duration: 200 } }
            
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 6
                spacing: 8
                
                Text {
                    // 1=Medium "Ara", 2=Wide "Arama yap...", 3=Extra Wide "Arama yapmaya başla..."
                    text: modeCombo.currentIndex === 1 ? page.tr("search") : (modeCombo.currentIndex === 3 ? page.tr("start_searching") : page.tr("search_dots"))
                    color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.6)
                    font.pixelSize: modeCombo.currentIndex !== 1 ? 14 : 12
                    Layout.fillWidth: true
                    horizontalAlignment: modeCombo.currentIndex === 1 ? Text.AlignHCenter : Text.AlignLeft
                }
                
                // Search icon button (Wide and Extra Wide only)
                Rectangle {
                    Layout.preferredWidth: (modeCombo.currentIndex === 2 || modeCombo.currentIndex === 3) ? 28 : 0
                    Layout.preferredHeight: 28
                    radius: 14
                    color: Kirigami.Theme.highlightColor
                    visible: modeCombo.currentIndex === 2 || modeCombo.currentIndex === 3
                    
                    Behavior on Layout.preferredWidth { NumberAnimation { duration: 200 } }
                    
                    Kirigami.Icon {
                        anchors.centerIn: parent
                        width: 16
                        height: 16
                        source: "search"
                        color: "#ffffff"
                    }
                }
            }
        }
    }
    
    // View Mode Preview
    Item {
        Kirigami.FormData.label: page.tr("results_preview")
        Layout.fillWidth: true
        Layout.preferredHeight: viewModeCombo.currentIndex === 0 ? 100 : 180
        
        Behavior on Layout.preferredHeight { NumberAnimation { duration: 200 } }
        
        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(Kirigami.Theme.backgroundColor.r, Kirigami.Theme.backgroundColor.g, Kirigami.Theme.backgroundColor.b, 0.5)
            radius: 8
            border.width: 1
            border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.1)
            
            // List View Preview
            Column {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 4
                visible: viewModeCombo.currentIndex === 0
                
                Repeater {
                    model: [page.tr("application_1"), page.tr("application_2"), page.tr("file_txt")]
                    
                    Rectangle {
                        width: parent.width
                        height: Math.max(28, iconSizeModel[listIconSizeCombo.currentIndex] + 6)
                        color: index === 0 ? Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.15) : "transparent"
                        radius: 4
                        
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            spacing: 8
                            
                            Kirigami.Icon {
                                source: index === 2 ? "text-x-generic" : "application-x-executable"
                                Layout.preferredWidth: iconSizeModel[listIconSizeCombo.currentIndex]
                                Layout.preferredHeight: iconSizeModel[listIconSizeCombo.currentIndex]
                                color: Kirigami.Theme.textColor
                            }
                            
                            Text {
                                text: modelData
                                color: Kirigami.Theme.textColor
                                font.pixelSize: 12
                                Layout.fillWidth: true
                            }
                        }
                    }
                }
            }
            
            // Tile View Preview with Category Headers
            Column {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8
                visible: viewModeCombo.currentIndex === 1
                
                // Category A header
                RowLayout {
                    width: parent.width
                    height: 20
                    spacing: 8
                    
                    Text {
                        text: "A"
                        color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.6)
                        font.pixelSize: 12
                        font.bold: true
                    }
                    
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 1
                        color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.2)
                    }
                }
                
                // Category A tiles
                Row {
                    spacing: 8
                    
                    Repeater {
                        model: ["App1", "App2"]
                        
                        Column {
                            width: 60
                            spacing: 4
                            
                            Rectangle {
                                width: iconSizeModel[iconSizeCombo.currentIndex] > 48 ? 48 : iconSizeModel[iconSizeCombo.currentIndex]
                                height: width
                                anchors.horizontalCenter: parent.horizontalCenter
                                radius: 8
                                color: index === 0 ? Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.2) : "transparent"
                                
                                Kirigami.Icon {
                                    anchors.centerIn: parent
                                    width: parent.width * 0.8
                                    height: width
                                    source: "applications-other"
                                    color: Kirigami.Theme.textColor
                                }
                            }
                            
                            Text {
                                width: parent.width
                                text: modelData
                                color: Kirigami.Theme.textColor
                                font.pixelSize: 10
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }
                    }
                }
                
                // Category B header
                RowLayout {
                    width: parent.width
                    height: 20
                    spacing: 8
                    
                    Text {
                        text: "B"
                        color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.6)
                        font.pixelSize: 12
                        font.bold: true
                    }
                    
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 1
                        color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.2)
                    }
                }
                
                // Category B tiles
                Row {
                    spacing: 8
                    
                    Column {
                        width: 60
                        spacing: 4
                        
                        Rectangle {
                            width: iconSizeModel[iconSizeCombo.currentIndex] > 48 ? 48 : iconSizeModel[iconSizeCombo.currentIndex]
                            height: width
                            anchors.horizontalCenter: parent.horizontalCenter
                            radius: 8
                            color: "transparent"
                            
                            Kirigami.Icon {
                                anchors.centerIn: parent
                                width: parent.width * 0.8
                                height: width
                                source: "folder"
                                color: Kirigami.Theme.textColor
                            }
                        }
                        
                        Text {
                            width: parent.width
                            text: page.tr("file")
                            color: Kirigami.Theme.textColor
                            font.pixelSize: 10
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }
                }
            }
        }
    }
}
