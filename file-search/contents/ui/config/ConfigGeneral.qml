import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import org.kde.kirigami as Kirigami
import org.kde.plasma.plasma5support as PlasmaSupport


Item {
    id: configGeneral
    
    // Power Management Source
    PlasmaSupport.DataSource {
        id: pmSource
        engine: "powermanagement"
        connectedSources: ["PowerManagement"]
    }
    
    readonly property bool canHibernate: (pmSource.data && pmSource.data["PowerManagement"]) ? pmSource.data["PowerManagement"]["CanHibernate"] : false
    readonly property bool canReboot: (pmSource.data && pmSource.data["PowerManagement"]) ? pmSource.data["PowerManagement"]["CanReboot"] : true
    
    // Appearance Title
    property string title: i18nd("plasma_applet_com.mcc45tr.filesearch", "Appearance")
    
    // =========================================================================
    // CONFIGURATION PROPERTIES
    // =========================================================================
    
    // Panel (General + Power)
    property alias cfg_displayMode: displayModeCombo.currentIndex
    property alias cfg_panelRadius: panelRadiusCombo.currentIndex
    property int cfg_panelHeight

    property alias cfg_showBootOptions: showBootOptionsSearch.checked
    property int cfg_userProfile
    
    // Popup (View + Search Limits)
    property alias cfg_viewMode: viewModeCombo.currentIndex
    property alias cfg_scrollBarStyle: scrollBarCombo.currentIndex
    property int cfg_iconSize
    property int cfg_listIconSize
    property int cfg_minResults
    property int cfg_maxResults
    property bool cfg_smartResultLimit
    property alias cfg_showPinnedBar: showPinnedBarCheck.checked
    property alias cfg_autoMinimizePinned: autoMinimizePinnedCheck.checked
    property alias cfg_compactPinnedView: tileViewModeCombo.currentIndex
    property int cfg_searchAlgorithm 
    
    // Preview
    property string cfg_previewSettings
    property alias cfg_previewEnabled: masterPreviewSwitch.checked
    
    // Prefix
    property alias cfg_prefixDateShowClock: prefixDateClock.checked
    property alias cfg_prefixDateShowEvents: prefixDateEvents.checked
    property alias cfg_weatherEnabled: weatherEnabledCheck.checked
    property alias cfg_weatherUseSystemUnits: useSystemUnitsCheck.checked
    property int cfg_weatherRefreshInterval

    property alias cfg_prefixPowerShowHibernate: showHibernateCheck.checked
    property alias cfg_prefixPowerShowSleep: prefixPowerSleep.checked
    
    // Placeholder (Search History & Others) - defined to prevent warnings
    property string cfg_searchHistory
    property string cfg_cachedBootEntries
    
    // Other (Defined to prevent warnings)
    property string cfg_pinnedItems
    property string cfg_categorySettings
    property bool cfg_debugOverlay

    property string cfg_telemetryData

    // Missing non-default properties
    property string cfg_weatherUnits
    property double cfg_weatherLastUpdate
    property string cfg_weatherCache

    // Default Properties (Matching main.xml to prevent errors)
    property int cfg_displayModeDefault
    property int cfg_panelRadiusDefault
    property int cfg_panelHeightDefault
    property bool cfg_showBootOptionsDefault
    property int cfg_userProfileDefault
    property int cfg_viewModeDefault
    property int cfg_iconSizeDefault
    property int cfg_listIconSizeDefault
    property int cfg_minResultsDefault
    property int cfg_maxResultsDefault
    property bool cfg_smartResultLimitDefault
    property bool cfg_showPinnedBarDefault
    property bool cfg_autoMinimizePinnedDefault
    // cfg_compactPinnedViewDefault is handled by the alias
    property int cfg_searchAlgorithmDefault
    property string cfg_previewSettingsDefault
    property bool cfg_previewEnabledDefault
    property bool cfg_prefixDateShowClockDefault
    property bool cfg_prefixDateShowEventsDefault
    property bool cfg_weatherEnabledDefault
    property bool cfg_weatherUseSystemUnitsDefault
    property int cfg_weatherRefreshIntervalDefault
    property bool cfg_prefixPowerShowHibernateDefault
    property bool cfg_prefixPowerShowSleepDefault
    property string cfg_searchHistoryDefault
    property string cfg_cachedBootEntriesDefault
    property string cfg_pinnedItemsDefault
    property string cfg_categorySettingsDefault
    property bool cfg_debugOverlayDefault
    property string cfg_telemetryDataDefault
    property string cfg_weatherCacheDefault
    property string cfg_weatherLastUpdateDefault
    property string cfg_weatherUnitsDefault

    // Internal
    property var previewSettings: ({})
    readonly property var iconSizeModel: [16, 22, 32, 48, 64, 128]



    // Init Logic
    Component.onCompleted: {
        try {
            previewSettings = JSON.parse(cfg_previewSettings || '{"images": true, "videos": false, "text": false, "documents": false}')
        } catch (e) {
            previewSettings = {"images": true, "videos": false, "text": false, "documents": false}
        }
    }
    
    // Save Logic for Previews
    function updatePreviewSetting(key, value) {
        var newSettings = Object.assign({}, previewSettings)
        newSettings[key] = value
        previewSettings = newSettings
        cfg_previewSettings = JSON.stringify(previewSettings)
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0
        
        TabBar {
            id: navBar
            Layout.fillWidth: true
            
            TabButton {
                text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Panel")
                icon.name: "dashboard-show"
            }
            TabButton {
                text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Popup")
                icon.name: "window-new"
            }

            TabButton {
                text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Preview")
                icon.name: "view-preview"
            }
            TabButton {
                text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Prefixes")
                icon.name: "code-context"
            }

        }
        
        Frame {
            Layout.fillWidth: true
            Layout.fillHeight: true
            background: Rectangle { color: "transparent" }
            padding: 0
            
            StackLayout {
                anchors.fill: parent
                currentIndex: navBar.currentIndex
                
                // TAB 1: PANEL
                Kirigami.FormLayout {
                    Kirigami.Separator {
                        Kirigami.FormData.label: i18nd("plasma_applet_com.mcc45tr.filesearch", "Panel Appearance")
                        Kirigami.FormData.isSection: true
                    }
                    
                    ComboBox {
                        id: displayModeCombo
                        Kirigami.FormData.label: i18nd("plasma_applet_com.mcc45tr.filesearch", "Display Mode")
                        model: [
                            i18nd("plasma_applet_com.mcc45tr.filesearch", "Button Mode (Icon only)"), 
                            i18nd("plasma_applet_com.mcc45tr.filesearch", "Medium Mode (Text)"), 
                            i18nd("plasma_applet_com.mcc45tr.filesearch", "Wide Mode (Search Bar)"), 
                            i18nd("plasma_applet_com.mcc45tr.filesearch", "Extra Wide Mode")
                        ]
                        Layout.fillWidth: true
                    }

                    ComboBox {
                        id: panelRadiusCombo
                        Kirigami.FormData.label: i18nd("plasma_applet_com.mcc45tr.filesearch", "Edge Appearance")
                        enabled: displayModeCombo.currentIndex !== 0
                        model: [
                            i18nd("plasma_applet_com.mcc45tr.filesearch", "Round corners"),
                            i18nd("plasma_applet_com.mcc45tr.filesearch", "Slightly round"),
                            i18nd("plasma_applet_com.mcc45tr.filesearch", "Less round"),
                            i18nd("plasma_applet_com.mcc45tr.filesearch", "Square corners")
                        ]
                        Layout.fillWidth: true
                    }

                    RowLayout {
                        Kirigami.FormData.label: i18nd("plasma_applet_com.mcc45tr.filesearch", "Panel Height")
                        Layout.fillWidth: true
                        
                        CheckBox {
                            id: autoHeightCheck
                            text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Automatic")
                            checked: cfg_panelHeight === 0
                            onToggled: {
                                if (checked) {
                                    cfg_panelHeight = 0
                                } else {
                                    cfg_panelHeight = panelHeightSpin.value
                                }
                            }
                        }
                        
                        SpinBox {
                            id: panelHeightSpin
                            from: 18
                            to: 96
                            stepSize: 1
                            editable: true
                            enabled: !autoHeightCheck.checked
                            Layout.fillWidth: true
                            
                            Component.onCompleted: {
                                if (cfg_panelHeight > 0) {
                                    value = cfg_panelHeight
                                } else {
                                    value = 32 // Default fallback
                                }
                            }
                            
                            onValueModified: {
                                if (!autoHeightCheck.checked) {
                                    cfg_panelHeight = value
                                }
                            }
                            
                            textFromValue: function(value, locale) {
                                return value + " px"
                            }
                            valueFromText: function(text, locale) {
                                return Number.fromLocaleString(locale, text.replace(" px", ""))
                            }
                        }
                    }
                    
                    // Panel Preview
                    Item {
                        Kirigami.FormData.label: i18nd("plasma_applet_com.mcc45tr.filesearch", "Panel Preview")
                        Layout.fillWidth: true
                        Layout.preferredHeight: 50
                        
                        // Button Mode
                        Rectangle {
                            anchors.left: parent.left
                            width: 36
                            height: 36
                            radius: panelRadiusCombo.currentIndex === 0 ? width / 2 : (panelRadiusCombo.currentIndex === 1 ? 12 : (panelRadiusCombo.currentIndex === 2 ? 6 : 0))
                            color: Kirigami.Theme.backgroundColor
                            border.width: 1
                            border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.2)
                            visible: displayModeCombo.currentIndex === 0
                            
                            Kirigami.Icon {
                                anchors.centerIn: parent
                                width: 18
                                height: 18
                                source: "plasma-search"
                                color: Kirigami.Theme.textColor
                            }
                        }
                        
                        // Text/Bar Mode
                        Rectangle {
                            anchors.left: parent.left
                            width: displayModeCombo.currentIndex === 1 ? 70 : (displayModeCombo.currentIndex === 3 ? 260 : 180)
                            height: 36
                            radius: panelRadiusCombo.currentIndex === 0 ? height / 2 : (panelRadiusCombo.currentIndex === 1 ? 12 : (panelRadiusCombo.currentIndex === 2 ? 6 : 0))
                            color: Kirigami.Theme.backgroundColor
                            border.width: 1
                            border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.2)
                            visible: displayModeCombo.currentIndex !== 0
                            
                            Behavior on width { NumberAnimation { duration: 200 } }
                            
                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 6
                                spacing: 8
                                
                                Text {
                                    text: displayModeCombo.currentIndex === 1 ? i18nd("plasma_applet_com.mcc45tr.filesearch", "Search") : (displayModeCombo.currentIndex === 3 ? i18nd("plasma_applet_com.mcc45tr.filesearch", "Start searching...") : i18nd("plasma_applet_com.mcc45tr.filesearch", "Search..."))
                                    color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.6)
                                    font.pixelSize: displayModeCombo.currentIndex !== 1 ? 14 : 12
                                    Layout.fillWidth: true
                                    horizontalAlignment: displayModeCombo.currentIndex === 1 ? Text.AlignHCenter : Text.AlignLeft
                                }
                                                                Rectangle {
                                        Layout.preferredWidth: (displayModeCombo.currentIndex === 2 || displayModeCombo.currentIndex === 3) ? 28 : 0
                                        Layout.preferredHeight: 28
                                        radius: panelRadiusCombo.currentIndex === 0 ? height / 2 : (panelRadiusCombo.currentIndex === 1 ? 8 : (panelRadiusCombo.currentIndex === 2 ? 4 : 0))
                                        color: Kirigami.Theme.highlightColor
                                        visible: displayModeCombo.currentIndex === 2 || displayModeCombo.currentIndex === 3
                                        
                                        Kirigami.Icon {
                                            anchors.centerIn: parent
                                            width: 16
                                            height: 16
                                            source: "search"
                                            color: "#ffffff"
                                        }
                                    }                          }
                        }
                    }


                }
                
                // TAB 2: POPUP
                Kirigami.FormLayout {
                     Kirigami.Separator {
                        Kirigami.FormData.label: i18nd("plasma_applet_com.mcc45tr.filesearch", "Results View")
                        Kirigami.FormData.isSection: true
                    }
                    
                    ComboBox {
                        id: viewModeCombo
                        Kirigami.FormData.label: i18nd("plasma_applet_com.mcc45tr.filesearch", "View Mode")
                        model: [i18nd("plasma_applet_com.mcc45tr.filesearch", "List View"), i18nd("plasma_applet_com.mcc45tr.filesearch", "Tile View")]
                        Layout.fillWidth: true
                    }
                    
                    ComboBox {
                        id: scrollBarCombo
                        Kirigami.FormData.label: i18nd("plasma_applet_com.mcc45tr.filesearch", "Scroll Bar")
                        model: [
                            i18nd("plasma_applet_com.mcc45tr.filesearch", "System Default"), 
                            i18nd("plasma_applet_com.mcc45tr.filesearch", "Minimal (Custom)"), 
                            i18nd("plasma_applet_com.mcc45tr.filesearch", "Hidden")
                        ]
                        Layout.fillWidth: true
                    }
                    
                    // Icon Size Logic
                    ComboBox {
                        id: listIconSizeCombo
                        Kirigami.FormData.label: i18nd("plasma_applet_com.mcc45tr.filesearch", "List Icon Size")
                        model: ["16", "22", "32", "48", "64", "128"]
                        visible: viewModeCombo.currentIndex === 0
                        onActivated: cfg_listIconSize = parseInt(currentText)
                        Component.onCompleted: currentIndex = model.indexOf(String(cfg_listIconSize))
                    }
                     ComboBox {
                        id: tileIconSizeCombo
                        Kirigami.FormData.label: i18nd("plasma_applet_com.mcc45tr.filesearch", "Tile Icon Size")
                        model: ["16", "22", "32", "48", "64", "128"]
                        visible: viewModeCombo.currentIndex === 1
                        onActivated: cfg_iconSize = parseInt(currentText)
                        Component.onCompleted: currentIndex = model.indexOf(String(cfg_iconSize))
                    }
                    
                    ColumnLayout {
                        Kirigami.FormData.label: i18nd("plasma_applet_com.mcc45tr.filesearch", "Pinned Items")
                        spacing: Kirigami.Units.smallSpacing
                        
                        CheckBox {
                            id: showPinnedBarCheck
                            text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Show pinned items bar")
                            checked: cfg_showPinnedBar
                        }
                        
                        CheckBox {
                            id: autoMinimizePinnedCheck
                            text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Minimize automatically when searching")
                            checked: cfg_autoMinimizePinned
                            enabled: showPinnedBarCheck.checked
                        }
                    }
                    
                    // Tile View Mode ComboBox
                    ComboBox {
                        id: tileViewModeCombo
                        Kirigami.FormData.label: i18nd("plasma_applet_com.mcc45tr.filesearch", "Tile Size Mode")
                        enabled: viewModeCombo.currentIndex === 1
                        model: [
                            i18nd("plasma_applet_com.mcc45tr.filesearch", "Normal (wide tiles)"),
                            i18nd("plasma_applet_com.mcc45tr.filesearch", "Compact (all small)"),
                            i18nd("plasma_applet_com.mcc45tr.filesearch", "Only pinned compact"),
                            i18nd("plasma_applet_com.mcc45tr.filesearch", "Only history/results compact")
                        ]
                        Layout.fillWidth: true
                        // currentIndex is bound via alias to cfg_compactPinnedView
                    }
                    
                    // Popup Preview
                    Item {
                        Kirigami.FormData.label: i18nd("plasma_applet_com.mcc45tr.filesearch", "Preview")
                        Layout.fillWidth: true
                        implicitHeight: 150
                        Layout.minimumHeight: 150
                        
                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 0
                            radius: 6
                            color: Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.1)
                            border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.2)
                            border.width: 1
                            clip: true
                            
                            // List View Mockup
                            ColumnLayout {
                                anchors.centerIn: parent
                                width: parent.width - 40
                                visible: viewModeCombo.currentIndex === 0
                                spacing: 12
                                
                                RowLayout {
                                    spacing: 15
                                    Kirigami.Icon { 
                                        source: "applications-system"
                                        Layout.preferredWidth: cfg_listIconSize
                                        Layout.preferredHeight: cfg_listIconSize
                                    }
                                    Label { 
                                        text: i18nd("plasma_applet_com.mcc45tr.filesearch", "System Settings")
                                        Layout.fillWidth: true 
                                        font.bold: true 
                                        color: Kirigami.Theme.textColor
                                    }
                                }
                                
                                Rectangle { 
                                    height: 1
                                    Layout.fillWidth: true
                                    color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.15) 
                                }
                                
                                RowLayout {
                                    spacing: 15
                                    Kirigami.Icon { 
                                        source: "folder-documents"
                                        Layout.preferredWidth: cfg_listIconSize
                                        Layout.preferredHeight: cfg_listIconSize
                                    }
                                    Label { 
                                        text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Documents")
                                        Layout.fillWidth: true 
                                        font.bold: true 
                                        color: Kirigami.Theme.textColor
                                    }
                                }
                            }
                            
                            // Tile View Mockup
                            RowLayout {
                                anchors.centerIn: parent
                                visible: viewModeCombo.currentIndex === 1
                                spacing: 40
                                
                                ColumnLayout {
                                    spacing: 10
                                    Kirigami.Icon { 
                                        source: "applications-system"
                                        Layout.preferredWidth: cfg_iconSize
                                        Layout.preferredHeight: cfg_iconSize
                                        Layout.alignment: Qt.AlignHCenter
                                    }
                                    Label { 
                                        text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Settings")
                                        font.pixelSize: 12
                                        Layout.alignment: Qt.AlignHCenter 
                                        color: Kirigami.Theme.textColor
                                    }
                                }
                                ColumnLayout {
                                    spacing: 10
                                    Kirigami.Icon { 
                                        source: "folder-documents"
                                        Layout.preferredWidth: cfg_iconSize
                                        Layout.preferredHeight: cfg_iconSize
                                        Layout.alignment: Qt.AlignHCenter
                                    }
                                    Label { 
                                        text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Docs")
                                        font.pixelSize: 12
                                        Layout.alignment: Qt.AlignHCenter 
                                        color: Kirigami.Theme.textColor
                                    }
                                }
                            }
                        }
                    }
                }


                
                // TAB 4: PREVIEW
                Kirigami.FormLayout {
                     Switch {
                        id: masterPreviewSwitch
                        text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Enable File Previews")
                        Kirigami.FormData.label: i18nd("plasma_applet_com.mcc45tr.filesearch", "Show/Hide Previews")
                        onCheckedChanged: cfg_previewEnabled = checked
                     }
                     
                    Kirigami.Separator {
                        Kirigami.FormData.label: i18nd("plasma_applet_com.mcc45tr.filesearch", "Preview Types")
                        Kirigami.FormData.isSection: true
                    }
                    
                    // Images
                    RowLayout {
                        Layout.topMargin: Kirigami.Units.largeSpacing
                        spacing: Kirigami.Units.largeSpacing
                        Kirigami.Icon {
                            source: "image-x-generic"
                            Layout.preferredWidth: 32
                            Layout.preferredHeight: 32
                            Layout.alignment: Qt.AlignTop
                            Layout.topMargin: 4
                        }
                        ColumnLayout {
                            spacing: 0
                            CheckBox {
                                text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Images")
                                checked: previewSettings.images || false
                                onToggled: updatePreviewSetting("images", checked)
                                enabled: masterPreviewSwitch.checked
                            }
                            Label {
                                text: "png, jpg, jpeg, gif, bmp, svg, webp, tiff, ico"
                                font.pixelSize: Kirigami.Theme.smallFont.pixelSize * 0.9
                                color: Kirigami.Theme.textColor
                                opacity: 0.6
                                Layout.leftMargin: Kirigami.Units.largeSpacing + Kirigami.Units.smallSpacing
                            }
                        }
                    }
                    
                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: Kirigami.Theme.textColor
                        opacity: 0.1
                        Layout.topMargin: Kirigami.Units.smallSpacing
                        Layout.bottomMargin: Kirigami.Units.smallSpacing
                    }

                    // Videos
                    RowLayout {
                        spacing: Kirigami.Units.largeSpacing
                        Kirigami.Icon {
                            source: "video-x-generic"
                            Layout.preferredWidth: 32
                            Layout.preferredHeight: 32
                            Layout.alignment: Qt.AlignTop
                            Layout.topMargin: 4
                        }
                        ColumnLayout {
                            spacing: 0
                            CheckBox {
                                text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Videos")
                                checked: previewSettings.videos || false
                                onToggled: updatePreviewSetting("videos", checked)
                                enabled: masterPreviewSwitch.checked
                            }
                            Label {
                                text: "mp4, mkv, avi, mov, webm, flv, wmv, m4v"
                                font.pixelSize: Kirigami.Theme.smallFont.pixelSize * 0.9
                                color: Kirigami.Theme.textColor
                                opacity: 0.6
                                Layout.leftMargin: Kirigami.Units.largeSpacing + Kirigami.Units.smallSpacing
                            }
                        }
                    }
                    
                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: Kirigami.Theme.textColor
                        opacity: 0.1
                        Layout.topMargin: Kirigami.Units.smallSpacing
                        Layout.bottomMargin: Kirigami.Units.smallSpacing
                    }

                    // Text Files
                    RowLayout {
                        spacing: Kirigami.Units.largeSpacing
                        Kirigami.Icon {
                            source: "text-x-generic"
                            Layout.preferredWidth: 32
                            Layout.preferredHeight: 32
                            Layout.alignment: Qt.AlignTop
                            Layout.topMargin: 4
                        }
                        ColumnLayout {
                            spacing: 0
                            CheckBox {
                                text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Text Files")
                                checked: previewSettings.text || false
                                onToggled: updatePreviewSetting("text", checked)
                                enabled: masterPreviewSwitch.checked
                            }
                            Label {
                                text: "txt, md, log, ini, cfg, conf, json, xml, yml, yaml, qml, js, py, cpp, h, c, sh"
                                font.pixelSize: Kirigami.Theme.smallFont.pixelSize * 0.9
                                color: Kirigami.Theme.textColor
                                opacity: 0.6
                                Layout.leftMargin: Kirigami.Units.largeSpacing + Kirigami.Units.smallSpacing
                            }
                        }
                    }
                    
                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: Kirigami.Theme.textColor
                        opacity: 0.1
                        Layout.topMargin: Kirigami.Units.smallSpacing
                        Layout.bottomMargin: Kirigami.Units.smallSpacing
                    }

                    // Documents
                    RowLayout {
                        spacing: Kirigami.Units.largeSpacing
                        Kirigami.Icon {
                            source: "x-office-document"
                            Layout.preferredWidth: 32
                            Layout.preferredHeight: 32
                            Layout.alignment: Qt.AlignTop
                            Layout.topMargin: 4
                        }
                        ColumnLayout {
                            spacing: 0
                            CheckBox {
                                text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Documents")
                                checked: previewSettings.documents || false
                                onToggled: updatePreviewSetting("documents", checked)
                                enabled: masterPreviewSwitch.checked
                            }
                            Label {
                                text: "pdf, doc, docx, odt, ods, odp, ppt, pptx, xls, xlsx, kkra, cbz"
                                font.pixelSize: Kirigami.Theme.smallFont.pixelSize * 0.9
                                color: Kirigami.Theme.textColor
                                opacity: 0.6
                                Layout.leftMargin: Kirigami.Units.largeSpacing + Kirigami.Units.smallSpacing
                            }
                        }
                    }
                }
                
                // TAB 4: PREFIXES
                Kirigami.FormLayout {
                    Kirigami.Separator {
                        Kirigami.FormData.label: i18nd("plasma_applet_com.mcc45tr.filesearch", "Date View (date:)")
                        Kirigami.FormData.isSection: true
                    }
                    CheckBox {
                        id: prefixDateClock
                        text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Show Large Clock")
                    }
                    CheckBox {
                        id: prefixDateEvents
                        text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Show Calendar Events")
                    }

                    // Weather View Settings
                    Kirigami.Separator {
                        Kirigami.FormData.label: i18nd("plasma_applet_com.mcc45tr.filesearch", "Weather View (weather:)")
                        Kirigami.FormData.isSection: true
                    }

                    CheckBox {
                        id: weatherEnabledCheck
                        text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Enable Weather Prefix")
                        checked: cfg_weatherEnabled
                        onToggled: cfg_weatherEnabled = checked
                    }

                    // Group enabled state based on master toggle
                    ColumnLayout {
                        Layout.fillWidth: true
                        enabled: cfg_weatherEnabled
                        opacity: enabled ? 1.0 : 0.5
                    
                        CheckBox {
                            id: useSystemUnitsCheck
                            text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Use System Units")
                            checked: cfg_weatherUseSystemUnits
                            onToggled: cfg_weatherUseSystemUnits = checked
                        }
                        
                        RowLayout {
                            Layout.fillWidth: true
                            
                            Label { 
                                text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Refresh Interval:") 
                            }
                            
                            ComboBox {
                                id: refreshIntervalCombo
                                model: [
                                    i18nd("plasma_applet_com.mcc45tr.filesearch", "Every Search"), 
                                    i18nd("plasma_applet_com.mcc45tr.filesearch", "15 Minutes"), 
                                    i18nd("plasma_applet_com.mcc45tr.filesearch", "30 Minutes"), 
                                    i18nd("plasma_applet_com.mcc45tr.filesearch", "1 Hour")
                                ]
                                
                                Component.onCompleted: {
                                    if (cfg_weatherRefreshInterval === 0) currentIndex = 0
                                    else if (cfg_weatherRefreshInterval === 15) currentIndex = 1
                                    else if (cfg_weatherRefreshInterval === 30) currentIndex = 2
                                    else if (cfg_weatherRefreshInterval === 60) currentIndex = 3
                                    else currentIndex = 1 // default 15
                                }
                                
                                onActivated: {
                                    if (index === 0) cfg_weatherRefreshInterval = 0
                                    else if (index === 1) cfg_weatherRefreshInterval = 15
                                    else if (index === 2) cfg_weatherRefreshInterval = 30
                                    else if (index === 3) cfg_weatherRefreshInterval = 60
                                }
                            }
                            
                            Label {
                                text: i18nd("plasma_applet_com.mcc45tr.filesearch", "(If time since last update > interval)")
                                font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                                color: Kirigami.Theme.disabledTextColor
                            }
                        }
                    } // End ColumnLayout
                    Kirigami.Separator {
                        Kirigami.FormData.label: i18nd("plasma_applet_com.mcc45tr.filesearch", "Power View (power:)")
                        Kirigami.FormData.isSection: true
                    }
                    CheckBox {
                        id: prefixPowerSleep
                        text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Show Sleep Button")
                    }
                    CheckBox {
                        id: showHibernateCheck
                        text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Show Hibernate Button")
                        enabled: canHibernate
                        opacity: enabled ? 1.0 : 0.5
                    }
                    
                    Label {
                        padding: 0
                        leftPadding: 30
                        visible: !canHibernate
                        text: i18nd("plasma_applet_com.mcc45tr.filesearch", "(Swap partition size is smaller than RAM or no swap found)")
                        color: Kirigami.Theme.disabledTextColor
                        font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                        Layout.fillWidth: true
                    }
                    
                    CheckBox {
                        id: showBootOptionsSearch
                        text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Show boot options in Reboot button")
                        enabled: canReboot
                        opacity: enabled ? 1.0 : 0.5
                    }
                    
                    Label {
                        padding: 0
                        leftPadding: 30
                        text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Note: Systemd boot is required for this feature")
                        color: Kirigami.Theme.disabledTextColor
                        font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                        Layout.fillWidth: true
                    }

                    Kirigami.Separator {
                        Kirigami.FormData.isSection: true
                        Kirigami.FormData.label: i18nd("plasma_applet_com.mcc45tr.filesearch", "Available Prefixes Reference")
                    }
                    
                    Label {
                        text: i18nd("plasma_applet_com.mcc45tr.filesearch", "These prefixes can be used to perform specific actions directly from the search bar.")
                        wrapMode: Text.Wrap
                        Layout.fillWidth: true
                        opacity: 0.7
                    }
                    
                    // Prefixes List
                    GridLayout {
                        columns: 3
                        rowSpacing: 10
                        columnSpacing: 10
                        Layout.fillWidth: true
                        Layout.topMargin: 10
                        
                        // timeline:
                        Kirigami.Icon { source: "view-calendar-timeline"; Layout.preferredWidth: 16; Layout.preferredHeight: 16 }
                        Label { 
                            text: "timeline:/today"
                            font.family: "Monospace"
                            font.bold: true
                            color: Kirigami.Theme.highlightColor
                        }
                        Label {
                            text: i18nd("plasma_applet_com.mcc45tr.filesearch", "List files modified today")
                            Layout.fillWidth: true
                        }
                
                        // gg:
                        Kirigami.Icon { source: "im-google"; Layout.preferredWidth: 16; Layout.preferredHeight: 16 }
                        Label { 
                            text: "gg:search_term"
                            font.family: "Monospace"
                            font.bold: true
                            color: Kirigami.Theme.highlightColor
                        }
                        Label {
                                    text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Search on Google")
                                    Layout.fillWidth: true
                                }
                        
                        // dd:
                        Kirigami.Icon { source: "edit-find"; Layout.preferredWidth: 16; Layout.preferredHeight: 16 }
                        Label { 
                            text: "dd:search_term"
                            font.family: "Monospace"
                            font.bold: true
                            color: Kirigami.Theme.highlightColor
                        }
                        Label {
                                    text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Search on DuckDuckGo")
                                    Layout.fillWidth: true
                                }
                        
                        // date:
                        Kirigami.Icon { source: "view-calendar-day"; Layout.preferredWidth: 16; Layout.preferredHeight: 16 }
                        Label { 
                            text: "date:"
                            font.family: "Monospace"
                            font.bold: true
                            color: Kirigami.Theme.highlightColor
                        }
                        Label {
                                    text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Show calendar and date information")
                                    Layout.fillWidth: true
                                }
                        
                        // clock:
                        Kirigami.Icon { source: "preferences-system-time"; Layout.preferredWidth: 16; Layout.preferredHeight: 16 }
                        Label { 
                            text: "clock:"
                            font.family: "Monospace"
                            font.bold: true
                            color: Kirigami.Theme.highlightColor
                        }
                        Label {
                                    text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Show large clock")
                                    Layout.fillWidth: true
                                }
                        
                        // power:
                        Kirigami.Icon { source: "system-log-out"; Layout.preferredWidth: 16; Layout.preferredHeight: 16 }
                        Label { 
                            text: "power:"
                            font.family: "Monospace"
                            font.bold: true
                            color: Kirigami.Theme.highlightColor
                        }
                        Label {
                                    text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Show power management options")
                                    Layout.fillWidth: true
                                }
                        
                        // help:
                        Kirigami.Icon { source: "help-contents"; Layout.preferredWidth: 16; Layout.preferredHeight: 16 }
                        Label { 
                            text: "help:"
                            font.family: "Monospace"
                            font.bold: true
                            color: Kirigami.Theme.highlightColor
                        }
                        Label {
                                    text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Show this help screen")
                                    Layout.fillWidth: true
                                }
                        
                        // kill
                        Kirigami.Icon { source: "process-stop"; Layout.preferredWidth: 16; Layout.preferredHeight: 16 }
                        Label { 
                            text: "kill process_name"
                            font.family: "Monospace"
                            font.bold: true
                            color: Kirigami.Theme.highlightColor
                        }
                        Label {
                                    text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Terminate running processes")
                                    Layout.fillWidth: true
                                }
                        
                        // spell
                        Kirigami.Icon { source: "tools-check-spelling"; Layout.preferredWidth: 16; Layout.preferredHeight: 16 }
                        Label { 
                            text: "spell word"
                            font.family: "Monospace"
                            font.bold: true
                            color: Kirigami.Theme.highlightColor
                        }
                        Label {
                                    text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Check spelling of a word")
                                    Layout.fillWidth: true
                                }
                        
                        // shell:
                        Kirigami.Icon { source: "utilities-terminal"; Layout.preferredWidth: 16; Layout.preferredHeight: 16 }
                        Label { 
                            text: "shell:command"
                            font.family: "Monospace"
                            font.bold: true
                            color: Kirigami.Theme.highlightColor
                        }
                        Label {
                                    text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Execute shell commands")
                                    Layout.fillWidth: true
                                }
                
                        // unit:
                        Kirigami.Icon { source: "accessories-calculator"; Layout.preferredWidth: 16; Layout.preferredHeight: 16 }
                        Label { 
                            text: "unit:10km to mi"
                            font.family: "Monospace"
                            font.bold: true
                            color: Kirigami.Theme.highlightColor
                        }
                        Label {
                                    text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Convert units (requires KRunner)")
                                    Layout.fillWidth: true
                                }
                    }
                }       
            }
        }
    }
}