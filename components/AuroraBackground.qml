import QtQuick
import QtQuick.Effects

Item {
    id: root
    clip: true

    // =========================================
    // 1. DEEP MIDNIGHT VOID BASE
    // =========================================
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.00; color: assetBackend.themeColor("#050811", assetBackend.theme) }
            GradientStop { position: 0.50; color: assetBackend.themeColor("#0B101D", assetBackend.theme) }
            GradientStop { position: 1.00; color: assetBackend.themeColor("#03050A", assetBackend.theme) }
        }
    }

    // =========================================
    // 2. BACKGROUND AMBIENT NEON GLOWS (Fluid Depth)
    // =========================================
    Item {
        id: glowLayer
        anchors.fill: parent

        // Electric Cyan Upper Glow
        Rectangle {
            width: root.width * 0.9
            height: width
            x: -width * 0.2
            y: -height * 0.3
            radius: width * 0.5
            color: assetBackend.themeColor("#00E5FF", assetBackend.theme)
            opacity: 0.25

            SequentialAnimation on scale {
                running: true
                loops: Animation.Infinite
                NumberAnimation { to: 1.15; duration: 8000; easing.type: Easing.InOutSine }
                NumberAnimation { to: 0.90; duration: 8000; easing.type: Easing.InOutSine }
            }
        }

        // Iridescent Magenta/Purple Core Glow
        Rectangle {
            width: root.width * 0.8
            height: width
            x: root.width * 0.3
            y: root.height * 0.2
            radius: width * 0.5
            color: assetBackend.themeColor("#9933FF", assetBackend.theme)
            opacity: 0.22

            SequentialAnimation on x {
                running: true
                loops: Animation.Infinite
                NumberAnimation { to: root.width * 0.2; duration: 11000; easing.type: Easing.InOutSine }
                NumberAnimation { to: root.width * 0.4; duration: 11000; easing.type: Easing.InOutSine }
            }
        }
    }

    MultiEffect {
        source: glowLayer
        anchors.fill: glowLayer
        blurEnabled: true
        blurMax: 64
        blur: 1.0
    }

    // =========================================
    // 3. FLUID HOLOGRAPHIC WAVE RIBBONS (3D Layered Flow)
    // =========================================

    // --- STREAM LAYER A: Deep Violet/Indigo Under-Wave ---
    Item {
        id: waveLayer1
        width: root.width * 1.50
        height: root.height * 0.70
        x: -root.width * 0.25
        y: root.height * 0.15
        rotation: -18

        Rectangle {
            anchors.fill: parent
            radius: height * 0.48
            opacity: 0.65
            border.width: 1
            border.color: assetBackend.themeColor("#339933FF", assetBackend.theme)

            gradient: Gradient {
                GradientStop { position: 0.00; color: assetBackend.themeColor("#2B1A4A", assetBackend.theme) }
                GradientStop { position: 0.35; color: assetBackend.themeColor("#5C2375", assetBackend.theme) }
                GradientStop { position: 0.70; color: assetBackend.themeColor("#1E1A34", assetBackend.theme) }
                GradientStop { position: 1.00; color: assetBackend.themeColor("#0B0913", assetBackend.theme) }
            }
        }

        SequentialAnimation on y {
            running: true
            loops: Animation.Infinite
            NumberAnimation { to: root.height * 0.08; duration: 9000; easing.type: Easing.InOutSine }
            NumberAnimation { to: root.height * 0.22; duration: 9000; easing.type: Easing.InOutSine }
        }
        SequentialAnimation on rotation {
            running: true
            loops: Animation.Infinite
            NumberAnimation { to: -14; duration: 12000; easing.type: Easing.InOutSine }
            NumberAnimation { to: -22; duration: 12000; easing.type: Easing.InOutSine }
        }
    }

    // --- STREAM LAYER B: Electric Cyan & Holographic Rainbow Mid-Wave ---
    Item {
        id: waveLayer2
        width: root.width * 1.60
        height: root.height * 0.65
        x: -root.width * 0.20
        y: root.height * 0.05
        rotation: -12

        // Main body with high-contrast metallic neon stops
        Rectangle {
            anchors.fill: parent
            radius: height * 0.5
            opacity: 0.85
            border.width: 1.5
            border.color: assetBackend.themeColor("#88CCFFFF", assetBackend.theme) // Sharp specular top edge

            gradient: Gradient {
                GradientStop { position: 0.00; color: assetBackend.themeColor("#00F0FF", assetBackend.theme) } // Electric Cyan Peak
                GradientStop { position: 0.22; color: assetBackend.themeColor("#00A8CC", assetBackend.theme) }
                GradientStop { position: 0.48; color: assetBackend.themeColor("#B833FF", assetBackend.theme) } // Vivid Neon Purple
                GradientStop { position: 0.75; color: assetBackend.themeColor("#FF3399", assetBackend.theme) } // Hot Pink Highlight
                GradientStop { position: 1.00; color: assetBackend.themeColor("#120B24", assetBackend.theme) }
            }
        }

        // Internal caustic light ribbon
        Rectangle {
            width: parent.width * 0.85
            height: parent.height * 0.45
            anchors.centerIn: parent
            radius: height * 0.5
            opacity: 0.40

            gradient: Gradient {
                GradientStop { position: 0.0; color: assetBackend.themeColor("#FFFFFF", assetBackend.theme) }
                GradientStop { position: 0.4; color: assetBackend.themeColor("#00FFFF", assetBackend.theme) }
                GradientStop { position: 0.8; color: assetBackend.themeColor("#FF00AA", assetBackend.theme) }
                GradientStop { position: 1.0; color: assetBackend.themeColor("#00000000", assetBackend.theme) }
            }
        }

        // Razor-sharp specular light streak across the crest
        Rectangle {
            width: parent.width * 0.70
            height: 2
            x: parent.width * 0.15
            y: parent.height * 0.25
            opacity: 0.80
            radius: 1

            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: assetBackend.themeColor("#00FFFFFF", assetBackend.theme) }
                GradientStop { position: 0.3; color: assetBackend.themeColor("#FFFFFFFF", assetBackend.theme) }
                GradientStop { position: 0.7; color: assetBackend.themeColor("#88E0FFFF", assetBackend.theme) }
                GradientStop { position: 1.0; color: assetBackend.themeColor("#00FFFFFF", assetBackend.theme) }
            }
        }

        SequentialAnimation on y {
            running: true
            loops: Animation.Infinite
            NumberAnimation { to: root.height * 0.00; duration: 7500; easing.type: Easing.InOutSine }
            NumberAnimation { to: root.height * 0.12; duration: 7500; easing.type: Easing.InOutSine }
        }
        SequentialAnimation on rotation {
            running: true
            loops: Animation.Infinite
            NumberAnimation { to: -8;  duration: 10000; easing.type: Easing.InOutSine }
            NumberAnimation { to: -16; duration: 10000; easing.type: Easing.InOutSine }
        }
    }

    // --- STREAM LAYER C: Foreground Cyan & Silver Ribbon (Crisp Edge) ---
    Item {
        id: waveLayer3
        width: root.width * 1.40
        height: root.height * 0.55
        x: -root.width * 0.10
        y: root.height * 0.25
        rotation: -6

        Rectangle {
            anchors.fill: parent
            radius: height * 0.5
            opacity: 0.50
            border.width: 1
            border.color: assetBackend.themeColor("#FFAAFF", assetBackend.theme) // Fixed typo here (was #FFAAFFA)

            gradient: Gradient {
                GradientStop { position: 0.00; color: assetBackend.themeColor("#80FFFF", assetBackend.theme) }
                GradientStop { position: 0.30; color: assetBackend.themeColor("#336699", assetBackend.theme) }
                GradientStop { position: 0.70; color: assetBackend.themeColor("#24103B", assetBackend.theme) }
                GradientStop { position: 1.00; color: assetBackend.themeColor("#05030A", assetBackend.theme) }
            }
        }

        SequentialAnimation on y {
            running: true
            loops: Animation.Infinite
            NumberAnimation { to: root.height * 0.20; duration: 8500; easing.type: Easing.InOutSine }
            NumberAnimation { to: root.height * 0.30; duration: 8500; easing.type: Easing.InOutSine }
        }
    }

    // =========================================
    // 4. FLOATING HOLOGRAPHIC DUST / SPARKS
    // =========================================
    Repeater {
        model: 18
        Rectangle {
            id: spark
            property real seedX: (index * 53) % 100 / 100.0
            property real seedY: (index * 37) % 100 / 100.0
            property real size: (index % 3) + 1.0

            width: size
            height: size
            radius: width * 0.5
            color: index % 2 === 0 ? "#00FFFF" : "#FF66CC"
            opacity: 0.3 + (index % 3) * 0.2
            x: root.width * seedX
            y: root.height * seedY

            SequentialAnimation on y {
                running: true
                loops: Animation.Infinite
                NumberAnimation {
                    to: spark.y - (40 + (index * 7))
                    duration: 6000 + (index * 800)
                    easing.type: Easing.InOutSine
                }
                NumberAnimation {
                    to: spark.y
                    duration: 6000 + (index * 800)
                    easing.type: Easing.InOutSine
                }
            }
        }
    }

    // =========================================
    // 5. CINEMATIC VIGNETTE & CONTRAST FRAME
    // =========================================
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.00; color: assetBackend.themeColor("#77020512", assetBackend.theme) }
            GradientStop { position: 0.35; color: assetBackend.themeColor("#00000000", assetBackend.theme) }
            GradientStop { position: 0.75; color: assetBackend.themeColor("#00000000", assetBackend.theme) }
            GradientStop { position: 1.00; color: assetBackend.themeColor("#EE010309", assetBackend.theme) }
        }
    }
}