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
    
    // --- Search text property ---
    property string searchText: ""
    
    // --- Localization ---
    property string currentLocale: Qt.locale().name.substring(0, 2)
    
    Component.onCompleted: {
        detectDefaultBrowser()
    }
    
    // --- Browser Detection ---
    property string detectedBrowser: "xdg-open"
    property string browserType: "other"
    property string browserIcon: "internet-web-browser"
    property string browserScheme: "https"
    property string browserDisplayName: "Browser"
    
    Plasma5Support.DataSource {
        id: executable
        engine: "executable"
        connectedSources: []
        
        onNewData: function(source, data) {
            var stdout = data["stdout"] || ""
            stdout = stdout.trim().toLowerCase()
            
            if (source === "xdg-settings get default-web-browser") {
                if (stdout.includes("firefox")) {
                    root.detectedBrowser = "firefox"
                    root.browserType = "firefox"
                    root.browserIcon = "firefox"
                    root.browserScheme = "about"
                    root.browserDisplayName = "Firefox"
                } else if (stdout.includes("brave")) {
                    root.detectedBrowser = "brave"
                    root.browserType = "chromium"
                    root.browserIcon = "brave"
                    root.browserScheme = "brave"
                    root.browserDisplayName = "Brave"
                } else if (stdout.includes("chromium")) {
                    root.detectedBrowser = "chromium"
                    root.browserType = "chromium"
                    root.browserIcon = "chromium"
                    root.browserScheme = "chrome"
                    root.browserDisplayName = "Chromium"
                } else if (stdout.includes("google-chrome") || stdout.includes("chrome")) {
                    root.detectedBrowser = "google-chrome"
                    root.browserType = "chromium"
                    root.browserIcon = "google-chrome"
                    root.browserScheme = "chrome"
                    root.browserDisplayName = "Chrome"
                } else if (stdout.includes("vivaldi")) {
                    root.detectedBrowser = "vivaldi"
                    root.browserType = "chromium"
                    root.browserIcon = "vivaldi"
                    root.browserScheme = "vivaldi"
                    root.browserDisplayName = "Vivaldi"
                } else if (stdout.includes("opera")) {
                    root.detectedBrowser = "opera"
                    root.browserType = "chromium"
                    root.browserIcon = "opera"
                    root.browserScheme = "opera"
                    root.browserDisplayName = "Opera"
                } else if (stdout.includes("edge")) {
                    root.detectedBrowser = "microsoft-edge"
                    root.browserType = "chromium"
                    root.browserIcon = "microsoft-edge"
                    root.browserScheme = "edge"
                    root.browserDisplayName = "Edge"
                } else {
                    root.detectedBrowser = "xdg-open"
                    root.browserType = "other"
                    root.browserIcon = "internet-web-browser"
                    root.browserScheme = "https"
                    root.browserDisplayName = i18n("Browser")
                }
            }
            disconnectSource(source)
        }
    }
    
    function detectDefaultBrowser() {
        executable.connectSource("xdg-settings get default-web-browser")
    }
    
    function runCommand(cmd) {
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
    
    function openSettings() {
        if (browserType === "chromium") {
            runCommand(detectedBrowser + ' "' + browserScheme + '://settings"')
        } else if (browserType === "firefox") {
            runCommand(detectedBrowser + ' "about:preferences"')
        }
    }
    
    // --- Layout Mode Detection (like weather widget) ---
    readonly property bool only_search_bar: root.height < 150
    readonly property bool isLargeMode: root.width > 200 && root.height > 200
    readonly property bool isWideMode: root.width > 280 && !only_search_bar && !isLargeMode
    readonly property bool isSmallMode: !isWideMode && !isLargeMode && !only_search_bar
    
    // --- Widget Size Constraints ---
    Layout.preferredWidth: 300
    Layout.preferredHeight: 80
    Layout.minimumWidth: 150
    Layout.minimumHeight: 60
    
    // --- No Background (like weather widget) ---
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    
    preferredRepresentation: fullRepresentation
    
    fullRepresentation: Item {
        id: fullRep
        anchors.fill: parent
        
        Rectangle {
            id: mainRect
            anchors.fill: parent
            anchors.margins: Plasmoid.configuration.edgeMargin !== undefined ? Plasmoid.configuration.edgeMargin : 10
            color: Kirigami.Theme.backgroundColor
            radius: 20
            clip: true
            
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 10
                
                // Search Bar - Always visible
                Rectangle {
                    id: searchBar
                    Layout.fillWidth: true
                    Layout.preferredHeight: 48
                    radius: 14
                    color: Qt.rgba(
                        Kirigami.Theme.textColor.r,
                        Kirigami.Theme.textColor.g,
                        Kirigami.Theme.textColor.b,
                        0.08
                    )
                    
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 12
                        spacing: 8
                        
                        TextField {
                            id: searchInput
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            
                            placeholderText: i18n("Search the web...")
                            placeholderTextColor: Qt.rgba(
                                Kirigami.Theme.textColor.r,
                                Kirigami.Theme.textColor.g,
                                Kirigami.Theme.textColor.b,
                                0.5
                            )
                            
                            font.pixelSize: 15
                            font.weight: Font.Normal
                            color: Kirigami.Theme.textColor
                            
                            background: Item {}
                            
                            text: root.searchText
                            onTextChanged: root.searchText = text
                            onAccepted: root.doSearch()
                            
                            Keys.onEscapePressed: {
                                text = ""
                                focus = false
                            }
                        }
                        
                        // Search Icon
                        Kirigami.Icon {
                            source: "search"
                            Layout.preferredWidth: 22
                            Layout.preferredHeight: 22
                            color: Kirigami.Theme.textColor
                            
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.doSearch()
                            }
                        }
                    }
                }
                
                // Wide Mode: Horizontal buttons centered
                Item {
                    visible: root.isWideMode
                    Layout.fillWidth: true
                    Layout.preferredHeight: 56
                    
                    RowLayout {
                        anchors.horizontalCenter: parent.horizontalCenter
                        height: parent.height
                        spacing: 8
                        
                        Repeater {
                            model: [
                                { icon: "view-history", action: "history", tooltip: i18n("Open History") },
                                { icon: "tab-new", action: "newTab", tooltip: i18n("Open New Tab") },
                                { icon: "download", action: "downloads", tooltip: i18n("Open Downloads") },
                                { icon: "application-x-addon", action: "extensions", tooltip: i18n("Manage Extensions") },
                                { icon: "configure", action: "settings", tooltip: i18n("Browser Settings") }
                            ]
                            
                            delegate: Rectangle {
                                width: 50
                                height: 50
                                radius: 25
                                color: wideButtonMouseArea.containsMouse 
                                    ? Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.12)
                                    : Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.06)
                                
                                Behavior on color {
                                    ColorAnimation { duration: 150 }
                                }
                                
                                Kirigami.Icon {
                                    anchors.centerIn: parent
                                    source: modelData.icon
                                    width: 22
                                    height: 22
                                    color: Kirigami.Theme.textColor
                                }
                                
                                MouseArea {
                                    id: wideButtonMouseArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    
                                    ToolTip.text: modelData.tooltip
                                    ToolTip.visible: containsMouse
                                    ToolTip.delay: 500
                                    
                                    onClicked: {
                                        switch(modelData.action) {
                                            case "history": root.openHistory(); break
                                            case "newTab": root.openNewTab(); break
                                            case "downloads": root.openDownloads(); break
                                            case "extensions": root.openExtensions(); break
                                            case "settings": root.openSettings(); break
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Wide Mode: Browser label
                Row {
                    visible: root.isWideMode
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 6
                    
                    Kirigami.Icon {
                        source: root.browserIcon
                        width: 18
                        height: 18
                    }
                    
                    Text {
                        text: root.browserDisplayName
                        font.pixelSize: 13
                        font.weight: Font.Medium
                        color: Kirigami.Theme.textColor
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
                
                // Large Mode: 2x2 Grid buttons
                GridLayout {
                    visible: root.isLargeMode
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    columns: 2
                    rows: 2
                    rowSpacing: 10
                    columnSpacing: 10
                    
                    Repeater {
                        model: [
                            { icon: "view-history", action: "history", tooltip: i18n("Open History") },
                            { icon: "download", action: "downloads", tooltip: i18n("Open Downloads") },
                            { icon: "application-x-addon", action: "extensions", tooltip: i18n("Manage Extensions") },
                            { icon: "configure", action: "settings", tooltip: i18n("Browser Settings") }
                        ]
                        
                        delegate: Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 14
                            color: largeButtonMouseArea.containsMouse 
                                ? Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.12)
                                : Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.06)
                            
                            Behavior on color {
                                ColorAnimation { duration: 150 }
                            }
                            
                            Kirigami.Icon {
                                anchors.centerIn: parent
                                source: modelData.icon
                                width: 32
                                height: 32
                                color: Kirigami.Theme.textColor
                            }
                            
                            MouseArea {
                                id: largeButtonMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                
                                ToolTip.text: modelData.tooltip
                                ToolTip.visible: containsMouse
                                ToolTip.delay: 500
                                
                                onClicked: {
                                    switch(modelData.action) {
                                        case "history": root.openHistory(); break
                                        case "downloads": root.openDownloads(); break
                                        case "extensions": root.openExtensions(); break
                                        case "settings": root.openSettings(); break
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Small Mode: No extra elements, only search bar
                Item {
                    visible: root.isSmallMode
                    Layout.fillHeight: true
                }
            }
        }
    }
    
    compactRepresentation: Item {
        Layout.preferredWidth: 32
        Layout.preferredHeight: 32
        
        Kirigami.Icon {
            anchors.centerIn: parent
            source: root.browserIcon
            width: 24
            height: 24
        }
        
        MouseArea {
            anchors.fill: parent
            onClicked: root.expanded = !root.expanded
        }
    }
}
