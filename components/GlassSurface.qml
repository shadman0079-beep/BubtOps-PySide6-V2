import QtQuick
import QtQuick.Window
import QtQuick.Effects

Item {
    id: surface

    property Item backdropSource: null
    property real radius: 22
    property color tintColor: Qt.rgba(0.28, 0.39, 0.62, 0.12)
    property bool elevated: true
    property bool showEdge: true
    property real sheen: 1.0

    function updateSlice() {
        if (!backdropSource || width <= 0 || height <= 0)
            return

        const p = surface.mapToItem(backdropSource, 0, 0)

        slice.sourceRect = Qt.rect(
            p.x, p.y, width, height
        )
    }

    onXChanged: settle.restart()
    onYChanged: settle.restart()
    onWidthChanged: settle.restart()
    onHeightChanged: settle.restart()
    onVisibleChanged: if (visible) settle.restart()
    onBackdropSourceChanged: settle.restart()

    Component.onCompleted: settle.restart()

    Timer {
        id: settle
        interval: 60
        onTriggered: surface.updateSlice()
    }

    Connections {
        target: surface.Window.window
        ignoreUnknownSignals: true

        function onWidthChanged() {
            settle.restart()
        }

        function onHeightChanged() {
            settle.restart()
        }
    }

    // Shadow
    Rectangle {
        id: shadowCaster

        anchors.fill: parent
        anchors.margins: 1

        radius: surface.radius
        color: "black"
        visible: false

        layer.enabled: surface.elevated
    }

    MultiEffect {
        anchors.fill: parent
        source: shadowCaster
        visible: surface.elevated

        shadowEnabled: true
        shadowColor: "#000000"
        shadowOpacity: 0.34
        shadowBlur: 1.0
        shadowVerticalOffset: 9
        shadowHorizontalOffset: 0
        shadowScale: 0.97
    }

    // Background capture
    ShaderEffectSource {
        id: slice

        anchors.fill: parent
        sourceItem: surface.backdropSource

        live: true
        hideSource: false
        smooth: true
        visible: false
    }

    // Rounded mask
    Item {
        id: roundMask

        anchors.fill: parent
        visible: false
        layer.enabled: true

        Rectangle {
            anchors.fill: parent
            radius: surface.radius
            color: "black"
        }
    }

    // Rounded backdrop
    MultiEffect {
       anchors.fill: parent
    source: slice

    visible: surface.backdropSource !== null

    maskEnabled: true
    maskSource: roundMask
    maskThresholdMin: 0.5
    maskSpreadAtMin: 1.0
    }

    // Glass tint
    Rectangle {
        anchors.fill: parent
        radius: surface.radius
        color: surface.tintColor
    }

    // Body sheen
    Rectangle {
        anchors.fill: parent
        radius: surface.radius
        opacity: surface.sheen

        gradient: Gradient {
            GradientStop { position: 0.00; color: "#22FFFFFF" }
            GradientStop { position: 0.25; color: "#0DFFFFFF" }
            GradientStop { position: 0.60; color: "#04FFFFFF" }
            GradientStop { position: 1.00; color: "#18101B33" }
        }
    }

    // Upper reflection
    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top

        height: parent.height * 0.30
        radius: surface.radius
        opacity: surface.sheen

        gradient: Gradient {
            GradientStop { position: 0.0; color: "#16FFFFFF" }
            GradientStop { position: 1.0; color: "#00FFFFFF" }
        }
    }

    // Diagonal reflection
    Rectangle {
        width: parent.width * 1.2
        height: parent.height * 0.28

        x: -parent.width * 0.08
        y: -parent.height * 0.06

        rotation: -8
        opacity: surface.sheen * 0.45

        gradient: Gradient {
            GradientStop { position: 0.0; color: "#00FFFFFF" }
            GradientStop { position: 0.48; color: "#12FFFFFF" }
            GradientStop { position: 0.58; color: "#08FFFFFF" }
            GradientStop { position: 1.0; color: "#00FFFFFF" }
        }
    }

    // Optical edge
    Item {
        anchors.fill: parent
        visible: surface.showEdge

        Rectangle {
            anchors.fill: parent
            radius: surface.radius

            color: "transparent"
            border.width: 1
            border.color: "#58FFFFFF"
        }

        Rectangle {
            anchors.fill: parent
            anchors.margins: 1

            radius: Math.max(0, surface.radius - 1)

            color: "transparent"
            border.width: 1
            border.color: "#20FFFFFF"
        }
    }
}