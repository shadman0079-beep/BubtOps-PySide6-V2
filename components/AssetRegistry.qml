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

    property color textPrimary: "#F2F6FF"
    property color textSecondary: "#91A5C0"
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
        default: return "#A9BBD5"
        }
    }

    function statusColor(status) {
        switch (status) {
        case "In Service": return "#68D9B0"
        case "Needs Maintenance": return "#F2B76F"
        case "Under Maintenance": return "#83CFFF"
        case "Out of Service": return "#E58B9A"
        default: return "#A9BBD5"
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
        width: 350
        modal: true

        background: Rectangle {
            radius: 17
            color: "#E91B2941"
            border.width: 1
            border.color: "#70FFFFFF"
        }

        contentItem: ColumnLayout {
            spacing: 15

            Text {
                text: messageText.text
                color: "#EAF2FF"
                font.pixelSize: 12
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            GlassButton {
                label: "Continue"
                primary: true
                backdropSource: page.backdropSource

                Layout.preferredWidth: 110
                Layout.preferredHeight: 36
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
        spacing: 14

        // HEADER
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 62

            ColumnLayout {
                spacing: 4

                Text {
                    text: "Asset Registry"
                    color: page.textPrimary
                    font.pixelSize: 25
                    font.weight: Font.Bold
                }

                Text {
                    text: "Manage, monitor and organize campus assets."
                    color: page.textSecondary
                    font.pixelSize: 11
                }
            }

            Item {
                Layout.fillWidth: true
            }

            GlassButton {
                label: "+  Add New Asset"
                primary: true
                backdropSource: page.backdropSource

                Layout.preferredWidth: 155
                Layout.preferredHeight: 40

                onClicked: page.openNewAsset()
            }
        }

        // STATISTICS
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

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
                    Layout.preferredHeight: 88

                    backdropSource: page.backdropSource
                    glassTint: 0.085
                    radius: 15
                    blurAmount: 0.62

                    Rectangle {
                        width: 3
                        height: 40
                        radius: 2

                        color: modelData.accent

                        anchors.left: parent.left
                        anchors.leftMargin: 13
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    ColumnLayout {
                        anchors.fill: parent

                        anchors.leftMargin: 24
                        anchors.rightMargin: 10
                        anchors.topMargin: 12
                        anchors.bottomMargin: 10

                        spacing: 5

                        Text {
                            text: modelData.label
                            color: "#A8BAD4"
                            font.pixelSize: 8
                            font.weight: Font.Bold
                            font.letterSpacing: 0.7
                        }

                        Text {
                            text: String(modelData.value)
                            color: "#F4F7FF"
                            font.pixelSize: 20
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
            Layout.preferredHeight: 62

            backdropSource: page.backdropSource
            glassTint: 0.075
            radius: 14
            blurAmount: 0.62

            RowLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 9

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

                    Layout.preferredWidth: 125

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

                    Layout.preferredWidth: 145

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

                    Layout.preferredWidth: 135

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

                    Layout.preferredWidth: 68
                    Layout.preferredHeight: 38

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
                anchors.margins: 15
                spacing: 11

                // Inventory heading
                RowLayout {
                    Layout.fillWidth: true

                    ColumnLayout {
                        spacing: 3

                        Text {
                            text: "Asset inventory"
                            color: "#F1F5FF"
                            font.pixelSize: 14
                            font.weight: Font.DemiBold
                        }

                        Text {
                            text: "Registered campus equipment and resources"
                            color: "#8FA4C2"
                            font.pixelSize: 9
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    Rectangle {
                        radius: 10
                        color: "#1CFFFFFF"
                        border.width: 1
                        border.color: "#30FFFFFF"

                        Layout.preferredWidth: 85
                        Layout.preferredHeight: 27

                        Text {
                            anchors.centerIn: parent
                            text: page.assets.length + " ASSETS"
                            color: "#B9CBE4"
                            font.pixelSize: 9
                            font.weight: Font.Bold
                        }
                    }
                }

                // Table header
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 37

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
                            color: "#B5C8E2"
                            font.pixelSize: 8
                            font.bold: true
                        }

                        Text {
                            Layout.fillWidth: true
                            text: "ASSET"
                            color: "#B5C8E2"
                            font.pixelSize: 8
                            font.bold: true
                        }

                        Text {
                            Layout.preferredWidth: 85
                            text: "CATEGORY"
                            color: "#B5C8E2"
                            font.pixelSize: 8
                            font.bold: true
                        }

                        Text {
                            Layout.preferredWidth: 105
                            text: "LOCATION"
                            color: "#B5C8E2"
                            font.pixelSize: 8
                            font.bold: true
                        }

                        Text {
                            Layout.preferredWidth: 75
                            text: "CONDITION"
                            color: "#B5C8E2"
                            font.pixelSize: 8
                            font.bold: true
                        }

                        Text {
                            Layout.preferredWidth: 92
                            text: "STATUS"
                            color: "#B5C8E2"
                            font.pixelSize: 8
                            font.bold: true
                        }

                        Text {
                            Layout.preferredWidth: 74
                            text: "VALUE"
                            color: "#B5C8E2"
                            font.pixelSize: 8
                            font.bold: true
                        }

                        Text {
                            Layout.preferredWidth: 92
                            text: "ACTIONS"
                            color: "#B5C8E2"
                            font.pixelSize: 8
                            font.bold: true
                        }
                    }
                }

                // Scrollable inventory
                ListView {
                    id: assetList

                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    clip: true
                    spacing: 5

                    model: page.assets

                    boundsBehavior: Flickable.StopAtBounds

                    ScrollBar.vertical: ScrollBar {
                        policy: ScrollBar.AsNeeded
                    }

                    delegate: Rectangle {
                        width: assetList.width
                        height: 49

                        radius: 9

                        color: index % 2 === 0
                               ? "#1AFFFFFF"
                               : "#0CFFFFFF"

                        border.width: 1
                        border.color: "#28FFFFFF"

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
                                color: "#83CFFF"
                                font.pixelSize: 9
                                font.bold: true
                                elide: Text.ElideRight
                            }

                            Text {
                                Layout.fillWidth: true
                                text: modelData.asset_name || ""
                                color: "#EAF0FC"
                                font.pixelSize: 10
                                elide: Text.ElideRight
                            }

                            Text {
                                Layout.preferredWidth: 85
                                text: modelData.category || ""
                                color: "#B9C9DF"
                                font.pixelSize: 9
                                elide: Text.ElideRight
                            }

                            Text {
                                Layout.preferredWidth: 105
                                text: page.locationName(modelData)
                                color: "#B9C9DF"
                                font.pixelSize: 9
                                elide: Text.ElideRight
                            }

                            Text {
                                Layout.preferredWidth: 75
                                text: modelData.asset_condition || ""
                                color: page.conditionColor(
                                    modelData.asset_condition
                                )
                                font.pixelSize: 9
                                elide: Text.ElideRight
                            }

                            Text {
                                Layout.preferredWidth: 92
                                text: modelData.status || ""
                                color: page.statusColor(modelData.status)
                                font.pixelSize: 9
                                elide: Text.ElideRight
                            }

                            Text {
                                Layout.preferredWidth: 74
                                text: page.money(modelData.purchase_cost)
                                color: "#D7E2F3"
                                font.pixelSize: 9
                                elide: Text.ElideRight
                            }

                            RowLayout {
                                Layout.preferredWidth: 92
                                spacing: 4

                                GlassButton {
                                    label: "Edit"
                                    backdropSource: page.backdropSource

                                    Layout.preferredWidth: 43
                                    Layout.preferredHeight: 29

                                    onClicked: {
                                        page.openEditAsset(modelData)
                                    }
                                }

                                GlassButton {
                                    label: "Del"
                                    backdropSource: page.backdropSource

                                    Layout.preferredWidth: 42
                                    Layout.preferredHeight: 29

                                    onClicked: {
                                        deleteDialog.assetId =
                                            modelData.asset_id

                                        deleteDialog.open()
                                    }
                                }
                            }
                        }
                    }

                    // Empty state
                    Item {
                        anchors.centerIn: parent

                        width: 260
                        height: 90

                        visible: page.assets.length === 0

                        Column {
                            anchors.centerIn: parent
                            spacing: 7

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "◇"
                                color: "#83CFFF"
                                font.pixelSize: 27
                            }

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "No assets found"
                                color: "#DCE8F8"
                                font.pixelSize: 13
                                font.weight: Font.DemiBold
                            }

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "Try changing your search or filters."
                                color: "#8FA4C2"
                                font.pixelSize: 10
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

        width: 390

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
            spacing: 15

            Text {
                Layout.fillWidth: true

                text: "Are you sure you want to delete this asset? This action cannot be undone."

                color: "#EAF0FC"
                wrapMode: Text.WordWrap
                font.pixelSize: 12
            }

            RowLayout {
                Layout.fillWidth: true

                Item {
                    Layout.fillWidth: true
                }

                GlassButton {
                    label: "Cancel"
                    backdropSource: page.backdropSource

                    Layout.preferredWidth: 85
                    Layout.preferredHeight: 36

                    onClicked: deleteDialog.close()
                }

                GlassButton {
                    label: "Delete"
                    primary: true
                    backdropSource: page.backdropSource

                    Layout.preferredWidth: 85
                    Layout.preferredHeight: 36

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

            width: Math.min(490, parent.width - 30)
            height: Math.min(660, parent.height - 30)

            anchors.centerIn: parent

            radius: 20
            glassTint: 0.20
            blurAmount: 0.82
            backdropSource: page.backdropSource

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 21
                spacing: 10

                // Form heading
                RowLayout {
                    Layout.fillWidth: true

                    ColumnLayout {
                        spacing: 4

                        Text {
                            text: page.editingAssetId > 0
                                  ? "Edit asset"
                                  : "Register new asset"

                            color: "#F2F6FF"
                            font.pixelSize: 20
                            font.bold: true
                        }

                        Text {
                            text: "Enter the asset information below."
                            color: "#A4B8D5"
                            font.pixelSize: 10
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    GlassButton {
                        label: "✕"
                        backdropSource: page.backdropSource

                        Layout.preferredWidth: 36
                        Layout.preferredHeight: 34

                        onClicked: page.formVisible = false
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: "#38FFFFFF"
                }

                // Scrollable form content
                ScrollView {
                    id: formScroll

                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    clip: true

                    ScrollBar.vertical.policy: ScrollBar.AsNeeded

                    ColumnLayout {
                        width: formScroll.availableWidth
                        spacing: 9

                        Label {
                            text: "Asset code *"
                            color: "#C1D0E5"
                            font.pixelSize: 10
                        }

                        GlassField {
                            id: assetCodeField

                            Layout.fillWidth: true
                            placeholderText: "Example: AST-0100"
                        }

                        Label {
                            text: "Asset name *"
                            color: "#C1D0E5"
                            font.pixelSize: 10
                        }

                        GlassField {
                            id: assetNameField

                            Layout.fillWidth: true
                            placeholderText: "Example: Desktop Computer"
                        }

                        Label {
                            text: "Category *"
                            color: "#C1D0E5"
                            font.pixelSize: 10
                        }

                        GlassField {
                            id: categoryField

                            Layout.fillWidth: true
                            placeholderText: "Example: Electronics"
                        }

                        Label {
                            text: "Location"
                            color: "#C1D0E5"
                            font.pixelSize: 10
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
                            spacing: 10

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 7

                                Label {
                                    text: "Condition"
                                    color: "#C1D0E5"
                                    font.pixelSize: 10
                                }

                                GlassCombo {
                                    id: conditionCombo

                                    Layout.fillWidth: true
                                    model: page.conditionOptions
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 7

                                Label {
                                    text: "Status"
                                    color: "#C1D0E5"
                                    font.pixelSize: 10
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
                            color: "#C1D0E5"
                            font.pixelSize: 10
                        }

                        GlassField {
                            id: purchaseDateField

                            Layout.fillWidth: true
                            placeholderText: "2026-10-10"
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 7

                                Label {
                                    text: "Purchase cost"
                                    color: "#C1D0E5"
                                    font.pixelSize: 10
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
                                spacing: 7

                                Label {
                                    text: "Estimated repair cost"
                                    color: "#C1D0E5"
                                    font.pixelSize: 10
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
                            Layout.preferredHeight: 8
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: "#30FFFFFF"
                }

                // Form actions
                RowLayout {
                    Layout.fillWidth: true

                    Item {
                        Layout.fillWidth: true
                    }

                    GlassButton {
                        label: "Cancel"
                        backdropSource: page.backdropSource

                        Layout.preferredWidth: 85
                        Layout.preferredHeight: 38

                        onClicked: page.formVisible = false
                    }

                    GlassButton {
                        label: page.editingAssetId > 0
                               ? "Save Changes"
                               : "Register Asset"

                        primary: true
                        backdropSource: page.backdropSource

                        Layout.preferredWidth: 135
                        Layout.preferredHeight: 38

                        onClicked: page.saveCurrentAsset()
                    }
                }
            }
        }
    }
}