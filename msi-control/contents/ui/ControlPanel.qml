import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.extras as PlasmaExtras
import org.kde.kirigami as Kirigami

Item {
    id: root
    
    property var msiModel: null
    
    // Main Layout
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Kirigami.Units.gridUnit
        spacing: Kirigami.Units.largeSpacing
        
        // 1. Status Card (Top)
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: Kirigami.Units.gridUnit * 10
            color: "#333333" // Dark background as per image
            radius: Kirigami.Units.smallSpacing * 2
            
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Kirigami.Units.largeSpacing
                spacing: Kirigami.Units.smallSpacing
                
                // Top Row: Temps & Fans
                RowLayout {
                    Layout.fillWidth: true
                    
                    // Left Column: Temps
                    ColumnLayout {
                        spacing: Kirigami.Units.smallSpacing
                        PlasmaComponents.Label {
                            text: msiModel ? i18n("CPU Sıcaklığı: %1 C", msiModel.cpuTemp) : i18n("CPU Sıcaklığı: --")
                            color: "white"
                            font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.1
                        }
                        PlasmaComponents.Label {
                            text: msiModel ? i18n("GPU Sıcaklığı: %1 C", msiModel.gpuTemp) : i18n("GPU Sıcaklığı: --")
                            color: "white"
                            font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.1
                        }
                    }
                    
                    Item { Layout.fillWidth: true }
                    
                    // Right Column: Fans
                    ColumnLayout {
                        spacing: Kirigami.Units.smallSpacing
                        PlasmaComponents.Label {
                            Layout.alignment: Qt.AlignRight
                            text: msiModel ? i18n("CPU Fan: %1 Devir", msiModel.cpuFan) : i18n("CPU Fan: --")
                            color: "white"
                            font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.1
                        }
                        PlasmaComponents.Label {
                            Layout.alignment: Qt.AlignRight
                            text: msiModel ? i18n("GPU Fan: %1 Devir", msiModel.gpuFan) : i18n("GPU Fan: --")
                            color: "white"
                            font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.1
                        }
                    }
                }
                
                // Middle Info
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: Kirigami.Units.smallSpacing
                    spacing: Kirigami.Units.smallSpacing
                    
                    PlasmaComponents.Label {
                        text: msiModel ? i18n("EC Versiyonu: %1", msiModel.fwVersion) : i18n("EC Versiyonu: --")
                        color: "white"
                        opacity: 0.9
                    }
                    PlasmaComponents.Label {
                        text: msiModel ? i18n("EC Derleme tarihi: %1", msiModel.fwDate) : i18n("EC Derleme tarihi: --")
                        color: "white"
                        opacity: 0.9
                    }
                    PlasmaComponents.Label {
                        text: msiModel ? i18n("Pil Şarj Durumu: %%1", msiModel.batteryPercentage) : i18n("Pil Şarj Durumu: --")
                        color: "white"
                        opacity: 0.9
                    }
                    PlasmaComponents.Label {
                        text: i18n("msi-ec paketi durumu: %1", (msiModel && msiModel.isAvailable) ? i18n("Yüklendi") : i18n("Bulunamadı"))
                        color: "white"
                        opacity: 0.9
                    }
                }
            }
        }
        
        // 2. Control Grid (Middle)
        GridLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            columns: 2
            rowSpacing: Kirigami.Units.largeSpacing
            columnSpacing: Kirigami.Units.largeSpacing
            
            // FN / Meta
            ControlKeyButton {
                label: i18n("FN veya META")
                isActive: msiModel ? msiModel.fnKeySwap : false
                onClicked: if(msiModel) msiModel.setFnKeySwap(!msiModel.fnKeySwap)
            }
            
            // USB Power
            ControlKeyButton {
                label: i18n("USB Güç Aktarımı")
                isActive: msiModel ? msiModel.usbPower : false
                onClicked: if(msiModel) msiModel.setUsbPower(!msiModel.usbPower)
            }
            
            // Cooler Boost
            ControlKeyButton {
                label: i18n("CoolerBoost Fan")
                isActive: msiModel ? msiModel.coolerBoost : false
                isCheckMark: true
                onClicked: if(msiModel) msiModel.setCoolerBoost(!msiModel.coolerBoost)
            }
            
            // Camera Block
            ControlKeyButton {
                label: i18n("Kamera Engelleme")
                isActive: msiModel ? !msiModel.webcamEnabled : false
                onClicked: if(msiModel) msiModel.setWebcam(!msiModel.webcamEnabled)
            }
        }
        
        // 3. Settings (Bottom)
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing
            
            // Battery Limit
            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing
                
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 2.5
                    color: "#444444"
                    radius: Kirigami.Units.smallSpacing
                    
                    PlasmaComponents.Label {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: Kirigami.Units.largeSpacing
                        text: i18n("Laptop Batarya Dolum Limiti:")
                        color: "white"
                        font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 1.1
                    }
                    
                    Rectangle { // Button-like look
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.rightMargin: Kirigami.Units.smallSpacing
                        width: parent.width * 0.35
                        height: parent.height * 0.8
                        color: "#222222"
                        border.color: "#555555"
                        border.width: 1
                        radius: 4
                        
                        PlasmaComponents.Label {
                            anchors.centerIn: parent
                            text: msiModel ? "%%1 Limitli".arg(msiModel.batteryLimit) : "--"
                            color: "white"
                        }
                        
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                if (!msiModel) return;
                                // Cycle limit 60 -> 80 -> 100
                                var newLimit = msiModel.batteryLimit >= 100 ? 60 : msiModel.batteryLimit + 20
                                msiModel.setBatteryLimit(newLimit)
                            }
                        }
                    }
                }
            }
            
            // Power Mode
            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing
                
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 2.5
                    color: "#444444"
                    radius: Kirigami.Units.smallSpacing
                     
                    PlasmaComponents.Label {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: Kirigami.Units.largeSpacing
                        text: i18n("MSI EC Güç Yönetimi Modu:")
                        color: "white"
                        font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 1.1
                    }
                    
                     Rectangle { // Dropdown-like look
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.rightMargin: Kirigami.Units.smallSpacing
                        width: parent.width * 0.35
                        height: parent.height * 0.8
                        color: "#222222"
                        border.color: "#555555"
                        border.width: 1
                        radius: 4
                        
                        PlasmaComponents.Label {
                            anchors.centerIn: parent
                            text: {
                                if (!msiModel) return "--"
                                switch(msiModel.shiftMode) {
                                    case "eco": return i18n("Super Battery")
                                    case "comfort": return i18n("Dengeli")
                                    case "sport": return i18n("Sport")
                                    case "turbo": return i18n("Turbo")
                                    default: return msiModel.shiftMode
                                }
                            }
                            color: "white"
                        }
                        
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                if (!msiModel) return;
                                // Simple cycle for now: eco -> comfort -> sport -> turbo
                                var modes = ["eco", "comfort", "sport", "turbo"]
                                var idx = modes.indexOf(msiModel.shiftMode)
                                var nextIdx = (idx + 1) % modes.length
                                msiModel.setShiftMode(modes[nextIdx])
                            }
                        }
                        
                         // Down arrow icon representation
                        Text {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.rightMargin: 10
                            text: "v"
                            color: "#888888"
                            font.pixelSize: 10
                            visible: true
                        }
                    }
                }
            }
        }
    }
    
    // Component for the big buttons
    component ControlKeyButton : Rectangle {
        id: btn
        property string label: ""
        property bool isActive: false
        property bool isCheckMark: false // "v" checkmark vs square
        signal clicked()
        
        Layout.fillWidth: true
        Layout.preferredHeight: Kirigami.Units.gridUnit * 5
        color: "#444444"
        radius: Kirigami.Units.smallSpacing * 2
        
        ColumnLayout {
            anchors.centerIn: parent
            spacing: Kirigami.Units.mediumSpacing
            
            PlasmaComponents.Label {
                Layout.alignment: Qt.AlignHCenter
                text: btn.label
                color: "white"
                font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.1
            }
            
            // Indicator Box
            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                width: Kirigami.Units.iconSizes.medium
                height: width
                color: "#222222" // Dark inner
                radius: 4
                
                // Active indicator
                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width * 0.6
                    height: parent.height * 0.6
                    color: "#333333" // Slightly lighter
                    visible: !btn.isActive && !btn.isCheckMark
                }
                
                 // Checkmark for CoolerBoost styling from image
                Kirigami.Icon {
                    anchors.centerIn: parent
                    width: parent.width * 1.2
                    height: parent.height * 1.2
                    source: "check" 
                    color: "white"
                    visible: btn.isActive && btn.isCheckMark
                }
                
                // Solid square for others when active (or whatever the "active" state looks like)
                // The image shows solid squares for FN/Meta and USB when presumably inactive/active?
                // Left side items seem "off" (dark square), Right side "off"?
                // Let's assume:
                // OFF = Dark square
                // ON = Light square or Checkmark
                
                Rectangle {
                   anchors.centerIn: parent
                   width: parent.width * 0.7
                   height: parent.height * 0.7
                   color: "#888888"
                   visible: btn.isActive && !btn.isCheckMark
                   radius: 2
                }
            }
        }
        
        MouseArea {
            anchors.fill: parent
            onClicked: btn.clicked()
            hoverEnabled: true
            onEntered: btn.color = "#555555"
            onExited: btn.color = "#444444"
        }
    }
}
