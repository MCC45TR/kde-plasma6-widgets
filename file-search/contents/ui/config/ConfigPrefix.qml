import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    id: configPrefix
    
    property string title: i18n("Prefixes")
    
    // Properties from main.xml
    property bool cfg_prefixDateShowClock: true
    property bool cfg_prefixDateShowEvents: true
    property bool cfg_prefixPowerShowHibernate: false
    property bool cfg_prefixPowerShowSleep: true
    
    // Extra properties to prevent warnings
    property int cfg_searchAlgorithm: 0
    property bool cfg_smartResultLimit: true
    
    // Header
    Kirigami.Separator {
        Kirigami.FormData.isSection: true
        Kirigami.FormData.label: i18n("Prefix View Settings")
    }
    
    // Date View Settings
    Label {
        text: i18n("Date View (date:)")
        font.bold: true
        Layout.fillWidth: true
    }
    
    CheckBox {
        id: showClockCheck
        text: i18n("Show Large Clock")
        checked: cfg_prefixDateShowClock
        onToggled: cfg_prefixDateShowClock = checked
    }
    
    CheckBox {
        id: showEventsCheck
        text: i18n("Show Calendar Events")
        checked: cfg_prefixDateShowEvents
        onToggled: cfg_prefixDateShowEvents = checked
    }
    
    // Power View Settings
    Label {
        text: i18n("Power View (power:)")
        font.bold: true
        Layout.fillWidth: true
        Layout.topMargin: 10
    }
    
    CheckBox {
        id: showSleepCheck
        text: i18n("Show Sleep Button")
        checked: cfg_prefixPowerShowSleep
        onToggled: cfg_prefixPowerShowSleep = checked
    }
    
    CheckBox {
        id: showHibernateCheck
        text: i18n("Show Hibernate Button")
        checked: cfg_prefixPowerShowHibernate
        onToggled: cfg_prefixPowerShowHibernate = checked
    }
    
    Kirigami.Separator {
        Kirigami.FormData.isSection: true
        Kirigami.FormData.label: i18n("Available Prefixes Reference")
    }
    
    Label {
        text: i18n("These prefixes can be used to perform specific actions directly from the search bar.")
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
            text: i18n("List files modified today")
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
            text: i18n("Search on Google")
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
            text: i18n("Search on DuckDuckGo")
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
            text: i18n("Show calendar and date information")
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
            text: i18n("Show large clock")
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
            text: i18n("Show power management options (Shutdown, Reboot, etc.)")
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
            text: i18n("Show this help screen")
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
            text: i18n("Terminate running processes")
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
            text: i18n("Check spelling of a word")
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
            text: i18n("Execute shell commands")
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
            text: i18n("Convert units (requires KRunner installed)")
            Layout.fillWidth: true
        }
    }
    
    Item { Layout.fillHeight: true }
    
    Kirigami.InlineMessage {
        Layout.fillWidth: true
        type: Kirigami.MessageType.Information
        text: i18n("Note: Some prefixes (like unit conversion) depend on installed KRunner runners.")
        visible: true
    }
}
