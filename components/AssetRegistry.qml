
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects


Item {
    id: page

    property var backend: null

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


    // =====================================================
    // 01. DATA LOADING
    // =====================================================

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

        let selectedLocation = locationCombo.currentIndex > 0
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


    // =====================================================
    // 02. DATABASE SIGNAL CONNECTION
    // =====================================================

    Connections {
        target: page.backend

        function onAssetsChanged() {
            page.refreshData()
        }
    }

    Component.onCompleted: refreshData()


    // =====================================================
    // 03. MESSAGE DIALOG
    // =====================================================

    Dialog {
        id: messageDialog

        anchors.centerIn: parent

        width: 350

        modal: true

        background: Rectangle {
            radius: 16
            color: "#18253B"
            border.color: "#526D91"
            border.width: 1
        }

        contentItem: ColumnLayout {
            spacing: 14

            Text {
                text: messageText.text
                color: "#EAF2FF"
                font.pixelSize: 12
                wrapMode: Text.WordWrap

                Layout.fillWidth: true
            }

            Button {
                text: "Continue"
                Layout.alignment: Qt.AlignRight

                onClicked: messageDialog.close()
            }
        }
    }

    QtObject {
        id: messageText
        property string text: ""
    }


    // =====================================================
    // 04. MAIN PAGE LAYOUT
    // =====================================================

    ColumnLayout {
        anchors.fill: parent
        spacing: 15


        // =================================================
        // A. PAGE HEADER
        // =================================================

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 65

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

            Button {
                text: "+  Add New Asset"

                onClicked: page.openNewAsset()

                contentItem: Text {
                    text: parent.text
                    color: "#071626"
                    font.pixelSize: 11
                    font.weight: Font.Bold
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                background: Rectangle {
                    radius: 10
                    color: "#83CFFF"
                }

                Layout.preferredWidth: 145
                Layout.preferredHeight: 39
            }
        }


        // =================================================
        // B. STATISTICS
        // =================================================

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
                                || a.status === "Out of Service"
                        ).length,
                        accent: "#F2B76F"
                    },
                    {
                        label: "PURCHASE VALUE",
                        value: page.money(
                            page.assets.reduce(
                                (sum, a) => sum + Number(a.purchase_cost || 0),
                                0
                            )
                        ),
                        accent: "#B9A2FF"
                    }
                ]

                delegate: Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 82

                    radius: 13
                    color: "#18243A"
                    border.width: 1
                    border.color: "#35FFFFFF"

                    Rectangle {
                        width: 3
                        height: 38
                        radius: 2
                        color: modelData.accent

                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 23
                        anchors.rightMargin: 10
                        anchors.topMargin: 12
                        anchors.bottomMargin: 10
                        spacing: 5

                        Text {
                            text: modelData.label
                            color: "#91A5C5"
                            font.pixelSize: 8
                            font.weight: Font.Bold
                        }

                        Text {
                            text: String(modelData.value)
                            color: "#F4F7FF"
                            font.pixelSize: 20
                            font.weight: Font.Bold
                        }
                    }
                }
            }
        }


        // =================================================
        // C. SEARCH AND FILTER BAR
        // =================================================

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 58

            radius: 12
            color: "#18243A"
            border.color: "#32FFFFFF"
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.margins: 9
                spacing: 9

                TextField {
                    Layout.fillWidth: true

                    placeholderText: "Search code, asset, category or building..."
                    text: page.searchText

                    color: "#EDF4FF"
                    placeholderTextColor: "#7186A6"

                    background: Rectangle {
                        radius: 8
                        color: "#172A43"
                        border.color: "#304B6C"
                        border.width: 1
                    }

                    onTextChanged: {
                        page.searchText = text
                        page.refreshData()
                    }
                }

                ComboBox {
                    id: filterCondition

                    Layout.preferredWidth: 120

                    model: ["All Conditions"].concat(
                        page.conditionOptions
                    )

                    onActivated: {
                        page.selectedCondition =
                            currentIndex === 0 ? "" : currentText

                        page.refreshData()
                    }
                }

                ComboBox {
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

                Button {
                    text: "Reset"

                    onClicked: {
                        page.searchText = ""
                        page.selectedCondition = ""
                        page.selectedStatus = ""
                        page.selectedCategory = ""

                        filterCondition.currentIndex = 0
                        filterStatus.currentIndex = 0

                        page.refreshData()
                    }
                }
            }
        }


        // =================================================
        // D. ASSET INVENTORY
        // =================================================

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true

            radius: 15
            color: "#162238"
            border.color: "#38FFFFFF"
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 15
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: "Asset inventory"
                        color: "#F1F5FF"
                        font.pixelSize: 14
                        font.weight: Font.DemiBold
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    Text {
                        text: page.assets.length + " ASSETS"
                        color: "#91A5C5"
                        font.pixelSize: 9
                        font.weight: Font.Bold
                    }
                }


                // TABLE HEADER

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 38

                    radius: 7
                    color: "#263953"

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10

                        Text {
                            Layout.preferredWidth: 75
                            text: "CODE"
                            color: "#9FB3D0"
                            font.pixelSize: 9
                            font.bold: true
                        }

                        Text {
                            Layout.fillWidth: true
                            text: "ASSET"
                            color: "#9FB3D0"
                            font.pixelSize: 9
                            font.bold: true
                        }

                        Text {
                            Layout.preferredWidth: 90
                            text: "CATEGORY"
                            color: "#9FB3D0"
                            font.pixelSize: 9
                            font.bold: true
                        }

                        Text {
                            Layout.preferredWidth: 115
                            text: "LOCATION"
                            color: "#9FB3D0"
                            font.pixelSize: 9
                            font.bold: true
                        }

                        Text {
                            Layout.preferredWidth: 82
                            text: "CONDITION"
                            color: "#9FB3D0"
                            font.pixelSize: 9
                            font.bold: true
                        }

                        Text {
                            Layout.preferredWidth: 95
                            text: "STATUS"
                            color: "#9FB3D0"
                            font.pixelSize: 9
                            font.bold: true
                        }

                        Text {
                            Layout.preferredWidth: 75
                            text: "VALUE"
                            color: "#9FB3D0"
                            font.pixelSize: 9
                            font.bold: true
                        }

                        Text {
                            Layout.preferredWidth: 95
                            text: "ACTIONS"
                            color: "#9FB3D0"
                            font.pixelSize: 9
                            font.bold: true
                        }
                    }
                }


                // TABLE CONTENT

                ListView {
                    id: assetList

                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    clip: true
                    spacing: 5

                    model: page.assets

                    ScrollBar.vertical: ScrollBar {
                        policy: ScrollBar.AsNeeded
                    }

                    delegate: Rectangle {
                        width: assetList.width
                        height: 51

                        radius: 8

                        color: index % 2 === 0
                               ? "#172A42"
                               : "#1C304A"

                        border.color: "#18FFFFFF"
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 8
                            spacing: 3

                            Text {
                                Layout.preferredWidth: 75
                                text: modelData.asset_code
                                color: "#83CFFF"
                                font.pixelSize: 9
                                font.bold: true
                                elide: Text.ElideRight
                            }

                            Text {
                                Layout.fillWidth: true
                                text: modelData.asset_name
                                color: "#EAF0FC"
                                font.pixelSize: 10
                                elide: Text.ElideRight
                            }

                            Text {
                                Layout.preferredWidth: 90
                                text: modelData.category
                                color: "#AABBD4"
                                font.pixelSize: 9
                                elide: Text.ElideRight
                            }

                            Text {
                                Layout.preferredWidth: 115
                                text: page.locationName(modelData)
                                color: "#AABBD4"
                                font.pixelSize: 9
                                elide: Text.ElideRight
                            }

                            Text {
                                Layout.preferredWidth: 82
                                text: modelData.asset_condition
                                color: modelData.asset_condition === "Good"
                                       ? "#68D9B0"
                                       : "#F2B76F"
                                font.pixelSize: 9
                                elide: Text.ElideRight
                            }

                            Text {
                                Layout.preferredWidth: 95
                                text: modelData.status
                                color: modelData.status === "In Service"
                                       ? "#68D9B0"
                                       : "#F2B76F"
                                font.pixelSize: 9
                                elide: Text.ElideRight
                            }

                            Text {
                                Layout.preferredWidth: 75
                                text: page.money(modelData.purchase_cost)
                                color: "#D7E2F3"
                                font.pixelSize: 9
                                elide: Text.ElideRight
                            }

                            RowLayout {
                                Layout.preferredWidth: 95
                                spacing: 4

                                Button {
                                    text: "Edit"

                                    onClicked: {
                                        page.openEditAsset(modelData)
                                    }

                                    Layout.preferredWidth: 43
                                    Layout.preferredHeight: 27
                                }

                                Button {
                                    text: "Del"

                                    onClicked: {
                                        deleteDialog.assetId =
                                            modelData.asset_id

                                        deleteDialog.open()
                                    }

                                    Layout.preferredWidth: 40
                                    Layout.preferredHeight: 27
                                }
                            }
                        }
                    }

                    Text {
                        anchors.centerIn: parent

                        visible: page.assets.length === 0

                        text: "No assets found"
                        color: "#91A5C5"
                        font.pixelSize: 13
                    }
                }
            }
        }
    }


    
    // =====================================================
    // 05. DELETE CONFIRMATION
    // =====================================================

    Dialog {
        id: deleteDialog

        property int assetId: 0

        width: 390

        x: (page.width - width) / 2
        y: (page.height - height) / 2

        modal: true

        title: "Delete asset?"

        standardButtons: Dialog.Yes | Dialog.No

        background: Rectangle {
            color: "#1A2940"
            radius: 13
            border.color: "#58708E"
            border.width: 1
        }

        contentItem: Text {
            width: 340

            text: "Are you sure you want to delete this asset? This action cannot be undone."

            color: "#EAF0FC"

            wrapMode: Text.WordWrap

            font.pixelSize: 12
        }

        onAccepted: {
            page.deleteCurrentAsset(assetId)
        }
    }



    // =====================================================
    // 06. ADD / EDIT ASSET FORM
    // =====================================================

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


        Rectangle {
            id: formPanel

            width: Math.min(480, parent.width - 30)
            height: Math.min(650, parent.height - 30)

            anchors.centerIn: parent

            radius: 18

            color: "#192A43"
            border.width: 1
            border.color: "#75BDEB"

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 22

                spacing: 12


                // FORM HEADER

                RowLayout {
                    Layout.fillWidth: true

                    ColumnLayout {
                        spacing: 3

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
                            color: "#91A5C5"
                            font.pixelSize: 10
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    Button {
                        text: "✕"
                        onClicked: page.formVisible = false
                    }
                }


                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: "#35FFFFFF"
                }


                // ASSET CODE

                Label {
                    text: "Asset code *"
                    color: "#B9C9DF"
                }

                TextField {
                    id: assetCodeField
                    Layout.fillWidth: true
                    placeholderText: "Example: AST-0100"
                }


                // ASSET NAME

                Label {
                    text: "Asset name *"
                    color: "#B9C9DF"
                }

                TextField {
                    id: assetNameField
                    Layout.fillWidth: true
                    placeholderText: "Example: Desktop Computer"
                }


                // CATEGORY

                Label {
                    text: "Category *"
                    color: "#B9C9DF"
                }

                TextField {
                    id: categoryField
                    Layout.fillWidth: true
                    placeholderText: "Example: Electronics"
                }


                // LOCATION

                Label {
                    text: "Location"
                    color: "#B9C9DF"
                }

                ComboBox {
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


                // CONDITION AND STATUS

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    ColumnLayout {
                        Layout.fillWidth: true

                        Label {
                            text: "Condition"
                            color: "#B9C9DF"
                        }

                        ComboBox {
                            id: conditionCombo
                            Layout.fillWidth: true
                            model: page.conditionOptions
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true

                        Label {
                            text: "Status"
                            color: "#B9C9DF"
                        }

                        ComboBox {
                            id: statusCombo
                            Layout.fillWidth: true
                            model: page.statusOptions
                        }
                    }
                }


                // PURCHASE DATE

                Label {
                    text: "Purchase date (YYYY-MM-DD)"
                    color: "#B9C9DF"
                }

                TextField {
                    id: purchaseDateField
                    Layout.fillWidth: true
                    placeholderText: "2026-10-10"
                }


                // COSTS

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    ColumnLayout {
                        Layout.fillWidth: true

                        Label {
                            text: "Purchase cost"
                            color: "#B9C9DF"
                        }

                        TextField {
                            id: purchaseCostField
                            Layout.fillWidth: true
                            text: "0"
                            inputMethodHints: Qt.ImhFormattedNumbersOnly
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true

                        Label {
                            text: "Estimated repair cost"
                            color: "#B9C9DF"
                        }

                        TextField {
                            id: repairCostField
                            Layout.fillWidth: true
                            text: "0"
                            inputMethodHints: Qt.ImhFormattedNumbersOnly
                        }
                    }
                }


                Item {
                    Layout.fillHeight: true
                }


                // FORM ACTIONS

                RowLayout {
                    Layout.fillWidth: true

                    Item {
                        Layout.fillWidth: true
                    }

                    Button {
                        text: "Cancel"

                        onClicked: page.formVisible = false
                    }

                    Button {
                        text: page.editingAssetId > 0
                              ? "Save Changes"
                              : "Register Asset"

                        onClicked: page.saveCurrentAsset()
                    }
                }
            }
        }
    }
}
