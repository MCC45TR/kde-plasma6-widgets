import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    id: page
    
    property alias cfg_searchEngine: searchEngineCombo.currentValue
    property alias cfg_customSearchUrl: customUrlField.text
    property alias cfg_customBrowserExecutable: customBrowserField.text
    
    TextField {
        id: customBrowserField
        Kirigami.FormData.label: "Custom Browser Command:"
        placeholderText: "e.g. brave-browser, firefox (Leave empty for auto-detect)"
        Layout.fillWidth: true
    }
    
    ComboBox {
        id: searchEngineCombo
        Kirigami.FormData.label: "Search Engine:"
        model: [
            { text: "Google", value: "google" },
            { text: "DuckDuckGo", value: "duckduckgo" },
            { text: "Bing", value: "bing" },
            { text: "Yahoo", value: "yahoo" },
            { text: "Yandex", value: "yandex" },
            { text: "Ecosia", value: "ecosia" },
            { text: "Startpage", value: "startpage" },
            { text: "Custom", value: "custom" }
        ]
        textRole: "text"
        valueRole: "value"
    }
    
    TextField {
        id: customUrlField
        Kirigami.FormData.label: "Custom URL:"
        visible: searchEngineCombo.currentValue === "custom"
        placeholderText: "https://example.com/search?q=%s"
        Layout.fillWidth: true
    }
    
    Label {
        visible: searchEngineCombo.currentValue === "custom"
        text: "Use %s as placeholder for the search query"
        font.pixelSize: 11
        opacity: 0.7
    }
}
