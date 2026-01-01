/*
    SPDX-FileCopyrightText: 2023 Denys Madureira <denysmb@zoho.com>
    SPDX-License-Identifier: LGPL-2.1-or-later
*/

import QtQuick
import QtQuick.Controls
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
    
    // Config properties
    property bool isLoading: false
    hideOnWindowDeactivate: !Plasmoid.configuration.pin
    
    // Initialize
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
    
    function updateSafetySettings() {
        // Map 0-3 int to Threshold Strings
        // 0=BLOCK_NONE, 1=BLOCK_MEDIUM_AND_ABOVE (Default), 2=BLOCK_LOW_AND_ABOVE, 3=BLOCK_ONLY_HIGH? 
        // Wait, standard is:
        // BLOCK_NONE (Allows everything)
        // BLOCK_ONLY_HIGH (Blocks only high probability)
        // BLOCK_MEDIUM_AND_ABOVE (Blocks medium & high)
        // BLOCK_LOW_AND_ABOVE (Blocks low, medium, high)
        
        // Let's assume the ComboBox logic was:
        // 0: "None" -> BLOCK_NONE
        // 1: "Few" (Default/Normal) -> BLOCK_MEDIUM_AND_ABOVE
        // 2: "Some" -> BLOCK_LOW_AND_ABOVE (More distinct)
        // 3: "Most" -> BLOCK_LOW_AND_ABOVE (Strict) -- actually let's re-map nicely
        
        // Better Mapping:
        // 0: None -> BLOCK_NONE
        // 1: Few -> BLOCK_ONLY_HIGH
        // 2: Some -> BLOCK_MEDIUM_AND_ABOVE
        // 3: Most -> BLOCK_LOW_AND_ABOVE
        
        var map = ["BLOCK_NONE", "BLOCK_ONLY_HIGH", "BLOCK_MEDIUM_AND_ABOVE", "BLOCK_LOW_AND_ABOVE"];
        var settings = [
            { category: "HARM_CATEGORY_HARASSMENT", threshold: map[Plasmoid.configuration.safetyHarassment || 1] },
            { category: "HARM_CATEGORY_HATE_SPEECH", threshold: map[Plasmoid.configuration.safetyHateSpeech || 1] },
            { category: "HARM_CATEGORY_SEXUALLY_EXPLICIT", threshold: map[Plasmoid.configuration.safetySexual || 1] },
            { category: "HARM_CATEGORY_DANGEROUS_CONTENT", threshold: map[Plasmoid.configuration.safetyDangerous || 1] }
        ];
        GeminiManager.setSafetySettings(settings);
    }
    
    function onGeminiResponse(text) {
        isLoading = false
        
        // Remove loading indicator if present
        if (chatModel.count > 0 && chatModel.get(chatModel.count - 1).chatRole === "loading") {
            chatModel.remove(chatModel.count - 1)
        }

        var formattedText = MarkdownParser.parse(text, root.tr("math_formula"))
        
        chatModel.append({
            "chatRole": "model",
            "chatText": formattedText,
            "chatImage": ""
        })
    }
    
    function handleSend(text, attachments) {
        if (!Plasmoid.configuration.apiKey) {
            chatModel.append({
                "chatRole": "error",
                "chatText": root.tr("api_key_missing"),
                "chatImage": ""
            })
            return
        }
    
        isLoading = true
        
        var imageUrl = ""
        if (attachments && attachments.length > 0) {
            imageUrl = attachments[0].url
        }
        
        // 1. Add User Message
        chatModel.append({
            "chatRole": "user",
            "chatText": MarkdownParser.parse(text, root.tr("math_formula")),
            "chatImage": imageUrl
        })
        
        // 2. Add Loading Indicator
        chatModel.append({
            "chatRole": "loading",
            "chatText": "",
            "chatImage": ""
        })
        
        // 3. Send to Backend
        GeminiManager.sendMessage(text, [], onGeminiError)
    }
    
    function onGeminiError(msg) {
        isLoading = false
        
        // Remove loading indicator
        if (chatModel.count > 0 && chatModel.get(chatModel.count - 1).chatRole === "loading") {
            chatModel.remove(chatModel.count - 1)
        }
        
        chatModel.append({
            "chatRole": "error",
            "chatText": msg,
            "chatImage": ""
        })
    }

    // Context Menu
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

    // Data Model
    ListModel {
        id: chatModel
    }

    // Compact Representation
    compactRepresentation: CompactRepresentation {}

    // Full Representation
    fullRepresentation: ColumnLayout {
        Layout.preferredWidth: 400
        Layout.preferredHeight: 500
        Layout.minimumWidth: 300
        Layout.minimumHeight: 400
        
        // Header
        PlasmaExtras.PlasmoidHeading {
            Layout.fillWidth: true
            
            contentItem: RowLayout {
                spacing: 8
                
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
                ComboBox {
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
                    
                    // Sync with config on load and change
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
                        currentIndex = 0; // Default fallback
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
        ScrollView {
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
                
                spacing: 12
                
                // Auto-scroll to bottom
                onCountChanged: {
                    Qt.callLater(function() {
                        chatListView.positionViewAtEnd()
                    })
                }
                
                // Placeholder with Guide Button
                ColumnLayout {
                    anchors.centerIn: parent
                    width: parent.width - 40
                    visible: chatListView.count === 0
                    spacing: Kirigami.Units.largeSpacing
                    
                    Kirigami.PlaceholderMessage {
                        Layout.fillWidth: true
                        text: (!Plasmoid.configuration.apiKey) ? root.tr("api_key_missing") : root.tr("waiting")
                        icon.name: "google-gemini"
                    }
                    
                    // Guide Button (only visible when API key is missing)
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
    
    function handleStop() {
        GeminiManager.abortRequest()
        isLoading = false
        // Remove loading indicator if present
        if (chatModel.count > 0 && chatModel.get(chatModel.count - 1).chatRole === "loading") {
            chatModel.remove(chatModel.count - 1)
        }
    }
}