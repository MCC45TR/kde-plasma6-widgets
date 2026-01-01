/*
    SPDX-FileCopyrightText: 2023 Denys Madureira <denysmb@zoho.com>
    SPDX-License-Identifier: LGPL-2.1-or-later
*/

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.plasma.extras as PlasmaExtras

import "localization.js" as Localization
import "GeminiManager.js" as GeminiManager
import "MarkdownParser.js" as MarkdownParser
import "components" as Components

PlasmoidItem {
    id: root
    
    // Localization helper
    property var locales: Localization.data
    property string currentLocale: Qt.locale().name.substring(0, 2)
    function tr(key) {
        if (locales[currentLocale] && locales[currentLocale][key]) return locales[currentLocale][key]
        if (locales["en"] && locales["en"][key]) return locales["en"][key]
        return key
    }
    
    // Config & State
    property bool isLoading: false
    hideOnWindowDeactivate: !Plasmoid.configuration.pin
    
    // Representations
    compactRepresentation: CompactRepresentation {}
    
    fullRepresentation: ColumnLayout {
        Layout.preferredWidth: Kirigami.Units.gridUnit * 25
        Layout.preferredHeight: Kirigami.Units.gridUnit * 35
        Layout.minimumWidth: Kirigami.Units.gridUnit * 20
        Layout.minimumHeight: Kirigami.Units.gridUnit * 25
        spacing: 0
        
        // Header
        PlasmaExtras.PlasmoidHeading {
            Layout.fillWidth: true
            
            contentItem: RowLayout {
                spacing: Kirigami.Units.smallSpacing
                
                // Pin Button
                PlasmaComponents.Button {
                    icon.name: Plasmoid.configuration.pin ? "window-pin" : "window-unpin"
                    checkable: true
                    checked: Plasmoid.configuration.pin
                    display: PlasmaComponents.AbstractButton.IconOnly
                    text: checked ? root.tr("unpin") : root.tr("keep_open")
                    onToggled: Plasmoid.configuration.pin = checked
                    
                    PlasmaComponents.ToolTip.visible: hovered
                    PlasmaComponents.ToolTip.text: text
                }
                
                // Model Selector
                QQC2.ComboBox {
                    id: modelSelector
                    Layout.fillWidth: true
                    
                    textRole: "text"
                    valueRole: "value"
                    
                    model: [
                        { text: "Gemini 2.0 Flash", value: "gemini-2.0-flash-exp" },
                        { text: "Gemini 1.5 Pro", value: "gemini-1.5-pro" },
                        { text: "Gemini 1.5 Flash", value: "gemini-1.5-flash" },
                        { text: "Gemini 1.0 Pro", value: "gemini-1.0-pro" },
                        { text: "Gemma 2", value: "gemma-2-9b-it" }
                    ]
                    
                    Component.onCompleted: updateSelection()
                    
                    Connections {
                        target: Plasmoid.configuration
                        function onSelectedModelChanged() { modelSelector.updateSelection() }
                    }
                    
                    function updateSelection() {
                        for (var i = 0; i < model.length; i++) {
                            if (model[i].value === Plasmoid.configuration.selectedModel) {
                                currentIndex = i;
                                return;
                            }
                        }
                        currentIndex = 0;
                    }
                    
                    onActivated: {
                        Plasmoid.configuration.selectedModel = model[currentIndex].value
                    }
                    
                    PlasmaComponents.ToolTip.visible: hovered
                    PlasmaComponents.ToolTip.text: root.tr("model_selection")
                }
                
                // Clear Button
                PlasmaComponents.Button {
                    icon.name: "edit-clear-symbolic"
                    display: PlasmaComponents.AbstractButton.IconOnly
                    text: root.tr("clear_chat")
                    onClicked: {
                        chatModel.clear()
                        GeminiManager.clearHistory()
                    }
                    
                    PlasmaComponents.ToolTip.visible: hovered
                    PlasmaComponents.ToolTip.text: text
                }
            }
        }
        
        // Chat List
        QQC2.ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            
            ListView {
                id: chatListView
                model: chatModel
                delegate: Components.MessageDelegate {
                    width: chatListView.width
                    trFunc: root.tr
                }
                
                spacing: Kirigami.Units.largeSpacing
                
                onCountChanged: {
                    if (chatListView.count > 0) {
                        Qt.callLater(function() {
                            chatListView.positionViewAtEnd()
                        })
                    }
                }
                
                // Placeholder
                ColumnLayout {
                    anchors.centerIn: parent
                    width: parent.width - Kirigami.Units.gridUnit * 2
                    visible: chatListView.count === 0
                    spacing: Kirigami.Units.largeSpacing
                    
                    Kirigami.PlaceholderMessage {
                        Layout.fillWidth: true
                        text: (!Plasmoid.configuration.apiKey) ? root.tr("api_key_missing") : root.tr("waiting")
                        icon.name: "google-gemini"
                    }
                    
                    PlasmaComponents.Button {
                        Layout.alignment: Qt.AlignHCenter
                        visible: !Plasmoid.configuration.apiKey
                        text: root.tr("guide")
                        icon.name: "help-about"
                        onClicked: Plasmoid.internalAction("configure").trigger()
                    }
                }
            }
        }
        
        // Input Area
        Components.InputArea {
            id: inputArea
            isLoading: root.isLoading
            trFunc: root.tr
            onMessageSent: (text, attachments) => root.handleSend(text, attachments)
            onStopRequested: root.handleStop()
        }
    }

    // Logic Functions
    function updateSafetySettings() {
        var map = ["BLOCK_NONE", "BLOCK_ONLY_HIGH", "BLOCK_MEDIUM_AND_ABOVE", "BLOCK_LOW_AND_ABOVE"];
        var settings = [
            { category: "HARM_CATEGORY_HARASSMENT", threshold: map[Math.max(0, Math.min(3, Plasmoid.configuration.safetyHarassment))] },
            { category: "HARM_CATEGORY_HATE_SPEECH", threshold: map[Math.max(0, Math.min(3, Plasmoid.configuration.safetyHateSpeech))] },
            { category: "HARM_CATEGORY_SEXUALLY_EXPLICIT", threshold: map[Math.max(0, Math.min(3, Plasmoid.configuration.safetySexual))] },
            { category: "HARM_CATEGORY_DANGEROUS_CONTENT", threshold: map[Math.max(0, Math.min(3, Plasmoid.configuration.safetyDangerous))] }
        ];
        GeminiManager.setSafetySettings(settings);
    }
    
    function onGeminiResponse(text) {
        isLoading = false
        if (chatModel.count > 0 && chatModel.get(chatModel.count - 1).chatRole === "loading") {
            chatModel.remove(chatModel.count - 1)
        }
        var formattedText = MarkdownParser.parse(text, root.tr("math_formula"))
        chatModel.append({ "chatRole": "model", "chatText": formattedText, "chatImage": "" })
    }
    
    function handleSend(text, attachments) {
        if (!Plasmoid.configuration.apiKey) {
            chatModel.append({ "chatRole": "error", "chatText": root.tr("api_key_missing"), "chatImage": "" })
            return
        }
        isLoading = true
        var imageUrl = (attachments && attachments.length > 0) ? attachments[0].url : ""
        chatModel.append({ "chatRole": "user", "chatText": MarkdownParser.parse(text, root.tr("math_formula")), "chatImage": imageUrl })
        chatModel.append({ "chatRole": "loading", "chatText": "", "chatImage": "" })
        GeminiManager.sendMessage(text, attachments, onGeminiError)
    }
    
    function onGeminiError(msg) {
        isLoading = false
        if (chatModel.count > 0 && chatModel.get(chatModel.count - 1).chatRole === "loading") {
            chatModel.remove(chatModel.count - 1)
        }
        chatModel.append({ "chatRole": "error", "chatText": msg, "chatImage": "" })
    }
    
    function handleStop() {
        GeminiManager.abortRequest()
        isLoading = false
        if (chatModel.count > 0 && chatModel.get(chatModel.count - 1).chatRole === "loading") {
            chatModel.remove(chatModel.count - 1)
        }
    }

    // Initialization
    Component.onCompleted: {
        GeminiManager.setApiKey(Plasmoid.configuration.apiKey)
        GeminiManager.setModel(Plasmoid.configuration.selectedModel || "gemini-1.5-flash")
        GeminiManager.setSystemInstruction(Plasmoid.configuration.systemInstruction)
        GeminiManager.setJsonMode(Plasmoid.configuration.jsonMode)
        updateSafetySettings()
        GeminiManager.setCallback(onGeminiResponse)
    }
    
    Connections {
        target: Plasmoid.configuration
        function onApiKeyChanged() { GeminiManager.setApiKey(Plasmoid.configuration.apiKey) }
        function onSelectedModelChanged() { GeminiManager.setModel(Plasmoid.configuration.selectedModel) }
        function onSystemInstructionChanged() { GeminiManager.setSystemInstruction(Plasmoid.configuration.systemInstruction) }
        function onJsonModeChanged() { GeminiManager.setJsonMode(Plasmoid.configuration.jsonMode) }
        function onSafetyHarassmentChanged() { updateSafetySettings() }
        function onSafetyHateSpeechChanged() { updateSafetySettings() }
        function onSafetySexualChanged() { updateSafetySettings() }
        function onSafetyDangerousChanged() { updateSafetySettings() }
        function onPinChanged() { root.hideOnWindowDeactivate = !Plasmoid.configuration.pin }
    }

    // Context Menu Actions
    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: root.tr("keep_open")
            icon.name: "window-pin"
            checkable: true
            checked: Plasmoid.configuration.pin
            onTriggered: Plasmoid.configuration.pin = checked
        },
        PlasmaCore.Action {
            text: root.tr("clear_chat")
            icon.name: "edit-clear"
            onTriggered: {
                chatModel.clear()
                GeminiManager.clearHistory()
            }
        }
    ]

    ListModel {
        id: chatModel
    }
}