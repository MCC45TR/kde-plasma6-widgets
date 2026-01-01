.pragma library

// Gemini Manager - Handles API interactions and chat session
// Handles localization and markdown parsing via helper methods

var apiKey = "";
var selectedModel = "gemini-1.5-flash";
var chatHistory = [];
var systemInstruction = ""; // Persona instruction
var chatCallback = null;
var safetySettings = [];
var jsonMode = false;
var activeXHR = null; // Track active request for abort

function abortRequest() {
    if (activeXHR) {
        activeXHR.abort();
        activeXHR = null;
        return true;
    }
    return false;
}

function setApiKey(key) { apiKey = key; }
function setModel(model) { selectedModel = model; }
function setCallback(callback) { chatCallback = callback; }

function setSystemInstruction(instruction) {
    if (instruction && instruction.trim() !== "") {
        systemInstruction = instruction;
    } else {
        systemInstruction = "";
    }
}

function setSafetySettings(settings) {
    // settings: array of { category: string, threshold: string }
    safetySettings = settings || [];
}

function setJsonMode(enabled) {
    jsonMode = enabled;
}

function clearHistory() { chatHistory = []; }

function addToHistory(role, text) {
    chatHistory.push({
        "role": role,
        "parts": [{ "text": text }]
    });
}

// Function to send message to Gemini API
function sendMessage(text, attachments, onError) {
    if (!apiKey) {
        if (onError) onError("API Key not configured");
        return;
    }

    var newMessage = {
        "role": "user",
        "parts": []
    };

    // Add text part
    if (text && text.trim() !== "") {
        newMessage.parts.push({ "text": text });
    }

    // Add attachments (images)
    if (attachments && attachments.length > 0) {
        for (var i = 0; i < attachments.length; i++) {
            var att = attachments[i];
            if (att.base64) {
                newMessage.parts.push({
                    "inline_data": {
                        "mime_type": att.mimeType || "image/jpeg",
                        "data": att.base64
                    }
                });
            }
        }
    }

    // Temporary array for this request (history + new message)
    var contents = chatHistory.slice();
    contents.push(newMessage);

    var url = "https://generativelanguage.googleapis.com/v1beta/models/" + selectedModel + ":generateContent?key=" + apiKey;

    var xhr = new XMLHttpRequest();
    activeXHR = xhr; // Store for abort capability
    xhr.open("POST", url, true);
    xhr.setRequestHeader("Content-Type", "application/json");

    xhr.onreadystatechange = function () {
        if (xhr.readyState === XMLHttpRequest.DONE) {
            activeXHR = null; // Clear active reference
            if (xhr.status === 200) {
                try {
                    var response = JSON.parse(xhr.responseText);
                    var candidates = response.candidates;

                    if (candidates && candidates.length > 0) {
                        var content = candidates[0].content;
                        var replyText = "";

                        // Extract text from parts
                        if (content.parts && content.parts.length > 0) {
                            for (var j = 0; j < content.parts.length; j++) {
                                if (content.parts[j].text) {
                                    replyText += content.parts[j].text;
                                }
                            }
                        }

                        // Update local history
                        chatHistory.push(newMessage);
                        chatHistory.push({
                            "role": "model",
                            "parts": [{ "text": replyText }]
                        });

                        if (chatCallback) chatCallback(replyText);
                    } else {
                        // Check for block reason
                        if (response.promptFeedback && response.promptFeedback.blockReason) {
                            if (onError) onError("Safety Block: " + response.promptFeedback.blockReason);
                        } else {
                            if (onError) onError("No response returned. Check settings.");
                        }
                    }
                } catch (e) {
                    if (onError) onError("JSON Parse Error: " + e.message);
                }
            } else {
                var errorMsg = "Error " + xhr.status;
                try {
                    var errJson = JSON.parse(xhr.responseText);
                    if (errJson.error && errJson.error.message) {
                        errorMsg += ": " + errJson.error.message;
                    }
                } catch (e) { }
                if (onError) onError(errorMsg);
            }
        }
    };

    var payload = {
        "contents": contents
    };

    // 1. System Instruction (Persona)
    if (systemInstruction !== "") {
        payload["systemInstruction"] = {
            "parts": [{ "text": systemInstruction }]
        };
    }

    // 2. Safety Settings
    if (safetySettings && safetySettings.length > 0) {
        payload["safetySettings"] = safetySettings;
    }

    // 3. Generation Config (JSON Mode)
    var genConfig = {};
    if (jsonMode) {
        genConfig["responseMimeType"] = "application/json";
    }
    // Only add if not empty
    if (Object.keys(genConfig).length > 0) {
        payload["generationConfig"] = genConfig;
    }

    xhr.send(JSON.stringify(payload));
}
