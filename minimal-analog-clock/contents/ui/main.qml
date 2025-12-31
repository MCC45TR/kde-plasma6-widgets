import QtQuick 2.15
import QtQuick.Layouts 1.15
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.components 3.0 as PlasmaComponents
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root
    width: 200
    height: 200

    preferredRepresentation: fullRepresentation
    fullRepresentation: Item {
        id: clockContainer
        anchors.fill: parent

        function updateTime() {
            var date = new Date();
            var hours = date.getHours();
            var minutes = date.getMinutes();
            var seconds = date.getSeconds();

            // Rotate hands
            hourHandRotation.angle = (hours % 12 + minutes / 60) * 30;
            minuteHandRotation.angle = (minutes + seconds / 60) * 6;
            secondHandRotation.angle = seconds * 6;
        }

        Timer {
            interval: 500
            running: true
            repeat: true
            onTriggered: updateTime()
        }

        Component.onCompleted: updateTime()

        // Main Shape (Squircle)
        Rectangle {
            id: clockFace
            anchors.centerIn: parent
            width: Math.min(parent.width, parent.height)
            height: width
            radius: width * 0.22 // Matches typical "squircle" icon look
            color: Kirigami.Theme.backgroundColor
            border.color: Kirigami.Theme.textColor
            border.width: 1

            // Inner Face (Circular hint) - Made simpler/subtler for system theme compatibility
            Rectangle {
                anchors.centerIn: parent
                width: parent.width * 0.85
                height: width
                radius: width / 2
                color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.1)
            }
            
            // Center Point for Hands
            Item {
                id: centerPoint
                anchors.centerIn: parent
                width: 0
                height: 0

                // Hour Hand
                Rectangle {
                    id: hourHand
                    width: clockFace.width * 0.035
                    height: clockFace.height * 0.25
                    color: Kirigami.Theme.textColor
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    antialiasing: true
                    transform: Rotation {
                        id: hourHandRotation
                        origin.x: hourHand.width / 2
                        origin.y: hourHand.height
                    }
                }

                // Minute Hand
                Rectangle {
                    id: minuteHand
                    width: clockFace.width * 0.025
                    height: clockFace.height * 0.35
                    color: Kirigami.Theme.textColor
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    antialiasing: true
                     transform: Rotation {
                        id: minuteHandRotation
                        origin.x: minuteHand.width / 2
                        origin.y: minuteHand.height
                    }
                }

                // Second Hand
                Rectangle {
                    id: secondHand
                    width: clockFace.width * 0.01
                    height: clockFace.height * 0.4
                    color: Kirigami.Theme.highlightColor
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: -clockFace.height * 0.05 // Little bit of overhang
                    anchors.horizontalCenter: parent.horizontalCenter
                    antialiasing: true
                     transform: Rotation {
                        id: secondHandRotation
                        origin.x: secondHand.width / 2
                        origin.y: secondHand.height - (clockFace.height * 0.05)
                    }
                }
            }

            // Central Cap (Over hands)
            Rectangle {
                anchors.centerIn: parent
                width: parent.width * 0.05
                height: width
                radius: width / 2
                color: Kirigami.Theme.highlightColor
                border.color: Kirigami.Theme.backgroundColor
                border.width: 2
            }
        }
    }
}
