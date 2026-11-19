import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import QtQuick.Window
import "components"

Rectangle {
    id: root

    width: 1200
    height: 760
    color: "#0A1020"
    clip: true

    property string activeSection: "Overview"


    // Live SQLite dashboard snapshot. Values remain blank until the
    // backend successfully reads the database; no demo numbers are shown.
    property var dashboardData: ({ success: false })
    property string clockTime: "--:--"
    property string clockDate: "Loading date..."

    function refreshDashboardData() {
        try {
            var result = assetBackend.getDashboardData()
            if (result && result.success) {
                dashboardData = result
            } else {
                dashboardData = result || ({ success: false })
                console.warn(
                    "Dashboard data could not be loaded:",
                    dashboardData.error || "Unknown database error"
                )
            }
        } catch (error) {
            dashboardData = ({ success: false, error: String(error) })
            console.error("Dashboard refresh failed:", error)
        }
    }

    function twoDigits(value) {
        return value < 10 ? "0" + value : String(value)
    }

    function updateClock() {
        var now = new Date()
        var hour = now.getHours()
        var hour12 = hour % 12
        if (hour12 === 0)
            hour12 = 12

        var days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        var months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

        clockTime = twoDigits(hour12) + ":"
                    + twoDigits(now.getMinutes()) + ":"
                    + twoDigits(now.getSeconds())
                    + (hour >= 12 ? " PM" : " AM")

        clockDate = days[now.getDay()] + ", "
                    + twoDigits(now.getDate()) + " "
                    + months[now.getMonth()] + " "
                    + now.getFullYear()
    }

    function dashboardCount(key) {
        if (!dashboardData || dashboardData.success !== true)
            return "—"
        return String(Number(dashboardData[key] || 0))
    }

    function dashboardMoney() {
        if (!dashboardData || dashboardData.success !== true)
            return "—"
        var amount = Number(dashboardData.maintenanceCost || 0)
        return "৳ " + amount.toLocaleString(Qt.locale("en_US"), "f", 2)
    }

    function dashboardPercent(key) {
        if (!dashboardData || dashboardData.success !== true)
            return "—"
        var total = Number(dashboardData.totalAssets || 0)
        if (total <= 0)
            return "0%"
        var value = Number(dashboardData[key] || 0) * 100 / total
        return value.toFixed(1) + "%"
    }

    function conditionRatio(key) {
        if (!dashboardData || dashboardData.success !== true)
            return 0
        var total = Number(dashboardData.totalAssets || 0)
        if (total <= 0)
            return 0
        return Math.max(0, Math.min(1,
            Number(dashboardData[key] || 0) / total
        ))
    }

    function maintenanceStatusColor(status) {
        var value = String(status || "").toLowerCase()
        if (value.indexOf("complete") >= 0 || value.indexOf("closed") >= 0)
            return "#68D9B0"
        if (value.indexOf("progress") >= 0 || value.indexOf("pending") >= 0)
            return "#F2B76F"
        if (value.indexOf("urgent") >= 0 || value.indexOf("cancel") >= 0)
            return "#F18C9B"
        return "#83CFFF"
    }

    Timer {
        id: dashboardClockTimer
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.updateClock()
    }

    Connections {
        target: assetBackend
        function onAssetsChanged() {
            root.refreshDashboardData()
        }
        function onMaintenanceChanged() {
            root.refreshDashboardData()
        }
    }

    Component.onCompleted: {
        updateClock()
        refreshDashboardData()
    }

    onDashboardDataChanged: {
        // The dashboard is data-driven; its progress bars update through
        // bindings, without a continuously repainting chart canvas.
    }

    // Window state is read from the containing QQuickView.
    readonly property bool isFullScreen: Window.visibility === Window.FullScreen

    function toggleFullScreen() {
        var appWindow = Window.window
        if (!appWindow)
            return

        if (isFullScreen)
            appWindow.showMaximized()
        else
            appWindow.showFullScreen()
    }

    // Open the dedicated repair/service list. When an asset ID is supplied,
    // the detail panel selects that asset immediately.
    function openAttentionAssets(assetId) {
        activeSection = "Needs Attention"
        attentionPage.refreshData(Number(assetId || 0))
    }

    function exitFullScreen() {
        var appWindow = Window.window
        if (appWindow && isFullScreen)
            appWindow.showMaximized()
    }

    // Global keyboard controls. Escape restores the maximized window.
    Shortcut {
        sequence: "F11"
        context: Qt.ApplicationShortcut
        onActivated: root.toggleFullScreen()
    }

    Shortcut {
        sequence: "Escape"
        context: Qt.WindowShortcut
        enabled: root.isFullScreen
        onActivated: root.exitFullScreen()
    }

    AuroraBackground {
        id: backgroundScene
        anchors.fill: parent
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 18

        // SIDEBAR

        GlassPanel {
            id: sidebar

            Layout.preferredWidth: 235
            Layout.minimumWidth: 215
            Layout.fillHeight: true

            backdropSource: backgroundScene
            glassTint: 0.035

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 13

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 11

                    Rectangle {
                        Layout.preferredWidth: 45
                        Layout.preferredHeight: 45
                        radius: 13

                        gradient: Gradient {
                            GradientStop { position: 0.0; color: "#65BDEB" }
                            GradientStop { position: 1.0; color: "#5A4EA3" }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "B"
                            color: "#FFFFFF"
                            font.pixelSize: 27
                            font.weight: Font.Bold
                        }
                    }

                    ColumnLayout {
                        spacing: 3

                        Text {
                            text: "BubtOps"
                            color: "#FFFFFF"
                            font.pixelSize: 21
                            font.weight: Font.Bold
                        }

                        Text {
                            text: "CAMPUS OPERATIONS"
                            color: "#E0E8F5"
                            font.pixelSize: 10
                            font.letterSpacing: 1.2
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.topMargin: 10
                    Layout.bottomMargin: 7
                    height: 1
                    color: "#36FFFFFF"
                }

                Text {
                    text: "WORKSPACE"
                    color: "#FFFFFF"
                    font.pixelSize: 11
                    font.weight: Font.Bold
                    font.letterSpacing: 1.4
                    Layout.leftMargin: 7
                }

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
                        Layout.preferredHeight: 49

                        property bool selected: root.activeSection === modelData
                        property bool hovered: navMouse.containsMouse
                        property bool pressed: navMouse.pressed

                        // Shared glass material for every navigation item.
                        GlassPanel {
                            id: navGlass
                            anchors.fill: parent
                            radius: 14
                            backdropSource: backgroundScene
                            blurAmount: 0.58

                            glassTint: navItem.selected ? 0.15
                                       : navItem.hovered ? 0.115 : 0.075

                            sheen: navItem.selected ? 1.0
                                   : navItem.hovered ? 0.92 : 0.78

                            showEdge: true

                            Behavior on glassTint {
                                NumberAnimation {
                                    duration: 170
                                    easing.type: Easing.OutCubic
                                }
                            }

                            Behavior on sheen {
                                NumberAnimation {
                                    duration: 170
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: 14
                            color: "transparent"
                            border.width: navItem.selected ? 1 : 0
                            border.color: "#9ADFFFFF"
                        }

                        Rectangle {
                            width: 3
                            height: 25
                            radius: 2
                            anchors.left: parent.left
                            anchors.leftMargin: 1
                            anchors.verticalCenter: parent.verticalCenter
                            color: "#B8EDFF"
                            visible: navItem.selected
                        }

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 15
                            anchors.verticalCenter: parent.verticalCenter
                            width: 22
                            horizontalAlignment: Text.AlignHCenter

                            text: {
                                switch (modelData) {
                                    case "Overview": return "▦"
                                    case "Asset Registry": return "◇"
                                    case "Locations": return "⌖"
                                    case "Maintenance": return "⚙"
                                    case "Reports": return "▤"
                                    case "Glass Preview": return "✧"
                                    default: return "•"
                                }
                            }

                            color: "#FFFFFF"
                            font.pixelSize: 19
                        }

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 48
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData
                            color: "#FFFFFF"
                            font.pixelSize: 14
                            font.weight: navItem.selected
                                         ? Font.DemiBold : Font.Medium
                        }

                        MouseArea {
                            id: navMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor

                            onClicked: root.activeSection = modelData
                        }

                        scale: navItem.pressed ? 0.992
                               : navItem.hovered ? 1.012 : 1.0

                        Behavior on scale {
                            NumberAnimation {
                                duration: 150
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

                GlassPanel {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 76

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
                        anchors.margins: 12
                        spacing: 7

                        RowLayout {
                            spacing: 8

                            Rectangle {
                                width: 8
                                height: 8
                                radius: 4
                                color: "#57D9A3"
                            }

                            Text {
                                text: "OFFLINE MODE"
                                color: "#FFFFFF"
                                font.pixelSize: 12
                                font.weight: Font.Bold
                                font.letterSpacing: 0.8
                            }
                        }

                        Text {
                            text: "Local database active"
                            color: "#E0EAEF"
                            font.pixelSize: 12
                        }
                    }
                }

                Text {
                    text: "BubtOps  •  Version 1.0"
                    color: "#E0E8F5"
                    font.pixelSize: 11
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 5
                }
            }
        }

        // PAGE CONTAINER

        StackLayout {
            id: pageStack

            Layout.fillWidth: true
            Layout.fillHeight: true

            currentIndex:
                root.activeSection === "Asset Registry" ? 1
                : root.activeSection === "Glass Preview" ? 2
                : root.activeSection === "Needs Attention" ? 3
                : root.activeSection === "Maintenance" ? 4
                : 0

            // OVERVIEW PAGE

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 19

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 72

                    ColumnLayout {
                        spacing: 5

                        Text {
                            text: "Overview"
                            color: "#FFFFFF"
                            font.pixelSize: 29
                            font.weight: Font.Bold
                        }

                        Text {
                            text: "Your campus assets at a glance."
                            color: "#E0E8F5"
                            font.pixelSize: 14
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        id: dashboardClockCard
                        Layout.preferredWidth: 205
                        Layout.minimumWidth: 195
                        Layout.preferredHeight: 56
                        Layout.alignment: Qt.AlignVCenter
                        radius: 13
                        color: "#26FFFFFF"
                        border.width: 1
                        border.color: "#48FFFFFF"
                        visible: true

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 10
                            anchors.topMargin: 5
                            anchors.bottomMargin: 5
                            spacing: 1

                            Text {
                                text: root.clockTime
                                color: "#FFFFFF"
                                font.pixelSize: 19
                                font.weight: Font.DemiBold
                                font.family: "Consolas"
                            }

                            Text {
                                text: root.clockDate
                                color: "#E1EAF6"
                                font.pixelSize: 10
                                elide: Text.ElideRight
                            }
                        }
                    }

                    Rectangle {
                        id: fullScreenButton
                        Layout.preferredWidth: 43
                        Layout.preferredHeight: 43
                        radius: 12
                        color: fullScreenMouse.containsMouse
                               ? "#35FFFFFF" : "#18FFFFFF"
                        border.width: 1
                        border.color: "#55FFFFFF"

                        Text {
                            anchors.centerIn: parent
                            text: root.isFullScreen ? "⧉" : "⛶"
                            color: "#FFFFFF"
                            font.pixelSize: 23
                        }

                        MouseArea {
                            id: fullScreenMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.toggleFullScreen()
                        }
                    }
                }

                // LIVE SUMMARY CARDS

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 13

                    Repeater {
                        // Use an integer model so each displayed value remains
                        // a live binding when dashboardData changes.
                        model: 4

                        delegate: GlassPanel {
                            id: summaryCard

                            Layout.fillWidth: true
                            Layout.preferredHeight: 142

                            property string cardTitle: index === 0 ? "REGISTERED ASSETS"
                                                        : index === 1 ? "IN SERVICE"
                                                        : index === 2 ? "NEEDS ATTENTION"
                                                        : "TOTAL MAINTENANCE COST"
                            property string cardValue: index === 0 ? root.dashboardCount("totalAssets")
                                                        : index === 1 ? root.dashboardCount("inService")
                                                        : index === 2 ? root.dashboardCount("needsAttention")
                                                        : root.dashboardMoney()
                            property string cardNote: index === 0 ? "All registered campus assets"
                                                       : index === 1 ? "Currently operational"
                                                       : index === 2 ? "Maintenance or inspection"
                                                       : Number(root.dashboardData.maintenanceRecordCount || 0) === 0
                                                         ? "No maintenance expenses recorded yet"
                                                         : "Total of " + root.dashboardCount("maintenanceRecordCount") + " maintenance records"
                            property color cardAccent: index === 0 ? "#83CFFF"
                                                       : index === 1 ? "#68D9B0"
                                                       : index === 2 ? "#F2B76F"
                                                       : "#B9A2FF"

                            backdropSource: backgroundScene
                            glassTint: 0.13

                            Rectangle {
                                width: 3
                                height: 48
                                radius: 2
                                color: summaryCard.cardAccent
                                anchors.left: parent.left
                                anchors.leftMargin: 15
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 27
                                anchors.rightMargin: 12
                                anchors.topMargin: 17
                                anchors.bottomMargin: 14
                                spacing: 7

                                Text {
                                    Layout.fillWidth: true
                                    text: summaryCard.cardTitle
                                    color: "#FFFFFF"
                                    font.pixelSize: 11
                                    font.weight: Font.Bold
                                    font.letterSpacing: 0.5
                                    elide: Text.ElideRight
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: summaryCard.cardValue
                                    color: "#FFFFFF"
                                    font.pixelSize: index === 3 ? 24 : 30
                                    font.weight: Font.Bold
                                    elide: Text.ElideRight
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: index === 2 ? "Click to view repair / service list" : summaryCard.cardNote
                                    color: "#E0E8F5"
                                    font.pixelSize: 11
                                    elide: Text.ElideRight
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                z: 20
                                enabled: index === 2 || index === 3
                                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                onClicked: {
                                    if (index === 2)
                                        root.openAttentionAssets()
                                    else
                                        root.activeSection = "Maintenance"
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

                    GlassPanel {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.minimumWidth: 250

                        backdropSource: backgroundScene
                        glassTint: 0.14

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 19
                            spacing: 12

                            RowLayout {
                                Layout.fillWidth: true

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 3

                                    Text {
                                        text: "Asset condition"
                                        color: "#FFFFFF"
                                        font.pixelSize: 19
                                        font.weight: Font.DemiBold
                                    }

                                    Text {
                                        text: "Live distribution from SQLite"
                                        color: "#E0E8F5"
                                        font.pixelSize: 12
                                    }
                                }

                                Rectangle {
                                    Layout.preferredWidth: 73
                                    Layout.preferredHeight: 27
                                    radius: 13
                                    color: "#1F68D9A8"
                                    border.width: 1
                                    border.color: "#4568D9A8"

                                    Text {
                                        anchors.centerIn: parent
                                        text: "LIVE DATA"
                                        color: "#A5F0D2"
                                        font.pixelSize: 9
                                        font.weight: Font.Bold
                                    }
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                Layout.topMargin: 3
                                spacing: 12

                                ColumnLayout {
                                    spacing: 3

                                    Text {
                                        text: root.dashboardData.success
                                              ? root.dashboardPercent("inService")
                                              : "—"
                                        color: "#FFFFFF"
                                        font.pixelSize: 34
                                        font.weight: Font.Bold
                                    }

                                    Text {
                                        text: "Operational rate"
                                        color: "#D7E2F1"
                                        font.pixelSize: 12
                                    }
                                }

                                Item { Layout.fillWidth: true }

                                ColumnLayout {
                                    spacing: 3
                                    Layout.alignment: Qt.AlignVCenter | Qt.AlignRight

                                    Text {
                                        text: root.dashboardData.success
                                              ? root.dashboardCount("inService") + " / "
                                                + root.dashboardCount("totalAssets")
                                              : "—"
                                        color: "#FFFFFF"
                                        font.pixelSize: 17
                                        font.weight: Font.DemiBold
                                        horizontalAlignment: Text.AlignRight
                                    }

                                    Text {
                                        text: "In service"
                                        color: "#D7E2F1"
                                        font.pixelSize: 11
                                        horizontalAlignment: Text.AlignRight
                                    }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                height: 1
                                color: "#45FFFFFF"
                            }

                            // GOOD CONDITION
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 5

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { text: "Good"; color: "#FFFFFF"; font.pixelSize: 12 }
                                    Item { Layout.fillWidth: true }
                                    Text {
                                        text: root.dashboardCount("goodCondition") + "  ·  "
                                              + root.dashboardPercent("goodCondition")
                                        color: "#D7E2F1"
                                        Layout.preferredWidth: 104
                                        horizontalAlignment: Text.AlignRight
                                        font.pixelSize: 12
                                        font.weight: Font.DemiBold
                                    }
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 8
                                    radius: 4
                                    color: "#293A4B5B"
                                    clip: true
                                    Rectangle {
                                        width: parent.width * root.conditionRatio("goodCondition")
                                        height: parent.height
                                        radius: 4
                                        color: "#68D9B0"
                                    }
                                }
                            }

                            // FAIR CONDITION
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 5

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { text: "Fair"; color: "#FFFFFF"; font.pixelSize: 12 }
                                    Item { Layout.fillWidth: true }
                                    Text {
                                        text: root.dashboardCount("fairCondition") + "  ·  "
                                              + root.dashboardPercent("fairCondition")
                                        color: "#D7E2F1"
                                        Layout.preferredWidth: 104
                                        horizontalAlignment: Text.AlignRight
                                        font.pixelSize: 12
                                        font.weight: Font.DemiBold
                                    }
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 8
                                    radius: 4
                                    color: "#293A4B5B"
                                    clip: true
                                    Rectangle {
                                        width: parent.width * root.conditionRatio("fairCondition")
                                        height: parent.height
                                        radius: 4
                                        color: "#E7B66E"
                                    }
                                }
                            }

                            // POOR / DAMAGED CONDITION
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 5

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { text: "Poor / damaged"; color: "#FFFFFF"; font.pixelSize: 12 }
                                    Item { Layout.fillWidth: true }
                                    Text {
                                        text: root.dashboardCount("attentionCondition") + "  ·  "
                                              + root.dashboardPercent("attentionCondition")
                                        color: "#D7E2F1"
                                        Layout.preferredWidth: 104
                                        horizontalAlignment: Text.AlignRight
                                        font.pixelSize: 12
                                        font.weight: Font.DemiBold
                                    }
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 8
                                    radius: 4
                                    color: "#293A4B5B"
                                    clip: true
                                    Rectangle {
                                        width: parent.width * root.conditionRatio("attentionCondition")
                                        height: parent.height
                                        radius: 4
                                        color: "#E17E91"
                                    }
                                }
                            }

                            // OTHER / UNCLASSIFIED CONDITION
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 5

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { text: "Other / unclassified"; color: "#FFFFFF"; font.pixelSize: 12 }
                                    Item { Layout.fillWidth: true }
                                    Text {
                                        text: root.dashboardCount("otherCondition") + "  ·  "
                                              + root.dashboardPercent("otherCondition")
                                        color: "#D7E2F1"
                                        Layout.preferredWidth: 104
                                        horizontalAlignment: Text.AlignRight
                                        font.pixelSize: 12
                                        font.weight: Font.DemiBold
                                    }
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 8
                                    radius: 4
                                    color: "#293A4B5B"
                                    clip: true
                                    Rectangle {
                                        width: parent.width * root.conditionRatio("otherCondition")
                                        height: parent.height
                                        radius: 4
                                        color: "#83CFFF"
                                    }
                                }
                            }

                            Item { Layout.fillHeight: true }

                            Text {
                                text: root.dashboardData.success
                                      ? "Based on " + root.dashboardCount("totalAssets") + " registered assets"
                                      : "Dashboard data unavailable"
                                color: "#D0D9E8"
                                font.pixelSize: 10
                            }
                        }
                    }

                    // ALL ASSETS NEEDING ATTENTION - INDEPENDENT SCROLL LIST
                    GlassPanel {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.minimumWidth: 300
                        backdropSource: backgroundScene
                        glassTint: 0.14

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 19
                            spacing: 11

                            RowLayout {
                                Layout.fillWidth: true
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 3
                                    Text {
                                        text: "Assets needing attention"
                                        color: "#FFFFFF"
                                        font.pixelSize: 19
                                        font.weight: Font.DemiBold
                                    }
                                    Text {
                                        text: "All assets flagged by status or condition"
                                        color: "#E0E8F5"
                                        font.pixelSize: 11
                                        elide: Text.ElideRight
                                    }
                                }
                                Text {
                                    text: root.dashboardData.success
                                          ? root.dashboardCount("needsAttention") + " ITEMS"
                                          : "—"
                                    color: "#FFFFFF"
                                    font.pixelSize: 10
                                    font.weight: Font.Bold
                                    font.letterSpacing: 0.5
                                }
                                Text {
                                    visible: root.dashboardData.success
                                             && Number(root.dashboardData.needsAttention || 0) > 0
                                    text: "VIEW ALL  ›"
                                    color: "#A9DFFF"
                                    font.pixelSize: 9
                                    font.weight: Font.Bold
                                    font.letterSpacing: 0.35
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.openAttentionAssets()
                                    }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                height: 1
                                color: "#45FFFFFF"
                            }

                            Item {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                clip: true

                                ListView {
                                    id: dashboardAttentionList
                                    anchors.fill: parent
                                    clip: true
                                    spacing: 8
                                    boundsBehavior: Flickable.StopAtBounds
                                    model: root.dashboardData.success
                                           ? (root.dashboardData.attentionAssets || [])
                                           : []

                                    ScrollBar.vertical: ScrollBar {
                                        active: true
                                        policy: ScrollBar.AsNeeded
                                    }

                                    delegate: Rectangle {
                                        required property var modelData
                                        width: dashboardAttentionList.width - 8
                                        height: 76
                                        radius: 11
                                        color: attentionRowMouse.containsMouse
                                               ? "#2CFFFFFF" : "#18FFFFFF"
                                        border.width: 1
                                        border.color: attentionRowMouse.containsMouse
                                                       ? "#55FFFFFF" : "#22FFFFFF"

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 11
                                            anchors.rightMargin: 11
                                            spacing: 10

                                            Rectangle {
                                                Layout.preferredWidth: 35
                                                Layout.preferredHeight: 35
                                                radius: 10
                                                color: "#263D6490"
                                                Text {
                                                    anchors.centerIn: parent
                                                    text: "⚙"
                                                    color: root.maintenanceStatusColor(modelData.status)
                                                    font.pixelSize: 17
                                                }
                                            }

                                            ColumnLayout {
                                                Layout.fillWidth: true
                                                spacing: 2
                                                Text {
                                                    Layout.fillWidth: true
                                                    text: modelData.asset_name || "Unnamed asset"
                                                    color: "#FFFFFF"
                                                    font.pixelSize: 13
                                                    font.weight: Font.DemiBold
                                                    elide: Text.ElideRight
                                                }
                                                Text {
                                                    Layout.fillWidth: true
                                                    text: "Condition: " + (modelData.asset_condition || "Unknown")
                                                          + "  ·  " + (modelData.category || "Uncategorized")
                                                    color: "#E0E8F5"
                                                    font.pixelSize: 10
                                                    elide: Text.ElideRight
                                                }
                                                Text {
                                                    Layout.fillWidth: true
                                                    text: (modelData.asset_code || "—")
                                                          + "  ·  " + (modelData.building || "Not assigned")
                                                    color: "#AFC0D5"
                                                    font.pixelSize: 9
                                                    elide: Text.ElideRight
                                                }
                                            }

                                            Rectangle {
                                                Layout.preferredWidth: 105
                                                Layout.preferredHeight: 26
                                                radius: 13
                                                color: "#20FFFFFF"
                                                border.width: 1
                                                border.color: "#35FFFFFF"
                                                Text {
                                                    anchors.centerIn: parent
                                                    width: parent.width - 10
                                                    text: modelData.status || "Needs review"
                                                    color: root.maintenanceStatusColor(modelData.status)
                                                    font.pixelSize: 9
                                                    font.weight: Font.DemiBold
                                                    horizontalAlignment: Text.AlignHCenter
                                                    elide: Text.ElideRight
                                                }
                                            }
                                        }

                                        MouseArea {
                                            id: attentionRowMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.openAttentionAssets(Number(modelData.asset_id || 0))
                                        }
                                    }
                                }

                                Text {
                                    anchors.centerIn: parent
                                    width: parent.width * 0.78
                                    visible: root.dashboardData.success
                                             && (!root.dashboardData.attentionAssets
                                                 || root.dashboardData.attentionAssets.length === 0)
                                    text: "No assets currently need attention."
                                    color: "#D0D9E8"
                                    font.pixelSize: 13
                                    horizontalAlignment: Text.AlignHCenter
                                    wrapMode: Text.WordWrap
                                }

                                Text {
                                    anchors.centerIn: parent
                                    width: parent.width * 0.88
                                    visible: !root.dashboardData.success
                                    text: "Unable to load dashboard records. Check the Python console for the database error."
                                    color: "#F0B4BC"
                                    font.pixelSize: 11
                                    wrapMode: Text.WordWrap
                                    horizontalAlignment: Text.AlignHCenter
                                }
                            }
                        }
                    }

                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 22

                    Text {
                        text: "BubtOps  |  Campus Asset Management"
                        color: "#D0D9E8"
                        font.pixelSize: 11
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: root.dashboardData.success ? "Live SQLite data · refreshes after asset and maintenance changes" : "Dashboard data unavailable · check database connection"
                        color: "#D0D9E8"
                        font.pixelSize: 11
                    }
                }
            }

            // ASSET REGISTRY PAGE

            AssetRegistry {
                id: assetRegistryPage

                Layout.fillWidth: true
                Layout.fillHeight: true

                backend: assetBackend
                backdropSource: backgroundScene
            }

            // GLASS PREVIEW PAGE

            ColumnLayout {
                id: glassPreviewPage

                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 19

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 72

                    ColumnLayout {
                        spacing: 5

                        Text {
                            text: "Glass Preview"
                            color: "#FFFFFF"
                            font.pixelSize: 29
                            font.weight: Font.Bold
                        }

                        Text {
                            text: "Test the new glass components against the Aurora background."
                            color: "#E0E8F5"
                            font.pixelSize: 14
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: "VISUAL TEST"
                        color: "#FFFFFF"
                        font.pixelSize: 11
                        font.weight: Font.Bold
                        font.letterSpacing: 1.2
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 15

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
                            spacing: 15

                            Text {
                                text: "GLASS SURFACE"
                                color: "#FFFFFF"
                                font.pixelSize: 12
                                font.weight: Font.Bold
                                font.letterSpacing: 1.2
                            }

                            Text {
                                text: "A clearer look\nat layered glass."
                                color: "#FFFFFF"
                                font.pixelSize: 30
                                font.weight: Font.DemiBold
                            }

                            Text {
                                Layout.fillWidth: true
                                text: "This panel samples the Aurora background and combines it with a translucent tint, soft sheen and optical edge."
                                color: "#E0E8F5"
                                font.pixelSize: 14
                                wrapMode: Text.WordWrap
                            }

                            Item { Layout.fillHeight: true }

                            Rectangle {
                                Layout.fillWidth: true
                                height: 1
                                color: "#45FFFFFF"
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 10

                                ColumnLayout {
                                    spacing: 4

                                    Text {
                                        text: "BACKGROUND"
                                        color: "#FFFFFF"
                                        font.pixelSize: 11
                                        font.weight: Font.Bold
                                        font.letterSpacing: 0.8
                                    }

                                    Text {
                                        text: "Live Aurora sample"
                                        color: "#FFFFFF"
                                        font.pixelSize: 13
                                    }
                                }

                                Item { Layout.fillWidth: true }

                                Text {
                                    text: "01 / 03"
                                    color: "#FFFFFF"
                                    font.pixelSize: 12
                                    font.weight: Font.DemiBold
                                }
                            }
                        }
                    }

                    GlassSurface {
                        id: glassControlsPreview

                        Layout.preferredWidth: 310
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
                            spacing: 14

                            Text {
                                text: "INPUT COMPONENTS"
                                color: "#FFFFFF"
                                font.pixelSize: 12
                                font.weight: Font.Bold
                                font.letterSpacing: 1.2
                            }

                            Text {
                                text: "GlassField"
                                color: "#FFFFFF"
                                font.pixelSize: 16
                                font.weight: Font.DemiBold
                            }

                            Text {
                                text: "Search field appearance"
                                color: "#E0E8F5"
                                font.pixelSize: 13
                            }

                            GlassField {
                                id: previewGlassField
                                Layout.fillWidth: true
                                placeholderText: "Search campus assets..."
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                height: 1
                                color: "#45FFFFFF"
                                Layout.topMargin: 5
                                Layout.bottomMargin: 3
                            }

                            Text {
                                text: "GlassCombo"
                                color: "#FFFFFF"
                                font.pixelSize: 16
                                font.weight: Font.DemiBold
                            }

                            Text {
                                text: "Dropdown appearance"
                                color: "#E0E8F5"
                                font.pixelSize: 13
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

                            Item { Layout.fillHeight: true }

                            Text {
                                Layout.fillWidth: true
                                text: "These controls are for visual testing only."
                                color: "#D0D9E8"
                                font.pixelSize: 12
                                wrapMode: Text.WordWrap
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 36
                    spacing: 10

                    Text {
                        text: "CHECK:"
                        color: "#FFFFFF"
                        font.pixelSize: 11
                        font.weight: Font.Bold
                    }

                    Text {
                        text: "Transparency  •  Background visibility  •  Blur  •  Edge reflections"
                        color: "#E0E8F5"
                        font.pixelSize: 12
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: "No database changes"
                        color: "#FFFFFF"
                        font.pixelSize: 12
                    }
                }
            }


            // NEEDS ATTENTION PAGE
            NeedsAttention {
                id: attentionPage

                Layout.fillWidth: true
                Layout.fillHeight: true

                backend: assetBackend
                backdropSource: backgroundScene

                onBackRequested: root.activeSection = "Overview"
            }

            MaintenancePage {
                id: maintenancePage

                Layout.fillWidth: true
                Layout.fillHeight: true

                backend: assetBackend
                backdropSource: backgroundScene

                onBackRequested: root.activeSection = "Overview"
            }

        }
    }
}