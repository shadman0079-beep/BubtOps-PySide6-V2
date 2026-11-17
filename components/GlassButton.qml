import QtQuick
import QtQuick.Effects

Rectangle {
    id: button

    property string label: "Continue"
    property bool primary: false
    property bool hovered: false
    property bool pressed: false
    property Item backdropSource: null

    signal clicked()

    implicitWidth: 150
    implicitHeight: 43

    radius: 13
    color: "transparent"
    clip: true

    opacity: enabled ? 1.0 : 0.48

    scale: pressed ? 0.985
         : hovered ? 1.012
         : 1.0

    border.width: 1
    border.color: primary
                  ? "#8ACFFFFF"
                  : hovered
                    ? "#78FFFFFF"
                    : "#43FFFFFF"

    Behavior on scale {
        NumberAnimation {
            duration: 150
            easing.type: Easing.OutCubic
        }
    }

    Behavior on border.color {
        ColorAnimation {
            duration: 160
        }
    }

    // Background capture
    ShaderEffectSource {
        id: backdropTexture

        anchors.fill: parent
        sourceItem: button.backdropSource

        live: true
        hideSource: false
        smooth: true

        sourceRect: {
            if (!button.backdropSource)
                return Qt.rect(0, 0, 0, 0)

            const p = button.mapToItem(
                button.backdropSource, 0, 0
            )

            return Qt.rect(
                p.x, p.y,
                button.width, button.height
            )
        }
    }

    // Glass blur
    MultiEffect {
        anchors.fill: parent
        source: backdropTexture
        visible: button.backdropSource !== null

        blurEnabled: true
        blur: 0.68
        blurMax: 30
    }

    // Translucent button material
    Rectangle {
        anchors.fill: parent
        radius: button.radius

        gradient: Gradient {
            GradientStop {
                position: 0.0
                color: button.primary
                       ? "#506F9DBE"
                       : "#28D7EDFA"
            }
            GradientStop {
                position: 0.48
                color: button.primary
                       ? "#3A577FA9"
                       : "#19A9D9EA"
            }
            GradientStop {
                position: 1.0
                color: button.primary
                       ? "#40516F9A"
                       : "#187B9BBF"
            }
        }

        opacity: button.pressed ? 0.92
               : button.hovered ? 0.88
               : 0.72

        Behavior on opacity {
            NumberAnimation { duration: 160 }
        }
    }

    // Body reflection
    Rectangle {
        anchors.fill: parent
        radius: button.radius

        gradient: Gradient {
            GradientStop {
                position: 0.0
                color: button.hovered
                       ? "#35FFFFFF"
                       : "#25FFFFFF"
            }
            GradientStop {
                position: 0.30
                color: "#11FFFFFF"
            }
            GradientStop {
                position: 0.68
                color: "#03FFFFFF"
            }
            GradientStop {
                position: 1.0
                color: "#14142643"
            }
        }
    }

    // Diagonal optical highlight
    Rectangle {
        width: parent.width * 1.3
        height: parent.height * 0.45

        x: -parent.width * 0.14
        y: -parent.height * 0.13

        rotation: -10
        opacity: button.hovered ? 0.85 : 0.48

        gradient: Gradient {
            GradientStop {
                position: 0.0
                color: "#00FFFFFF"
            }
            GradientStop {
                position: 0.5
                color: "#20FFFFFF"
            }
            GradientStop {
                position: 1.0
                color: "#00FFFFFF"
            }
        }

        Behavior on opacity {
            NumberAnimation { duration: 170 }
        }
    }

    // Top edge reflection
    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top

        anchors.leftMargin: 11
        anchors.rightMargin: 11

        height: 1
        color: "#AFFFFFFF"
        opacity: button.hovered ? 0.75 : 0.42
    }

    // Inner optical edge
    Rectangle {
        anchors.fill: parent
        anchors.margins: 1

        radius: Math.max(0, button.radius - 1)

        color: "transparent"
        border.width: 1
        border.color: "#22FFFFFF"
    }

    // Label
    Text {
        anchors.centerIn: parent

        text: button.label
        color: "#F5F8FF"

        font.pixelSize: 12
        font.weight: Font.DemiBold
        font.letterSpacing: 0.25

        opacity: button.pressed ? 0.84 : 1.0

        Behavior on opacity {
            NumberAnimation { duration: 120 }
        }
    }

    // Interaction
    MouseArea {
        anchors.fill: parent
        enabled: button.enabled

        hoverEnabled: true
        cursorShape: button.enabled
                     ? Qt.PointingHandCursor
                     : Qt.ArrowCursor

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

        onCanceled: button.pressed = false
    }
}