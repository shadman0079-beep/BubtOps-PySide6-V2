import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: page

    property var backend: null
    property Item backdropSource: null

    property var assets: []
    property var selectedAsset: null
    property var maintenanceHistory: []
    property string loadMessage: ""

    signal backRequested()

    function textValue(value, fallback) {
        return value === undefined || value === null || String(value).trim() === ""
                ? fallback : String(value)
    }

    function money(value) {
        var amount = Number(value || 0)
        if (isNaN(amount)) amount = 0
        return "৳ " + amount.toLocaleString(Qt.locale("en_US"), "f", 0)
    }

    function locationText(asset) {
        if (!asset) return "Not assigned"
        var parts = []
        if (asset.building) parts.push(String(asset.building))
        if (asset.floor) parts.push("Floor " + asset.floor)
        if (asset.room) parts.push("Room " + asset.room)
        return parts.length > 0 ? parts.join("  /  ") : "Not assigned"
    }

    function statusIsAttention(status) {
        var value = String(status || "").trim().toLowerCase()
        return [
            "needs maintenance",
            "under maintenance",
            "out of service"
        ].indexOf(value) >= 0
    }

    function conditionIsAttention(condition) {
        var value = String(condition || "").trim().toLowerCase()
        return [
            "poor", "damaged", "critical", "needs repair"
        ].indexOf(value) >= 0
    }

    function attentionReason(asset) {
        if (!asset) return ""
        var reasons = []
        if (statusIsAttention(asset.status))
            reasons.push("Status: " + textValue(asset.status, "Unknown"))
        if (conditionIsAttention(asset.asset_condition))
            reasons.push("Condition: " + textValue(asset.asset_condition, "Unknown"))
        return reasons.length ? reasons.join("  •  ") : "Flagged for review"
    }

    function statusColor(status) {
        var value = String(status || "").toLowerCase()
        if (value.indexOf("out of service") >= 0 || value.indexOf("urgent") >= 0)
            return "#F18C9B"
        if (value.indexOf("maintenance") >= 0 || value.indexOf("repair") >= 0 || value.indexOf("service") >= 0)
            return "#F2B76F"
        return "#83CFFF"
    }

    function conditionColor(condition) {
        var value = String(condition || "").toLowerCase()
        if (value === "critical" || value === "damaged") return "#F18C9B"
        if (value === "poor" || value.indexOf("repair") >= 0) return "#F2B76F"
        return "#83CFFF"
    }

    function loadSelectedHistory() {
        maintenanceHistory = []
        if (!backend || !selectedAsset)
            return
        try {
            maintenanceHistory = backend.getAssetMaintenanceHistory(
                Number(selectedAsset.asset_id)
            ) || []
        } catch (error) {
            console.warn("Could not load asset maintenance history:", error)
        }
    }

    function selectAsset(asset) {
        selectedAsset = asset
        loadSelectedHistory()
    }

    function refreshData(targetAssetId) {
        if (!backend)
            return

        var keepId = Number(targetAssetId || 0)
        if (keepId <= 0 && selectedAsset)
            keepId = Number(selectedAsset.asset_id || 0)

        try {
            assets = backend.getAttentionAssets() || []
            loadMessage = ""

            var match = null
            if (keepId > 0) {
                for (var i = 0; i < assets.length; i++) {
                    if (Number(assets[i].asset_id) === keepId) {
                        match = assets[i]
                        break
                    }
                }
            }

            if (!match && assets.length > 0)
                match = assets[0]

            selectAsset(match)
        } catch (error) {
            assets = []
            selectedAsset = null
            maintenanceHistory = []
            loadMessage = String(error)
            console.error("Could not load attention assets:", error)
        }
    }

    Connections {
        target: page.backend
        function onAssetsChanged() {
            page.refreshData(page.selectedAsset ? Number(page.selectedAsset.asset_id) : 0)
        }
        function onMaintenanceChanged() {
            page.loadSelectedHistory()
        }
    }

    Component.onCompleted: refreshData()
    onVisibleChanged: {
        if (visible)
            refreshData(selectedAsset ? Number(selectedAsset.asset_id) : 0)
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 15

        // =========================================
        // PAGE HEADER
        // =========================================

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 64
            spacing: 12

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 3

                Text {
                    text: assetBackend.translateText("Assets needing attention", assetBackend.language)
                    color: assetBackend.themeColor("#FFFFFF", assetBackend.theme)
                    font.pixelSize: 27 * assetBackend.fontScale
                    font.weight: Font.Bold
                }

                Text {
                    text: page.assets.length + " assets require repair, service or inspection"
                    color: assetBackend.themeColor("#D7E2F1", assetBackend.theme)
                    font.pixelSize: 12 * assetBackend.fontScale
                }
            }

            Rectangle {
                Layout.preferredWidth: 132
                Layout.preferredHeight: 40
                radius: 12
                color: backMouse.containsMouse ? "#35FFFFFF" : "#1EFFFFFF"
                border.width: 1
                border.color: assetBackend.themeColor("#4AFFFFFF", assetBackend.theme)

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 7
                    Text {
                        text: assetBackend.translateText("←", assetBackend.language)
                        color: assetBackend.themeColor("#FFFFFF", assetBackend.theme)
                        font.pixelSize: 17 * assetBackend.fontScale
                    }
                    Text {
                        text: assetBackend.translateText("Overview", assetBackend.language)
                        color: assetBackend.themeColor("#FFFFFF", assetBackend.theme)
                        font.pixelSize: 12 * assetBackend.fontScale
                        font.weight: Font.DemiBold
                    }
                }

                MouseArea {
                    id: backMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: page.backRequested()
                }
            }
        }

        // =========================================
        // LIST AND DETAIL PANELS
        // =========================================

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 14

            // LEFT: ATTENTION LIST
            GlassPanel {
                Layout.preferredWidth: 370
                Layout.minimumWidth: 300
                Layout.fillHeight: true

                backdropSource: page.backdropSource
                glassTint: 0.12

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 17
                    spacing: 10

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: assetBackend.translateText("REPAIR & SERVICE LIST", assetBackend.language)
                            color: assetBackend.themeColor("#FFFFFF", assetBackend.theme)
                            font.pixelSize: 11 * assetBackend.fontScale
                            font.weight: Font.Bold
                            font.letterSpacing: 0.8
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: page.assets.length + " TOTAL"
                            color: assetBackend.themeColor("#F2B76F", assetBackend.theme)
                            font.pixelSize: 10 * assetBackend.fontScale
                            font.weight: Font.Bold
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: assetBackend.themeColor("#35FFFFFF", assetBackend.theme)
                    }

                    ListView {
                        id: attentionList
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        spacing: 7
                        model: page.assets
                        currentIndex: {
                            if (!page.selectedAsset) return -1
                            for (var i = 0; i < page.assets.length; i++) {
                                if (Number(page.assets[i].asset_id) === Number(page.selectedAsset.asset_id))
                                    return i
                            }
                            return -1
                        }

                        delegate: Rectangle {
                            id: assetRow
                            required property var modelData
                            width: attentionList.width
                            height: 82
                            radius: 12

                            property bool selected: page.selectedAsset
                                && Number(page.selectedAsset.asset_id) === Number(modelData.asset_id)

                            color: selected ? "#3A6D91B8" : (rowMouse.containsMouse ? "#2BFFFFFF" : "#16FFFFFF")
                            border.width: 1
                            border.color: selected ? "#8CCFF5" : "#25FFFFFF"

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 10
                                spacing: 10

                                Rectangle {
                                    Layout.preferredWidth: 35
                                    Layout.preferredHeight: 35
                                    radius: 10
                                    color: assetBackend.themeColor("#233C536E", assetBackend.theme)
                                    Text {
                                        anchors.centerIn: parent
                                        text: assetBackend.translateText("!", assetBackend.language)
                                        color: page.conditionColor(assetRow.modelData.asset_condition)
                                        font.pixelSize: 19 * assetBackend.fontScale
                                        font.weight: Font.Bold
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 3

                                    Text {
                                        Layout.fillWidth: true
                                        text: page.textValue(assetRow.modelData.asset_name, "Unnamed asset")
                                        color: assetBackend.themeColor("#FFFFFF", assetBackend.theme)
                                        font.pixelSize: 13 * assetBackend.fontScale
                                        font.weight: Font.DemiBold
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: page.textValue(assetRow.modelData.asset_code, "—")
                                            + "  ·  "
                                            + page.textValue(assetRow.modelData.building, "Not assigned")
                                        color: assetBackend.themeColor("#B9CBE0", assetBackend.theme)
                                        font.pixelSize: 10 * assetBackend.fontScale
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: page.textValue(assetRow.modelData.status, "Unknown")
                                            + "  /  "
                                            + page.textValue(assetRow.modelData.asset_condition, "Unknown")
                                        color: assetBackend.themeColor("#F2C98D", assetBackend.theme)
                                        font.pixelSize: 10 * assetBackend.fontScale
                                        elide: Text.ElideRight
                                    }
                                }

                                Text {
                                    text: assetRow.selected ? "●" : "›"
                                    color: assetRow.selected ? "#9EE2FF" : "#B9CBE0"
                                    font.pixelSize: 18 * assetBackend.fontScale
                                }
                            }

                            MouseArea {
                                id: rowMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: page.selectAsset(assetRow.modelData)
                            }
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 76
                        visible: page.assets.length === 0

                        Column {
                            anchors.centerIn: parent
                            spacing: 6
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: assetBackend.translateText("✓", assetBackend.language)
                                color: assetBackend.themeColor("#78D9B0", assetBackend.theme)
                                font.pixelSize: 27 * assetBackend.fontScale
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: page.loadMessage.length > 0
                                      ? "Could not load attention list"
                                      : "No assets need attention"
                                color: assetBackend.themeColor("#FFFFFF", assetBackend.theme)
                                font.pixelSize: 13 * assetBackend.fontScale
                                font.weight: Font.DemiBold
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: page.loadMessage.length > 0
                                      ? page.loadMessage
                                      : "Everything is currently in good standing."
                                color: assetBackend.themeColor("#B9CBE0", assetBackend.theme)
                                font.pixelSize: 10 * assetBackend.fontScale
                            }
                        }
                    }
                }
            }

            // RIGHT: SELECTED ASSET DETAILS
            GlassPanel {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumWidth: 320

                backdropSource: page.backdropSource
                glassTint: 0.13

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 12

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 3
                            Text {
                                text: page.selectedAsset
                                      ? page.textValue(page.selectedAsset.asset_name, "Unnamed asset")
                                      : "Select an asset"
                                color: assetBackend.themeColor("#FFFFFF", assetBackend.theme)
                                font.pixelSize: 21 * assetBackend.fontScale
                                font.weight: Font.Bold
                                elide: Text.ElideRight
                            }
                            Text {
                                text: page.selectedAsset
                                      ? page.textValue(page.selectedAsset.asset_code, "No asset code")
                                      : "Asset details will appear here"
                                color: assetBackend.themeColor("#B9CBE0", assetBackend.theme)
                                font.pixelSize: 11 * assetBackend.fontScale
                            }
                        }

                        Rectangle {
                            visible: page.selectedAsset !== null
                            Layout.preferredWidth: 112
                            Layout.preferredHeight: 30
                            radius: 15
                            color: assetBackend.themeColor("#20FFFFFF", assetBackend.theme)
                            border.width: 1
                            border.color: assetBackend.themeColor("#40FFFFFF", assetBackend.theme)
                            Text {
                                anchors.centerIn: parent
                                text: page.selectedAsset
                                      ? page.textValue(page.selectedAsset.status, "Unknown")
                                      : ""
                                color: page.selectedAsset
                                       ? page.statusColor(page.selectedAsset.status)
                                       : "#FFFFFF"
                                font.pixelSize: 9 * assetBackend.fontScale
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: assetBackend.themeColor("#35FFFFFF", assetBackend.theme)
                    }

                    Text {
                        text: assetBackend.translateText("WHY THIS ASSET NEEDS ATTENTION", assetBackend.language)
                        color: assetBackend.themeColor("#F2B76F", assetBackend.theme)
                        font.pixelSize: 10 * assetBackend.fontScale
                        font.weight: Font.Bold
                        font.letterSpacing: 0.9
                    }

                    Text {
                        Layout.fillWidth: true
                        text: page.selectedAsset
                              ? page.attentionReason(page.selectedAsset)
                              : "Choose an asset from the list to inspect its details."
                        color: assetBackend.themeColor("#FFFFFF", assetBackend.theme)
                        font.pixelSize: 13 * assetBackend.fontScale
                        wrapMode: Text.WordWrap
                    }

                    // Asset information grid
                    GridLayout {
                        Layout.fillWidth: true
                        columns: 2
                        rowSpacing: 9
                        columnSpacing: 10

                        Repeater {
                            model: [
                                { label: "CATEGORY", key: "category", fallback: "Uncategorized" },
                                { label: "CONDITION", key: "asset_condition", fallback: "Unknown" },
                                { label: "LOCATION", key: "location", fallback: "Not assigned" },
                                { label: "PURCHASE DATE", key: "purchase_date", fallback: "Not recorded" },
                                { label: "PURCHASE COST", key: "purchase_cost", fallback: "0" },
                                { label: "ESTIMATED REPAIR COST", key: "estimated_repair_cost", fallback: "0" }
                            ]

                            delegate: Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 62
                                radius: 11
                                color: assetBackend.themeColor("#16FFFFFF", assetBackend.theme)
                                border.width: 1
                                border.color: assetBackend.themeColor("#20FFFFFF", assetBackend.theme)

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 11
                                    anchors.rightMargin: 8
                                    anchors.topMargin: 7
                                    anchors.bottomMargin: 7
                                    spacing: 3
                                    Text {
                                        text: modelData.label
                                        color: assetBackend.themeColor("#AFC0D5", assetBackend.theme)
                                        font.pixelSize: 8 * assetBackend.fontScale
                                        font.weight: Font.Bold
                                        font.letterSpacing: 0.5
                                    }
                                    Text {
                                        Layout.fillWidth: true
                                        text: {
                                            if (!page.selectedAsset)
                                                return "—"
                                            if (modelData.key === "location")
                                                return page.locationText(page.selectedAsset)
                                            if (modelData.key === "purchase_cost" || modelData.key === "estimated_repair_cost")
                                                return page.money(page.selectedAsset[modelData.key])
                                            return page.textValue(page.selectedAsset[modelData.key], modelData.fallback)
                                        }
                                        color: assetBackend.themeColor("#FFFFFF", assetBackend.theme)
                                        font.pixelSize: 11 * assetBackend.fontScale
                                        font.weight: Font.DemiBold
                                        elide: Text.ElideRight
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: assetBackend.themeColor("#35FFFFFF", assetBackend.theme)
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: assetBackend.translateText("MAINTENANCE HISTORY", assetBackend.language)
                            color: assetBackend.themeColor("#FFFFFF", assetBackend.theme)
                            font.pixelSize: 10 * assetBackend.fontScale
                            font.weight: Font.Bold
                            font.letterSpacing: 0.9
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: page.maintenanceHistory.length + " RECORDS"
                            color: assetBackend.themeColor("#B9CBE0", assetBackend.theme)
                            font.pixelSize: 9 * assetBackend.fontScale
                            font.weight: Font.Bold
                        }
                    }

                    ListView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.minimumHeight: 70
                        clip: true
                        spacing: 6
                        model: page.maintenanceHistory

                        delegate: Rectangle {
                            required property var modelData
                            width: ListView.view.width
                            height: 57
                            radius: 10
                            color: assetBackend.themeColor("#16FFFFFF", assetBackend.theme)
                            border.width: 1
                            border.color: assetBackend.themeColor("#20FFFFFF", assetBackend.theme)

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                spacing: 9
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2
                                    Text {
                                        Layout.fillWidth: true
                                        text: page.textValue(modelData.description, "Maintenance record")
                                        color: assetBackend.themeColor("#FFFFFF", assetBackend.theme)
                                        font.pixelSize: 11 * assetBackend.fontScale
                                        font.weight: Font.DemiBold
                                        elide: Text.ElideRight
                                    }
                                    Text {
                                        Layout.fillWidth: true
                                        text: page.textValue(assetBackend.formatDate(modelData.maintenance_date) || "Date not recorded")
                                            + "  ·  "
                                            + page.textValue(modelData.status, "Unknown")
                                        color: assetBackend.themeColor("#B9CBE0", assetBackend.theme)
                                        font.pixelSize: 9 * assetBackend.fontScale
                                        elide: Text.ElideRight
                                    }
                                }
                                Text {
                                    text: page.money(modelData.cost)
                                    color: assetBackend.themeColor("#E0E8F5", assetBackend.theme)
                                    font.pixelSize: 10 * assetBackend.fontScale
                                    font.weight: Font.DemiBold
                                }
                            }
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        visible: page.selectedAsset !== null && page.maintenanceHistory.length === 0
                        text: assetBackend.translateText("No maintenance history has been recorded for this asset yet.", assetBackend.language)
                        color: assetBackend.themeColor("#B9CBE0", assetBackend.theme)
                        font.pixelSize: 10 * assetBackend.fontScale
                    }

                    Text {
                        Layout.fillWidth: true
                        visible: page.selectedAsset === null
                        text: assetBackend.translateText("Select an asset on the left to see its full details.", assetBackend.language)
                        color: assetBackend.themeColor("#B9CBE0", assetBackend.theme)
                        font.pixelSize: 11 * assetBackend.fontScale
                    }
                }
            }
        }
    }
}
