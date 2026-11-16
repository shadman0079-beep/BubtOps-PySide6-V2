 
import QtQuick
import QtQuick.Effects

Rectangle {
    id: panel

    property Item backdropSource: null
    property real glassTint: 0.12
    property real blurAmount: 0.68
    property real sheen: 1.0
    property bool showEdge: true

    radius: 22
    color: "transparent"
    border.width: 1
    border.color: panel.showEdge ? "#65FFFFFF" : "transparent"

    clip: true

    // =========================================
    // 01. LIVE BACKGROUND CAPTURE
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
    // 02. FROSTED BACKGROUND
    // =========================================

    MultiEffect {
        anchors.fill: parent
        source: backdropTexture

        visible: panel.backdropSource !== null

        blurEnabled: true
        blur: panel.blurAmount
        blurMax: 40
    }

    // =========================================
    // 03. TRANSLUCENT GLASS BASE
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
    // 04. DEPTH AND LIGHT GRADIENT
    // =========================================

    Rectangle {
        anchors.fill: parent
        radius: panel.radius
        opacity: panel.sheen

        gradient: Gradient {
            GradientStop {
                position: 0.0
                color: "#20FFFFFF"
            }

            GradientStop {
                position: 0.18
                color: "#12FFFFFF"
            }

            GradientStop {
                position: 0.48
                color: "#05FFFFFF"
            }

            GradientStop {
                position: 0.76
                color: "#0715223A"
            }

            GradientStop {
                position: 1.0
                color: "#19101A32"
            }
        }
    }

    // =========================================
    // 05. BROAD UPPER REFLECTION
    // =========================================

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top

        height: parent.height * 0.32
        radius: panel.radius
        opacity: panel.sheen

        gradient: Gradient {
            GradientStop {
                position: 0.0
                color: "#27FFFFFF"
            }

            GradientStop {
                position: 0.30
                color: "#14FFFFFF"
            }

            GradientStop {
                position: 0.72
                color: "#05FFFFFF"
            }

            GradientStop {
                position: 1.0
                color: "#00FFFFFF"
            }
        }
    }

    // =========================================
    // 06. DIAGONAL OPTICAL REFLECTION
    // =========================================

    Rectangle {
        width: parent.width * 1.25
        height: parent.height * 0.36

        x: -parent.width * 0.10
        y: -parent.height * 0.10

        rotation: -9
        opacity: panel.sheen * 0.62

        gradient: Gradient {
            GradientStop {
                position: 0.0
                color: "#00FFFFFF"
            }

            GradientStop {
                position: 0.40
                color: "#08FFFFFF"
            }

            GradientStop {
                position: 0.53
                color: "#1BFFFFFF"
            }

            GradientStop {
                position: 0.68
                color: "#08FFFFFF"
            }

            GradientStop {
                position: 1.0
                color: "#00FFFFFF"
            }
        }
    }

    // =========================================
    // 07. LOWER BOUNCE REFLECTION
    // =========================================

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom

        height: parent.height * 0.35
        radius: panel.radius

        gradient: Gradient {
            GradientStop {
                position: 0.0
                color: "#00FFFFFF"
            }

            GradientStop {
                position: 0.55
                color: "#061B3150"
            }

            GradientStop {
                position: 1.0
                color: "#17101B35"
            }
        }
    }

    // =========================================
    // 08. CRYSTAL OUTER EDGE
    // =========================================

    Rectangle {
        anchors.fill: parent

        radius: panel.radius
        color: "transparent"

        border.width: 1
        border.color: panel.showEdge
                     ? "#58FFFFFF"
                     : "transparent"
    }

    // =========================================
    // 09. INNER GLASS RIM
    // =========================================

    Rectangle {
        anchors.fill: parent
        anchors.margins: 1

        radius: Math.max(0, panel.radius - 1)

        color: "transparent"
        border.width: 1
        border.color: "#20FFFFFF"
    }

    // =========================================
    // 10. UPPER EDGE LIGHT
    // =========================================

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top

        anchors.leftMargin: panel.radius * 0.8
        anchors.rightMargin: panel.radius * 0.8

        height: 1
        color: "#A8FFFFFF"
        opacity: 0.42 * panel.sheen
    }
}
