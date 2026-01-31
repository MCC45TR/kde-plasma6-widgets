import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.extras as PlasmaExtras
import org.kde.kirigami as Kirigami

Item {
    id: root
    
    required property var msiModel
    
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Kirigami.Units.largeSpacing
        spacing: Kirigami.Units.largeSpacing
        
        // Header
        PlasmaExtras.Heading {
            Layout.fillWidth: true
            level: 3
            text: i18n("MSI Control Center")
            
            // Status indicator
            Rectangle {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: Kirigami.Units.iconSizes.small
                height: width
                radius: width / 2
                color: msiModel.isAvailable ? Kirigami.Theme.positiveColor : Kirigami.Theme.negativeColor
            }
        }
        
        // Separator
        Kirigami.Separator {
            Layout.fillWidth: true
        }
        
        // Unavailable message
        PlasmaExtras.PlaceholderMessage {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: !msiModel.isAvailable
            iconName: "dialog-warning"
            text: i18n("msi-ec driver not found")
            explanation: i18n("Make sure msi-ec kernel module is loaded")
        }
        
        // Main content (visible only when available)
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Kirigami.Units.largeSpacing
            visible: msiModel.isAvailable
            
            // Temperature Cards
            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.mediumSpacing
                
                TempCard {
                    Layout.fillWidth: true
                    label: "CPU"
                    temperature: msiModel.cpuTemp
                    fanSpeed: msiModel.cpuFan
                    iconSource: "cpu"
                }
                
                TempCard {
                    Layout.fillWidth: true
                    label: "GPU"
                    temperature: msiModel.gpuTemp
                    fanSpeed: msiModel.gpuFan
                    iconSource: "video-display"
                }
            }
            
            // Shift Mode Section
            ColumnLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing
                visible: msiModel.availableShiftModes.length > 0
                
                PlasmaExtras.Heading {
                    level: 5
                    text: i18n("Performance Mode")
                }
                
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.smallSpacing
                    
                    Repeater {
                        model: msiModel.availableShiftModes
                        
                        PlasmaComponents.ToolButton {
                            Layout.fillWidth: true
                            text: getShiftModeLabel(modelData)
                            checked: msiModel.shiftMode === modelData
                            checkable: true
                            display: PlasmaComponents.AbstractButton.TextBesideIcon
                            icon.name: getShiftModeIcon(modelData)
                            
                            onClicked: msiModel.setShiftMode(modelData)
                            
                            function getShiftModeLabel(mode) {
                                switch(mode) {
                                    case "eco": return i18n("Eco")
                                    case "comfort": return i18n("Balanced")
                                    case "sport": return i18n("Sport")
                                    case "turbo": return i18n("Turbo")
                                    default: return mode
                                }
                            }
                            
                            function getShiftModeIcon(mode) {
                                switch(mode) {
                                    case "eco": return "battery-profile-powersave"
                                    case "comfort": return "speedometer"
                                    case "sport": return "preferences-system-performance"
                                    case "turbo": return "lightning"
                                    default: return "preferences-system"
                                }
                            }
                        }
                    }
                }
            }
            
            // Separator
            Kirigami.Separator {
                Layout.fillWidth: true
            }
            
            // Toggle Settings
            ColumnLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing
                
                // Cooler Boost
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.mediumSpacing
                    
                    Kirigami.Icon {
                        source: "games-highscores"
                        Layout.preferredWidth: Kirigami.Units.iconSizes.medium
                        Layout.preferredHeight: Kirigami.Units.iconSizes.medium
                    }
                    
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        
                        PlasmaComponents.Label {
                            text: i18n("Cooler Boost")
                            Layout.fillWidth: true
                        }
                        
                        PlasmaComponents.Label {
                            text: i18n("Maximum fan speed for intensive tasks")
                            font: Kirigami.Theme.smallFont
                            opacity: 0.6
                            Layout.fillWidth: true
                        }
                    }
                    
                    PlasmaComponents.Switch {
                        checked: msiModel.coolerBoost
                        onToggled: msiModel.setCoolerBoost(checked)
                    }
                }
                
                // Webcam
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.mediumSpacing
                    
                    Kirigami.Icon {
                        source: "camera-web"
                        Layout.preferredWidth: Kirigami.Units.iconSizes.medium
                        Layout.preferredHeight: Kirigami.Units.iconSizes.medium
                    }
                    
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        
                        PlasmaComponents.Label {
                            text: i18n("Webcam")
                            Layout.fillWidth: true
                        }
                        
                        PlasmaComponents.Label {
                            text: i18n("Enable or disable integrated webcam")
                            font: Kirigami.Theme.smallFont
                            opacity: 0.6
                            Layout.fillWidth: true
                        }
                    }
                    
                    PlasmaComponents.Switch {
                        checked: msiModel.webcamEnabled
                        onToggled: msiModel.setWebcam(checked)
                    }
                }
            }
            
            // Separator
            Kirigami.Separator {
                Layout.fillWidth: true
            }
            
            // Battery Limit
            ColumnLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing
                
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.mediumSpacing
                    
                    Kirigami.Icon {
                        source: "battery-good"
                        Layout.preferredWidth: Kirigami.Units.iconSizes.medium
                        Layout.preferredHeight: Kirigami.Units.iconSizes.medium
                    }
                    
                    PlasmaComponents.Label {
                        text: i18n("Battery Charge Limit")
                        Layout.fillWidth: true
                    }
                    
                    PlasmaComponents.Label {
                        text: msiModel.batteryLimit + "%"
                        font.bold: true
                        color: Kirigami.Theme.highlightColor
                    }
                }
                
                PlasmaComponents.Slider {
                    Layout.fillWidth: true
                    from: 60
                    to: 100
                    stepSize: 10
                    value: msiModel.batteryLimit
                    
                    onPressedChanged: {
                        if (!pressed) {
                            msiModel.setBatteryLimit(value)
                        }
                    }
                }
                
                PlasmaComponents.Label {
                    text: i18n("Limiting charge extends battery lifespan")
                    font: Kirigami.Theme.smallFont
                    opacity: 0.6
                    Layout.fillWidth: true
                }
            }
            
            // Spacer
            Item { Layout.fillHeight: true }
            
            // Firmware Info Footer
            PlasmaComponents.Label {
                Layout.fillWidth: true
                text: msiModel.fwVersion ? i18n("Firmware: %1 (%2)", msiModel.fwVersion, msiModel.fwDate) : ""
                font: Kirigami.Theme.smallFont
                opacity: 0.4
                horizontalAlignment: Text.AlignCenter
                visible: text.length > 0
            }
        }
    }
    
    // TempCard Component
    component TempCard: Rectangle {
        id: tempCard
        
        property string label: ""
        property int temperature: 0
        property int fanSpeed: 0
        property string iconSource: "cpu"
        
        implicitHeight: Kirigami.Units.gridUnit * 5
        radius: Kirigami.Units.cornerRadius
        color: Kirigami.Theme.alternateBackgroundColor
        
        function getTempColor(temp) {
            if (temp >= 85) return Kirigami.Theme.negativeColor
            if (temp >= 70) return Kirigami.Theme.neutralColor
            return Kirigami.Theme.positiveColor
        }
        
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Kirigami.Units.mediumSpacing
            spacing: Kirigami.Units.smallSpacing
            
            RowLayout {
                spacing: Kirigami.Units.smallSpacing
                
                Kirigami.Icon {
                    source: tempCard.iconSource
                    Layout.preferredWidth: Kirigami.Units.iconSizes.small
                    Layout.preferredHeight: Kirigami.Units.iconSizes.small
                }
                
                PlasmaComponents.Label {
                    text: tempCard.label
                    font.bold: true
                    opacity: 0.7
                }
            }
            
            PlasmaExtras.Heading {
                level: 2
                text: i18n("%1°C", tempCard.temperature)
                color: getTempColor(tempCard.temperature)
            }
            
            RowLayout {
                spacing: Kirigami.Units.smallSpacing
                
                Kirigami.Icon {
                    source: "preferences-system-windows-behavior"
                    Layout.preferredWidth: Kirigami.Units.iconSizes.small
                    Layout.preferredHeight: Kirigami.Units.iconSizes.small
                    opacity: 0.6
                }
                
                PlasmaComponents.Label {
                    text: i18n("Fan: %1%", tempCard.fanSpeed)
                    font: Kirigami.Theme.smallFont
                    opacity: 0.6
                }
            }
        }
    }
}
