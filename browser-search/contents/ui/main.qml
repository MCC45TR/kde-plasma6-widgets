import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.plasma5support as Plasma5Support

PlasmoidItem {
    id: root
    
    // --- Search text property accessible from root ---
    property string searchText: ""
    
    // --- Localization ---
    property var locales: ({})
    property string currentLocale: Qt.locale().name.substring(0, 2)
    
    function loadLocales() {
        var xhr = new XMLHttpRequest()
        xhr.open("GET", Qt.resolvedUrl("localization.json"))
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200 || xhr.status === 0) {
                    try {
                        locales = JSON.parse(xhr.responseText)
                    } catch (e) {
                        console.log("Error parsing localization.json: " + e)
                        locales = {}
                    }
                }
            }
        }
        xhr.send()
    }
    
    function tr(key) {
        if (locales[currentLocale] && locales[currentLocale][key]) {
            return locales[currentLocale][key]
        } else if (locales["en"] && locales["en"][key]) {
            return locales["en"][key]
        }
        return key
    }
    
    Component.onCompleted: {
        loadLocales()
        detectDefaultBrowser()
    }
    
    // --- Browser Detection (values updated dynamically by detectDefaultBrowser) ---
    property string detectedBrowser: "xdg-open"
    property string browserType: "other" // chromium, firefox, other
    property string browserIcon: "internet-web-browser" // System icon for detected browser
    property string browserScheme: "https" // URL scheme: chrome, brave, edge, vivaldi, opera
    
    // DataSource for running executable commands
    Plasma5Support.DataSource {
        id: executable
        engine: "executable"
        connectedSources: []
        
        onNewData: function(source, data) {
            var stdout = data["stdout"] || ""
            stdout = stdout.trim().toLowerCase()
            
            if (source === "xdg-settings get default-web-browser") {
                console.log("Default browser detected: " + stdout)
                
                if (stdout.includes("firefox")) {
                    root.detectedBrowser = "firefox"
                    root.browserType = "firefox"
                    root.browserIcon = "firefox"
                    root.browserScheme = "about"
                } else if (stdout.includes("brave")) {
                    root.detectedBrowser = "brave"
                    root.browserType = "chromium"
                    root.browserIcon = "brave"
                    root.browserScheme = "brave"
                } else if (stdout.includes("chromium")) {
                    root.detectedBrowser = "chromium"
                    root.browserType = "chromium"
                    root.browserIcon = "chromium"
                    root.browserScheme = "chrome"
                } else if (stdout.includes("google-chrome") || stdout.includes("chrome")) {
                    root.detectedBrowser = "google-chrome"
                    root.browserType = "chromium"
                    root.browserIcon = "google-chrome"
                    root.browserScheme = "chrome"
                } else if (stdout.includes("vivaldi")) {
                    root.detectedBrowser = "vivaldi"
                    root.browserType = "chromium"
                    root.browserIcon = "vivaldi"
                    root.browserScheme = "vivaldi"
                } else if (stdout.includes("opera")) {
                    root.detectedBrowser = "opera"
                    root.browserType = "chromium"
                    root.browserIcon = "opera"
                    root.browserScheme = "opera"
                } else if (stdout.includes("edge")) {
                    root.detectedBrowser = "microsoft-edge"
                    root.browserType = "chromium"
                    root.browserIcon = "microsoft-edge"
                    root.browserScheme = "edge"
                } else {
                    root.detectedBrowser = "xdg-open"
                    root.browserType = "other"
                    root.browserIcon = "internet-web-browser"
                    root.browserScheme = "https"
                }
            }
            
            // Disconnect after receiving data
            disconnectSource(source)
        }
    }
    
    function detectDefaultBrowser() {
        executable.connectSource("xdg-settings get default-web-browser")
    }
    
    function runCommand(cmd) {
        console.log("Running command: " + cmd)
        executable.connectSource(cmd)
    }
    
    // --- Configuration ---
    property string searchEngine: Plasmoid.configuration.searchEngine || "google"
    property string customSearchUrl: Plasmoid.configuration.customSearchUrl || ""
    
    readonly property var searchEngines: {
        "google": "https://www.google.com/search?q=",
        "duckduckgo": "https://duckduckgo.com/?q=",
        "bing": "https://www.bing.com/search?q=",
        "yahoo": "https://search.yahoo.com/search?p=",
        "yandex": "https://yandex.com/search/?text=",
        "ecosia": "https://www.ecosia.org/search?q=",
        "startpage": "https://www.startpage.com/do/search?q="
    }
    
    function getSearchUrl(query) {
        if (searchEngine === "custom" && customSearchUrl) {
            return customSearchUrl.replace("%s", encodeURIComponent(query))
        }
        return (searchEngines[searchEngine] || searchEngines["google"]) + encodeURIComponent(query)
    }
    
    function doSearch() {
        var query = root.searchText.trim()
        if (query.length > 0) {
            var url = getSearchUrl(query)
            runCommand(detectedBrowser + ' "' + url + '"')
            root.searchText = ""
        }
    }
    
    function openIncognito() {
        if (browserType === "firefox") {
            runCommand(detectedBrowser + " --private-window")
        } else {
            runCommand(detectedBrowser + " --incognito")
        }
    }
    
    function openNewTab() {
        runCommand(detectedBrowser + " --new-tab")
    }
    
    function openHistory() {
        if (browserType === "firefox") {
            runCommand(detectedBrowser + ' "about:history"')
        } else {
            runCommand(detectedBrowser + ' "' + browserScheme + '://history"')
        }
    }
    
    function openDinoGame() {
        if (browserType === "chromium") {
            runCommand(detectedBrowser + ' "' + browserScheme + '://dino"')
        }
    }
    
    function openDownloads() {
        if (browserType === "chromium") {
            runCommand(detectedBrowser + ' "' + browserScheme + '://downloads"')
        } else if (browserType === "firefox") {
             runCommand(detectedBrowser + ' "about:downloads"')
        }
    }
    
    function openExtensions() {
        if (browserType === "chromium") {
            runCommand(detectedBrowser + ' "' + browserScheme + '://extensions"')
        } else if (browserType === "firefox") {
             runCommand(detectedBrowser + ' "about:addons"')
        }
    }
    
    function openBookmarks() {
        if (browserType === "chromium") {
            runCommand(detectedBrowser + ' "' + browserScheme + '://bookmarks"')
        } else if (browserType === "firefox") {
             // Firefox uses library for bookmarks
             runCommand(detectedBrowser + " about:logins") 
        }
    }
    
    function openSettings() {
        if (browserType === "chromium") {
            runCommand(detectedBrowser + ' "' + browserScheme + '://settings"')
        } else if (browserType === "firefox") {
             runCommand(detectedBrowser + ' "about:preferences"')
        }
    }
    
    // --- Layout ---
    preferredRepresentation: fullRepresentation
    
    property bool isCompact: width < 250
    
    fullRepresentation: Item {
        id: mainItem
        
        Layout.minimumWidth: 150
        Layout.minimumHeight: 40
        Layout.preferredWidth: 400
        Layout.preferredHeight: 48
        
        Rectangle {
            anchors.fill: parent
            anchors.margins: 4
            radius: 8
            color: Kirigami.Theme.backgroundColor
            border.color: searchInput.activeFocus ? Kirigami.Theme.highlightColor : "transparent"
            border.width: searchInput.activeFocus ? 2 : 0
            
            RowLayout {
                anchors.fill: parent
                anchors.margins: 6
                spacing: 8
                
                // Browser Icon (shows detected browser icon)
                Kirigami.Icon {
                    source: root.browserIcon
                    Layout.preferredWidth: 22
                    Layout.preferredHeight: 22
                }
                
                // Search Input
                TextField {
                    id: searchInput
                    Layout.fillWidth: true
                    placeholderText: root.tr("search_placeholder")
                    font.pixelSize: 14
                    background: Item {}
                    text: root.searchText
                    
                    onTextChanged: root.searchText = text
                    
                    onAccepted: root.doSearch()
                    
                    Keys.onEscapePressed: {
                        text = ""
                        focus = false
                    }
                }
                
                // Separator
                Rectangle {
                    visible: !root.isCompact
                    width: 1
                    Layout.fillHeight: true
                    Layout.topMargin: 6
                    Layout.bottomMargin: 6
                    color: Kirigami.Theme.textColor
                    opacity: 0.2
                }
                
                // Incognito Button
                ToolButton {
                    id: incognitoBtn
                    icon.name: "view-private"
                    Layout.preferredWidth: 32
                    Layout.preferredHeight: 32
                    
                    ToolTip.text: root.tr("incognito")
                    ToolTip.visible: hovered
                    ToolTip.delay: 500
                    
                    onClicked: root.openIncognito()
                }
                
                // New Tab Button
                ToolButton {
                    id: newTabBtn
                    icon.name: "tab-new"
                    Layout.preferredWidth: 32
                    Layout.preferredHeight: 32
                    
                    ToolTip.text: root.tr("new_tab")
                    ToolTip.visible: hovered
                    ToolTip.delay: 500
                    
                    onClicked: root.openNewTab()
                }
                
                // History Button
                ToolButton {
                    id: historyBtn
                    icon.name: "view-history"
                    Layout.preferredWidth: 32
                    Layout.preferredHeight: 32
                    
                    ToolTip.text: root.tr("history")
                    ToolTip.visible: hovered
                    ToolTip.delay: 500
                    
                    onClicked: root.openHistory()
                }
                
                // Dino Game Button
                ToolButton {
                    id: dinoBtn
                    visible: root.browserType === "chromium"
                    icon.name: "application-x-executable"
                    Layout.preferredWidth: 32
                    Layout.preferredHeight: 32
                    
                    ToolTip.text: root.tr("dino_game")
                    ToolTip.visible: hovered
                    ToolTip.delay: 500
                    
                    onClicked: root.openDinoGame()
                    
                    // Dino emoji as text fallback
                    Label {
                        anchors.centerIn: parent
                        text: "🦖"
                        font.pixelSize: 18
                    }
                }
                
                // Downloads Button
                ToolButton {
                    visible: !root.isCompact
                    icon.name: "download"
                    Layout.preferredWidth: 32
                    Layout.preferredHeight: 32
                    
                    ToolTip.text: root.tr("downloads")
                    ToolTip.visible: hovered
                    ToolTip.delay: 500
                    
                    onClicked: root.openDownloads()
                }
                
                // Extensions Button
                ToolButton {
                    visible: !root.isCompact
                    icon.name: "application-x-addon"
                    Layout.preferredWidth: 32
                    Layout.preferredHeight: 32
                    
                    ToolTip.text: root.tr("extensions")
                    ToolTip.visible: hovered
                    ToolTip.delay: 500
                    
                    onClicked: root.openExtensions()
                }
                
                // Bookmarks Button
                ToolButton {
                    visible: !root.isCompact
                    icon.name: "bookmarks"
                    Layout.preferredWidth: 32
                    Layout.preferredHeight: 32
                    
                    ToolTip.text: root.tr("bookmarks")
                    ToolTip.visible: hovered
                    ToolTip.delay: 500
                    
                    onClicked: root.openBookmarks()
                }
                
                // Settings Button
                ToolButton {
                    visible: !root.isCompact
                    icon.name: "configure"
                    Layout.preferredWidth: 32
                    Layout.preferredHeight: 32
                    
                    ToolTip.text: root.tr("settings")
                    ToolTip.visible: hovered
                    ToolTip.delay: 500
                    
                    onClicked: root.openSettings()
                }
            }
        }
    }
    
    compactRepresentation: Item {
        Layout.preferredWidth: 120
        Layout.preferredHeight: 32
        
        RowLayout {
            anchors.centerIn: parent
            spacing: 4
            
            Kirigami.Icon {
                source: root.browserIcon
                Layout.preferredWidth: 22
                Layout.preferredHeight: 22
            }
            
            ToolButton {
                icon.name: "view-private"
                Layout.preferredWidth: 24
                Layout.preferredHeight: 24
                onClicked: root.openIncognito()
            }
            
            ToolButton {
                icon.name: "tab-new"
                Layout.preferredWidth: 24
                Layout.preferredHeight: 24
                onClicked: root.openNewTab()
            }
            
            ToolButton {
                icon.name: "view-history"
                Layout.preferredWidth: 24
                Layout.preferredHeight: 24
                onClicked: root.openHistory()
            }
        }
        
        MouseArea {
            anchors.fill: parent
            onClicked: root.expanded = !root.expanded
        }
    }
}
