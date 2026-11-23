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
    color: assetBackend.themeColor("#0A1020", assetBackend.theme)
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

        var dateValue = now.getFullYear() + "-" + twoDigits(now.getMonth() + 1) + "-" + twoDigits(now.getDate())
        clockDate = assetBackend.formatDate(dateValue)
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
        var startup = assetBackend.getSettings().default_dashboard || "Overview"
        root.activeSection = startup === "Asset Registry" ? "Asset Registry" : "Overview"
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
                id: sidebarContent
                anchors.fill: parent
                anchors.margins: 18
                spacing: Math.max(5, Math.min(9, height * 0.012))

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 11

                    Rectangle {
                        Layout.preferredWidth: 45
                        Layout.preferredHeight: (45 * assetBackend.fontScale)
                        radius: 13

                        gradient: Gradient {
                            GradientStop { position: 0.0; color: assetBackend.themeColor("#65BDEB", assetBackend.theme) }
                            GradientStop { position: 1.0; color: assetBackend.themeColor("#5A4EA3", assetBackend.theme) }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: assetBackend.translateText("B", assetBackend.language)
                            color: assetBackend.themeColor("#FFFFFF", assetBackend.theme)
                            font.pixelSize: 27 * assetBackend.fontScale
                            font.weight: Font.Bold
                        }
                    }

                    ColumnLayout {
                        spacing: 3

                        Text {
                            text: assetBackend.applicationName
                            color: assetBackend.themeColor("#FFFFFF", assetBackend.theme)
                            font.pixelSize: 21 * assetBackend.fontScale
                            font.weight: Font.Bold
                        }

                        Text {
                            text: assetBackend.translateText("CAMPUS OPERATIONS", assetBackend.language)
                            color: assetBackend.themeColor("#E0E8F5", assetBackend.theme)
                            font.pixelSize: 10 * assetBackend.fontScale
                            font.letterSpacing: 1.2
                        }

                        Text {
                            text: assetBackend.adminName
                            color: assetBackend.themeColor("#FFFFFF", assetBackend.theme)
                            font.pixelSize: 11 * assetBackend.fontScale
                            font.weight: Font.DemiBold
                            Layout.topMargin: 3
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.topMargin: 10
                    Layout.bottomMargin: 7
                    height: 1
                    color: assetBackend.themeColor("#36FFFFFF", assetBackend.theme)
                }

                Text {
                    text: assetBackend.translateText("WORKSPACE", assetBackend.language)
                    color: assetBackend.themeColor("#FFFFFF", assetBackend.theme)
                    font.pixelSize: 11 * assetBackend.fontScale
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
                        "Glass Preview",
                        "Settings",
                        "About Application"
                    ]

                    delegate: Item {
                        id: navItem

                        Layout.fillWidth: true
                        Layout.preferredHeight: Math.max(
                            30,
                            Math.min(49, (sidebarContent.height - 250) / 8)
                        )

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
                            border.color: assetBackend.themeColor("#9ADFFFFF", assetBackend.theme)
                        }

                        Rectangle {
                            width: 3
                            height: (25 * assetBackend.fontScale)
                            radius: 2
                            anchors.left: parent.left
                            anchors.leftMargin: 1
                            anchors.verticalCenter: parent.verticalCenter
                            color: assetBackend.themeColor("#B8EDFF", assetBackend.theme)
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
                                    case "Settings": return "⚙"
                                    case "About Application": return "ⓘ"
                                    default: return "•"
                                }
                            }

                            color: assetBackend.themeColor("#FFFFFF", assetBackend.theme)
                            font.pixelSize: 19 * assetBackend.fontScale
                        }

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 48
                            anchors.verticalCenter: parent.verticalCenter
                            text: assetBackend.translateText(modelData, assetBackend.language)
                            color: assetBackend.themeColor("#FFFFFF", assetBackend.theme)
                            font.pixelSize: 14 * assetBackend.fontScale
                            font.weight: navItem.selected
                                         ? Font.DemiBold : Font.Medium
                        }

                        MouseArea {
                            id: navMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor

                            onClicked: {
                                if (modelData === "Settings")
                                    settingsPage.resetToGeneralSettings()
                                root.activeSection = modelData
                            }
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
                    color: assetBackend.themeColor("#30FFFFFF", assetBackend.theme)
                }

                GlassPanel {
                    Layout.fillWidth: true
                    Layout.preferredHeight: (66 * assetBackend.fontScale)

                    radius: 12
                    backdropSource: backgroundScene
                    glassTint: 0.045

                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        color: assetBackend.themeColor("#103DCC9C", assetBackend.theme)
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 4

                        RowLayout {
                            spacing: 8

                            Rectangle {
                                width: 8
                                height: 8
                                radius: 4
                                color: assetBackend.themeColor("#57D9A3", assetBackend.theme)
                            }

                            Text {
                                text: assetBackend.translateText("OFFLINE MODE", assetBackend.language)
                                color: assetBackend.themeColor("#FFFFFF", assetBackend.theme)
                                font.pixelSize: 12 * assetBackend.fontScale
                                font.weight: Font.Bold
                                font.letterSpacing: 0.8
                            }
                        }

                        Text {
                            text: assetBackend.translateText("Local database active", assetBackend.language)
                            color: assetBackend.themeColor("#E0EAEF", assetBackend.theme)
                            font.pixelSize: 12 * assetBackend.fontScale
                        }
                    }
                }

                Text {
                    text: assetBackend.applicationName + "  •  Version 1.0"
                    color: assetBackend.themeColor("#E0E8F5", assetBackend.theme)
                    font.pixelSize: 11 * assetBackend.fontScale
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
                : root.activeSection === "Settings" ? 5
                : root.activeSection === "About Application" ? 6
                : 0

            // OVERVIEW PAGE

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 19

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: (72 * assetBackend.fontScale)

                    ColumnLayout {
                        spacing: 5

                        Text {
                            text: assetBackend.translateText("Overview", assetBackend.language)
                            color: assetBackend.themeColor("#FFFFFF", assetBackend.theme)
                            font.pixelSize: 29 * assetBackend.fontScale
                            font.weight: Font.Bold
                        }

                        Text {
                            text: assetBackend.translateText("Your campus assets at a glance.", assetBackend.language)
                            color: assetBackend.themeColor("#E0E8F5", assetBackend.theme)
                            font.pixelSize: 14 * assetBackend.fontScale
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        id: dashboardClockCard
                        Layout.preferredWidth: 205
                        Layout.minimumWidth: 195
                        Layout.preferredHeight: (56 * assetBackend.fontScale)
                        Layout.alignment: Qt.AlignVCenter
                        radius: 13
                        color: assetBackend.themeColor("#26FFFFFF", assetBackend.theme)
                        border.width: 1
                        border.color: assetBackend.themeColor("#48FFFFFF", assetBackend.theme)
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
                                color: assetBackend.themeColor("#FFFFFF", assetBackend.theme)
                                font.pixelSize: 19 * assetBackend.fontScale
                                font.weight: Font.DemiBold
                                font.family: "Consolas"
                            }

                            Text {
                                text: root.clockDate
                                color: assetBackend.themeColor("#E1EAF6", assetBackend.theme)
                                font.pixelSize: 10 * assetBackend.fontScale
                                elide: Text.ElideRight
                            }
                        }
                    }

                    Rectangle {
                        id: fullScreenButton
                        Layout.preferredWidth: 43
                        Layout.preferredHeight: (43 * assetBackend.fontScale)
                        radius: 12
                        color: fullScreenMouse.containsMouse
                               ? "#35FFFFFF" : "#18FFFFFF"
                        border.width: 1
                        border.color: assetBackend.themeColor("#55FFFFFF", assetBackend.theme)

                        Text {
                            anchors.centerIn: parent
                            text: root.isFullScreen ? "⧉" : "⛶"
                            color: assetBackend.themeColor("#FFFFFF", assetBackend.theme)
                            font.pixelSize: 23 * assetBackend.fontScale
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
                            Layout.preferredHeight: (142 * assetBackend.fontScale)

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
                                height: (48 * assetBackend.fontScale)
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
                                    color: assetBackend.themeColor("#FFFFFF", assetBackend.theme)
                                    font.pixelSize: 11 * assetBackend.fontScale
                                    font.weight: Font.Bold
                                    font.letterSpacing: 0.5
                                    elide: Text.ElideRight
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: summaryCard.cardValue
                                    color: assetBackend.themeColor("#FFFFFF", assetBackend.theme)
                                    font.pixelSize: index === 3 ? 24 : 30
                                    font.weight: Font.Bold
                                    elide: Text.ElideRight
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: index === 2 ? "Click to view repair / service list" : summaryCard.cardNote
                                    color: assetBackend.themeColor("#E0E8F5", assetBackend.theme)
                                    font.pixelSize: 11 * assetBackend.fontScale
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
                                        text: assetBackend.translateText("Asset condition", assetBackend.language)
                                        color: assetBackend.themeColor("#FFFFFF", assetBackend.theme)
                                        font.pixelSize: 19 * assetBackend.fontScale
                                        font.weight: Font.DemiBold
                                    }

                                    Text {
                                        text: assetBackend.translateText("Live distribution from SQLite", assetBackend.language)
                                        color: assetBackend.themeColor("#E0E8F5", assetBackend.theme)
                                        font.pixelSize: 12 * assetBackend.fontScale
                                    }
                                }

                                Rectangle {
                                    Layout.preferredWidth: 73
                                    Layout.preferredHeight: (27 * assetBackend.fontScale)
                                    radius: 13
                                    color: assetBackend.themeColor("#1F68D9A8", assetBackend.theme)
                                    border.width: 1
                                    border.color: assetBackend.themeColor("#4568D9A8", assetBackend.theme)

                                    Text {
                                        anchors.centerIn: parent
                                        text: assetBackend.translateText("LIVE DATA", assetBackend.language)
                                        color: assetBackend.themeColor("#A5F0D2", assetBackend.theme)
                                        font.pixelSize: 9 * assetBackend.fontScale
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
                                        color: assetBackend.themeColor("#FFFFFF", assetBackend.theme)
                                        font.pixelSize: 34 * assetBackend.fontScale
                                        font.weight: Font.Bold
                                    }

                                    Text {
                                        text: assetBackend.translateText("Operational rate", assetBackend.language)
                                        color: assetBackend.themeColor("#D7E2F1", assetBackend.theme)
                                        font.pixelSize: 12 * assetBackend.fontScale
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
                                        color: assetBackend.themeColor("#FFFFFF", assetBackend.theme)
                                        font.pixelSize: 17 * assetBackend.fontScale
                                        font.weight: Font.DemiBold
                                        horizontalAlignment: Text.AlignRight
                                    }

                                    Text {
                                        text: assetBackend.translateText("In service", assetBackend.language)
                                        color: assetBackend.themeColor("#D7E2F1", assetBackend.theme)
                                        font.pixelSize: 11 * assetBackend.fontScale
                                        horizontalAlignment: Text.AlignRight
                                    }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                height: 1
                                color: assetBackend.themeColor("#45FFFFFF", assetBackend.theme)
                            }

                            // GOOD CONDITION
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 5

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { text: assetBackend.translateText("Good", assetBackend.language); color: assetBackend.themeColor("#FFFFFF", assetBackend.theme); font.pixelSize: 12 * assetBackend.fontScale }
                                    Item { Layout.fillWidth: true }
                                    Text {
                                        text: root.dashboardCount("goodCondition") + "  ·  "
                                              + root.dashboardPercent("goodCondition")
                                        color: assetBackend.themeColor("#D7E2F1", assetBackend.theme)
                                        Layout.preferredWidth: 104
                                        horizontalAlignment: Text.AlignRight
                                        font.pixelSize: 12 * assetBackend.fontScale
                                        font.weight: Font.DemiBold
                                    }
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 8
                                    radius: 4
                                    color: assetBackend.themeColor("#293A4B5B", assetBackend.theme)
                                    clip: true
                                    Rectangle {
                                        width: parent.width * root.conditionRatio("goodCondition")
                                        height: parent.height
                                        radius: 4
                                        color: assetBackend.themeColor("#68D9B0", assetBackend.theme)
                                    }
                                }
                            }

                            // FAIR CONDITION
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 5

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { text: assetBackend.translateText("Fair", assetBackend.language); color: assetBackend.themeColor("#FFFFFF", assetBackend.theme); font.pixelSize: 12 * assetBackend.fontScale }
                                    Item { Layout.fillWidth: true }
                                    Text {
                                        text: root.dashboardCount("fairCondition") + "  ·  "
                                              + root.dashboardPercent("fairCondition")
                                        color: assetBackend.themeColor("#D7E2F1", assetBackend.theme)
                                        Layout.preferredWidth: 104
                                        horizontalAlignment: Text.AlignRight
                                        font.pixelSize: 12 * assetBackend.fontScale
                                        font.weight: Font.DemiBold
                                    }
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 8
                                    radius: 4
                                    color: assetBackend.themeColor("#293A4B5B", assetBackend.theme)
                                    clip: true
                                    Rectangle {
                                        width: parent.width * root.conditionRatio("fairCondition")
                                        height: parent.height
                                        radius: 4
                                        color: assetBackend.themeColor("#E7B66E", assetBackend.theme)
                                    }
                                }
                            }

                            // POOR / DAMAGED CONDITION
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 5

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { text: assetBackend.translateText("Poor / damaged", assetBackend.language); color: assetBackend.themeColor("#FFFFFF", assetBackend.theme); font.pixelSize: 12 * assetBackend.fontScale }
                                    Item { Layout.fillWidth: true }
                                    Text {
                                        text: root.dashboardCount("attentionCondition") + "  ·  "
                                              + root.dashboardPercent("attentionCondition")
                                        color: assetBackend.themeColor("#D7E2F1", assetBackend.theme)
                                        Layout.preferredWidth: 104
                                        horizontalAlignment: Text.AlignRight
                                        font.pixelSize: 12 * assetBackend.fontScale
                                        font.weight: Font.DemiBold
                                    }
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 8
                                    radius: 4
                                    color: assetBackend.themeColor("#293A4B5B", assetBackend.theme)
                                    clip: true
                                    Rectangle {
                                        width: parent.width * root.conditionRatio("attentionCondition")
                                        height: parent.height
                                        radius: 4
                                        color: assetBackend.themeColor("#E17E91", assetBackend.theme)
                                    }
                                }
                            }

                            // OTHER / UNCLASSIFIED CONDITION
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 5

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { text: assetBackend.translateText("Other / unclassified", assetBackend.language); color: assetBackend.themeColor("#FFFFFF", assetBackend.theme); font.pixelSize: 12 * assetBackend.fontScale }
                                    Item { Layout.fillWidth: true }
                                    Text {
                                        text: root.dashboardCount("otherCondition") + "  ·  "
                                              + root.dashboardPercent("otherCondition")
                                        color: assetBackend.themeColor("#D7E2F1", assetBackend.theme)
                                        Layout.preferredWidth: 104
                                        horizontalAlignment: Text.AlignRight
                                        font.pixelSize: 12 * assetBackend.fontScale
                                        font.weight: Font.DemiBold
                                    }
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 8
                                    radius: 4
                                    color: assetBackend.themeColor("#293A4B5B", assetBackend.theme)
                                    clip: true
                                    Rectangle {
                                        width: parent.width * root.conditionRatio("otherCondition")
                                        height: parent.height
                                        radius: 4
                                        color: assetBackend.themeColor("#83CFFF", assetBackend.theme)
                                    }
                                }
                            }

                            Item { Layout.fillHeight: true }

                            Text {
                                text: root.dashboardData.success
                                      ? "Based on " + root.dashboardCount("totalAssets") + " registered assets"
                                      : "Dashboard data unavailable"
                                color: assetBackend.themeColor("#D0D9E8", assetBackend.theme)
                                font.pixelSize: 10 * assetBackend.fontScale
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
                                        text: assetBackend.translateText("Assets needing attention", assetBackend.language)
                                        color: assetBackend.themeColor("#FFFFFF", assetBackend.theme)
                                        font.pixelSize: 19 * assetBackend.fontScale
                                        font.weight: Font.DemiBold
                                    }
                                    Text {
                                        text: assetBackend.translateText("All assets flagged by status or condition", assetBackend.language)
                                        color: assetBackend.themeColor("#E0E8F5", assetBackend.theme)
                                        font.pixelSize: 11 * assetBackend.fontScale
                                        elide: Text.ElideRight
                                    }
                                }
                                Text {
                                    text: root.dashboardData.success
                                          ? root.dashboardCount("needsAttention") + " ITEMS"
                                          : "—"
                                    color: assetBackend.themeColor("#FFFFFF", assetBackend.theme)
                                    font.pixelSize: 10 * assetBackend.fontScale
                                    font.weight: Font.Bold
                                    font.letterSpacing: 0.5
                                }
                                Text {
                                    visible: root.dashboardData.success
                                             && Number(root.dashboardData.needsAttention || 0) > 0
                                    text: assetBackend.translateText("VIEW ALL  ›", assetBackend.language)
                                    color: assetBackend.themeColor("#A9DFFF", assetBackend.theme)
                                    font.pixelSize: 9 * assetBackend.fontScale
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
                                color: assetBackend.themeColor("#45FFFFFF", assetBackend.theme)
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
                                        height: (76 * assetBackend.fontScale)
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
                                                Layout.preferredHeight: (35 * assetBackend.fontScale)
                                                radius: 10
                                                color: assetBackend.themeColor("#263D6490", assetBackend.theme)
                                                Text {
                                                    anchors.centerIn: parent
                                                    text: assetBackend.translateText("⚙", assetBackend.language)
                                                    color: root.maintenanceStatusColor(modelData.status)
                                                    font.pixelSize: 17 * assetBackend.fontScale
                                                }
                                            }

                                            ColumnLayout {
                                                Layout.fillWidth: true
                                                spacing: 2
                                                Text {
                                                    Layout.fillWidth: true
                                                    text: modelData.asset_name || "Unnamed asset"
                                                    color: assetBackend.themeColor("#FFFFFF", assetBackend.theme)
                                                    font.pixelSize: 13 * assetBackend.fontScale
                                                    font.weight: Font.DemiBold
                                                    elide: Text.ElideRight
                                                }
                                                Text {
                                                    Layout.fillWidth: true
                                                    text: assetBackend.translateText("Condition: ", assetBackend.language) + (modelData.asset_condition || "Unknown")
                                                          + "  ·  " + (modelData.category || "Uncategorized")
                                                    color: assetBackend.themeColor("#E0E8F5", assetBackend.theme)
                                                    font.pixelSize: 10 * assetBackend.fontScale
                                                    elide: Text.ElideRight
                                                }
                                                Text {
                                                    Layout.fillWidth: true
                                                    text: (modelData.asset_code || "—")
                                                          + "  ·  " + (modelData.building || "Not assigned")
                                                    color: assetBackend.themeColor("#AFC0D5", assetBackend.theme)
                                                    font.pixelSize: 9 * assetBackend.fontScale
                                                    elide: Text.ElideRight
                                                }
                                            }

                                            Rectangle {
                                                Layout.preferredWidth: 105
                                                Layout.preferredHeight: (26 * assetBackend.fontScale)
                                                radius: 13
                                                color: assetBackend.themeColor("#20FFFFFF", assetBackend.theme)
                                                border.width: 1
                                                border.color: assetBackend.themeColor("#35FFFFFF", assetBackend.theme)
                                                Text {
                                                    anchors.centerIn: parent
                                                    width: parent.width - 10
                                                    text: modelData.status || "Needs review"
                                                    color: root.maintenanceStatusColor(modelData.status)
                                                    font.pixelSize: 9 * assetBackend.fontScale
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
                                    text: assetBackend.translateText("No assets currently need attention.", assetBackend.language)
                                    color: assetBackend.themeColor("#D0D9E8", assetBackend.theme)
                                    font.pixelSize: 13 * assetBackend.fontScale
                                    horizontalAlignment: Text.AlignHCenter
                                    wrapMode: Text.WordWrap
                                }

                                Text {
                                    anchors.centerIn: parent
                                    width: parent.width * 0.88
                                    visible: !root.dashboardData.success
                                    text: assetBackend.translateText("Unable to load dashboard records. Check the Python console for the database error.", assetBackend.language)
                                    color: assetBackend.themeColor("#F0B4BC", assetBackend.theme)
                                    font.pixelSize: 11 * assetBackend.fontScale
                                    wrapMode: Text.WordWrap
                                    horizontalAlignment: Text.AlignHCenter
                                }
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: (22 * assetBackend.fontScale)

                    Text {
                        text: assetBackend.applicationName + "  |  Campus Asset Management"
                        color: assetBackend.themeColor("#D0D9E8", assetBackend.theme)
                        font.pixelSize: 11 * assetBackend.fontScale
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: root.dashboardData.success ? "Live SQLite data · refreshes after asset and maintenance changes" : "Dashboard data unavailable · check database connection"
                        color: assetBackend.themeColor("#D0D9E8", assetBackend.theme)
                        font.pixelSize: 11 * assetBackend.fontScale
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
                    Layout.preferredHeight: (72 * assetBackend.fontScale)

                    ColumnLayout {
                        spacing: 5

                        Text {
                            text: assetBackend.translateText("Glass Preview", assetBackend.language)
                            color: assetBackend.themeColor("#FFFFFF", assetBackend.theme)
                            font.pixelSize: 29 * assetBackend.fontScale
                            font.weight: Font.Bold
                        }

                        Text {
                            text: assetBackend.translateText("Test the new glass components against the Aurora background.", assetBackend.language)
                            color: assetBackend.themeColor("#E0E8F5", assetBackend.theme)
                            font.pixelSize: 14 * assetBackend.fontScale
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: assetBackend.translateText("VISUAL TEST", assetBackend.language)
                        color: assetBackend.themeColor("#FFFFFF", assetBackend.theme)
                        font.pixelSize: 11 * assetBackend.fontScale
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
                                text: assetBackend.translateText("GLASS SURFACE", assetBackend.language)
                                color: assetBackend.themeColor("#FFFFFF", assetBackend.theme)
                                font.pixelSize: 12 * assetBackend.fontScale
                                font.weight: Font.Bold
                                font.letterSpacing: 1.2
                            }

                            Text {
                                text: assetBackend.translateText("A clearer look\nat layered glass.", assetBackend.language)
                                color: assetBackend.themeColor("#FFFFFF", assetBackend.theme)
                                font.pixelSize: 30 * assetBackend.fontScale
                                font.weight: Font.DemiBold
                            }

                            Text {
                                Layout.fillWidth: true
                                text: assetBackend.translateText("This panel samples the Aurora background and combines it with a translucent tint, soft sheen and optical edge.", assetBackend.language)
                                color: assetBackend.themeColor("#E0E8F5", assetBackend.theme)
                                font.pixelSize: 14 * assetBackend.fontScale
                                wrapMode: Text.WordWrap
                            }

                            Item { Layout.fillHeight: true }

                            Rectangle {
                                Layout.fillWidth: true
                                height: 1
                                color: assetBackend.themeColor("#45FFFFFF", assetBackend.theme)
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 10

                                ColumnLayout {
                                    spacing: 4

                                    Text {
                                        text: assetBackend.translateText("BACKGROUND", assetBackend.language)
                                        color: assetBackend.themeColor("#FFFFFF", assetBackend.theme)
                                        font.pixelSize: 11 * assetBackend.fontScale
                                        font.weight: Font.Bold
                                        font.letterSpacing: 0.8
                                    }

                                    Text {
                                        text: assetBackend.translateText("Live Aurora sample", assetBackend.language)
                                        color: assetBackend.themeColor("#FFFFFF", assetBackend.theme)
                                        font.pixelSize: 13 * assetBackend.fontScale
                                    }
                                }

                                Item { Layout.fillWidth: true }

                                Text {
                                    text: assetBackend.translateText("01 / 03", assetBackend.language)
                                    color: assetBackend.themeColor("#FFFFFF", assetBackend.theme)
                                    font.pixelSize: 12 * assetBackend.fontScale
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
                                text: assetBackend.translateText("INPUT COMPONENTS", assetBackend.language)
                                color: assetBackend.themeColor("#FFFFFF", assetBackend.theme)
                                font.pixelSize: 12 * assetBackend.fontScale
                                font.weight: Font.Bold
                                font.letterSpacing: 1.2
                            }

                            Text {
                                text: assetBackend.translateText("GlassField", assetBackend.language)
                                color: assetBackend.themeColor("#FFFFFF", assetBackend.theme)
                                font.pixelSize: 16 * assetBackend.fontScale
                                font.weight: Font.DemiBold
                            }

                            Text {
                                text: assetBackend.translateText("Search field appearance", assetBackend.language)
                                color: assetBackend.themeColor("#E0E8F5", assetBackend.theme)
                                font.pixelSize: 13 * assetBackend.fontScale
                            }

                            GlassField {
                                id: previewGlassField
                                Layout.fillWidth: true
                                placeholderText: assetBackend.translateText("Search campus assets...", assetBackend.language)
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                height: 1
                                color: assetBackend.themeColor("#45FFFFFF", assetBackend.theme)
                                Layout.topMargin: 5
                                Layout.bottomMargin: 3
                            }

                            Text {
                                text: assetBackend.translateText("GlassCombo", assetBackend.language)
                                color: assetBackend.themeColor("#FFFFFF", assetBackend.theme)
                                font.pixelSize: 16 * assetBackend.fontScale
                                font.weight: Font.DemiBold
                            }

                            Text {
                                text: assetBackend.translateText("Dropdown appearance", assetBackend.language)
                                color: assetBackend.themeColor("#E0E8F5", assetBackend.theme)
                                font.pixelSize: 13 * assetBackend.fontScale
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
                                text: assetBackend.translateText("These controls are for visual testing only.", assetBackend.language)
                                color: assetBackend.themeColor("#D0D9E8", assetBackend.theme)
                                font.pixelSize: 12 * assetBackend.fontScale
                                wrapMode: Text.WordWrap
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: (36 * assetBackend.fontScale)
                    spacing: 10

                    Text {
                        text: assetBackend.translateText("CHECK:", assetBackend.language)
                        color: assetBackend.themeColor("#FFFFFF", assetBackend.theme)
                        font.pixelSize: 11 * assetBackend.fontScale
                        font.weight: Font.Bold
                    }

                    Text {
                        text: assetBackend.translateText("Transparency  •  Background visibility  •  Blur  •  Edge reflections", assetBackend.language)
                        color: assetBackend.themeColor("#E0E8F5", assetBackend.theme)
                        font.pixelSize: 12 * assetBackend.fontScale
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: assetBackend.translateText("No database changes", assetBackend.language)
                        color: assetBackend.themeColor("#FFFFFF", assetBackend.theme)
                        font.pixelSize: 12 * assetBackend.fontScale
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

            SettingsPage {
                id: settingsPage
                Layout.fillWidth: true
                Layout.fillHeight: true
                backend: assetBackend
                backdropSource: backgroundScene
            }

            AboutPage {
                id: aboutPage
                Layout.fillWidth: true
                Layout.fillHeight: true
                backdropSource: backgroundScene
            }

        }
    }
}