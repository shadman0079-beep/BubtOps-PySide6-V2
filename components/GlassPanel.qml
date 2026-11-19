
import QtQuick
import QtQuick.Effects

Rectangle {
    id: panel

    property Item backdropSource: null
    property real glassTint: 0.10
    property real blurAmount: 0.58
    property real sheen: 1.0
    property bool showEdge: true

    radius: 20
    color: "transparent"
    border.width: 0
    clip: false

    // =====================================
    // GLASS MATERIAL
    // =====================================

    Item {
        id: material

        anchors.fill: parent
        visible: false

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
                    p.x,
                    p.y,
                    panel.width,
                    panel.height
                )
            }
        }

        // Background blur
        MultiEffect {
            anchors.fill: parent

            source: backdropTexture
            visible: panel.backdropSource !== null

            blurEnabled: true
            blur: panel.blurAmount
            blurMax: 40
        }

        // Subtle cool glass tint
        Rectangle {
            anchors.fill: parent

            radius: panel.radius

            color: Qt.rgba(
                0.30,
                0.42,
                0.65,
                panel.glassTint
            )
        }

        // Main optical surface
        Rectangle {
            anchors.fill: parent

            radius: panel.radius
            opacity: panel.sheen

            gradient: Gradient {
                GradientStop {
                    position: 0.0
                    color: "#26FFFFFF"
                }

                GradientStop {
                    position: 0.24
                    color: "#15FFFFFF"
                }

                GradientStop {
                    position: 0.56
                    color: "#07FFFFFF"
                }

                GradientStop {
                    position: 0.82
                    color: "#0A17263D"
                }

                GradientStop {
                    position: 1.0
                    color: "#17101B35"
                }
            }
        }
    }

    // =====================================
    // COMPLETE ROUNDED MASK
    // =====================================

    Item {
        id: roundedMask

        anchors.fill: parent
        visible: false
        layer.enabled: true

        Rectangle {
            anchors.fill: parent

            radius: panel.radius
            color: "white"
        }
    }

    MultiEffect {
        anchors.fill: parent

        source: material

        maskEnabled: true
        maskSource: roundedMask

        maskThresholdMin: 0.5
        maskSpreadAtMin: 1.0
    }

    // =====================================
    // SINGLE OPTICAL EDGE
    // =====================================

    Rectangle {
        anchors.fill: parent

        radius: panel.radius

        color: "transparent"

        border.width: panel.showEdge ? 1 : 0
        border.color: "#65FFFFFF"
    }
}
