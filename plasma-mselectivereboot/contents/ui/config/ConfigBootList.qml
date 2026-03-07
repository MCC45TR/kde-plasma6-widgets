import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasma5support as Plasma5Support
import QtQml.Models
import org.kde.iconthemes as KIconThemes

Item {
    id: page
    
    property string title: i18n("Boot List")
    
    property string cfg_customEntryRules: "[]"
    property string cfg_customEntryRulesDefault: "[]"
    property string cfg_cachedBootEntries: ""
    property string cfg_cachedBootEntriesDefault: ""
    
    // Dummy properties for KCM compatibility
    property double cfg_backgroundOpacity
    property double cfg_backgroundOpacityDefault
    property string cfg_cachedBootloader
    property string cfg_cachedBootloaderDefault
    property int cfg_edgeMargin
    property int cfg_edgeMarginDefault
    property int cfg_listItemHeight
    property int cfg_listItemHeightDefault
    property int cfg_viewMode
    property int cfg_viewModeDefault
    
    onCfg_cachedBootEntriesChanged: refreshModel()
    onCfg_customEntryRulesChanged: refreshModel()
    
    KIconThemes.IconDialog {
        id: iconDialog
        property int targetIndex: -1
        onIconNameChanged: iconName => {
            if (targetIndex !== -1 && iconName !== "") {
                bootListModel.setProperty(targetIndex, "customIcon", iconName)
                saveRules()
            }
            targetIndex = -1
        }
    }

    function getFallbackIcon(t, i) {
        t = (t || "").toLowerCase()
        i = (i || "").toLowerCase()
        if (i === "auto-reboot-to-firmware-setup" || i === "uefi-firmware" || t.includes("bios") || t.includes("firmware")) return "application-x-firmware"
        if (t.includes("limine") || i.includes("limine")) return "org.xfce.terminal-settings"
        if (t.includes("arch") || i.includes("arch")) return "distributor-logo-archlinux"
        if (t.includes("manjaro")) return "distributor-logo-manjaro"
        if (t.includes("endeavour")) return "distributor-logo-endeavouros"
        if (t.includes("garuda")) return "distributor-logo-garuda"
        if (t.includes("cachyos")) return "distributor-logo-cachyos"
        if (t.includes("gentoo")) return "distributor-logo-gentoo"
        if (t.includes("windows") || i.includes("windows")) return "distributor-logo-windows"
        if (t.includes("kubuntu")) return "distributor-logo-kubuntu"
        if (t.includes("xubuntu")) return "distributor-logo-xubuntu"
        if (t.includes("lubuntu")) return "distributor-logo-lubuntu"
        if (t.includes("neon")) return "distributor-logo-neon"
        if (t.includes("ubuntu")) return "distributor-logo-ubuntu"
        if (t.includes("fedora")) return "distributor-logo-fedora"
        if (t.includes("opensuse") || t.includes("suse")) return "distributor-logo-opensuse"
        if (t.includes("debian")) return "distributor-logo-debian"
        if (t.includes("kali")) return "distributor-logo-kali"
        if (t.includes("mint")) return "distributor-logo-linuxmint"
        if (t.includes("elementary")) return "distributor-logo-elementary"
        if (t.includes("pop") && t.includes("os")) return "distributor-logo-pop-os"
        if (t.includes("centos")) return "distributor-logo-centos"
        if (t.includes("alma")) return "distributor-logo-almalinux"
        if (t.includes("rocky")) return "distributor-logo-rocky"
        if (t.includes("rhel") || t.includes("redhat")) return "distributor-logo-redhat"
        if (t.includes("nixos")) return "distributor-logo-nixos"
        if (t.includes("void")) return "distributor-logo-void"
        if (t.includes("mageia")) return "distributor-logo-mageia"
        if (t.includes("zorin")) return "distributor-logo-zorin"
        if (t.includes("freebsd")) return "distributor-logo-freebsd"
        if (t.includes("android")) return "distributor-logo-android"
        if (t.includes("qubes")) return "distributor-logo-qubes"
        if (t.includes("slackware")) return "distributor-logo-slackware"
        if (t.includes("alpine")) return "distributor-logo-alpine"
        if (t.includes("deepin")) return "distributor-logo-deepin"
        if (t.includes("mx ") || t.includes("mxlinux")) return "distributor-logo-mx"
        if (t.includes("parrot")) return "distributor-logo-parrot"
        if (t.includes("solus")) return "distributor-logo-solus"
        if (t.includes("steamos")) return "distributor-logo-steamos"
        return "system-run"
    }
    
    ListModel {
        id: bootListModel
    }
    
    // Internal function to combine cache + current rules on tab load
    function refreshModel() {
        bootListModel.clear()
        if (cfg_cachedBootEntries === "") return
        try {
            var entries = JSON.parse(cfg_cachedBootEntries)
            var rules = []
            if (cfg_customEntryRules !== "" && cfg_customEntryRules !== "[]") {
                rules = JSON.parse(cfg_customEntryRules)
            }
            
            var rulesMap = {}
            for (var r=0; r<rules.length; r++) {
               rulesMap[rules[r].id] = rules[r]
            }
            
            var addedIds = {}
            
            // 1. Add customized components in sorted order
            for (var i=0; i<rules.length; i++) {
                var rule = rules[i]
                var found = null
                for(var e=0; e<entries.length; e++) {
                   if (entries[e].id === rule.id) {
                      found = entries[e]
                      break
                   }
                }
                
                if (found) {
                   bootListModel.append({
                       entryId: found.id,
                       originalTitle: found.title,
                       titleToDisplay: rule.customTitle ? rule.customTitle : found.title,
                       isHidden: rule.isHidden !== undefined ? rule.isHidden : false,
                       customIcon: rule.customIcon ? rule.customIcon : ""
                   })
                   addedIds[found.id] = true
                }
            }
            // 2. Add remaining uncustomized
            for (var j=0; j<entries.length; j++) {
                if (!addedIds[entries[j].id]) {
                   bootListModel.append({
                       entryId: entries[j].id,
                       originalTitle: entries[j].title,
                       titleToDisplay: entries[j].title,
                       isHidden: false,
                       customIcon: ""
                   })
                }
            }
        } catch(e) { console.error("ConfigBootList: Error loading lists - " + e) }
    }
    
    Component.onCompleted: refreshModel()
    
    function saveRules() {
        var rules = []
        for (var i=0; i<bootListModel.count; i++) {
            var item = bootListModel.get(i)
            rules.push({
                id: item.entryId,
                isHidden: item.isHidden,
                customTitle: item.titleToDisplay !== item.originalTitle ? item.titleToDisplay : "",
                customIcon: item.customIcon,
                orderIndex: i
            })
        }
        page.cfg_customEntryRules = JSON.stringify(rules)
    }

    ColumnLayout {
         anchors.fill: parent
         anchors.margins: Kirigami.Units.largeSpacing
         spacing: Kirigami.Units.smallSpacing

         Label {
             Layout.fillWidth: true
             text: i18n("Reorder entries by dragging. Configure visibility and custom names.")
             color: Kirigami.Theme.disabledTextColor
             wrapMode: Text.WordWrap
         }

         ListView {
             id: entryListView
             Layout.fillWidth: true
             Layout.fillHeight: true
             clip: true
             model: bootListModel
             
             delegate: Item {
                 id: delegateRoot
                 width: ListView.view.width
                 height: Kirigami.Units.iconSizes.huge
                 
                 property bool isUpdating: false
                 
                 Rectangle {
                     anchors.fill: parent
                     anchors.margins: 4
                     color: Kirigami.Theme.backgroundColor
                     border.color: Kirigami.Theme.disabledTextColor
                     radius: 4
                     opacity: model.isHidden ? 0.6 : 1.0
                     
                     RowLayout {
                         anchors.fill: parent
                         anchors.margins: Kirigami.Units.smallSpacing
                         
                         // Icon button (Click to select custom icon)
                         Button {
                             Layout.minimumWidth: Kirigami.Units.iconSizes.medium
                             icon.name: model.customIcon !== "" ? model.customIcon : page.getFallbackIcon(model.originalTitle, model.entryId)
                             flat: true
                             ToolTip.visible: hovered
                             ToolTip.text: i18n("Click to change icon")
                             onClicked: {
                                 iconDialog.targetIndex = index
                                 iconDialog.open()
                             }
                         }
                         
                         // Title Field
                         TextField {
                             Layout.fillWidth: true
                             text: model.titleToDisplay
                             placeholderText: model.originalTitle
                             onEditingFinished: {
                                 if (!delegateRoot.isUpdating) {
                                     bootListModel.setProperty(index, "titleToDisplay", text)
                                     saveRules()
                                 }
                             }
                         }
                         
                         // Arrow Buttons for sorting
                         ColumnLayout {
                             spacing: 0
                             ToolButton {
                                 icon.name: "draw-arrow-up"
                                 enabled: index > 0
                                 display: AbstractButton.IconOnly
                                 Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
                                 Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                                 onClicked: {
                                    bootListModel.move(index, index - 1, 1)
                                    saveRules()
                                 }
                             }
                             ToolButton {
                                 icon.name: "draw-arrow-down"
                                 enabled: index < bootListModel.count - 1
                                 display: AbstractButton.IconOnly
                                 Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
                                 Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                                 onClicked: {
                                    bootListModel.move(index, index + 1, 1)
                                    saveRules()
                                 }
                             }
                         }
                         
                         // Visibility Toggle
                         ToolButton {
                             icon.name: model.isHidden ? "view-hidden" : "view-visible"
                             onClicked: {
                                 bootListModel.setProperty(index, "isHidden", !model.isHidden)
                                 saveRules()
                             }
                         }
                     }
                 }
             }
         }
         
         RowLayout {
             Layout.fillWidth: true
             Item { Layout.fillWidth: true }
             Button {
                 text: i18n("Restore Defaults")
                 icon.name: "edit-undo"
                 onClicked: {
                     page.cfg_customEntryRules = "[]"
                     refreshModel()
                 }
             }
         }
    }
}
