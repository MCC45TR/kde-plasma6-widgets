import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasma5support as PlasmaSupport

Kirigami.FormLayout {
    id: configPrefix
    
    property string title: i18nd("plasma_applet_com.mcc45tr.filesearch", "Prefixes")
    
    // Properties from main.xml
    property bool cfg_prefixDateShowClock: true
    property bool cfg_prefixDateShowEvents: true
    property bool cfg_prefixPowerShowHibernate: false
    property bool cfg_prefixPowerShowSleep: true
    property bool cfg_showBootOptions: false
    // Weather properties
    property bool cfg_weatherEnabled: true
    property string cfg_weatherUnits: "metric"
    property bool cfg_weatherUseSystemUnits: true
    property int cfg_weatherRefreshInterval: 15

    // ... (existing content) ...

    // Weather View Settings
    Label {
        text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Weather View (weather:)")
        font.bold: true
        Layout.fillWidth: true
        Layout.topMargin: 10
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
        id: pmSource
        engine: "powermanagement"
        connectedSources: ["PowerManagement"]
    }
    
    readonly property bool canHibernate: (pmSource.data && pmSource.data["PowerManagement"]) ? pmSource.data["PowerManagement"]["CanHibernate"] : false
    
    // Extra properties to prevent warnings
    property int cfg_searchAlgorithm: 0
    property bool cfg_smartResultLimit: true
    
    // Header
    Kirigami.Separator {
        Kirigami.FormData.isSection: true
        Kirigami.FormData.label: i18nd("plasma_applet_com.mcc45tr.filesearch", "Prefix View Settings")
    }
    
    // Date View Settings
    Label {
        text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Date View (date:)")
        font.bold: true
        Layout.fillWidth: true
    }
    
    CheckBox {
        id: showClockCheck
        text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Show Large Clock")
        checked: cfg_prefixDateShowClock
        onToggled: cfg_prefixDateShowClock = checked
    }
    
    CheckBox {
        id: showEventsCheck
        text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Show Calendar Events")
        checked: cfg_prefixDateShowEvents
        onToggled: cfg_prefixDateShowEvents = checked
    }
    
    // Power View Settings
    Label {
        text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Power View (power:)")
        font.bold: true
        Layout.fillWidth: true
        Layout.topMargin: 10
    }
    
    CheckBox {
        id: showSleepCheck
        text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Show Sleep Button")
        checked: cfg_prefixPowerShowSleep
        onToggled: cfg_prefixPowerShowSleep = checked
    }
    
    CheckBox {
        id: showHibernateCheck
        text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Show Hibernate Button")
        checked: cfg_prefixPowerShowHibernate
        onToggled: cfg_prefixPowerShowHibernate = checked
        enabled: canHibernate
        opacity: enabled ? 1.0 : 0.5
    }
    
    Label {
        padding: 0
        leftPadding: 30 // Indent to align with checkbox text roughly
        visible: !canHibernate
        text: i18nd("plasma_applet_com.mcc45tr.filesearch", "(Swap partition size is smaller than RAM or no swap found)")
        color: Kirigami.Theme.disabledTextColor
        font.pixelSize: Kirigami.Theme.smallFont.pixelSize
        Layout.fillWidth: true
    }

    readonly property bool canReboot: (pmSource.data && pmSource.data["PowerManagement"]) ? pmSource.data["PowerManagement"]["CanReboot"] : true

    CheckBox {
        id: showBootOptionsSearch
        text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Show boot options in Reboot button")
        checked: cfg_showBootOptions
        onToggled: cfg_showBootOptions = checked
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
        columns: 2
        rowSpacing: 10
        columnSpacing: 20
        Layout.fillWidth: true
        Layout.topMargin: 10
        
        // timeline:
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
        Label { 
            text: "power:"
            font.family: "Monospace"
            font.bold: true
            color: Kirigami.Theme.highlightColor
        }
        Label {
            text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Show power management options (Shutdown, Reboot, etc.)")
            Layout.fillWidth: true
        }
        
        // weather:
        Label { 
            text: "weather:"
            font.family: "Monospace"
            font.bold: true
            color: Kirigami.Theme.highlightColor
        }
        Label {
            text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Show current weather")
            Layout.fillWidth: true
        }

        // help:
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
        Label { 
            text: "unit:10km to mi"
            font.family: "Monospace"
            font.bold: true
            color: Kirigami.Theme.highlightColor
        }
        Label {
            text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Convert units (requires KRunner installed)")
            Layout.fillWidth: true
        }
    }
    
    Item { Layout.fillHeight: true }
    
    Kirigami.InlineMessage {
        Layout.fillWidth: true
        type: Kirigami.MessageType.Information
        text: i18nd("plasma_applet_com.mcc45tr.filesearch", "Note: Some prefixes (like unit conversion) depend on installed KRunner runners.")
        visible: true
    }
}
