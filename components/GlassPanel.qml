import QtQuick
import QtQuick.Effects

Rectangle {
    id: panel

    property Item backdropSource: null
    property real glassTint: 0.10
    property real blurAmount: 0.68
    property real sheen: 1.0
    property bool showEdge: true

    radius: 20
    color: "transparent"
    border.width: 0
    clip: false

    // =====================================
    // COMPLETE GLASS MATERIAL
    // =====================================

    Item {
        id: material

        anchors.fill: parent
        visible: false

        // Background capture
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

        // Frosted background
        MultiEffect {
            anchors.fill: parent
            source: backdropTexture
            visible: panel.backdropSource !== null

            blurEnabled: true
            blur: panel.blurAmount
            blurMax: 40
        }

        // Glass tint
        Rectangle {
            anchors.fill: parent
            radius: panel.radius
            color: Qt.rgba(
                0.25, 0.37, 0.60,
                panel.glassTint
            )
        }

        // Main material gradient
        Rectangle {
            anchors.fill: parent
            radius: panel.radius
            opacity: panel.sheen

            gradient: Gradient {
                GradientStop { position: 0.0; color: "#20FFFFFF" }
                GradientStop { position: 0.20; color: "#12FFFFFF" }
                GradientStop { position: 0.48; color: "#04FFFFFF" }
                GradientStop { position: 0.78; color: "#0715223A" }
                GradientStop { position: 1.0; color: "#19101A32" }
            }
        }

        // Upper reflection
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top

            height: parent.height * 0.32
            radius: panel.radius
            opacity: panel.sheen

            gradient: Gradient {
                GradientStop { position: 0.0; color: "#27FFFFFF" }
                GradientStop { position: 0.35; color: "#14FFFFFF" }
                GradientStop { position: 1.0; color: "#00FFFFFF" }
            }
        }

        // Diagonal reflection
        Rectangle {
            width: parent.width * 1.25
            height: parent.height * 0.36

            x: -parent.width * 0.10
            y: -parent.height * 0.10

            rotation: -9
            opacity: panel.sheen * 0.52

            gradient: Gradient {
                GradientStop { position: 0.0; color: "#00FFFFFF" }
                GradientStop { position: 0.43; color: "#08FFFFFF" }
                GradientStop { position: 0.54; color: "#19FFFFFF" }
                GradientStop { position: 0.68; color: "#07FFFFFF" }
                GradientStop { position: 1.0; color: "#00FFFFFF" }
            }
        }

        // Lower reflection
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom

            height: parent.height * 0.34
            radius: panel.radius

            gradient: Gradient {
                GradientStop { position: 0.0; color: "#00FFFFFF" }
                GradientStop { position: 0.55; color: "#061B3150" }
                GradientStop { position: 1.0; color: "#17101B35" }
            }
        }
    }

    // =====================================
    // ROUNDED ALPHA MASK
    // =====================================

    Rectangle {
        id: roundedMask

        anchors.fill: parent
        radius: panel.radius

        color: "white"
        visible: false
    }

    // The complete material is clipped here.
    MultiEffect {
        anchors.fill: parent

        source: material
        maskEnabled: true
        maskSource: roundedMask

        maskThresholdMin: 0.5
        maskSpreadAtMin: 1.0
    }

    // =====================================
    // OPTICAL EDGES
    // =====================================

    Rectangle {
        anchors.fill: parent

        radius: panel.radius
        color: "transparent"

        border.width: panel.showEdge ? 1 : 0
        border.color: "#65FFFFFF"
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: 1

        radius: Math.max(0, panel.radius - 1)

        color: "transparent"
        border.width: panel.showEdge ? 1 : 0
        border.color: "#20FFFFFF"
    }

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