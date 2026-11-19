
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects

Item {
    id: page

    property var backend: null
    property Item backdropSource: null

    property var assets: []
    property var locations: []
    property var categories: []

    property string searchText: ""
    property string selectedCondition: ""
    property string selectedStatus: ""
    property string selectedCategory: ""

    property bool formVisible: false
    property int editingAssetId: 0

    property color textPrimary: "#FFFFFF"
    property color textSecondary: "#E0E8F5"
    property color accent: "#83CFFF"

    property var conditionOptions: [
        "Good", "Fair", "Poor", "Damaged", "Critical"
    ]

    property var statusOptions: [
        "In Service",
        "Needs Maintenance",
        "Under Maintenance",
        "Out of Service"
    ]

    // =========================================
    // DATABASE FUNCTIONS
    // =========================================

    function refreshData() {
        if (!backend)
            return

        assets = backend.getAssets(
            searchText,
            selectedCondition,
            selectedStatus,
            selectedCategory
        )

        locations = backend.getLocations()
        categories = backend.getCategories()
    }

    function money(value) {
        return "৳" + Number(value || 0).toLocaleString(
            Qt.locale("en_US"), "f", 0
        )
    }

    function locationName(asset) {
        let parts = []

        if (asset.building)
            parts.push(asset.building)

        if (asset.floor)
            parts.push("Floor " + asset.floor)

        if (asset.room)
            parts.push("Room " + asset.room)

        return parts.length ? parts.join(" / ") : "Unassigned"
    }

    function openNewAsset() {
        editingAssetId = 0

        assetCodeField.text = ""
        assetNameField.text = ""
        categoryField.text = ""
        purchaseDateField.text = ""
        purchaseCostField.text = "0"
        repairCostField.text = "0"

        locationCombo.currentIndex = 0
        conditionCombo.currentIndex = 0
        statusCombo.currentIndex = 0

        formVisible = true
    }

    function openEditAsset(asset) {
        editingAssetId = asset.asset_id

        assetCodeField.text = asset.asset_code || ""
        assetNameField.text = asset.asset_name || ""
        categoryField.text = asset.category || ""
        purchaseDateField.text = asset.purchase_date || ""

        purchaseCostField.text =
            String(asset.purchase_cost || 0)

        repairCostField.text =
            String(asset.estimated_repair_cost || 0)

        let locationIndex = 0

        for (let i = 0; i < locations.length; i++) {
            if (locations[i].location_id === asset.location_id) {
                locationIndex = i + 1
                break
            }
        }

        locationCombo.currentIndex = locationIndex

        let conditionIndex = conditionOptions.indexOf(
            asset.asset_condition
        )

        conditionCombo.currentIndex =
            conditionIndex >= 0 ? conditionIndex : 0

        let statusIndex = statusOptions.indexOf(
            asset.status
        )

        statusCombo.currentIndex =
            statusIndex >= 0 ? statusIndex : 0

        formVisible = true
    }

    function saveCurrentAsset() {
        if (!backend)
            return

        let selectedLocation =
            locationCombo.currentIndex > 0
            ? locations[locationCombo.currentIndex - 1].location_id
            : null

        let result = backend.saveAsset({
            "asset_id": editingAssetId,
            "asset_code": assetCodeField.text,
            "asset_name": assetNameField.text,
            "category": categoryField.text,
            "purchase_date": purchaseDateField.text,
            "purchase_cost": purchaseCostField.text,
            "estimated_repair_cost": repairCostField.text,
            "location_id": selectedLocation,
            "asset_condition": conditionCombo.currentText,
            "status": statusCombo.currentText
        })

        messageText.text = result.message

        if (result.success) {
            formVisible = false
            refreshData()
        }

        messageDialog.open()
    }

    function deleteCurrentAsset(assetId) {
        if (!backend)
            return

        let result = backend.deleteAsset(assetId)

        messageText.text = result.message

        if (result.success)
            refreshData()

        messageDialog.open()
    }

    function conditionColor(condition) {
        switch (condition) {
        case "Good": return "#68D9B0"
        case "Fair": return "#83CFFF"
        case "Poor": return "#F2B76F"
        case "Damaged": return "#E58B9A"
        case "Critical": return "#FF718A"
        default: return "#FFFFFF"
        }
    }

    function statusColor(status) {
        switch (status) {
        case "In Service": return "#68D9B0"
        case "Needs Maintenance": return "#F2B76F"
        case "Under Maintenance": return "#83CFFF"
        case "Out of Service": return "#E58B9A"
        default: return "#FFFFFF"
        }
    }

    // =========================================
    // DATABASE CONNECTION
    // =========================================

    Connections {
        target: page.backend

        function onAssetsChanged() {
            page.refreshData()
        }
    }

    Component.onCompleted: refreshData()

    // =========================================
    // MESSAGE DIALOG
    // =========================================

    Dialog {
        id: messageDialog

        anchors.centerIn: parent
        width: 390
        modal: true

        background: Rectangle {
            radius: 17
            color: "#E91B2941"
            border.width: 1
            border.color: "#70FFFFFF"
        }

        contentItem: ColumnLayout {
            spacing: 18

            Text {
                text: messageText.text
                color: "#FFFFFF"
                font.pixelSize: 15
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            GlassButton {
                label: "Continue"
                primary: true
                backdropSource: page.backdropSource

                Layout.preferredWidth: 120
                Layout.preferredHeight: 42
                Layout.alignment: Qt.AlignRight

                onClicked: messageDialog.close()
            }
        }
    }

    QtObject {
        id: messageText
        property string text: ""
    }

    // =========================================
    // MAIN PAGE LAYOUT
    // =========================================

    ColumnLayout {
        anchors.fill: parent
        spacing: 16

        // HEADER

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 72

            ColumnLayout {
                spacing: 5

                Text {
                    text: "Asset Registry"
                    color: "#FFFFFF"
                    font.pixelSize: 29
                    font.weight: Font.Bold
                }

                Text {
                    text: "Manage, monitor and organize campus assets."
                    color: "#E0E8F5"
                    font.pixelSize: 14
                }
            }

            Item {
                Layout.fillWidth: true
            }

            GlassButton {
                label: "+  Add New Asset"
                primary: true
                backdropSource: page.backdropSource

                Layout.preferredWidth: 175
                Layout.preferredHeight: 44

                onClicked: page.openNewAsset()
            }
        }

        // STATISTICS

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Repeater {
                model: [
                    {
                        label: "TOTAL ASSETS",
                        value: page.assets.length,
                        accent: "#83CFFF"
                    },
                    {
                        label: "IN SERVICE",
                        value: page.assets.filter(
                            a => a.status === "In Service"
                        ).length,
                        accent: "#68D9B0"
                    },
                    {
                        label: "NEEDS ATTENTION",
                        value: page.assets.filter(
                            a => a.status === "Needs Maintenance"
                                || a.status === "Under Maintenance"
                                || a.status === "Out of Service"
                                || a.asset_condition === "Poor"
                                || a.asset_condition === "Damaged"
                                || a.asset_condition === "Critical"
                        ).length,
                        accent: "#F2B76F"
                    },
                    {
                        label: "PURCHASE VALUE",
                        value: page.money(
                            page.assets.reduce(
                                (sum, a) =>
                                    sum + Number(a.purchase_cost || 0),
                                0
                            )
                        ),
                        accent: "#B9A2FF"
                    }
                ]

                delegate: GlassPanel {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 108

                    backdropSource: page.backdropSource
                    glassTint: 0.085
                    radius: 15
                    blurAmount: 0.62

                    Rectangle {
                        width: 3
                        height: 48
                        radius: 2
                        color: modelData.accent

                        anchors.left: parent.left
                        anchors.leftMargin: 14
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 26
                        anchors.rightMargin: 10
                        anchors.topMargin: 14
                        anchors.bottomMargin: 12
                        spacing: 7

                        Text {
                            text: modelData.label
                            color: "#FFFFFF"
                            font.pixelSize: 11
                            font.weight: Font.Bold
                            font.letterSpacing: 0.6
                        }

                        Text {
                            text: String(modelData.value)
                            color: "#FFFFFF"
                            font.pixelSize: 25
                            font.weight: Font.Bold
                            elide: Text.ElideRight
                        }
                    }
                }
            }
        }

        // SEARCH AND FILTERS

        GlassPanel {
            Layout.fillWidth: true
            Layout.preferredHeight: 70

            backdropSource: page.backdropSource
            glassTint: 0.075
            radius: 14
            blurAmount: 0.62

            RowLayout {
                anchors.fill: parent
                anchors.margins: 11
                spacing: 10

                GlassField {
                    Layout.fillWidth: true
                    placeholderText:
                        "Search code, asset, category or building..."

                    text: page.searchText

                    onTextChanged: {
                        page.searchText = text
                        page.refreshData()
                    }
                }

                GlassCombo {
                    id: filterCondition
                    Layout.preferredWidth: 135

                    model: ["All Conditions"].concat(
                        page.conditionOptions
                    )

                    onActivated: {
                        page.selectedCondition =
                            currentIndex === 0 ? "" : currentText

                        page.refreshData()
                    }
                }

                GlassCombo {
                    id: filterStatus
                    Layout.preferredWidth: 155

                    model: ["All Statuses"].concat(
                        page.statusOptions
                    )

                    onActivated: {
                        page.selectedStatus =
                            currentIndex === 0 ? "" : currentText

                        page.refreshData()
                    }
                }

                GlassCombo {
                    id: filterCategory
                    Layout.preferredWidth: 145

                    model: ["All Categories"].concat(
                        page.categories
                    )

                    onActivated: {
                        page.selectedCategory =
                            currentIndex === 0 ? "" : currentText

                        page.refreshData()
                    }
                }

                GlassButton {
                    label: "Reset"
                    backdropSource: page.backdropSource

                    Layout.preferredWidth: 78
                    Layout.preferredHeight: 42

                    onClicked: {
                        page.searchText = ""
                        page.selectedCondition = ""
                        page.selectedStatus = ""
                        page.selectedCategory = ""

                        filterCondition.currentIndex = 0
                        filterStatus.currentIndex = 0
                        filterCategory.currentIndex = 0

                        page.refreshData()
                    }
                }
            }
        }

        // INVENTORY PANEL

        GlassPanel {
            Layout.fillWidth: true
            Layout.fillHeight: true

            backdropSource: page.backdropSource
            glassTint: 0.095
            radius: 17
            blurAmount: 0.66

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 13

                RowLayout {
                    Layout.fillWidth: true

                    ColumnLayout {
                        spacing: 4

                        Text {
                            text: "Asset inventory"
                            color: "#FFFFFF"
                            font.pixelSize: 19
                            font.weight: Font.DemiBold
                        }

                        Text {
                            text: "Registered campus equipment and resources"
                            color: "#E0E8F5"
                            font.pixelSize: 13
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    Rectangle {
                        radius: 11
                        color: "#1CFFFFFF"
                        border.width: 1
                        border.color: "#40FFFFFF"

                        Layout.preferredWidth: 105
                        Layout.preferredHeight: 32

                        Text {
                            anchors.centerIn: parent
                            text: page.assets.length + " ASSETS"
                            color: "#FFFFFF"
                            font.pixelSize: 12
                            font.weight: Font.Bold
                        }
                    }
                }

                // TABLE HEADER

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 43

                    radius: 9
                    color: "#263D5A"
                    border.width: 1
                    border.color: "#40FFFFFF"

                    gradient: Gradient {
                        GradientStop {
                            position: 0.0
                            color: "#3BFFFFFF"
                        }
                        GradientStop {
                            position: 1.0
                            color: "#172C4960"
                        }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 4

                        Text {
                            Layout.preferredWidth: 76
                            text: "CODE"
                            color: "#FFFFFF"
                            font.pixelSize: 11
                            font.bold: true
                        }

                        Text {
                            Layout.fillWidth: true
                            text: "ASSET"
                            color: "#FFFFFF"
                            font.pixelSize: 11
                            font.bold: true
                        }

                        Text {
                            Layout.preferredWidth: 85
                            text: "CATEGORY"
                            color: "#FFFFFF"
                            font.pixelSize: 11
                            font.bold: true
                        }

                        Text {
                            Layout.preferredWidth: 105
                            text: "LOCATION"
                            color: "#FFFFFF"
                            font.pixelSize: 11
                            font.bold: true
                        }

                        Text {
                            Layout.preferredWidth: 75
                            text: "CONDITION"
                            color: "#FFFFFF"
                            font.pixelSize: 11
                            font.bold: true
                        }

                        Text {
                            Layout.preferredWidth: 92
                            text: "STATUS"
                            color: "#FFFFFF"
                            font.pixelSize: 11
                            font.bold: true
                        }

                        Text {
                            Layout.preferredWidth: 74
                            text: "VALUE"
                            color: "#FFFFFF"
                            font.pixelSize: 11
                            font.bold: true
                        }

                        Text {
                            Layout.preferredWidth: 92
                            text: "ACTIONS"
                            color: "#FFFFFF"
                            font.pixelSize: 11
                            font.bold: true
                        }
                    }
                }

                // SCROLLABLE INVENTORY

                ListView {
                    id: assetList

                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    clip: true
                    spacing: 6
                    model: page.assets

                    boundsBehavior: Flickable.StopAtBounds

                    ScrollBar.vertical: ScrollBar {
                        policy: ScrollBar.AsNeeded
                    }

                    delegate: Rectangle {
                        width: assetList.width
                        height: 57
                        radius: 9

                        color: index % 2 === 0
                               ? "#1AFFFFFF"
                               : "#0CFFFFFF"

                        border.width: 1
                        border.color: "#35FFFFFF"

                        Behavior on color {
                            ColorAnimation { duration: 120 }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 8
                            spacing: 4

                            Text {
                                Layout.preferredWidth: 76
                                text: modelData.asset_code || ""
                                color: "#FFFFFF"
                                font.pixelSize: 12
                                font.bold: true
                                elide: Text.ElideRight
                            }

                            Text {
                                Layout.fillWidth: true
                                text: modelData.asset_name || ""
                                color: "#FFFFFF"
                                font.pixelSize: 13
                                font.weight: Font.Medium
                                elide: Text.ElideRight
                            }

                            Text {
                                Layout.preferredWidth: 85
                                text: modelData.category || ""
                                color: "#FFFFFF"
                                font.pixelSize: 12
                                elide: Text.ElideRight
                            }

                            Text {
                                Layout.preferredWidth: 105
                                text: page.locationName(modelData)
                                color: "#FFFFFF"
                                font.pixelSize: 12
                                elide: Text.ElideRight
                            }

                            Text {
                                Layout.preferredWidth: 75
                                text: modelData.asset_condition || ""
                                color: page.conditionColor(
                                    modelData.asset_condition
                                )
                                font.pixelSize: 12
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                            }

                            Text {
                                Layout.preferredWidth: 92
                                text: modelData.status || ""
                                color: page.statusColor(modelData.status)
                                font.pixelSize: 12
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                            }

                            Text {
                                Layout.preferredWidth: 74
                                text: page.money(modelData.purchase_cost)
                                color: "#FFFFFF"
                                font.pixelSize: 12
                                elide: Text.ElideRight
                            }

                            RowLayout {
                                Layout.preferredWidth: 92
                                spacing: 4

                                GlassButton {
                                    label: "Edit"
                                    backdropSource: page.backdropSource

                                    Layout.preferredWidth: 43
                                    Layout.preferredHeight: 33

                                    onClicked: page.openEditAsset(modelData)
                                }

                                GlassButton {
                                    label: "Del"
                                    backdropSource: page.backdropSource

                                    Layout.preferredWidth: 42
                                    Layout.preferredHeight: 33

                                    onClicked: {
                                        deleteDialog.assetId =
                                            modelData.asset_id

                                        deleteDialog.open()
                                    }
                                }
                            }
                        }
                    }

                    Item {
                        anchors.centerIn: parent
                        width: 280
                        height: 100
                        visible: page.assets.length === 0

                        Column {
                            anchors.centerIn: parent
                            spacing: 9

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "◇"
                                color: "#83CFFF"
                                font.pixelSize: 30
                            }

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "No assets found"
                                color: "#FFFFFF"
                                font.pixelSize: 17
                                font.weight: Font.DemiBold
                            }

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "Try changing your search or filters."
                                color: "#E0E8F5"
                                font.pixelSize: 13
                            }
                        }
                    }
                }
            }
        }
    }

    // =========================================
    // DELETE CONFIRMATION
    // =========================================

    Dialog {
        id: deleteDialog

        property int assetId: 0

        width: 410

        x: (page.width - width) / 2
        y: (page.height - height) / 2

        modal: true
        title: "Delete asset?"

        background: Rectangle {
            color: "#E91B2941"
            radius: 16
            border.color: "#70FFFFFF"
            border.width: 1
        }

        contentItem: ColumnLayout {
            spacing: 18

            Text {
                Layout.fillWidth: true

                text: "Are you sure you want to delete this asset? This action cannot be undone."

                color: "#FFFFFF"
                wrapMode: Text.WordWrap
                font.pixelSize: 15
            }

            RowLayout {
                Layout.fillWidth: true

                Item { Layout.fillWidth: true }

                GlassButton {
                    label: "Cancel"
                    backdropSource: page.backdropSource

                    Layout.preferredWidth: 95
                    Layout.preferredHeight: 42

                    onClicked: deleteDialog.close()
                }

                GlassButton {
                    label: "Delete"
                    primary: true
                    backdropSource: page.backdropSource

                    Layout.preferredWidth: 95
                    Layout.preferredHeight: 42

                    onClicked: {
                        const id = deleteDialog.assetId
                        deleteDialog.close()
                        page.deleteCurrentAsset(id)
                    }
                }
            }
        }
    }

    // =========================================
    // ADD / EDIT FORM OVERLAY
    // =========================================

    Rectangle {
        id: formOverlay

        anchors.fill: parent
        visible: page.formVisible
        color: "#B80A1020"
        z: 10

        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }

        GlassPanel {
            id: formPanel

            width: Math.min(510, parent.width - 30)
            height: Math.min(690, parent.height - 30)

            anchors.centerIn: parent

            radius: 20
            glassTint: 0.20
            blurAmount: 0.82
            backdropSource: page.backdropSource

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 22
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true

                    ColumnLayout {
                        spacing: 5

                        Text {
                            text: page.editingAssetId > 0
                                  ? "Edit asset"
                                  : "Register new asset"

                            color: "#FFFFFF"
                            font.pixelSize: 24
                            font.bold: true
                        }

                        Text {
                            text: "Enter the asset information below."
                            color: "#E0E8F5"
                            font.pixelSize: 13
                        }
                    }

                    Item { Layout.fillWidth: true }

                    GlassButton {
                        label: "✕"
                        backdropSource: page.backdropSource

                        Layout.preferredWidth: 40
                        Layout.preferredHeight: 40

                        onClicked: page.formVisible = false
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: "#45FFFFFF"
                }

                ScrollView {
                    id: formScroll

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true

                    ScrollBar.vertical.policy: ScrollBar.AsNeeded

                    ColumnLayout {
                        width: formScroll.availableWidth
                        spacing: 11

                        Label {
                            text: "Asset code *"
                            color: "#FFFFFF"
                            font.pixelSize: 14
                            font.weight: Font.DemiBold
                        }

                        GlassField {
                            id: assetCodeField
                            Layout.fillWidth: true
                            placeholderText: "Example: AST-0100"
                        }

                        Label {
                            text: "Asset name *"
                            color: "#FFFFFF"
                            font.pixelSize: 14
                            font.weight: Font.DemiBold
                        }

                        GlassField {
                            id: assetNameField
                            Layout.fillWidth: true
                            placeholderText: "Example: Desktop Computer"
                        }

                        Label {
                            text: "Category *"
                            color: "#FFFFFF"
                            font.pixelSize: 14
                            font.weight: Font.DemiBold
                        }

                        GlassField {
                            id: categoryField
                            Layout.fillWidth: true
                            placeholderText: "Example: Electronics"
                        }

                        Label {
                            text: "Location"
                            color: "#FFFFFF"
                            font.pixelSize: 14
                            font.weight: Font.DemiBold
                        }

                        GlassCombo {
                            id: locationCombo
                            Layout.fillWidth: true

                            model: ["Unassigned"].concat(
                                page.locations.map(
                                    l => {
                                        let name = l.building || ""

                                        if (l.floor)
                                            name += " / Floor " + l.floor

                                        if (l.room)
                                            name += " / Room " + l.room

                                        return name
                                    }
                                )
                            )
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 12

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Label {
                                    text: "Condition"
                                    color: "#FFFFFF"
                                    font.pixelSize: 14
                                    font.weight: Font.DemiBold
                                }

                                GlassCombo {
                                    id: conditionCombo
                                    Layout.fillWidth: true
                                    model: page.conditionOptions
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Label {
                                    text: "Status"
                                    color: "#FFFFFF"
                                    font.pixelSize: 14
                                    font.weight: Font.DemiBold
                                }

                                GlassCombo {
                                    id: statusCombo
                                    Layout.fillWidth: true
                                    model: page.statusOptions
                                }
                            }
                        }

                        Label {
                            text: "Purchase date (YYYY-MM-DD)"
                            color: "#FFFFFF"
                            font.pixelSize: 14
                            font.weight: Font.DemiBold
                        }

                        GlassField {
                            id: purchaseDateField
                            Layout.fillWidth: true
                            placeholderText: "2026-10-10"
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 12

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Label {
                                    text: "Purchase cost"
                                    color: "#FFFFFF"
                                    font.pixelSize: 14
                                    font.weight: Font.DemiBold
                                }

                                GlassField {
                                    id: purchaseCostField
                                    Layout.fillWidth: true
                                    text: "0"
                                    inputMethodHints:
                                        Qt.ImhFormattedNumbersOnly
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Label {
                                    text: "Estimated repair cost"
                                    color: "#FFFFFF"
                                    font.pixelSize: 14
                                    font.weight: Font.DemiBold
                                }

                                GlassField {
                                    id: repairCostField
                                    Layout.fillWidth: true
                                    text: "0"
                                    inputMethodHints:
                                        Qt.ImhFormattedNumbersOnly
                                }
                            }
                        }

                        Item {
                            Layout.preferredHeight: 10
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: "#45FFFFFF"
                }

                RowLayout {
                    Layout.fillWidth: true

                    Item { Layout.fillWidth: true }

                    GlassButton {
                        label: "Cancel"
                        backdropSource: page.backdropSource

                        Layout.preferredWidth: 95
                        Layout.preferredHeight: 42

                        onClicked: page.formVisible = false
                    }

                    GlassButton {
                        label: page.editingAssetId > 0
                               ? "Save Changes"
                               : "Register Asset"

                        primary: true
                        backdropSource: page.backdropSource

                        Layout.preferredWidth: 150
                        Layout.preferredHeight: 42

                        onClicked: page.saveCurrentAsset()
                    }
                }
            }
        }
    }
}
