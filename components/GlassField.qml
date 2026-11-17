import QtQuick
import QtQuick.Controls

TextField {
    id: control

    color: "#EDF4FF"
    placeholderTextColor: "#8295B2"

    selectionColor: "#6683CFFF"
    selectedTextColor: "#FFFFFF"

    font.pixelSize: 12

    leftPadding: 12
    rightPadding: 12

    implicitHeight: 39

    background: Rectangle {
        radius: 10

        color: control.activeFocus
               ? "#27FFFFFF"
               : "#14FFFFFF"

        border.width: 1

        border.color: control.activeFocus
                      ? "#9ACFFFFF"
                      : "#38FFFFFF"

        Behavior on color {
            ColorAnimation { duration: 150 }
        }

        Behavior on border.color {
            ColorAnimation { duration: 150 }
        }

        // Top inner reflection
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top

            anchors.margins: 1

            height: parent.height * 0.42
            radius: 9

            gradient: Gradient {
                GradientStop {
                    position: 0.0
                    color: "#17FFFFFF"
                }

                GradientStop {
                    position: 1.0
                    color: "#00FFFFFF"
                }
            }
        }

        // Focus highlight
        Rectangle {
            anchors.fill: parent

            radius: 10
            color: "transparent"

            border.width: 1
            border.color: control.activeFocus
                          ? "#35BDEBFF"
                          : "transparent"
        }
    }
}