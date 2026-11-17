
import QtQuick
import QtQuick.Effects

Item {
    id: aurora

    clip: true

    // =========================================
    // MIDNIGHT PASTEL AURORA BASE
    // =========================================

    Rectangle {
        anchors.fill: parent

        gradient: Gradient {
            GradientStop { position: 0.0; color: "#10131F" }
            GradientStop { position: 0.48; color: "#202033" }
            GradientStop { position: 1.0; color: "#10131C" }
        }
    }

    // =========================================
    // SOFT AMBIENT LIGHT
    // =========================================

    Rectangle {
        width: aurora.width * 0.75
        height: aurora.height * 0.75

        x: -width * 0.28
        y: -height * 0.20

        radius: width * 0.5
        opacity: 0.32

        gradient: Gradient {
            GradientStop { position: 0.0; color: "#668DBD" }
            GradientStop { position: 0.55; color: "#394C78" }
            GradientStop { position: 1.0; color: "#00394C78" }
        }
    }

    Rectangle {
        width: aurora.width * 0.85
        height: aurora.height * 0.70

        x: aurora.width * 0.50
        y: aurora.height * 0.35

        radius: width * 0.5
        opacity: 0.25

        gradient: Gradient {
            GradientStop { position: 0.0; color: "#B58CA8" }
            GradientStop { position: 0.55; color: "#66506F" }
            GradientStop { position: 1.0; color: "#0066506F" }
        }
    }

    // =========================================
    // LARGE FROSTED GLASS SURFACE
    // =========================================

    Item {
        id: upperGlass

        width: aurora.width * 1.25
        height: aurora.height * 0.85

        x: -aurora.width * 0.12
        y: -aurora.height * 0.30

        rotation: -12

        Rectangle {
            anchors.fill: parent
            radius: height * 0.48
            opacity: 0.48

            gradient: Gradient {
                GradientStop { position: 0.0; color: "#829DBF" }
                GradientStop { position: 0.28; color: "#647FAD" }
                GradientStop { position: 0.65; color: "#455C85" }
                GradientStop { position: 1.0; color: "#25364F" }
            }
        }

        Rectangle {
            anchors.fill: parent
            anchors.margins: parent.height * 0.10
            radius: height * 0.48
            opacity: 0.22

            gradient: Gradient {
                GradientStop { position: 0.0; color: "#D3E1EF" }
                GradientStop { position: 0.45; color: "#9AB6D1" }
                GradientStop { position: 1.0; color: "#354B6C" }
            }
        }

        SequentialAnimation on y {
            running: true
            loops: Animation.Infinite

            NumberAnimation {
                to: -aurora.height * 0.24
                duration: 8500
                easing.type: Easing.InOutSine
            }

            NumberAnimation {
                to: -aurora.height * 0.34
                duration: 8500
                easing.type: Easing.InOutSine
            }
        }

        SequentialAnimation on rotation {
            running: true
            loops: Animation.Infinite

            NumberAnimation {
                to: -9
                duration: 10000
                easing.type: Easing.InOutSine
            }

            NumberAnimation {
                to: -14
                duration: 10000
                easing.type: Easing.InOutSine
            }
        }
    }

    // =========================================
    // CENTRAL FLOWING GLASS FORM
    // =========================================

    Item {
        id: centralGlass

        width: aurora.width * 1.35
        height: aurora.height * 0.78

        x: -aurora.width * 0.16
        y: aurora.height * 0.18

        rotation: 8

        Rectangle {
            anchors.fill: parent
            radius: height * 0.48
            opacity: 0.58

            gradient: Gradient {
                GradientStop { position: 0.0; color: "#485A85" }
                GradientStop { position: 0.30; color: "#9A9ABF" }
                GradientStop { position: 0.58; color: "#9B819F" }
                GradientStop { position: 1.0; color: "#3F405F" }
            }
        }

        Rectangle {
            width: parent.width * 0.88
            height: parent.height * 0.70

            x: parent.width * 0.06
            y: parent.height * 0.13

            radius: height * 0.48
            opacity: 0.28

            gradient: Gradient {
                GradientStop { position: 0.0; color: "#E4D8EA" }
                GradientStop { position: 0.35; color: "#B5B5D9" }
                GradientStop { position: 1.0; color: "#465875" }
            }
        }

        SequentialAnimation on y {
            running: true
            loops: Animation.Infinite

            NumberAnimation {
                to: aurora.height * 0.12
                duration: 11000
                easing.type: Easing.InOutSine
            }

            NumberAnimation {
                to: aurora.height * 0.23
                duration: 11000
                easing.type: Easing.InOutSine
            }
        }

        SequentialAnimation on rotation {
            running: true
            loops: Animation.Infinite

            NumberAnimation {
                to: 11
                duration: 12000
                easing.type: Easing.InOutSine
            }

            NumberAnimation {
                to: 5
                duration: 12000
                easing.type: Easing.InOutSine
            }
        }
    }

    // =========================================
    // LOWER PEARL GLASS SURFACE
    // =========================================

    Item {
        id: lowerGlass

        width: aurora.width * 1.20
        height: aurora.height * 0.70

        x: aurora.width * 0.12
        y: aurora.height * 0.55

        rotation: -14

        Rectangle {
            anchors.fill: parent
            radius: height * 0.48
            opacity: 0.42

            gradient: Gradient {
                GradientStop { position: 0.0; color: "#D4C7D1" }
                GradientStop { position: 0.25; color: "#B2A8C1" }
                GradientStop { position: 0.62; color: "#78849F" }
                GradientStop { position: 1.0; color: "#303D56" }
            }
        }

        Rectangle {
            anchors.fill: parent
            anchors.margins: parent.height * 0.12
            radius: height * 0.48
            opacity: 0.20

            gradient: Gradient {
                GradientStop { position: 0.0; color: "#F0E5DD" }
                GradientStop { position: 0.35; color: "#D4C5D7" }
                GradientStop { position: 1.0; color: "#56647D" }
            }
        }

        SequentialAnimation on y {
            running: true
            loops: Animation.Infinite

            NumberAnimation {
                to: aurora.height * 0.50
                duration: 9500
                easing.type: Easing.InOutSine
            }

            NumberAnimation {
                to: aurora.height * 0.61
                duration: 9500
                easing.type: Easing.InOutSine
            }
        }

        SequentialAnimation on rotation {
            running: true
            loops: Animation.Infinite

            NumberAnimation {
                to: -10
                duration: 13000
                easing.type: Easing.InOutSine
            }

            NumberAnimation {
                to: -17
                duration: 13000
                easing.type: Easing.InOutSine
            }
        }
    }

    // =========================================
    // SOFT ATMOSPHERIC LIGHT
    // =========================================

    Rectangle {
        width: aurora.width * 0.70
        height: aurora.height * 0.38

        x: aurora.width * 0.12
        y: aurora.height * 0.28

        radius: width * 0.5
        opacity: 0.14

        gradient: Gradient {
            GradientStop { position: 0.0; color: "#F0D8DF" }
            GradientStop { position: 0.45; color: "#B9B6E0" }
            GradientStop { position: 1.0; color: "#00B9B6E0" }
        }

        SequentialAnimation on x {
            running: true
            loops: Animation.Infinite

            NumberAnimation {
                to: aurora.width * 0.20
                duration: 14000
                easing.type: Easing.InOutSine
            }

            NumberAnimation {
                to: aurora.width * 0.08
                duration: 14000
                easing.type: Easing.InOutSine
            }
        }
    }

    // =========================================
    // SUBTLE CYAN AND WARM PEARL ACCENTS
    // =========================================

    Rectangle {
        width: aurora.width * 0.55
        height: aurora.height * 0.30

        x: aurora.width * 0.48
        y: aurora.height * 0.08

        radius: width * 0.5
        opacity: 0.10

        gradient: Gradient {
            GradientStop { position: 0.0; color: "#A4E2E6" }
            GradientStop { position: 0.50; color: "#7DBBCF" }
            GradientStop { position: 1.0; color: "#007DBBCF" }
        }
    }

    Rectangle {
        width: aurora.width * 0.42
        height: aurora.height * 0.24

        x: aurora.width * 0.45
        y: aurora.height * 0.63

        radius: width * 0.5
        opacity: 0.09

        gradient: Gradient {
            GradientStop { position: 0.0; color: "#F0C9A8" }
            GradientStop { position: 0.55; color: "#D9B9B2" }
            GradientStop { position: 1.0; color: "#00D9B9B2" }
        }
    }

    // =========================================
    // DARK EDGE DEPTH
    // =========================================

    Rectangle {
        anchors.fill: parent

        gradient: Gradient {
            GradientStop { position: 0.0; color: "#00101825" }
            GradientStop { position: 0.55; color: "#00101825" }
            GradientStop { position: 1.0; color: "#9A080F19" }
        }
    }
}
