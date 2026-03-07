import QtQuick
import QtQuick.Controls

Item {
   property var bootEntries: []
   property int edgeMargin: 10

   Text {
       anchors.centerIn: parent
       text: i18n("Large Mode (Coming Soon)")
   }
}
