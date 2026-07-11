import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Item {
    id: configGeneral
    
    // Explicitly define properties to map and prevent undefined property warnings
    property bool cfg_breezeStyle
    property int cfg_animationSpeed
    property int cfg_iconSize
    property string cfg_pinnedItems
    property bool cfg_showLabelsInTiles

    onCfg_breezeStyleChanged: {
        if (cfg_breezeStyle) breezeRadio.checked = true
        else minimalRadio.checked = true
    }

    ButtonGroup { id: styleGroup }

    ColumnLayout {
        anchors.fill: parent
        
        Kirigami.FormLayout {
            Layout.fillWidth: true
            
            ComboBox {
                id: appNameFormat
                Kirigami.FormData.label: i18n("Application name format:")
                model: [i18n("Name only"), i18n("Generic name only"), i18n("Name (Generic name)"), i18n("Generic name (Name)")]
            }
            
            Item {
                Kirigami.FormData.label: i18n("Style:")
                implicitWidth: radioRow.implicitWidth
                implicitHeight: radioRow.implicitHeight
                RowLayout {
                    id: radioRow
                    spacing: Kirigami.Units.largeSpacing
                    RadioButton {
                        id: breezeRadio
                        text: i18n("Breeze")
                        ButtonGroup.group: styleGroup
                        onCheckedChanged: if (checked) cfg_breezeStyle = true
                    }
                    RadioButton {
                        id: minimalRadio
                        text: i18n("Minimal")
                        ButtonGroup.group: styleGroup
                        onCheckedChanged: if (checked) cfg_breezeStyle = false
                    }
                }
            }

            ComboBox {
                id: iconSizeBox
                Kirigami.FormData.label: i18n("Icon size:")
                textRole: "text"
                valueRole: "value"
                model: [
                    { text: "16", value: 16 },
                    { text: "24", value: 24 },
                    { text: "32", value: 32 },
                    { text: "48", value: 48 },
                    { text: "64", value: 64 },
                    { text: "96", value: 96 },
                    { text: "128", value: 128 }
                ]
                currentIndex: {
                    for (var i = 0; i < model.length; i++) {
                        if (model[i].value === cfg_iconSize) return i;
                    }
                    return 3; // Default 48
                }
                onActivated: cfg_iconSize = currentValue
            }

            Slider {
                id: animationSlider
                Kirigami.FormData.label: i18n("Animation speed:")
                from: 0
                to: 1000
                stepSize: 100
                snapMode: Slider.SnapAlways
                value: cfg_animationSpeed
                onMoved: cfg_animationSpeed = value
                
                Kirigami.FormData.buddyFor: Label {
                    text: animationSlider.value + " ms"
                }
            }

            CheckBox {
                id: showLabelsCheck
                Kirigami.FormData.label: i18n("Labels:")
                text: i18n("Show labels in tiles")
                checked: cfg_showLabelsInTiles
                onToggled: cfg_showLabelsInTiles = checked
            }
        }
        
        Item {
            Layout.fillHeight: true
            Layout.fillWidth: true
        }
    }
}
