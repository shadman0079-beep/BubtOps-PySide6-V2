import QtQuick
import QtQuick.Controls

TextField {
    id: control

    color: "#EDF4FF"
    placeholderTextColor: "#7186A6"
    selectionColor: "#6683CFFF"
    selectedTextColor: "#FFFFFF"
    font.pixelSize: 12

    leftPadding: 12
    rightPadding: 12
    implicitHeight: 38

    background: Rectangle {
        radius: 10
        color: control.activeFocus ? "#24FFFFFF" : "#14FFFFFF"
        border.width: 1
        border.color: control.activeFocus ? "#99BDEBFF" : "#30FFFFFF"

        Behavior on color {
            ColorAnimation { duration: 140 }
        }

        Behavior on border.color {
            ColorAnimation { duration: 140 }
        }

        // top inner light
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 1
            height: parent.height * 0.45
            radius: 9
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#12FFFFFF" }
                GradientStop { position: 1.0; color: "#00FFFFFF" }
            }
        }
    }
}
