import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami



Kirigami.FormLayout {
    id: page
    
    // ===== Configuration Properties (mapped from main.xml) =====
    // Display and View
    property alias cfg_displayMode: modeCombo.currentIndex
    property alias cfg_viewMode: viewModeCombo.currentIndex
    property int cfg_iconSize
    property int cfg_listIconSize
    property alias cfg_userProfile: profileCombo.currentIndex
    
    // Preview Settings
    property bool cfg_previewEnabled: true
    property string cfg_previewSettings: "{}"
    
    // Debug and Telemetry
    property bool cfg_debugOverlay: false
    property string cfg_telemetryData: "{}"
    
    // Data Storage (not editable in General, but needed for property injection)
    property string cfg_searchHistory: ""
    property string cfg_pinnedItems: "[]"
    property string cfg_categorySettings: "{}"
    
    // Search Settings
    property int cfg_searchAlgorithm: 0
    property int cfg_minResults: 3
    property int cfg_maxResults: 20
    property bool cfg_smartResultLimit: true
    
    // ===== Default Values (mapped from main.xml for Reset functionality) =====
    // Display and View
    property int cfg_displayModeDefault: 1
    property int cfg_viewModeDefault: 0
    property int cfg_iconSizeDefault: 48
    property int cfg_listIconSizeDefault: 22
    property int cfg_userProfileDefault: 0
    
    // Preview Settings
    property bool cfg_previewEnabledDefault: true
    property string cfg_previewSettingsDefault: "{\"images\": true, \"videos\": false, \"text\": false, \"documents\": false}"
    
    // Debug and Telemetry
    property bool cfg_debugOverlayDefault: false
    property string cfg_telemetryDataDefault: "{}"
    
    // Data Storage
    property string cfg_searchHistoryDefault: ""
    property string cfg_pinnedItemsDefault: "[]"
    property string cfg_categorySettingsDefault: "{}"
    
    // Search Settings
    property int cfg_searchAlgorithmDefault: 0
    property int cfg_minResultsDefault: 3
    property int cfg_maxResultsDefault: 20
    property bool cfg_smartResultLimitDefault: true
    
    // --- Localization removed
    // Use standard i18n()
    // --- End Localization Logic ---
    
    // Icon size options
    readonly property var iconSizeModel: [16, 22, 32, 48, 64, 128]
    
    // Profile Selector
    Kirigami.Separator {
        Kirigami.FormData.isSection: true
        Kirigami.FormData.label: i18n("General Settings")
    }
    
    ComboBox {
        id: profileCombo
        Kirigami.FormData.label: i18n("User Profile")
        model: [
            i18n("Minimal"),
            i18n("Developer"),
            i18n("Power User")
        ]
        Layout.fillWidth: true
    }
    
    Label {
        text: {
            switch(profileCombo.currentIndex) {
                case 0: return i18n("A simplified interface with essential features.")
                case 1: return i18n("Debug tab active, developer features enabled.")
                case 2: return i18n("All features active, advanced settings available.")
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
        Kirigami.FormData.label: i18n("Appearance")
    }

    ComboBox {
        id: modeCombo
        Kirigami.FormData.label: i18n("Panel View")
        model: [
            i18n("Button Mode"), 
            i18n("Medium Mode"), 
            i18n("Wide Mode"), 
            i18n("Extra Wide Mode")
        ]
        Layout.fillWidth: true
    }
    
    ComboBox {
        id: viewModeCombo
        Kirigami.FormData.label: i18n("Results View")
        model: [i18n("List View"), i18n("Tile View")]
        Layout.fillWidth: true
    }
    
    // List Icon Size Selector
    ComboBox {
        id: listIconSizeCombo
        Kirigami.FormData.label: i18n("List Icon Size")
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
        Kirigami.FormData.label: i18n("Tile Icon Size")
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
        Kirigami.FormData.label: i18n("Panel Preview")
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
                    text: modeCombo.currentIndex === 1 ? i18n("Search") : (modeCombo.currentIndex === 3 ? i18n("Start searching...") : i18n("Search..."))
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
        Kirigami.FormData.label: i18n("Results Preview")
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
                    model: ["App 1", "App 2", "File.txt"]
                    
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
                            text: "File"
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
