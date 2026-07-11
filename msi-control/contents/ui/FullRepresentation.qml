import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.extras as PlasmaExtras
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

PlasmaExtras.Representation {
    id: fullRep

    implicitWidth: Kirigami.Units.gridUnit * 22
    implicitHeight: Kirigami.Units.gridUnit * 32
    Layout.minimumWidth: 400
    Layout.minimumHeight: 500

    // Properties — injected by main.qml
    property var msiModel: null
    property var shiftModeInfo: ({})
    property var fanModeInfo: ({})
    property var kbdBacklightLabels: []

    // Shorthand — safe accessor (empty while msiModel hasn't bound)
    readonly property bool modelReady: msiModel !== null

    contentItem: Item {

        // ═══════════════════════════════════════
        //  PAGE 1: Permission Gate (shown when not ready)
        // ═══════════════════════════════════════

        ColumnLayout {
            id: permissionGatePage
            anchors.fill: parent
            anchors.margins: Kirigami.Units.gridUnit
            visible: modelReady && msiModel.permissionStatus !== "ready"
            spacing: Kirigami.Units.largeSpacing * 2

            Item { Layout.fillHeight: true }

            Kirigami.Icon {
                source: modelReady && msiModel.permissionStatus === "needs_relogin" ? "dialog-information" : "security-high-symbolic"
                Layout.preferredWidth: Kirigami.Units.iconSizes.huge
                Layout.preferredHeight: Kirigami.Units.iconSizes.huge
                Layout.alignment: Qt.AlignHCenter
                color: modelReady && msiModel.permissionStatus === "needs_relogin"
                    ? Kirigami.Theme.positiveTextColor
                    : Kirigami.Theme.neutralTextColor
            }

            Kirigami.Heading {
                text: {
                    if (!modelReady) return ""
                    if (!msiModel.isAvailable)
                        return i18n("Driver Not Found")
                    if (msiModel.permissionStatus === "needs_relogin")
                        return i18n("Almost Ready!")
                    return i18n("Permission Required")
                }
                level: 3
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
            }

            PlasmaComponents.Label {
                text: {
                    if (!modelReady) return ""
                    if (!msiModel.isAvailable)
                        return i18n("The msi-ec kernel module is not loaded.\nMake sure it is installed and loaded:\n\nsudo modprobe msi-ec")
                    if (msiModel.permissionStatus === "needs_relogin")
                        return i18n("Permissions have been configured successfully.\nPlease log out and log back in to activate.")
                    return i18n("System permissions are needed to control\nyour MSI laptop settings.\n\nThis will create a system group and install\nudev rules for secure access. (One-time setup)")
                }
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                opacity: 0.8
            }

            // Setup button (needs_setup OR needs_relogin as retry)
            QQC2.Button {
                visible: modelReady && msiModel.isAvailable && (msiModel.permissionStatus === "needs_setup" || msiModel.permissionStatus === "needs_relogin")
                Layout.alignment: Qt.AlignHCenter
                icon.name: modelReady && msiModel.permissionStatus === "needs_relogin" ? "view-refresh" : "dialog-password"
                text: {
                    if (!modelReady) return ""
                    if (msiModel.setupInProgress) return i18n("Running Setup...")
                    if (msiModel.permissionStatus === "needs_relogin") return i18n("Re-run Setup")
                    return i18n("Grant Permissions")
                }
                enabled: modelReady && !msiModel.setupInProgress
                onClicked: if (modelReady) msiModel.setupPermissions()
            }

            // Logout button (double-click to confirm)
            QQC2.Button {
                id: logoutBtn
                visible: modelReady && msiModel.permissionStatus === "needs_relogin"
                Layout.alignment: Qt.AlignHCenter
                icon.name: "system-log-out"

                property bool confirmPending: false

                text: confirmPending ? i18n("Click Again to Log Out") : i18n("Log Out")

                Timer {
                    id: confirmTimer
                    interval: 3000
                    onTriggered: logoutBtn.confirmPending = false
                }

                onClicked: {
                    if (!modelReady) return
                    if (confirmPending) {
                        msiModel.execLogout()
                    } else {
                        confirmPending = true
                        confirmTimer.restart()
                    }
                }
            }

            Item { Layout.fillHeight: true }
        }

        // ═══════════════════════════════════════
        //  PAGE 2: Full Controls (shown when ready)
        // ═══════════════════════════════════════

        QQC2.ScrollView {
            anchors.fill: parent
            visible: modelReady && msiModel.permissionStatus === "ready"
            QQC2.ScrollBar.horizontal.policy: QQC2.ScrollBar.AlwaysOff

            Kirigami.FormLayout {
                id: formLayout
                width: parent.width

                // ── System Metrics ──

                Kirigami.Separator {
                    Kirigami.FormData.isSection: true
                    Kirigami.FormData.label: i18n("System Metrics")
                    visible: modelReady && (msiModel.hasCpuTemp || msiModel.hasGpuTemp || msiModel.hasCpuFan || msiModel.hasGpuFan)
                }

                RowLayout {
                    Kirigami.FormData.label: i18n("Battery:")
                    spacing: Kirigami.Units.smallSpacing
                    visible: modelReady

                    QQC2.ProgressBar {
                        Layout.fillWidth: true
                        from: 0; to: 100
                        value: modelReady ? msiModel.batteryPercentage : 0
                    }

                    QQC2.Label {
                        text: (modelReady ? msiModel.batteryPercentage : 0) + "%"
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 2.5
                        horizontalAlignment: Text.AlignRight
                    }
                }

                QQC2.Label {
                    Kirigami.FormData.label: i18n("Status:")
                    visible: modelReady
                    text: {
                        if (!modelReady) return ""
                        if (msiModel.batteryStatus === "Discharging") return i18n("Discharging")
                        if (msiModel.batteryStatus === "Charging") return i18n("Charging")
                        if (msiModel.batteryStatus === "Full") return i18n("Full")
                        if (msiModel.batteryStatus === "Not charging") return i18n("Not Charging")
                        return msiModel.batteryStatus
                    }
                }

                GridLayout {
                    visible: modelReady && (msiModel.hasCpuTemp || msiModel.hasGpuTemp || msiModel.hasCpuFan || msiModel.hasGpuFan)
                    Layout.fillWidth: true
                    columns: 2
                    rowSpacing: Kirigami.Units.smallSpacing
                    columnSpacing: Kirigami.Units.smallSpacing

                    // ── CPU Temp ──
                    Rectangle {
                        visible: modelReady && msiModel.hasCpuTemp
                        Layout.fillWidth: true
                        Layout.preferredHeight: Kirigami.Units.gridUnit * 5
                        radius: Kirigami.Units.cornerRadius
                        color: "transparent"
                        border.width: 1
                        border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.2)

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: Kirigami.Units.smallSpacing
                            spacing: Kirigami.Units.smallSpacing

                            Kirigami.Icon {
                                source: modelReady && msiModel.cpuTemp >= 75 ? "psensor_hot" : "psensor_normal"
                                Layout.preferredWidth: Kirigami.Units.iconSizes.medium
                                Layout.preferredHeight: Kirigami.Units.iconSizes.medium
                                Layout.alignment: Qt.AlignHCenter
                            }

                            QQC2.Label {
                                Layout.alignment: Qt.AlignHCenter
                                text: i18n("CPU Temp")
                                font: Kirigami.Theme.smallFont
                                opacity: 0.7
                            }

                            QQC2.Label {
                                Layout.alignment: Qt.AlignHCenter
                                text: (modelReady ? msiModel.cpuTemp : 0) + "°C"
                                font.bold: true
                                font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.1
                                color: modelReady && msiModel.cpuTemp >= 85
                                    ? Kirigami.Theme.negativeTextColor
                                    : (modelReady && msiModel.cpuTemp >= 70
                                        ? Kirigami.Theme.neutralTextColor
                                        : Kirigami.Theme.positiveTextColor)
                            }
                        }
                    }

                    // ── GPU Temp ──
                    Rectangle {
                        visible: modelReady && msiModel.hasGpuTemp
                        Layout.fillWidth: true
                        Layout.preferredHeight: Kirigami.Units.gridUnit * 5
                        radius: Kirigami.Units.cornerRadius
                        color: "transparent"
                        border.width: 1
                        border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.2)

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: Kirigami.Units.smallSpacing
                            spacing: Kirigami.Units.smallSpacing

                            Kirigami.Icon {
                                source: modelReady && msiModel.gpuTemp >= 75 ? "psensor_hot" : "psensor_normal"
                                Layout.preferredWidth: Kirigami.Units.iconSizes.medium
                                Layout.preferredHeight: Kirigami.Units.iconSizes.medium
                                Layout.alignment: Qt.AlignHCenter
                            }

                            QQC2.Label {
                                Layout.alignment: Qt.AlignHCenter
                                text: i18n("GPU Temp")
                                font: Kirigami.Theme.smallFont
                                opacity: 0.7
                            }

                            QQC2.Label {
                                Layout.alignment: Qt.AlignHCenter
                                text: (modelReady ? msiModel.gpuTemp : 0) + "°C"
                                font.bold: true
                                font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.1
                                color: modelReady && msiModel.gpuTemp >= 85
                                    ? Kirigami.Theme.negativeTextColor
                                    : (modelReady && msiModel.gpuTemp >= 70
                                        ? Kirigami.Theme.neutralTextColor
                                        : Kirigami.Theme.positiveTextColor)
                            }
                        }
                    }

                    // ── CPU Fan ──
                    Rectangle {
                        visible: modelReady && msiModel.hasCpuFan
                        Layout.fillWidth: true
                        Layout.preferredHeight: Kirigami.Units.gridUnit * 5
                        radius: Kirigami.Units.cornerRadius
                        color: "transparent"
                        border.width: 1
                        border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.2)

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: Kirigami.Units.smallSpacing
                            spacing: Kirigami.Units.smallSpacing

                            Image {
                                id: cpuFanIcon
                                source: "icons/fan.svg"
                                Layout.preferredWidth: Kirigami.Units.iconSizes.medium
                                Layout.preferredHeight: Kirigami.Units.iconSizes.medium
                                Layout.alignment: Qt.AlignHCenter
                                sourceSize: Qt.size(Kirigami.Units.iconSizes.medium, Kirigami.Units.iconSizes.medium)
                            }

                            QQC2.Label {
                                Layout.alignment: Qt.AlignHCenter
                                text: i18n("CPU Fan")
                                font: Kirigami.Theme.smallFont
                                opacity: 0.7
                            }

                            QQC2.Label {
                                Layout.alignment: Qt.AlignHCenter
                                text: (modelReady ? msiModel.cpuFan : 0) + " %"
                                font.bold: true
                                font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.1
                            }
                        }
                    }

                    // ── GPU Fan ──
                    Rectangle {
                        visible: modelReady && msiModel.hasGpuFan
                        Layout.fillWidth: true
                        Layout.preferredHeight: Kirigami.Units.gridUnit * 5
                        radius: Kirigami.Units.cornerRadius
                        color: "transparent"
                        border.width: 1
                        border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.2)

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: Kirigami.Units.smallSpacing
                            spacing: Kirigami.Units.smallSpacing

                            Image {
                                id: gpuFanIcon
                                source: "icons/fan.svg"
                                Layout.preferredWidth: Kirigami.Units.iconSizes.medium
                                Layout.preferredHeight: Kirigami.Units.iconSizes.medium
                                Layout.alignment: Qt.AlignHCenter
                                sourceSize: Qt.size(Kirigami.Units.iconSizes.medium, Kirigami.Units.iconSizes.medium)
                            }

                            QQC2.Label {
                                Layout.alignment: Qt.AlignHCenter
                                text: i18n("GPU Fan")
                                font: Kirigami.Theme.smallFont
                                opacity: 0.7
                            }

                            QQC2.Label {
                                Layout.alignment: Qt.AlignHCenter
                                text: (modelReady ? msiModel.gpuFan : 0) + " %"
                                font.bold: true
                                font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.1
                            }
                        }
                    }
                }

                // ── Keyboard Backlight ──

                Kirigami.Separator {
                    visible: modelReady && msiModel.hasKbdBacklight
                    Kirigami.FormData.isSection: true
                    Kirigami.FormData.label: i18n("Keyboard Backlight")
                }

                ColumnLayout {
                    visible: modelReady && msiModel.hasKbdBacklight
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.smallSpacing

                    QQC2.Slider {
                        Layout.fillWidth: true
                        from: 0; to: 3; stepSize: 1
                        snapMode: QQC2.Slider.SnapAlways
                        value: modelReady ? msiModel.kbdBacklight : 0
                        onMoved: if (modelReady) msiModel.setKbdBacklight(value)
                    }

                    QQC2.Label {
                        Layout.alignment: Qt.AlignHCenter
                        text: modelReady ? (kbdBacklightLabels[msiModel.kbdBacklight] || i18n("Off")) : ""
                        font.bold: true
                    }
                }

                // ── Controls ──

                Kirigami.Separator {
                    Kirigami.FormData.isSection: true
                    Kirigami.FormData.label: i18n("Controls")
                    visible: modelReady && (msiModel.hasCoolerBoost || msiModel.hasSuperBattery ||
                             msiModel.hasFnKey || msiModel.hasWinKey ||
                             msiModel.hasWebcam || msiModel.hasWebcamBlock ||
                             msiModel.hasUsbPower)
                }

                GridLayout {
                    visible: modelReady && (msiModel.hasCoolerBoost || msiModel.hasSuperBattery ||
                             msiModel.hasFnKey || msiModel.hasWinKey ||
                             msiModel.hasWebcam || msiModel.hasWebcamBlock ||
                             msiModel.hasUsbPower)
                    Layout.fillWidth: true
                    columns: 2
                    rowSpacing: Kirigami.Units.smallSpacing
                    columnSpacing: Kirigami.Units.smallSpacing

                    // ── Cooler Boost ──
                    Rectangle {
                        visible: modelReady && msiModel.hasCoolerBoost
                        Layout.fillWidth: true
                        Layout.preferredHeight: Kirigami.Units.gridUnit * 5
                        radius: Kirigami.Units.cornerRadius
                        color: "transparent"
                        border.width: 1
                        border.color: (modelReady && msiModel.coolerBoost) ? Kirigami.Theme.highlightColor : Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.2)

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: Kirigami.Units.smallSpacing
                            spacing: Kirigami.Units.smallSpacing

                            Kirigami.Icon {
                                source: "sensors-fan-symbolic"
                                Layout.preferredWidth: Kirigami.Units.iconSizes.medium
                                Layout.preferredHeight: Kirigami.Units.iconSizes.medium
                                Layout.alignment: Qt.AlignHCenter
                            }

                            QQC2.Label {
                                Layout.alignment: Qt.AlignHCenter
                                text: i18n("Cooler Boost")
                                font.bold: true
                                font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.1
                            }

                            QQC2.Switch {
                                Layout.alignment: Qt.AlignHCenter
                                checked: modelReady && msiModel.coolerBoost
                                onToggled: if (modelReady) msiModel.setCoolerBoost(checked)
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: if (modelReady) msiModel.setCoolerBoost(!msiModel.coolerBoost)
                        }
                    }

                    // ── FN / Win Key Swap (exclusive toggle) ──
                    Rectangle {
                        visible: modelReady && (msiModel.hasFnKey || msiModel.hasWinKey)
                        Layout.fillWidth: true
                        Layout.preferredHeight: Kirigami.Units.gridUnit * 5
                        radius: Kirigami.Units.cornerRadius
                        color: "transparent"
                        border.width: 1
                        border.color: (modelReady && (msiModel.fnKeySwap || msiModel.winKeySwap)) ? Kirigami.Theme.highlightColor : Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.2)

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: Kirigami.Units.smallSpacing
                            spacing: Kirigami.Units.smallSpacing

                            Kirigami.Icon {
                                source: "autokey-status"
                                Layout.preferredWidth: Kirigami.Units.iconSizes.medium
                                Layout.preferredHeight: Kirigami.Units.iconSizes.medium
                                Layout.alignment: Qt.AlignHCenter
                            }

                            QQC2.Label {
                                Layout.alignment: Qt.AlignHCenter
                                text: modelReady && msiModel.fnKeySwap ? i18n("FN Key Swap") : i18n("Win Key Swap")
                                font.bold: true
                                font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.1
                            }

                            QQC2.Switch {
                                Layout.alignment: Qt.AlignHCenter
                                checked: modelReady && (msiModel.fnKeySwap || msiModel.winKeySwap)
                                onToggled: {
                                    if (!modelReady) return
                                    if (msiModel.fnKeySwap) {
                                        msiModel.setFnKeySwap(false)
                                        msiModel.setWinKeySwap(true)
                                    } else {
                                        msiModel.setWinKeySwap(false)
                                        msiModel.setFnKeySwap(true)
                                    }
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                if (!modelReady) return
                                if (msiModel.fnKeySwap) {
                                    msiModel.setFnKeySwap(false)
                                    msiModel.setWinKeySwap(true)
                                } else {
                                    msiModel.setWinKeySwap(false)
                                    msiModel.setFnKeySwap(true)
                                }
                            }
                        }
                    }

                    // ── Webcam ──
                    Rectangle {
                        visible: modelReady && msiModel.hasWebcam
                        Layout.fillWidth: true
                        Layout.preferredHeight: Kirigami.Units.gridUnit * 5
                        radius: Kirigami.Units.cornerRadius
                        color: "transparent"
                        border.width: 1
                        border.color: (modelReady && msiModel.webcamEnabled) ? Kirigami.Theme.highlightColor : Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.2)

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: Kirigami.Units.smallSpacing
                            spacing: Kirigami.Units.smallSpacing

                            Kirigami.Icon {
                                source: "camera-web-symbolic"
                                Layout.preferredWidth: Kirigami.Units.iconSizes.medium
                                Layout.preferredHeight: Kirigami.Units.iconSizes.medium
                                Layout.alignment: Qt.AlignHCenter
                            }

                            QQC2.Label {
                                Layout.alignment: Qt.AlignHCenter
                                text: i18n("Webcam")
                                font.bold: true
                                font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.1
                            }

                            QQC2.Switch {
                                Layout.alignment: Qt.AlignHCenter
                                checked: modelReady && msiModel.webcamEnabled
                                onToggled: if (modelReady) msiModel.setWebcam(checked)
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: if (modelReady) msiModel.setWebcam(!msiModel.webcamEnabled)
                        }
                    }

                    // ── Webcam Block ──
                    Rectangle {
                        visible: modelReady && msiModel.hasWebcamBlock
                        Layout.fillWidth: true
                        Layout.preferredHeight: Kirigami.Units.gridUnit * 5
                        radius: Kirigami.Units.cornerRadius
                        color: "transparent"
                        border.width: 1
                        border.color: (modelReady && msiModel.webcamBlocked) ? Kirigami.Theme.highlightColor : Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.2)

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: Kirigami.Units.smallSpacing
                            spacing: Kirigami.Units.smallSpacing

                            Kirigami.Icon {
                                source: "cards-block-symbolic"
                                Layout.preferredWidth: Kirigami.Units.iconSizes.medium
                                Layout.preferredHeight: Kirigami.Units.iconSizes.medium
                                Layout.alignment: Qt.AlignHCenter
                            }

                            QQC2.Label {
                                Layout.alignment: Qt.AlignHCenter
                                text: i18n("Webcam Block")
                                font.bold: true
                                font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.1
                            }

                            QQC2.Switch {
                                Layout.alignment: Qt.AlignHCenter
                                checked: modelReady && msiModel.webcamBlocked
                                onToggled: if (modelReady) msiModel.setWebcamBlock(checked)
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: if (modelReady) msiModel.setWebcamBlock(!msiModel.webcamBlocked)
                        }
                    }

                    // ── Super Battery ──
                    Rectangle {
                        visible: modelReady && msiModel.hasSuperBattery
                        Layout.fillWidth: true
                        Layout.preferredHeight: Kirigami.Units.gridUnit * 5
                        radius: Kirigami.Units.cornerRadius
                        color: "transparent"
                        border.width: 1
                        border.color: (modelReady && msiModel.superBattery) ? Kirigami.Theme.highlightColor : Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.2)

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: Kirigami.Units.smallSpacing
                            spacing: Kirigami.Units.smallSpacing

                            Kirigami.Icon {
                                source: "battery-profile-powersave-symbolic"
                                Layout.preferredWidth: Kirigami.Units.iconSizes.medium
                                Layout.preferredHeight: Kirigami.Units.iconSizes.medium
                                Layout.alignment: Qt.AlignHCenter
                            }

                            QQC2.Label {
                                Layout.alignment: Qt.AlignHCenter
                                text: i18n("Super Battery")
                                font.bold: true
                                font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.1
                            }

                            QQC2.Switch {
                                Layout.alignment: Qt.AlignHCenter
                                checked: modelReady && msiModel.superBattery
                                onToggled: if (modelReady) msiModel.setSuperBattery(checked)
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: if (modelReady) msiModel.setSuperBattery(!msiModel.superBattery)
                        }
                    }

                    // ── USB Power Share ──
                    Rectangle {
                        visible: modelReady && msiModel.hasUsbPower
                        Layout.fillWidth: true
                        Layout.preferredHeight: Kirigami.Units.gridUnit * 5
                        radius: Kirigami.Units.cornerRadius
                        color: "transparent"
                        border.width: 1
                        border.color: (modelReady && msiModel.usbPower) ? Kirigami.Theme.highlightColor : Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.2)

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: Kirigami.Units.smallSpacing
                            spacing: Kirigami.Units.smallSpacing

                            Kirigami.Icon {
                                source: "drive-removable-media-usb-symbolic"
                                Layout.preferredWidth: Kirigami.Units.iconSizes.medium
                                Layout.preferredHeight: Kirigami.Units.iconSizes.medium
                                Layout.alignment: Qt.AlignHCenter
                            }

                            QQC2.Label {
                                Layout.alignment: Qt.AlignHCenter
                                text: i18n("USB Power")
                                font.bold: true
                                font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.1
                            }

                            QQC2.Switch {
                                Layout.alignment: Qt.AlignHCenter
                                checked: modelReady && msiModel.usbPower
                                onToggled: if (modelReady) msiModel.setUsbPower(checked)
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: if (modelReady) msiModel.setUsbPower(!msiModel.usbPower)
                        }
                    }
                }

                // ── Shift Mode (Dynamic) ──

                Kirigami.Separator {
                    visible: modelReady && msiModel.hasShiftMode && msiModel.availableShiftModes.length > 0
                    Kirigami.FormData.isSection: true
                    Kirigami.FormData.label: i18n("Shift Mode")
                }

                RowLayout {
                    visible: modelReady && msiModel.hasShiftMode && msiModel.availableShiftModes.length > 0
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.smallSpacing

                    Kirigami.FormData.label: {
                        if (!modelReady || msiModel.availableShiftModes.length === 0) return ""
                        var idx = shiftModeSlider.value
                        var mode = msiModel.availableShiftModes[idx]
                        var info = shiftModeInfo[mode]
                        return info ? info.label + " — " + info.desc : mode
                    }

                    QQC2.Slider {
                        id: shiftModeSlider
                        Layout.fillWidth: true
                        from: 0
                        to: modelReady ? Math.max(0, msiModel.availableShiftModes.length - 1) : 0
                        stepSize: 1
                        snapMode: QQC2.Slider.SnapAlways
                        value: {
                            if (!modelReady) return 0
                            var idx = msiModel.availableShiftModes.indexOf(msiModel.shiftMode)
                            return idx >= 0 ? idx : 0
                        }
                        onMoved: {
                            if (!modelReady) return
                            var mode = msiModel.availableShiftModes[value]
                            if (mode) msiModel.setShiftMode(mode)
                        }
                    }
                }

                // ── Fan Mode (Dynamic) ──

                Kirigami.Separator {
                    visible: modelReady && msiModel.hasFanMode && msiModel.availableFanModes.length > 0
                    Kirigami.FormData.isSection: true
                    Kirigami.FormData.label: i18n("Fan Mode")
                }

                Repeater {
                    model: modelReady ? msiModel.availableFanModes : []

                    QQC2.RadioButton {
                        required property string modelData
                        visible: modelReady && msiModel.hasFanMode
                        Kirigami.FormData.label: {
                            var info = fanModeInfo[modelData]
                            return info ? info.label : modelData
                        }
                        text: {
                            var info = fanModeInfo[modelData]
                            return info ? info.desc : ""
                        }
                        checked: modelReady && msiModel.fanMode === modelData
                        onClicked: if (modelReady) msiModel.setFanMode(modelData)
                    }
                }

                // ── Basic Fan Speed (only in basic mode) ──

                Kirigami.Separator {
                    visible: modelReady && msiModel.fanMode === "basic" && (msiModel.hasCpuBasicFanSpeed || msiModel.hasGpuBasicFanSpeed)
                    Kirigami.FormData.isSection: true
                    Kirigami.FormData.label: i18n("Fan Speed Control")
                }

                RowLayout {
                    visible: modelReady && msiModel.fanMode === "basic" && msiModel.hasCpuBasicFanSpeed
                    Kirigami.FormData.label: i18n("CPU Fan:")
                    spacing: Kirigami.Units.smallSpacing

                    QQC2.Slider {
                        id: cpuFanSlider
                        Layout.fillWidth: true
                        from: 0; to: 100; stepSize: 5
                        value: modelReady ? msiModel.cpuBasicFanSpeed : 0
                        onMoved: if (modelReady) msiModel.setCpuBasicFanSpeed(value)
                    }

                    QQC2.Label {
                        text: Math.round(cpuFanSlider.value) + "%"
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 2.5
                        horizontalAlignment: Text.AlignRight
                    }
                }

                RowLayout {
                    visible: modelReady && msiModel.fanMode === "basic" && msiModel.hasGpuBasicFanSpeed
                    Kirigami.FormData.label: i18n("GPU Fan:")
                    spacing: Kirigami.Units.smallSpacing

                    QQC2.Slider {
                        id: gpuFanSlider
                        Layout.fillWidth: true
                        from: 0; to: 100; stepSize: 5
                        value: modelReady ? msiModel.gpuBasicFanSpeed : 0
                        onMoved: if (modelReady) msiModel.setGpuBasicFanSpeed(value)
                    }

                    QQC2.Label {
                        text: Math.round(gpuFanSlider.value) + "%"
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 2.5
                        horizontalAlignment: Text.AlignRight
                    }
                }

                // ── Battery Strategy ──

                Kirigami.Separator {
                    visible: modelReady && msiModel.hasBatteryThreshold
                    Kirigami.FormData.isSection: true
                    Kirigami.FormData.label: i18n("Battery Strategy")
                }

                QQC2.RadioButton {
                    visible: modelReady && msiModel.hasBatteryThreshold
                    Kirigami.FormData.label: i18n("Mobility")
                    text: i18n("90% → 100%")
                    checked: modelReady && msiModel.batteryLimit === 100
                    onClicked: if (modelReady) msiModel.setBatteryThresholds("90", "100")
                }

                QQC2.RadioButton {
                    visible: modelReady && msiModel.hasBatteryThreshold
                    Kirigami.FormData.label: i18n("Balanced")
                    text: i18n("70% → 80%")
                    checked: modelReady && msiModel.batteryLimit === 80
                    onClicked: if (modelReady) msiModel.setBatteryThresholds("70", "80")
                }

                QQC2.RadioButton {
                    visible: modelReady && msiModel.hasBatteryThreshold
                    Kirigami.FormData.label: i18n("Life Span")
                    text: i18n("50% → 60%")
                    checked: modelReady && msiModel.batteryLimit === 60
                    onClicked: if (modelReady) msiModel.setBatteryThresholds("50", "60")
                }

                // ── System Info ──

                Kirigami.Separator {
                    Kirigami.FormData.isSection: true
                    Kirigami.FormData.label: i18n("System Info")
                    visible: modelReady
                }

                QQC2.Label {
                    visible: modelReady
                    Kirigami.FormData.label: i18n("EC Build:")
                    text: modelReady ? (msiModel.fwDate || "—") : "—"
                    font: Kirigami.Theme.smallFont
                    opacity: 0.7
                }

                QQC2.Label {
                    visible: modelReady
                    Kirigami.FormData.label: i18n("EC Version:")
                    text: modelReady ? (msiModel.fwVersion || "—") : "—"
                    font: Kirigami.Theme.smallFont
                    opacity: 0.7
                }

                QQC2.Label {
                    visible: modelReady
                    Kirigami.FormData.label: i18n("Driver:")
                    text: modelReady ? (msiModel.isAvailable ? i18n("msi-ec Detected") : i18n("Not Found")) : "—"
                    font: Kirigami.Theme.smallFont
                    color: modelReady && msiModel.isAvailable ? Kirigami.Theme.positiveTextColor : Kirigami.Theme.negativeTextColor
                    opacity: 0.7
                }
            }
        }
    }
}
