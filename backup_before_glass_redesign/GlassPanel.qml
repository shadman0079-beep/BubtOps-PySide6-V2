
import QtQuick
import QtQuick.Effects

Rectangle {
    id: panel

    property Item backdropSource
    property real glassTint: 0.10

    radius: 22
    color: "transparent"
    border.width: 1
    border.color: "#42FFFFFF"
    clip: true

    ShaderEffectSource {
        id: backdropTexture

        anchors.fill: parent
        sourceItem: panel.backdropSource
        live: true
        hideSource: false
        smooth: true

        sourceRect: {
            if (!panel.backdropSource)
                return Qt.rect(0, 0, 0, 0)

            const p = panel.mapToItem(
                panel.backdropSource, 0, 0
            )

            return Qt.rect(
                p.x, p.y,
                panel.width, panel.height
            )
        }
    }

    MultiEffect {
        anchors.fill: parent
        source: backdropTexture

        blurEnabled: true
        blur: 0.75
        blurMax: 32
    }

    Rectangle {
        anchors.fill: parent
        radius: parent.radius

        gradient: Gradient {
            GradientStop {
                position: 0.0
                color: Qt.rgba(0.82, 0.91, 1.0, panel.glassTint + 0.035)
            }

            GradientStop {
                position: 0.48
                color: Qt.rgba(0.48, 0.62, 0.88, panel.glassTint)
            }

            GradientStop {
                position: 1.0
                color: Qt.rgba(0.30, 0.40, 0.68, panel.glassTint + 0.035)
            }
        }
    }

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 2

        height: 1
        radius: 1
        color: "#8FFFFFFF"
        opacity: 0.55
    }
}
