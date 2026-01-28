import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami

Item {
    id: root
    
    required property var rootModel
    property int currentIndex: 0
    
    signal tabSelected(int index)
    
    RowLayout {
        anchors.fill: parent
        spacing: 5
        
        // Scrollable Tabs
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: tabRow.implicitWidth
            contentHeight: parent.height
            clip: true
            
            // Hide scrollbars
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            
            RowLayout {
                id: tabRow
                spacing: 5
                
                // Tab 0: Categorized
                PlasmaComponents.Button {
                    text: i18n("Categorized")
                    checked: root.currentIndex === 0
                    flat: true
                    onClicked: root.tabSelected(0)
                }

                // Tab 1: All Apps
                PlasmaComponents.Button {
                    text: i18n("All")
                    checked: root.currentIndex === 1
                    flat: true
                    onClicked: root.tabSelected(1)
                }
                
                // Dynamic Category Tabs (Index 2+)
                Repeater {
                    model: rootModel
                    
                    delegate: PlasmaComponents.Button {
                        text: model.display
                        checked: root.currentIndex === (index + 2)
                        flat: true
                        onClicked: root.tabSelected(index + 2)
                        
                        // Hide "Recent *" tabs
                        readonly property bool shouldShow: {
                            const name = model.display;
                            return name !== i18n("Recent Applications") && 
                                   name !== i18n("Recent Files") && 
                                   name !== i18n("Recent Documents") &&
                                   name !== "Son Kullanılan Uygulamalar" && // Hardcoded fallback for Turkish
                                   name !== "Son Dosyalar";
                        }
                        
                        visible: shouldShow
                        
                        // If hidden, don't take up space (Layout safety)
                        Layout.preferredWidth: visible ? implicitWidth : 0
                        Layout.preferredHeight: visible ? implicitHeight : 0
                    }
                }
            }
        }
        
        // Spacer if needed (ScrollView takes space, but we want Power Button pinned right)
        // ScrollView Layout.fillWidth triggers expansion.
        
        // Power Button
        PlasmaComponents.ToolButton {
            icon.name: "system-shutdown"
            onClicked: powerMenu.open()
            
            Menu {
                id: powerMenu
                y: -height
                
                MenuItem {
                    text: i18n("Sleep")
                    icon.name: "system-suspend"
                    onTriggered: console.log("Sleep triggered (mock)")
                }
                MenuItem {
                    text: i18n("Restart")
                    icon.name: "system-reboot"
                    onTriggered: console.log("Restart triggered (mock)")
                }
                MenuItem {
                    text: i18n("Shutdown")
                    icon.name: "system-shutdown"
                    onTriggered: console.log("Shutdown triggered (mock)")
                }
                 MenuItem {
                    text: i18n("Logout")
                    icon.name: "system-log-out"
                    onTriggered: console.log("Logout triggered (mock)")
                }
            }
        }
    }
}
