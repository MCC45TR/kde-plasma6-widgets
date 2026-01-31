import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Item {
    id: configRoot

    property var title

    // Notification settings bindings
    property alias cfg_notifyEnabled: masterToggle.checked
    property alias cfg_notifyRoutineEnabled: routineToggle.checked
    property alias cfg_notifyRoutineHour: routineHourSpin.value
    property alias cfg_notifySevereWeather: severeToggle.checked
    property alias cfg_notifyRain: rainToggle.checked
    property alias cfg_notifyTemperatureDrop: tempDropToggle.checked
    property alias cfg_notifyTemperatureThreshold: tempThresholdSpin.value

    // Defaults (required by Plasma config system)
    property bool cfg_notifyEnabledDefault: false
    property bool cfg_notifyRoutineEnabledDefault: false
    property int cfg_notifyRoutineHourDefault: 8
    property bool cfg_notifySevereWeatherDefault: true
    property bool cfg_notifyRainDefault: true
    property bool cfg_notifyTemperatureDropDefault: false
    property int cfg_notifyTemperatureThresholdDefault: 0

    ScrollView {
        id: scrollView
        anchors.fill: parent
        clip: true
        ScrollBar.vertical.policy: ScrollBar.AsNeeded
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

        ColumnLayout {
            width: scrollView.availableWidth
            spacing: 15

            // Master Toggle
            GroupBox {
                title: i18n("Weather Notifications")
                Layout.fillWidth: true

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 12

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Switch {
                            id: masterToggle
                        }
                        Label {
                            text: i18n("Enable weather notifications")
                            font.bold: true
                            Layout.fillWidth: true
                        }
                    }

                    Label {
                        text: i18n("When enabled, the widget will send Plasma desktop notifications based on weather conditions.")
                        font.pixelSize: 11
                        opacity: 0.7
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }
                }
            }

            // Routine Notifications
            GroupBox {
                title: i18n("Routine Notifications")
                Layout.fillWidth: true
                enabled: masterToggle.checked
                opacity: enabled ? 1.0 : 0.5

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 10

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Switch {
                            id: routineToggle
                        }
                        Label {
                            text: i18n("Daily weather summary")
                            Layout.fillWidth: true
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10
                        enabled: routineToggle.checked
                        opacity: enabled ? 1.0 : 0.5

                        Label {
                            text: i18n("Notification time:")
                        }
                        SpinBox {
                            id: routineHourSpin
                            from: 0
                            to: 23
                            value: 8
                            editable: true

                            textFromValue: function(value, locale) {
                                return value.toString().padStart(2, '0') + ":00"
                            }
                            valueFromText: function(text, locale) {
                                return parseInt(text.split(":")[0]) || 0
                            }
                        }
                        Label {
                            text: i18n("(24-hour format)")
                            opacity: 0.6
                            font.pixelSize: 11
                        }
                    }

                    Label {
                        text: i18n("Receive a daily notification with current weather and today's forecast.")
                        font.pixelSize: 11
                        opacity: 0.7
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }
                }
            }

            // Severe Weather Alerts
            GroupBox {
                title: i18n("Weather Alerts")
                Layout.fillWidth: true
                enabled: masterToggle.checked
                opacity: enabled ? 1.0 : 0.5

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 12

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Switch {
                            id: severeToggle
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Label {
                                text: i18n("Severe weather alerts")
                            }
                            Label {
                                text: i18n("Thunderstorm, heavy snow, dense fog")
                                font.pixelSize: 10
                                opacity: 0.6
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Switch {
                            id: rainToggle
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Label {
                                text: i18n("Rain forecast alert")
                            }
                            Label {
                                text: i18n("Notify when rain is expected in the next few hours")
                                font.pixelSize: 10
                                opacity: 0.6
                            }
                        }
                    }
                }
            }

            // Temperature Alerts
            GroupBox {
                title: i18n("Temperature Alerts")
                Layout.fillWidth: true
                enabled: masterToggle.checked
                opacity: enabled ? 1.0 : 0.5

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 10

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Switch {
                            id: tempDropToggle
                        }
                        Label {
                            text: i18n("Low temperature warning")
                            Layout.fillWidth: true
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10
                        enabled: tempDropToggle.checked
                        opacity: enabled ? 1.0 : 0.5

                        Label {
                            text: i18n("Alert when below:")
                        }
                        SpinBox {
                            id: tempThresholdSpin
                            from: -50
                            to: 50
                            value: 0
                            editable: true

                            textFromValue: function(value, locale) {
                                return value + "°"
                            }
                            valueFromText: function(text, locale) {
                                return parseInt(text.replace("°", "")) || 0
                            }
                        }
                        Label {
                            text: i18n("(Celsius)")
                            opacity: 0.6
                            font.pixelSize: 11
                        }
                    }

                    Label {
                        text: i18n("Receive an alert when the current temperature drops below your set threshold.")
                        font.pixelSize: 11
                        opacity: 0.7
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }
                }
            }

            // Info Box
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: infoCol.height + 20
                color: Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.1)
                radius: 8
                visible: masterToggle.checked

                ColumnLayout {
                    id: infoCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 10
                    spacing: 4

                    RowLayout {
                        spacing: 8
                        Kirigami.Icon {
                            source: "dialog-information"
                            Layout.preferredWidth: 16
                            Layout.preferredHeight: 16
                        }
                        Label {
                            text: i18n("How it works")
                            font.bold: true
                        }
                    }
                    Label {
                        text: i18n("Notifications are checked each time weather data is refreshed. To avoid spam, each alert type has a cooldown period.")
                        font.pixelSize: 11
                        opacity: 0.8
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }
                }
            }

            Item { Layout.fillHeight: true }
        }
    }
}
