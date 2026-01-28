import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    property alias cfg_appNameFormat: appNameFormat.currentIndex
    
    Layout.fillWidth: true
    
    Kirigami.FormLayout {
        ComboBox {
            id: appNameFormat
            Kirigami.FormData.label: i18n("Application name format:")
            model: [i18n("Name only"), i18n("Generic name only"), i18n("Name (Generic name)"), i18n("Generic name (Name)")]
        }
    }
}
