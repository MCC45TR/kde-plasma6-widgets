import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    id: page
    
    // Alias'lar "cfg_" öneki ile başlamalıdır ki main.xml'deki ayarlarla otomatik eşleşsin
    property alias cfg_googleClientId: clientIdField.text
    property alias cfg_googleClientSecret: clientSecretField.text
    property alias cfg_googleApiKey: apiKeyField.text
    property alias cfg_googleCalendarId: calendarIdField.text
    property alias cfg_showLocalHolidays: localHolidaysSwitch.checked
    property alias cfg_showEventsPanel: showEventsSwitch.checked
    property alias cfg_showDummyEvents: dummyEventsSwitch.checked

    // --- WARNING MESSAGE ---
    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: 20
        Layout.bottomMargin: 15
        
        Label {
            text: "DİKKAT: Google API verileri yanlış girilirse takvim çalışmayabilir."
            color: "red"
            font.bold: true
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }
    }

    // --- GOOGLE API SETTINGS ---
    TextField {
        id: clientIdField
        Kirigami.FormData.label: "Client ID:"
        placeholderText: "Google Client ID"
        Layout.fillWidth: true
    }

    TextField {
        id: clientSecretField
        Kirigami.FormData.label: "Client Secret:"
        placeholderText: "Google Client Secret"
        echoMode: TextInput.Password
        Layout.fillWidth: true
    }

    TextField {
        id: apiKeyField
        Kirigami.FormData.label: "API Key:"
        placeholderText: "Google API Key"
        echoMode: TextInput.Password
        Layout.fillWidth: true
    }
    
    TextField {
        id: calendarIdField
        Kirigami.FormData.label: "Calendar ID:"
        placeholderText: "primary"
        Layout.fillWidth: true
    }
    
    // --- DISPLAY SETTINGS ---
    CheckBox {
        id: showEventsSwitch
        Kirigami.FormData.label: "Görünüm:"
        text: "Etkinlikler Blokunu Göster"
    }

    // --- TEST DATA ---
    CheckBox {
        id: dummyEventsSwitch
        Kirigami.FormData.label: "Test Verisi:"
        text: "15 Adet Rastgele Test Etkinliği Göster"
    }

    // --- HOLIDAY SETTINGS ---
    CheckBox {
        id: localHolidaysSwitch
        Kirigami.FormData.label: "Özel Günler:"
        text: "İnternetten önemli günleri çek (Sistem diline göre)"
    }
    
    // --- ACTIONS ---
    RowLayout {
        Kirigami.FormData.label: "İşlemler:"
        
        Button {
            text: "Ayarları Sıfırla"
            icon.name: "edit-clear"
            onClicked: {
                clientIdField.text = ""
                clientSecretField.text = ""
                apiKeyField.text = ""
                calendarIdField.text = "primary"
                localHolidaysSwitch.checked = false
            }
        }
    }
}
