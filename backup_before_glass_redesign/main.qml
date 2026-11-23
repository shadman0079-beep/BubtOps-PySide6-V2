
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "components"

Rectangle {
    id: root

    width: 1200
    height: 760
    color: "#101522"
    clip: true

    property string activeSection: "Overview"

    // BACKGROUND
    Item {
        id: backgroundScene
        anchors.fill: parent

        Rectangle {
            anchors.fill: parent

            gradient: Gradient {
                GradientStop { position: 0.0; color: "#111827" }
                GradientStop { position: 0.52; color: "#19263D" }
                GradientStop { position: 1.0; color: "#17172C" }
            }
        }

        Rectangle {
            width: 650
            height: 650
            radius: 325
            x: root.width - 440
            y: -330
            opacity: 0.22

            gradient: Gradient {
                GradientStop { position: 0.0; color: "#6659C9" }
                GradientStop { position: 1.0; color: "#152B50" }
            }
        }

        Rectangle {
            width: 550
            height: 550
            radius: 275
            x: -280
            y: root.height - 390
            opacity: 0.20

            gradient: Gradient {
                GradientStop { position: 0.0; color: "#168FAF" }
                GradientStop { position: 1.0; color: "#17243D" }
            }
        }

        Rectangle {
            width: 380
            height: 380
            radius: 190
            x: root.width * 0.40
            y: root.height * 0.35
            opacity: 0.09

            gradient: Gradient {
                GradientStop { position: 0.0; color: "#4B76C8" }
                GradientStop { position: 1.0; color: "#25213F" }
            }
        }
    }

    // MAIN APPLICATION LAYOUT
    RowLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 18

        // SIDEBAR
        GlassPanel {
            id: sidebar

            backdropSource: backgroundScene
            glassTint: 0.12

            Layout.preferredWidth: 218
            Layout.fillHeight: true

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 19
                spacing: 0

                // BRAND
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 11

                    Rectangle {
                        width: 39
                        height: 39
                        radius: 12

                        gradient: Gradient {
                            GradientStop { position: 0.0; color: "#6989D8" }
                            GradientStop { position: 1.0; color: "#4357A2" }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "B"
                            color: "white"
                            font.pixelSize: 22
                            font.weight: Font.Bold
                        }
                    }

                    ColumnLayout {
                        spacing: 1

                        Text {
                            text: "BubtOps"
                            color: "#FFFFFF"
                            font.pixelSize: 19
                            font.weight: Font.Bold
                        }

                        Text {
                            text: "CAMPUS OPERATIONS"
                            color: "#8292B1"
                            font.pixelSize: 8
                            font.letterSpacing: 1.1
                        }
                    }
                }

                Item { Layout.preferredHeight: 34 }

                Text {
                    text: "WORKSPACE"
                    color: "#7585A3"
                    font.pixelSize: 9
                    font.weight: Font.DemiBold
                    font.letterSpacing: 1.5
                }

                Item { Layout.preferredHeight: 12 }

                // NAVIGATION
                Repeater {
                    model: [
                        { name: "Overview", symbol: "◈" },
                        { name: "Asset Registry", symbol: "▦" },
                        { name: "Locations", symbol: "⌖" },
                        { name: "Maintenance", symbol: "⌁" },
                        { name: "Reports", symbol: "▤" }
                    ]

                    delegate: Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 43
                        Layout.bottomMargin: 5

                        radius: 11

                        property bool selected:
                            root.activeSection === modelData.name

                        color: selected
                               ? "#344C76A0"
                               : navMouse.containsMouse
                                 ? "#1EFFFFFF"
                                 : "transparent"

                        border.width: selected ? 1 : 0
                        border.color: "#526FA4C7"

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 10
                            spacing: 12

                            Text {
                                text: modelData.symbol
                                color: parent.parent.selected
                                       ? "#B9DBFF"
                                       : "#899AB8"
                                font.pixelSize: 17
                                Layout.preferredWidth: 19
                                horizontalAlignment: Text.AlignHCenter
                            }

                            Text {
                                text: modelData.name
                                color: parent.parent.selected
                                       ? "#FFFFFF"
                                       : "#AAB6CC"
                                font.pixelSize: 11
                                font.weight: parent.parent.selected
                                             ? Font.DemiBold
                                             : Font.Medium

                                Layout.fillWidth: true
                            }
                        }

                        MouseArea {
                            id: navMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor

                            onClicked: {
                                root.activeSection = modelData.name
                                console.log("Selected:", modelData.name)
                            }
                        }

                        Behavior on color {
                            ColorAnimation { duration: 140 }
                        }
                    }
                }

                Item { Layout.fillHeight: true }

                // OFFLINE STATUS
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 65
                    radius: 13
                    color: "#172D4B43"
                    border.width: 1
                    border.color: "#365D9C82"

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
                                color: "#70DDB3"
                            }

                            Text {
                                text: "SYSTEM OPERATIONAL"
                                color: "#C2E9D8"
                                font.pixelSize: 9
                                font.weight: Font.DemiBold
                            }
                        }

                        Text {
                            text: "Local database active"
                            color: "#819AAB"
                            font.pixelSize: 9
                        }
                    }
                }

                Item { Layout.preferredHeight: 12 }

                Text {
                    text: "BUBTOPS  •  DESKTOP"
                    color: "#64738F"
                    font.pixelSize: 8
                    font.letterSpacing: 1
                }
            }
        }

        // MAIN CONTENT
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 17

            // HEADER
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 61

                ColumnLayout {
                    spacing: 4

                    Text {
                        text: root.activeSection
                        color: "#FFFFFF"
                        font.pixelSize: 25
                        font.weight: Font.Bold
                    }

                    Text {
                        text: "Your campus operations at a glance."
                        color: "#98A7C0"
                        font.pixelSize: 11
                    }
                }

                Item { Layout.fillWidth: true }

                Rectangle {
                    Layout.preferredWidth: 116
                    Layout.preferredHeight: 35
                    radius: 18

                    color: "#192D8067"
                    border.width: 1
                    border.color: "#4567A994"

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 7

                        Rectangle {
                            width: 6
                            height: 6
                            radius: 3
                            color: "#75DEB4"
                        }

                        Text {
                            text: "OFFLINE MODE"
                            color: "#D3E8E1"
                            font.pixelSize: 9
                            font.weight: Font.DemiBold
                        }
                    }
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
                            symbol: "▦",
                            tint: "#81B9F5"
                        },
                        {
                            title: "IN SERVICE",
                            value: "112",
                            note: "Currently operational",
                            symbol: "✓",
                            tint: "#7ADDB6"
                        },
                        {
                            title: "NEEDS ATTENTION",
                            value: "09",
                            note: "Requires inspection",
                            symbol: "!",
                            tint: "#E8BE7B"
                        },
                        {
                            title: "MAINTENANCE COST",
                            value: "৳ 24.8K",
                            note: "Recorded expenses",
                            symbol: "↗",
                            tint: "#B5A2F4"
                        }
                    ]

                    delegate: GlassPanel {
                        property var info: modelData

                        backdropSource: backgroundScene
                        glassTint: 0.10

                        Layout.fillWidth: true
                        Layout.preferredHeight: 137

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 15
                            spacing: 7

                            RowLayout {
                                Layout.fillWidth: true

                                Text {
                                    text: info.title
                                    color: "#A2B0C9"
                                    font.pixelSize: 8
                                    font.weight: Font.DemiBold
                                    font.letterSpacing: 0.7

                                    Layout.fillWidth: true
                                }

                                Rectangle {
                                    width: 27
                                    height: 27
                                    radius: 9
                                    color: "#20FFFFFF"
                                    border.width: 1
                                    border.color: "#30FFFFFF"

                                    Text {
                                        anchors.centerIn: parent
                                        text: info.symbol
                                        color: info.tint
                                        font.pixelSize: 14
                                        font.weight: Font.DemiBold
                                    }
                                }
                            }

                            Text {
                                text: info.value
                                color: "#FFFFFF"
                                font.pixelSize: 26
                                font.weight: Font.DemiBold
                            }

                            Text {
                                text: info.note
                                color: "#8798B5"
                                font.pixelSize: 9
                            }
                        }
                    }
                }
            }

            // LOWER CONTENT AREA
            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 12

                // ASSET CONDITION
                GlassPanel {
                    backdropSource: backgroundScene
                    glassTint: 0.11

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumWidth: 270

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 19
                        spacing: 14

                        RowLayout {
                            Layout.fillWidth: true

                            ColumnLayout {
                                spacing: 4

                                Text {
                                    text: "Asset condition"
                                    color: "#FFFFFF"
                                    font.pixelSize: 15
                                    font.weight: Font.DemiBold
                                }

                                Text {
                                    text: "Current equipment overview"
                                    color: "#8E9DB7"
                                    font.pixelSize: 9
                                }
                            }

                            Item { Layout.fillWidth: true }

                            Text {
                                text: "OVERVIEW"
                                color: "#8FA9D0"
                                font.pixelSize: 8
                                font.weight: Font.DemiBold
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 1
                            color: "#24FFFFFF"
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            ColumnLayout {
                                spacing: 3

                                Text {
                                    text: "87.5%"
                                    color: "#FFFFFF"
                                    font.pixelSize: 31
                                    font.weight: Font.DemiBold
                                }

                                Text {
                                    text: "Assets operational"
                                    color: "#9CAAC2"
                                    font.pixelSize: 10
                                }
                            }

                            Item { Layout.fillWidth: true }

                            Rectangle {
                                width: 64
                                height: 64
                                radius: 32
                                color: "#244D806D"
                                border.width: 3
                                border.color: "#72DDB5"

                                Text {
                                    anchors.centerIn: parent
                                    text: "88"
                                    color: "#B8F0D7"
                                    font.pixelSize: 20
                                    font.weight: Font.Bold
                                }
                            }
                        }

                        Item { Layout.preferredHeight: 2 }

                        // CONDITION BARS
                        Repeater {
                            model: [
                                {
                                    label: "Operational",
                                    count: "112",
                                    amount: 0.875,
                                    color: "#70D9B0"
                                },
                                {
                                    label: "Under maintenance",
                                    count: "07",
                                    amount: 0.055,
                                    color: "#83B8F1"
                                },
                                {
                                    label: "Needs inspection",
                                    count: "09",
                                    amount: 0.070,
                                    color: "#E7BD79"
                                }
                            ]

                            delegate: ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 7

                                RowLayout {
                                    Layout.fillWidth: true

                                    Text {
                                        text: modelData.label
                                        color: "#B7C3D7"
                                        font.pixelSize: 10
                                    }

                                    Item { Layout.fillWidth: true }

                                    Text {
                                        text: modelData.count
                                        color: "#FFFFFF"
                                        font.pixelSize: 10
                                        font.weight: Font.DemiBold
                                    }
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 6
                                    radius: 3
                                    color: "#263B526B"

                                    Rectangle {
                                        width: parent.width * modelData.amount
                                        height: parent.height
                                        radius: 3
                                        color: modelData.color

                                        Behavior on width {
                                            NumberAnimation { duration: 450 }
                                        }
                                    }
                                }
                            }
                        }

                        Item { Layout.fillHeight: true }

                        Text {
                            text: "Illustrative preview data — database connection comes next."
                            color: "#71829F"
                            font.pixelSize: 8
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }
                    }
                }

                // MAINTENANCE QUEUE
                GlassPanel {
                    backdropSource: backgroundScene
                    glassTint: 0.11

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumWidth: 270

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 19
                        spacing: 13

                        RowLayout {
                            Layout.fillWidth: true

                            ColumnLayout {
                                spacing: 4

                                Text {
                                    text: "Maintenance queue"
                                    color: "#FFFFFF"
                                    font.pixelSize: 15
                                    font.weight: Font.DemiBold
                                }

                                Text {
                                    text: "Items requiring attention"
                                    color: "#8E9DB7"
                                    font.pixelSize: 9
                                }
                            }

                            Item { Layout.fillWidth: true }

                            Text {
                                text: "VIEW ALL  →"
                                color: "#A9C9F3"
                                font.pixelSize: 8
                                font.weight: Font.DemiBold
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 1
                            color: "#24FFFFFF"
                        }

                        Repeater {
                            model: [
                                {
                                    name: "Projector — Room 302",
                                    detail: "Academic building • 2 hours ago",
                                    status: "Pending",
                                    tint: "#E8BF7B"
                                },
                                {
                                    name: "Air conditioner — Lab 04",
                                    detail: "Engineering block • Yesterday",
                                    status: "Review",
                                    tint: "#8BBDF2"
                                },
                                {
                                    name: "Desktop PC — Office 12",
                                    detail: "Administration • 2 days ago",
                                    status: "Scheduled",
                                    tint: "#91D8BB"
                                }
                            ]

                            delegate: RowLayout {
                                Layout.fillWidth: true
                                spacing: 10

                                Rectangle {
                                    width: 34
                                    height: 34
                                    radius: 11
                                    color: "#20FFFFFF"
                                    border.width: 1
                                    border.color: "#24FFFFFF"

                                    Text {
                                        anchors.centerIn: parent
                                        text: "⌁"
                                        color: modelData.tint
                                        font.pixelSize: 18
                                    }
                                }

                                ColumnLayout {
                                    spacing: 4
                                    Layout.fillWidth: true

                                    Text {
                                        text: modelData.name
                                        color: "#EAF0FB"
                                        font.pixelSize: 10
                                        font.weight: Font.DemiBold
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }

                                    Text {
                                        text: modelData.detail
                                        color: "#8293AF"
                                        font.pixelSize: 8
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                }

                                Rectangle {
                                    radius: 8
                                    color: "#20FFFFFF"
                                    border.width: 1
                                    border.color: "#32FFFFFF"

                                    Layout.preferredWidth: 65
                                    Layout.preferredHeight: 23

                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.status
                                        color: modelData.tint
                                        font.pixelSize: 8
                                        font.weight: Font.DemiBold
                                    }
                                }
                            }
                        }

                        Item { Layout.fillHeight: true }

                        GlassButton {
                            Layout.fillWidth: true
                            label: "Open maintenance records"
                            primary: true

                            onClicked: {
                                root.activeSection = "Maintenance"
                            }
                        }
                    }
                }
            }

            // FOOTER
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 20

                Text {
                    text: "BUBTOPS DESKTOP"
                    color: "#687A98"
                    font.pixelSize: 8
                    font.letterSpacing: 1
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: "LOCAL • PRIVATE • OFFLINE"
                    color: "#7185A3"
                    font.pixelSize: 8
                    font.letterSpacing: 0.8
                }
            }
        }
    }
}
