import QtQuick

GlassPanel {
    id: button

    property string label: "Continue"
    property bool primary: false
    property bool hovered: false
    property bool pressed: false

    signal clicked()

    implicitWidth: 150
    implicitHeight: 43

    radius: 13
    blurAmount: 0.58

    glassTint: primary ? 0.15
               : hovered ? 0.115
               : 0.075

    sheen: primary ? 1.0
           : hovered ? 0.92
           : 0.78

    showEdge: true

    opacity: enabled ? 1.0 : 0.48

    scale: pressed ? 0.985
         : hovered ? 1.012
         : 1.0

    Behavior on scale {
        NumberAnimation {
            duration: 150
            easing.type: Easing.OutCubic
        }
    }

    Behavior on glassTint {
        NumberAnimation {
            duration: 160
            easing.type: Easing.OutCubic
        }
    }

    Behavior on sheen {
        NumberAnimation {
            duration: 160
            easing.type: Easing.OutCubic
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: button.radius
        color: "transparent"
        border.width: button.primary ? 1 : 0
        border.color: assetBackend.themeColor("#9ADFFFFF", assetBackend.theme)
    }

    Text {
        anchors.centerIn: parent

        text: assetBackend.translateText(button.label, assetBackend.language)
        color: assetBackend.themeColor("#F5F8FF", assetBackend.theme)

        font.pixelSize: 14 * assetBackend.fontScale
        font.weight: Font.DemiBold
        font.letterSpacing: 0.1

        opacity: button.pressed ? 0.86 : 1.0

        Behavior on opacity {
            NumberAnimation {
                duration: 120
            }
        }
    }

    MouseArea {
        id: buttonMouse

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
        onReleased: button.pressed = false
        onCanceled: button.pressed = false

        onClicked: button.clicked()
    }
}