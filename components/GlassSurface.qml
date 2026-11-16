import QtQuick
import QtQuick.Window
import QtQuick.Effects

// Shared glass material: rounded blurred backdrop slice, tint, sheen,
// gradient edge and soft shadow. backdropSource must be the ONE
// pre-blurred background layer (backgroundScene in Main.qml).

Item {
    id: surface

    property Item backdropSource: null
    property real radius: 22
    property color tintColor: Qt.rgba(0.28, 0.39, 0.62, 0.12)
    property bool elevated: true
    property bool showEdge: true
    property real sheen: 1.0

    // ---------- keep the sampled slice aligned with the backdrop ----------

    function updateSlice() {
        if (!backdropSource || width <= 0 || height <= 0)
            return
        const p = surface.mapToItem(backdropSource, 0, 0)
        slice.sourceRect = Qt.rect(p.x, p.y, width, height)
    }

    onWidthChanged: updateSlice()
    onHeightChanged: updateSlice()
    onXChanged: updateSlice()
    onYChanged: updateSlice()
    onVisibleChanged: if (visible) settle.restart()
    onBackdropSourceChanged: updateSlice()

    Component.onCompleted: {
        updateSlice()
        settle.restart()
    }

    // Layouts settle after the first frame and after window resizes,
    // and parents can move without this item's x/y changing.
    Timer {
        id: settle
        interval: 60
        onTriggered: surface.updateSlice()
    }

    Connections {
        target: surface.Window.window
        ignoreUnknownSignals: true
        function onWidthChanged()  { settle.restart() }
        function onHeightChanged() { settle.restart() }
    }

    // ---------- 01. soft shadow ----------

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
        shadowOpacity: 0.40
        shadowBlur: 1.0
        shadowVerticalOffset: 10
        shadowHorizontalOffset: 0
        shadowScale: 0.97
    }

    // ---------- 02. blurred backdrop, clipped to rounded corners ----------

    ShaderEffectSource {
        id: slice
        anchors.fill: parent
        sourceItem: surface.backdropSource
        live: true
        hideSource: false
        smooth: true
        visible: false
    }

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

    MultiEffect {
        anchors.fill: parent
        source: slice
        visible: surface.backdropSource !== null

        maskEnabled: true
        maskSource: roundMask
        maskThresholdMin: 0.5
        maskSpreadAtMin: 1.0
    }

    // ---------- 03. glass tint ----------

    Rectangle {
        anchors.fill: parent
        radius: surface.radius
        color: surface.tintColor
    }

    // ---------- 04. body sheen: light on top, depth at the bottom ----------

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

    // ---------- 05. top gloss band ----------

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

    // ---------- 06. gradient glass edge (bright top, soft rim at bottom) ----------

    Item {
        anchors.fill: parent
        visible: surface.showEdge && surface.backdropSource !== null

        Rectangle {
            id: ringGradient
            anchors.fill: parent
            radius: surface.radius
            visible: false
            layer.enabled: true

            gradient: Gradient {
                GradientStop { position: 0.00; color: "#A6FFFFFF" }
                GradientStop { position: 0.30; color: "#3DFFFFFF" }
                GradientStop { position: 0.70; color: "#1CFFFFFF" }
                GradientStop { position: 1.00; color: "#4DFFFFFF" }
            }
        }

        Item {
            id: ringHole
            anchors.fill: parent
            visible: false
            layer.enabled: true

            Rectangle {
                anchors.fill: parent
                anchors.margins: 1
                radius: Math.max(0, surface.radius - 1)
                color: "black"
            }
        }

        MultiEffect {
            anchors.fill: parent
            source: ringGradient
            maskEnabled: true
            maskSource: ringHole
            maskInverted: true
            maskThresholdMin: 0.5
            maskSpreadAtMin: 1.0
        }
    }

    // Cheap edge for surfaces with no backdrop (e.g. buttons inside list rows)
    Rectangle {
        anchors.fill: parent
        radius: surface.radius
        color: "transparent"
        border.width: 1
        border.color: "#38FFFFFF"
        visible: surface.showEdge && surface.backdropSource === null
    }
}
