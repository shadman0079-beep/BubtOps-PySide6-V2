
import QtQuick
import QtQuick.Effects

Rectangle {
    id: panel

    property Item backdropSource: null
    property real glassTint: 0.12

    radius: 22
    color: "transparent"

    border.width: 1
    border.color: "#26FFFFFF"

    clip: true

    // =========================================
    // BACKGROUND CAPTURE
    // =========================================

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

            const position = panel.mapToItem(
                panel.backdropSource, 0, 0
            )

            return Qt.rect(
                position.x,
                position.y,
                panel.width,
                panel.height
            )
        }
    }

    // =========================================
    // FROSTED GLASS BLUR
    // =========================================

    MultiEffect {
        anchors.fill: parent
        source: backdropTexture

        blurEnabled: true
        blur: 0.78
        blurMax: 48
    }

    // =========================================
    // TRANSLUCENT GLASS BASE
    // =========================================

    Rectangle {
        anchors.fill: parent
        radius: panel.radius

        color: Qt.rgba(
            0.28,
            0.39,
            0.62,
            panel.glassTint
        )
    }

    // =========================================
    // SOFT GLASS REFLECTION
    // =========================================

    Rectangle {
        anchors.fill: parent
        radius: panel.radius

        gradient: Gradient {
            GradientStop {
                position: 0.0
                color: "#17FFFFFF"
            }

            GradientStop {
                position: 0.22
                color: "#0BFFFFFF"
            }

            GradientStop {
                position: 0.55
                color: "#03FFFFFF"
            }

            GradientStop {
                position: 1.0
                color: "#0C172B45"
            }
        }
    }

    // =========================================
    // BROAD UPPER LIGHT REFLECTION
    // =========================================

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top

        height: parent.height * 0.24

        radius: panel.radius

        gradient: Gradient {
            GradientStop {
                position: 0.0
                color: "#0DFFFFFF"
            }

            GradientStop {
                position: 0.55
                color: "#05FFFFFF"
            }

            GradientStop {
                position: 1.0
                color: "#00FFFFFF"
            }
        }
    }

    // No additional inner border.
    // The main Rectangle border provides the glass edge.
}
