 
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import "components"

Rectangle {
    id: root

    width: 1200
    height: 760

    color: "#0A1020"
    clip: true

    property string activeSection: "Overview"

    AuroraBackground {
        id: backgroundScene
        anchors.fill: parent
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 18

        // =================================================
        // SIDEBAR
        // =================================================

        GlassPanel {
            id: sidebar

            Layout.preferredWidth: 220
            Layout.minimumWidth: 200
            Layout.fillHeight: true

            backdropSource: backgroundScene
            glassTint: 0.035

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 12

                // BRAND

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 11

                    Rectangle {
                        Layout.preferredWidth: 43
                        Layout.preferredHeight: 43
                        radius: 13

                        gradient: Gradient {
                            GradientStop {
                                position: 0.0
                                color: "#65BDEB"
                            }
                            GradientStop {
                                position: 1.0
                                color: "#6254B9"
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "B"
                            color: "white"
                            font.pixelSize: 25
                            font.weight: Font.Bold
                        }
                    }

                    ColumnLayout {
                        spacing: 2

                        Text {
                            text: "BubtOps"
                            color: "#F4F7FF"
                            font.pixelSize: 19
                            font.weight: Font.Bold
                        }

                        Text {
                            text: "CAMPUS OPERATIONS"
                            color: "#91A5C5"
                            font.pixelSize: 8
                            font.letterSpacing: 1.5
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.topMargin: 12
                    Layout.bottomMargin: 8
                    height: 1
                    color: "#36FFFFFF"
                }

                Text {
                    text: "WORKSPACE"
                    color: "#7185A8"
                    font.pixelSize: 9
                    font.weight: Font.Bold
                    font.letterSpacing: 1.5
                    Layout.leftMargin: 7
                }

                // SIDEBAR NAVIGATION

                Repeater {
                    model: [
                        "Overview",
                        "Asset Registry",
                        "Locations",
                        "Maintenance",
                        "Reports",
                        "Glass Preview"
                    ]

                    delegate: Item {
                        id: navItem

                        Layout.fillWidth: true
                        Layout.preferredHeight: 45

                        property bool selected:
                            root.activeSection === modelData

                        property bool hovered:
                            navMouse.containsMouse

                        property Item backdropSource:
                            backgroundScene

                        Rectangle {
                            id: glassBody

                            anchors.fill: parent
                            radius: 14
                            color: "transparent"
                            clip: true

                            ShaderEffectSource {
                                id: backdropTexture

                                anchors.fill: parent
                                sourceItem: navItem.backdropSource

                                live: true
                                hideSource: false
                                smooth: true

                                sourceRect: {
                                    if (!navItem.backdropSource)
                                        return Qt.rect(0, 0, 0, 0)

                                    const p = navItem.mapToItem(
                                        navItem.backdropSource, 0, 0
                                    )

                                    return Qt.rect(
                                        p.x,
                                        p.y,
                                        navItem.width,
                                        navItem.height
                                    )
                                }
                            }

                            MultiEffect {
                                anchors.fill: parent
                                source: backdropTexture
                                blurEnabled: true
                                blur: 0.30
                                blurMax: 24
                            }

                            Rectangle {
                                anchors.fill: parent
                                radius: 14

                                gradient: Gradient {
                                    GradientStop {
                                        position: 0.0
                                        color: navItem.selected
                                               ? "#354E7190"
                                               : navItem.hovered
                                                 ? "#1BFFFFFF"
                                                 : "#0CFFFFFF"
                                    }

                                    GradientStop {
                                        position: 0.48
                                        color: navItem.selected
                                               ? "#224B6688"
                                               : "#08D8E9FF"
                                    }

                                    GradientStop {
                                        position: 1.0
                                        color: navItem.selected
                                               ? "#30405275"
                                               : "#1513233D"
                                    }
                                }
                            }

                            // TOP REFLECTION

                            Rectangle {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.top: parent.top

                                height: parent.height * 0.58
                                radius: 14

                                gradient: Gradient {
                                    GradientStop {
                                        position: 0.0
                                        color: "#38FFFFFF"
                                    }
                                    GradientStop {
                                        position: 0.35
                                        color: "#20FFFFFF"
                                    }
                                    GradientStop {
                                        position: 1.0
                                        color: "#00FFFFFF"
                                    }
                                }

                                opacity: navItem.selected ? 0.95
                                       : navItem.hovered ? 0.85
                                       : 0.65

                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: 180
                                    }
                                }
                            }

                            // DIAGONAL REFLECTION

                            Rectangle {
                                width: parent.width * 1.35
                                height: parent.height * 0.42

                                x: -parent.width * 0.16
                                y: -parent.height * 0.13

                                rotation: -11

                                gradient: Gradient {
                                    GradientStop {
                                        position: 0.0
                                        color: "#00FFFFFF"
                                    }
                                    GradientStop {
                                        position: 0.42
                                        color: "#19FFFFFF"
                                    }
                                    GradientStop {
                                        position: 0.58
                                        color: "#26FFFFFF"
                                    }
                                    GradientStop {
                                        position: 1.0
                                        color: "#00FFFFFF"
                                    }
                                }

                                opacity: navItem.hovered ? 0.9 : 0.48

                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: 200
                                    }
                                }
                            }

                            // LOWER REFLECTION

                            Rectangle {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom

                                height: parent.height * 0.34
                                radius: 14

                                gradient: Gradient {
                                    GradientStop {
                                        position: 0.0
                                        color: "#00FFFFFF"
                                    }
                                    GradientStop {
                                        position: 1.0
                                        color: "#14243F65"
                                    }
                                }
                            }

                            // OPTICAL EDGES

                            Rectangle {
                                anchors.fill: parent
                                radius: 14
                                color: "transparent"
                                border.width: 1

                                border.color: navItem.selected
                                              ? "#9ADFFAFF"
                                              : navItem.hovered
                                                ? "#70FFFFFF"
                                                : "#42FFFFFF"
                            }

                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: 1
                                radius: 13
                                color: "transparent"
                                border.width: 1
                                border.color: "#20FFFFFF"
                            }

                            Rectangle {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom

                                anchors.leftMargin: 14
                                anchors.rightMargin: 14

                                height: 1
                                color: "#45FFFFFF"
                                opacity: 0.55
                            }
                        }

                        // NAVIGATION ICON

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 15
                            anchors.verticalCenter: parent.verticalCenter

                            width: 22
                            horizontalAlignment: Text.AlignHCenter

                            text: {
                                switch (modelData) {
                                    case "Overview":       return "▦"
                                    case "Asset Registry": return "◇"
                                    case "Locations":      return "⌖"
                                    case "Maintenance":    return "⚙"
                                    case "Reports":        return "▤"
                                    case "Glass Preview":  return "✧"
                                    default:               return "•"
                                }
                            }

                            color: navItem.selected
                                   ? "#FFFFFF" : "#D1DDED"

                            font.pixelSize: 17
                        }

                        // NAVIGATION LABEL

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 48
                            anchors.verticalCenter: parent.verticalCenter

                            text: modelData

                            color: navItem.selected ? "#FFFFFF"
                                  : navItem.hovered ? "#F0F8FF"
                                  : "#B9C9DF"

                            font.pixelSize: 12
                            font.weight: navItem.selected
                                         ? Font.DemiBold
                                         : Font.Normal

                            Behavior on color {
                                ColorAnimation {
                                    duration: 160
                                }
                            }
                        }

                        Rectangle {
                            width: 3
                            height: 23
                            radius: 2

                            anchors.left: parent.left
                            anchors.leftMargin: 1
                            anchors.verticalCenter: parent.verticalCenter

                            color: "#B8EDFF"
                            visible: navItem.selected
                        }

                        MouseArea {
                            id: navMouse

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor

                            onClicked: {
                                root.activeSection = modelData
                            }
                        }

                        scale: hovered ? 1.018 : 1.0

                        Behavior on scale {
                            NumberAnimation {
                                duration: 160
                                easing.type: Easing.OutCubic
                            }
                        }
                    }
                }

                Item {
                    Layout.fillHeight: true
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: "#30FFFFFF"
                }

                // OFFLINE STATUS

                GlassPanel {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 65

                    radius: 12
                    backdropSource: backgroundScene
                    glassTint: 0.045

                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        color: "#103DCC9C"
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 11
                        spacing: 5

                        RowLayout {
                            spacing: 7

                            Rectangle {
                                width: 7
                                height: 7
                                radius: 4
                                color: "#57D9A3"
                            }

                            Text {
                                text: "OFFLINE MODE"
                                color: "#A8EBD0"
                                font.pixelSize: 9
                                font.weight: Font.Bold
                                font.letterSpacing: 1
                            }
                        }

                        Text {
                            text: "Local database active"
                            color: "#9EB6B5"
                            font.pixelSize: 10
                        }
                    }
                }

                Text {
                    text: "BubtOps  •  Version 1.0"
                    color: "#647795"
                    font.pixelSize: 9

                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 5
                }
            }
        }

        // =================================================
        // PAGE CONTAINER
        // =================================================

        StackLayout {
            id: pageStack

            Layout.fillWidth: true
            Layout.fillHeight: true

            currentIndex:
                root.activeSection === "Asset Registry" ? 1
                : root.activeSection === "Glass Preview" ? 2
                : 0

            // =================================================
            // PAGE 1 — OVERVIEW
            // =================================================

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true

                spacing: 17

                // DASHBOARD HEADER

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 65

                    ColumnLayout {
                        spacing: 4

                        Text {
                            text: "Overview"
                            color: "#F5F7FF"
                            font.pixelSize: 25
                            font.weight: Font.Bold
                        }

                        Text {
                            text: "Your campus assets at a glance."
                            color: "#91A3C0"
                            font.pixelSize: 11
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                    }
                }

                // SUMMARY CARDS

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    Repeater {
                        model: [
                            {
                                title: "REGISTERED ASSETS",
                                value: "128",
                                note: "Total campus assets",
                                accent: "#83CFFF"
                            },
                            {
                                title: "IN SERVICE",
                                value: "112",
                                note: "Currently operational",
                                accent: "#68D9B0"
                            },
                            {
                                title: "NEEDS ATTENTION",
                                value: "09",
                                note: "Require inspection",
                                accent: "#F2B76F"
                            },
                            {
                                title: "MAINTENANCE COST",
                                value: "৳24.8K",
                                note: "Recorded expenditure",
                                accent: "#B9A2FF"
                            }
                        ]

                        delegate: GlassPanel {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 118

                            backdropSource: backgroundScene
                            glassTint: 0.13

                            Rectangle {
                                width: 3
                                height: 42
                                radius: 2

                                color: modelData.accent
                                opacity: 0.9

                                anchors.left: parent.left
                                anchors.leftMargin: 15
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            ColumnLayout {
                                anchors.fill: parent

                                anchors.leftMargin: 27
                                anchors.rightMargin: 12
                                anchors.topMargin: 16
                                anchors.bottomMargin: 13

                                spacing: 5

                                Text {
                                    text: modelData.title
                                    color: "#A3B3CC"
                                    font.pixelSize: 9
                                    font.weight: Font.Bold
                                    font.letterSpacing: 0.7
                                }

                                Text {
                                    text: modelData.value
                                    color: "#F5F7FF"
                                    font.pixelSize: 25
                                    font.weight: Font.Bold
                                }

                                Text {
                                    text: modelData.note
                                    color: "#8498B7"
                                    font.pixelSize: 9
                                }
                            }
                        }
                    }
                }

                // LOWER DASHBOARD PANELS

                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 14

                    // ASSET CONDITION

                    GlassPanel {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.minimumWidth: 250

                        backdropSource: backgroundScene
                        glassTint: 0.14

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 19
                            spacing: 15

                            Text {
                                text: "Asset condition"
                                color: "#F3F6FF"
                                font.pixelSize: 15
                                font.weight: Font.DemiBold
                            }

                            Text {
                                text: "Current operational overview"
                                color: "#8FA2C0"
                                font.pixelSize: 10
                            }

                            RowLayout {
                                Layout.topMargin: 5
                                spacing: 15

                                ColumnLayout {
                                    spacing: 3

                                    Text {
                                        text: "87.5%"
                                        color: "#F5F7FF"
                                        font.pixelSize: 34
                                        font.weight: Font.Bold
                                    }

                                    Text {
                                        text: "Operational rate"
                                        color: "#91A4C2"
                                        font.pixelSize: 10
                                    }
                                }

                                Item {
                                    Layout.fillWidth: true
                                }

                                Rectangle {
                                    width: 76
                                    height: 76
                                    radius: 38
                                    color: "#183DCC9C"
                                    border.width: 5
                                    border.color: "#58D7AC"

                                    Text {
                                        anchors.centerIn: parent
                                        text: "87%"
                                        color: "#D9FFF0"
                                        font.pixelSize: 16
                                        font.weight: Font.Bold
                                    }
                                }
                            }

                            // CONDITION DISTRIBUTION

                            RowLayout {
                                Layout.fillWidth: true
                                Layout.topMargin: 8
                                spacing: 3

                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredWidth: 112
                                    height: 8
                                    radius: 4
                                    color: "#59D6A8"
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredWidth: 7
                                    height: 8
                                    radius: 4
                                    color: "#E7B66E"
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredWidth: 9
                                    height: 8
                                    radius: 4
                                    color: "#E17E91"
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                height: 1
                                color: "#2EFFFFFF"
                                Layout.topMargin: 3
                                Layout.bottomMargin: 3
                            }

                            // OPERATIONAL STATUS

                            RowLayout {
                                Layout.fillWidth: true

                                Rectangle {
                                    width: 8
                                    height: 8
                                    radius: 4
                                    color: "#59D6A8"
                                }

                                Text {
                                    text: "Operational"
                                    color: "#C6D1E3"
                                    font.pixelSize: 11
                                }

                                Item {
                                    Layout.fillWidth: true
                                }

                                Text {
                                    text: "112"
                                    color: "#F4F7FF"
                                    font.pixelSize: 12
                                    font.weight: Font.Bold
                                }
                            }

                            // MAINTENANCE STATUS

                            RowLayout {
                                Layout.fillWidth: true

                                Rectangle {
                                    width: 8
                                    height: 8
                                    radius: 4
                                    color: "#E7B66E"
                                }

                                Text {
                                    text: "Under maintenance"
                                    color: "#C6D1E3"
                                    font.pixelSize: 11
                                }

                                Item {
                                    Layout.fillWidth: true
                                }

                                Text {
                                    text: "07"
                                    color: "#F4F7FF"
                                    font.pixelSize: 12
                                    font.weight: Font.Bold
                                }
                            }

                            // INSPECTION STATUS

                            RowLayout {
                                Layout.fillWidth: true

                                Rectangle {
                                    width: 8
                                    height: 8
                                    radius: 4
                                    color: "#E17E91"
                                }

                                Text {
                                    text: "Needs inspection"
                                    color: "#C6D1E3"
                                    font.pixelSize: 11
                                }

                                Item {
                                    Layout.fillWidth: true
                                }

                                Text {
                                    text: "09"
                                    color: "#F4F7FF"
                                    font.pixelSize: 12
                                    font.weight: Font.Bold
                                }
                            }

                            Item {
                                Layout.fillHeight: true
                            }

                            Text {
                                text: "Illustrative preview data"
                                color: "#7186A6"
                                font.pixelSize: 9
                            }
                        }
                    }

                    // MAINTENANCE QUEUE

                    GlassPanel {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.minimumWidth: 300

                        backdropSource: backgroundScene
                        glassTint: 0.14

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 19
                            spacing: 12

                            RowLayout {
                                Layout.fillWidth: true

                                Text {
                                    text: "Maintenance queue"
                                    color: "#F3F6FF"
                                    font.pixelSize: 15
                                    font.weight: Font.DemiBold
                                }

                                Item {
                                    Layout.fillWidth: true
                                }

                                Text {
                                    text: "3 RECORDS"
                                    color: "#93A9C9"
                                    font.pixelSize: 8
                                    font.weight: Font.Bold
                                    font.letterSpacing: 0.8
                                }
                            }

                            Text {
                                text: "Recently reported maintenance issues"
                                color: "#8FA2C0"
                                font.pixelSize: 10
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                height: 1
                                color: "#2EFFFFFF"
                                Layout.topMargin: 3
                                Layout.bottomMargin: 2
                            }

                            Repeater {
                                model: [
                                    {
                                        asset: "Projector",
                                        location: "Room 302",
                                        status: "Pending",
                                        statusColor: "#E8B66D",
                                        reference: "AST-0018"
                                    },
                                    {
                                        asset: "Air conditioner",
                                        location: "Lab 04",
                                        status: "In progress",
                                        statusColor: "#81C8F1",
                                        reference: "AST-0042"
                                    },
                                    {
                                        asset: "Desktop PC",
                                        location: "Office 12",
                                        status: "Inspection",
                                        statusColor: "#E58B9A",
                                        reference: "AST-0067"
                                    }
                                ]

                                delegate: GlassPanel {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 65

                                    radius: 11
                                    backdropSource: backgroundScene
                                    glassTint: 0.045

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 12
                                        anchors.rightMargin: 12
                                        spacing: 10

                                        Rectangle {
                                            Layout.preferredWidth: 34
                                            Layout.preferredHeight: 34
                                            radius: 10
                                            color: "#263D6490"

                                            Text {
                                                anchors.centerIn: parent
                                                text: "•"
                                                color: modelData.statusColor
                                                font.pixelSize: 25
                                            }
                                        }

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 4

                                            Text {
                                                text: modelData.asset
                                                color: "#EAF0FC"
                                                font.pixelSize: 11
                                                font.weight: Font.DemiBold
                                            }

                                            Text {
                                                text: modelData.location
                                                      + "  •  "
                                                      + modelData.reference

                                                color: "#8298B9"
                                                font.pixelSize: 9
                                            }
                                        }

                                        Rectangle {
                                            Layout.preferredWidth: 75
                                            Layout.preferredHeight: 23
                                            radius: 12
                                            color: "#20FFFFFF"
                                            border.width: 1
                                            border.color: "#24FFFFFF"

                                            Text {
                                                anchors.centerIn: parent
                                                text: modelData.status
                                                color: modelData.statusColor
                                                font.pixelSize: 8
                                                font.weight: Font.DemiBold
                                            }
                                        }
                                    }
                                }
                            }

                            Item {
                                Layout.fillHeight: true
                            }
                        }
                    }
                }

                // DASHBOARD FOOTER

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 19

                    Text {
                        text: "BubtOps  |  Campus Asset Management"
                        color: "#657A9A"
                        font.pixelSize: 9
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    Text {
                        text: "Illustrative preview data — database connection comes next"
                        color: "#657A9A"
                        font.pixelSize: 9
                    }
                }
            }

            // =================================================
            // PAGE 2 — ASSET REGISTRY
            // =================================================

           AssetRegistry {
    id: assetRegistryPage

    Layout.fillWidth: true
    Layout.fillHeight: true

    backend: assetBackend
    backdropSource: backgroundScene
}

            // =================================================
            // PAGE 3 — GLASS COMPONENT PREVIEW
            // =================================================

            ColumnLayout {
                id: glassPreviewPage

                Layout.fillWidth: true
                Layout.fillHeight: true

                spacing: 17

                // PAGE HEADER

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 65

                    ColumnLayout {
                        spacing: 4

                        Text {
                            text: "Glass Preview"
                            color: "#F5F7FF"
                            font.pixelSize: 25
                            font.weight: Font.Bold
                        }

                        Text {
                            text: "Test the new glass components against the Aurora background."
                            color: "#91A3C0"
                            font.pixelSize: 11
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    Text {
                        text: "VISUAL TEST"
                        color: "#A9C8E8"
                        font.pixelSize: 9
                        font.weight: Font.Bold
                        font.letterSpacing: 1.2
                    }
                }

                // PREVIEW SURFACES

                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 15

                    // LARGE GLASS SURFACE

                    GlassSurface {
                        id: largeGlassPreview

                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.minimumWidth: 280

                        backdropSource: backgroundScene
                        radius: 22
                        tintColor: Qt.rgba(0.28, 0.39, 0.62, 0.12)
                        elevated: true
                        showEdge: true
                        sheen: 1.0

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 24
                            spacing: 14

                            Text {
                                text: "GLASS SURFACE"
                                color: "#AFC5E4"
                                font.pixelSize: 9
                                font.weight: Font.Bold
                                font.letterSpacing: 1.3
                            }

                            Text {
                                text: "A clearer look\nat layered glass."
                                color: "#F4F7FF"
                                font.pixelSize: 27
                                font.weight: Font.DemiBold
                            }

                            Text {
                                Layout.fillWidth: true

                                text: "This panel samples the Aurora background and combines it with a translucent tint, soft sheen and optical edge."

                                color: "#B5C5DC"
                                font.pixelSize: 11
                                wrapMode: Text.WordWrap
                            }

                            Item {
                                Layout.fillHeight: true
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                height: 1
                                color: "#35FFFFFF"
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 10

                                ColumnLayout {
                                    spacing: 3

                                    Text {
                                        text: "BACKGROUND"
                                        color: "#8198B8"
                                        font.pixelSize: 8
                                        font.weight: Font.Bold
                                        font.letterSpacing: 0.8
                                    }

                                    Text {
                                        text: "Live Aurora sample"
                                        color: "#E4EDFA"
                                        font.pixelSize: 10
                                    }
                                }

                                Item {
                                    Layout.fillWidth: true
                                }

                                Text {
                                    text: "01 / 03"
                                    color: "#AFC5E4"
                                    font.pixelSize: 9
                                    font.weight: Font.DemiBold
                                }
                            }
                        }
                    }

                    // INPUT COMPONENTS

                    GlassSurface {
                        id: glassControlsPreview

                        Layout.preferredWidth: 300
                        Layout.minimumWidth: 260
                        Layout.fillHeight: true

                        backdropSource: backgroundScene
                        radius: 22
                        tintColor: Qt.rgba(0.28, 0.39, 0.62, 0.10)
                        elevated: true
                        showEdge: true
                        sheen: 0.9

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 20
                            spacing: 12

                            Text {
                                text: "INPUT COMPONENTS"
                                color: "#AFC5E4"
                                font.pixelSize: 9
                                font.weight: Font.Bold
                                font.letterSpacing: 1.2
                            }

                            Text {
                                text: "GlassField"
                                color: "#F0F5FF"
                                font.pixelSize: 13
                                font.weight: Font.DemiBold
                            }

                            Text {
                                text: "Search field appearance"
                                color: "#8FA2C0"
                                font.pixelSize: 10
                            }

                            GlassField {
                                id: previewGlassField

                                Layout.fillWidth: true
                                placeholderText: "Search campus assets..."
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                height: 1
                                color: "#2EFFFFFF"
                                Layout.topMargin: 5
                                Layout.bottomMargin: 3
                            }

                            Text {
                                text: "GlassCombo"
                                color: "#F0F5FF"
                                font.pixelSize: 13
                                font.weight: Font.DemiBold
                            }

                            Text {
                                text: "Dropdown appearance"
                                color: "#8FA2C0"
                                font.pixelSize: 10
                            }

                            GlassCombo {
                                id: previewGlassCombo

                                Layout.fillWidth: true

                                model: [
                                    "All categories",
                                    "Computer",
                                    "Furniture",
                                    "Laboratory Equipment",
                                    "Electrical Equipment"
                                ]

                                currentIndex: 0
                            }

                            Item {
                                Layout.fillHeight: true
                            }

                            Text {
                                Layout.fillWidth: true

                                text: "These controls are for visual testing only."

                                color: "#7186A6"
                                font.pixelSize: 9
                                wrapMode: Text.WordWrap
                            }
                        }
                    }
                }

                // PREVIEW FOOTER

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 36
                    spacing: 10

                    Text {
                        text: "CHECK:"
                        color: "#8198B8"
                        font.pixelSize: 9
                        font.weight: Font.Bold
                    }

                    Text {
                        text: "Transparency  •  Background visibility  •  Blur  •  Edge reflections"
                        color: "#91A3C0"
                        font.pixelSize: 9
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    Text {
                        text: "No database changes"
                        color: "#72D6B0"
                        font.pixelSize: 9
                    }
                }
            }
        }
    }
}
