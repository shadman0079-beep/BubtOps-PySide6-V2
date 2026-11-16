
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

    radius: 14
    color: "transparent"

    border.width: 1

    border.color: button.primary
                  ? "#55BDEAFF"
                  : "#32FFFFFF"

    clip: true

    scale: button.pressed ? 0.985
         : button.hovered ? 1.012
         : 1.0

    Behavior on scale {
        NumberAnimation {
            duration: 150
            easing.type: Easing.OutCubic
        }
    }

    // =========================================
    // BACKGROUND CAPTURE
    // =========================================

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

            const position = button.mapToItem(
                button.backdropSource, 0, 0
            )

            return Qt.rect(
                position.x,
                position.y,
                button.width,
                button.height
            )
        }
    }

    // =========================================
    // GLASS BLUR
    // =========================================

    MultiEffect {
        anchors.fill: parent
        source: backdropTexture

        blurEnabled: true
        blur: 0.65
        blurMax: 28
    }

    // =========================================
    // TRANSLUCENT GLASS BASE
    // =========================================

    Rectangle {
        anchors.fill: parent
        radius: button.radius

        gradient: Gradient {
            GradientStop {
                position: 0.0

                color: button.primary
                       ? "#506D9DBD"
                       : "#35C8E5F5"
            }

            GradientStop {
                position: 0.48

                color: button.primary
                       ? "#3B547EAA"
                       : "#22A9D9E9"
            }

            GradientStop {
                position: 1.0

                color: button.primary
                       ? "#40516E99"
                       : "#187B9BBF"
            }
        }

        opacity: button.pressed ? 0.95
               : button.hovered ? 0.92
               : 0.78

        Behavior on opacity {
            NumberAnimation {
                duration: 160
            }
        }
    }

    // =========================================
    // SOFT GLOSSY REFLECTION
    // =========================================

    Rectangle {
        anchors.fill: parent
        radius: button.radius

        gradient: Gradient {
            GradientStop {
                position: 0.0
                color: button.hovered
                       ? "#30FFFFFF"
                       : "#20FFFFFF"
            }

            GradientStop {
                position: 0.30
                color: "#0BFFFFFF"
            }

            GradientStop {
                position: 0.70
                color: "#02FFFFFF"
            }

            GradientStop {
                position: 1.0
                color: "#0A152C45"
            }
        }
    }

    // =========================================
    // SUBTLE TOP GLASS LIGHT
    // =========================================

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top

        height: parent.height * 0.32

        radius: button.radius

        gradient: Gradient {
            GradientStop {
                position: 0.0
                color: button.hovered
                       ? "#20FFFFFF"
                       : "#12FFFFFF"
            }

            GradientStop {
                position: 1.0
                color: "#00FFFFFF"
            }
        }
    }

    // =========================================
    // BUTTON LABEL
    // =========================================

    Text {
        anchors.centerIn: parent

        text: button.label

        color: "#F5F8FF"

        font.pixelSize: 12
        font.weight: Font.DemiBold
        font.letterSpacing: 0.25

        opacity: button.pressed ? 0.85 : 1.0

        Behavior on opacity {
            NumberAnimation {
                duration: 120
            }
        }
    }

    // =========================================
    // INTERACTION
    // =========================================

    MouseArea {
        anchors.fill: parent

        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onEntered: button.hovered = true

        onExited: {
            button.hovered = false
            button.pressed = false
        }

        onPressed: {
            button.pressed = true
        }

        onReleased: {
            button.pressed = false

            if (containsMouse)
                button.clicked()
        }

        onCanceled: {
            button.pressed = false
        }
    }
}
