
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
    property real blurAmount: 0.58

    function updateSlice() {
        if (!backdropSource || width <= 0 || height <= 0)
            return

        const p = surface.mapToItem(backdropSource, 0, 0)

        slice.sourceRect = Qt.rect(
            p.x,
            p.y,
            width,
            height
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

    // =====================================
    // SOFT ELEVATION
    // =====================================

    Rectangle {
        id: shadowCaster

        anchors.fill: parent
        anchors.margins: 1

        radius: surface.radius
        color: "black"

        visible: false
        layer.enabled: true
    }

    MultiEffect {
        anchors.fill: parent

        source: shadowCaster
        visible: surface.elevated

        shadowEnabled: true
        shadowColor: "#000000"
        shadowOpacity: 0.28
        shadowBlur: 0.90

        shadowVerticalOffset: 8
        shadowHorizontalOffset: 0
        shadowScale: 0.97
    }

    // =====================================
    // GLASS MATERIAL
    // =====================================

    Item {
        id: material

        anchors.fill: parent
        visible: false

        ShaderEffectSource {
            id: slice

            anchors.fill: parent

            sourceItem: surface.backdropSource

            live: true
            hideSource: false
            smooth: true
        }

        MultiEffect {
            anchors.fill: parent

            source: slice
            visible: surface.backdropSource !== null

            blurEnabled: true
            blur: surface.blurAmount
            blurMax: 40
        }

        Rectangle {
            anchors.fill: parent

            radius: surface.radius
            color: surface.tintColor
        }

        Rectangle {
            anchors.fill: parent

            radius: surface.radius
            opacity: surface.sheen

            gradient: Gradient {
                GradientStop {
                    position: 0.0
                    color: assetBackend.themeColor("#28FFFFFF", assetBackend.theme)
                }

                GradientStop {
                    position: 0.26
                    color: assetBackend.themeColor("#14FFFFFF", assetBackend.theme)
                }

                GradientStop {
                    position: 0.60
                    color: assetBackend.themeColor("#06FFFFFF", assetBackend.theme)
                }

                GradientStop {
                    position: 1.0
                    color: assetBackend.themeColor("#18101B35", assetBackend.theme)
                }
            }
        }
    }

    // =====================================
    // ROUNDED MATERIAL MASK
    // =====================================

    Item {
        id: roundMask

        anchors.fill: parent

        visible: false
        layer.enabled: true

        Rectangle {
            anchors.fill: parent

            radius: surface.radius
            color: "white"
        }
    }

    MultiEffect {
        anchors.fill: parent

        source: material

        maskEnabled: true
        maskSource: roundMask

        maskThresholdMin: 0.5
        maskSpreadAtMin: 1.0
    }

    // =====================================
    // SINGLE OPTICAL EDGE
    // =====================================

    Rectangle {
        anchors.fill: parent

        radius: surface.radius

        color: "transparent"

        border.width: surface.showEdge ? 1 : 0
        border.color: assetBackend.themeColor("#65FFFFFF", assetBackend.theme)
    }
}
