
import QtQuick

Rectangle {
    id: button

    property string label: "Continue"
    property bool primary: false
    property bool hovered: false
    property bool pressed: false

    signal clicked()

    implicitWidth: 150
    implicitHeight: 43

    radius: 13

    color: primary
           ? (pressed ? "#526B9DDA" : hovered ? "#465C8CC7" : "#344D78A8")
           : (pressed ? "#30FFFFFF" : hovered ? "#24FFFFFF" : "#14FFFFFF")

    border.width: 1
    border.color: primary ? "#75B6E7FF" : "#48FFFFFF"

    Behavior on color {
        ColorAnimation { duration: 150 }
    }

    Behavior on border.color {
        ColorAnimation { duration: 150 }
    }

    Text {
        anchors.centerIn: parent

        text: button.label
        color: "#F4F7FF"

        font.pixelSize: 12
        font.weight: Font.DemiBold
        font.letterSpacing: 0.25
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onEntered: button.hovered = true

        onExited: {
            button.hovered = false
            button.pressed = false
        }

        onPressed: button.pressed = true

        onReleased: {
            button.pressed = false

            if (containsMouse)
                button.clicked()
        }
    }
}
