import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: page

    property var backend: null
    property Item backdropSource: null
    property var assets: []
    property var records: []
    property var assetOptions: []
    property string noticeText: ""
    property bool noticeIsError: false

    signal backRequested()

    function textValue(value, fallback) {
        return value === undefined || value === null || String(value).trim() === ""
                ? fallback : String(value)
    }

    function money(value) {
        var amount = Number(value || 0)
        if (isNaN(amount)) amount = 0
        return "৳ " + amount.toLocaleString(Qt.locale("en_US"), "f", 2)
    }

    function totalCost() {
        var total = 0
        for (var i = 0; i < records.length; i++)
            total += Number(records[i].cost || 0)
        return total
    }

    function refreshData() {
        if (!backend)
            return
        try {
            assets = backend.getAssets("", "", "", "") || []
            records = backend.getMaintenanceRecords() || []
            var options = []
            for (var i = 0; i < assets.length; i++) {
                var item = assets[i]
                options.push({
                    label: textValue(item.asset_name, "Unnamed asset")
                           + "  ·  " + textValue(item.asset_code, "—"),
                    asset_id: Number(item.asset_id)
                })
            }
            assetOptions = options
            if (assetPicker.currentIndex < 0 && assetOptions.length > 0)
                assetPicker.currentIndex = 0
        } catch (error) {
            noticeText = "Could not load maintenance data: " + error
            noticeIsError = true
        }
    }

    function saveRecord() {
        if (!backend) {
            noticeText = "The database connection is not available."
            noticeIsError = true
            return
        }
        if (assetPicker.currentIndex < 0 || assetPicker.currentIndex >= assetOptions.length) {
            noticeText = "Register an asset before creating a maintenance record."
            noticeIsError = true
            return
        }
        if (!/^\d{4}-\d{2}-\d{2}$/.test(dateField.text.trim())) {
            noticeText = "Use YYYY-MM-DD for the maintenance date."
            noticeIsError = true
            return
        }
        var cost = Number(costField.text || 0)
        if (isNaN(cost) || cost < 0) {
            noticeText = "Enter a valid non-negative maintenance cost."
            noticeIsError = true
            return
        }
        if (descriptionField.text.trim() === "") {
            noticeText = "Enter a description of the maintenance work."
            noticeIsError = true
            return
        }

        var selected = assetOptions[assetPicker.currentIndex]
        var result = backend.saveMaintenanceRecord({
            asset_id: Number(selected.asset_id),
            maintenance_date: dateField.text.trim(),
            description: descriptionField.text.trim(),
            cost: cost,
            status: statusPicker.currentText
        })

        if (result && result.success) {
            noticeText = result.message || "Maintenance record saved."
            noticeIsError = false
            descriptionField.text = ""
            costField.text = "0"
            refreshData()
        } else {
            noticeText = result && result.message
                        ? result.message : "Could not save maintenance record."
            noticeIsError = true
        }
    }

    function statusColor(status) {
        var value = String(status || "").toLowerCase()
        if (value.indexOf("complete") >= 0 || value.indexOf("closed") >= 0)
            return "#68D9B0"
        if (value.indexOf("progress") >= 0 || value.indexOf("pending") >= 0)
            return "#F2B76F"
        return "#83CFFF"
    }

    Connections {
        target: page.backend
        function onMaintenanceChanged() { page.refreshData() }
        function onAssetsChanged() { page.refreshData() }
    }

    Component.onCompleted: refreshData()
    onVisibleChanged: if (visible) refreshData()

    ColumnLayout {
        anchors.fill: parent
        spacing: 15

        // PAGE HEADER
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 65
            spacing: 12

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 3
                Text {
                    text: "Maintenance Management"
                    color: "#FFFFFF"
                    font.pixelSize: 27
                    font.weight: Font.Bold
                }
                Text {
                    text: "Register repair and service work and track actual expenses."
                    color: "#D7E2F1"
                    font.pixelSize: 12
                }
            }

            Rectangle {
                Layout.preferredWidth: 132
                Layout.preferredHeight: 40
                radius: 12
                color: backMouse.containsMouse ? "#35FFFFFF" : "#1EFFFFFF"
                border.width: 1
                border.color: "#4AFFFFFF"
                RowLayout {
                    anchors.centerIn: parent
                    spacing: 7
                    Text { text: "←"; color: "#FFFFFF"; font.pixelSize: 17 }
                    Text { text: "Overview"; color: "#FFFFFF"; font.pixelSize: 12; font.weight: Font.DemiBold }
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

        // SUMMARY STRIP
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 85
            spacing: 12

            GlassPanel {
                Layout.fillWidth: true
                Layout.fillHeight: true
                backdropSource: page.backdropSource
                glassTint: 0.10
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 3
                    Text { text: "TOTAL MAINTENANCE COST"; color: "#B9CBE0"; font.pixelSize: 9; font.weight: Font.Bold; font.letterSpacing: 0.8 }
                    Text { text: page.money(page.totalCost()); color: "#FFFFFF"; font.pixelSize: 23; font.weight: Font.Bold }
                    Text { text: page.records.length + " recorded maintenance entries"; color: "#D7E2F1"; font.pixelSize: 10 }
                }
            }
            GlassPanel {
                Layout.fillWidth: true
                Layout.fillHeight: true
                backdropSource: page.backdropSource
                glassTint: 0.10
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 3
                    Text { text: "MAINTENANCE RECORDS"; color: "#B9CBE0"; font.pixelSize: 9; font.weight: Font.Bold; font.letterSpacing: 0.8 }
                    Text { text: String(page.records.length); color: "#FFFFFF"; font.pixelSize: 23; font.weight: Font.Bold }
                    Text { text: "Stored in local SQLite database"; color: "#D7E2F1"; font.pixelSize: 10 }
                }
            }
        }

        // FORM + HISTORY
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 14

            GlassPanel {
                Layout.preferredWidth: 360
                Layout.minimumWidth: 310
                Layout.fillHeight: true
                backdropSource: page.backdropSource
                glassTint: 0.12

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 18
                    spacing: 10

                    Text {
                        text: "Register maintenance"
                        color: "#FFFFFF"
                        font.pixelSize: 18
                        font.weight: Font.DemiBold
                    }
                    Text {
                        text: "Record the actual work and amount spent."
                        color: "#D7E2F1"
                        font.pixelSize: 11
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: "#35FFFFFF" }

                    Text { text: "SELECT ASSET"; color: "#C2D0E2"; font.pixelSize: 9; font.weight: Font.Bold; font.letterSpacing: 0.7 }
                    ComboBox {
                        id: assetPicker
                        Layout.fillWidth: true
                        Layout.preferredHeight: 40
                        model: page.assetOptions
                        textRole: "label"
                        currentIndex: page.assetOptions.length > 0 ? 0 : -1
                        contentItem: Text {
                            leftPadding: 11
                            rightPadding: 26
                            text: assetPicker.displayText || "Select an asset"
                            color: "#FFFFFF"
                            font.pixelSize: 11
                            verticalAlignment: Text.AlignVCenter
                            elide: Text.ElideRight
                        }
                        indicator: Text {
                            x: assetPicker.width - width - 10
                            y: (assetPicker.height - height) / 2
                            text: "⌄"
                            color: "#D7E2F1"
                            font.pixelSize: 17
                        }
                        background: Rectangle {
                            radius: 10
                            color: "#29101D30"
                            border.color: "#45FFFFFF"
                        }
                        delegate: ItemDelegate {
                            width: assetPicker.width
                            contentItem: Text {
                                text: modelData.label
                                color: "#FFFFFF"
                                font.pixelSize: 11
                                verticalAlignment: Text.AlignVCenter
                                elide: Text.ElideRight
                            }
                            background: Rectangle { color: highlighted ? "#385A7C" : "#172943"; radius: 6 }
                        }
                        popup: Popup {
                            y: assetPicker.height + 4
                            width: assetPicker.width
                            padding: 5
                            contentItem: ListView {
                                implicitHeight: Math.min(contentHeight, 190)
                                model: assetPicker.popup.visible ? assetPicker.delegateModel : null
                                clip: true
                            }
                            background: Rectangle { color: "#172943"; radius: 10; border.color: "#52708F" }
                        }
                    }

                    Text { text: "MAINTENANCE DATE"; color: "#C2D0E2"; font.pixelSize: 9; font.weight: Font.Bold; font.letterSpacing: 0.7 }
                    TextField {
                        id: dateField
                        Layout.fillWidth: true
                        Layout.preferredHeight: 40
                        text: Qt.formatDate(new Date(), "yyyy-MM-dd")
                        placeholderText: "YYYY-MM-DD"
                        color: "#FFFFFF"
                        font.pixelSize: 11
                        selectByMouse: true
                        background: Rectangle { radius: 10; color: "#29101D30"; border.color: "#45FFFFFF" }
                    }

                    Text { text: "WORK / PROBLEM DESCRIPTION"; color: "#C2D0E2"; font.pixelSize: 9; font.weight: Font.Bold; font.letterSpacing: 0.7 }
                    TextField {
                        id: descriptionField
                        Layout.fillWidth: true
                        Layout.preferredHeight: 42
                        placeholderText: "e.g. Motherboard repair and testing"
                        color: "#FFFFFF"
                        font.pixelSize: 11
                        selectByMouse: true
                        background: Rectangle { radius: 10; color: "#29101D30"; border.color: "#45FFFFFF" }
                    }

                    Text { text: "ACTUAL MAINTENANCE COST (৳)"; color: "#C2D0E2"; font.pixelSize: 9; font.weight: Font.Bold; font.letterSpacing: 0.7 }
                    TextField {
                        id: costField
                        Layout.fillWidth: true
                        Layout.preferredHeight: 40
                        text: "0"
                        placeholderText: "Enter actual amount spent"
                        color: "#FFFFFF"
                        font.pixelSize: 12
                        selectByMouse: true
                        validator: DoubleValidator { bottom: 0; decimals: 2; notation: DoubleValidator.StandardNotation }
                        background: Rectangle { radius: 10; color: "#29101D30"; border.color: "#45FFFFFF" }
                    }

                    Text { text: "STATUS"; color: "#C2D0E2"; font.pixelSize: 9; font.weight: Font.Bold; font.letterSpacing: 0.7 }
                    ComboBox {
                        id: statusPicker
                        Layout.fillWidth: true
                        Layout.preferredHeight: 40
                        model: ["Completed", "In Progress", "Pending"]
                        currentIndex: 0
                        contentItem: Text {
                            leftPadding: 11
                            rightPadding: 24
                            text: statusPicker.displayText
                            color: "#FFFFFF"
                            font.pixelSize: 11
                            verticalAlignment: Text.AlignVCenter
                        }
                        indicator: Text { x: statusPicker.width - width - 10; y: (statusPicker.height - height) / 2; text: "⌄"; color: "#D7E2F1"; font.pixelSize: 17 }
                        background: Rectangle { radius: 10; color: "#29101D30"; border.color: "#45FFFFFF" }
                    }

                    Item { Layout.fillHeight: true }

                    Text {
                        Layout.fillWidth: true
                        visible: page.noticeText !== ""
                        text: page.noticeText
                        color: page.noticeIsError ? "#F3A5B2" : "#88E5C0"
                        font.pixelSize: 10
                        wrapMode: Text.WordWrap
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 43
                        radius: 11
                        color: saveMouse.containsMouse ? "#579BD9" : "#397FBF"
                        border.width: 1
                        border.color: "#82C9F5"
                        Text {
                            anchors.centerIn: parent
                            text: "SAVE MAINTENANCE RECORD"
                            color: "#FFFFFF"
                            font.pixelSize: 10
                            font.weight: Font.Bold
                            font.letterSpacing: 0.5
                        }
                        MouseArea {
                            id: saveMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: page.saveRecord()
                        }
                    }
                }
            }

            GlassPanel {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumWidth: 340
                backdropSource: page.backdropSource
                glassTint: 0.12

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 18
                    spacing: 10

                    RowLayout {
                        Layout.fillWidth: true
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 3
                            Text { text: "Maintenance history"; color: "#FFFFFF"; font.pixelSize: 18; font.weight: Font.DemiBold }
                            Text { text: "All recorded maintenance expenses"; color: "#D7E2F1"; font.pixelSize: 11 }
                        }
                        Text { text: page.records.length + " RECORDS"; color: "#B9DFFF"; font.pixelSize: 10; font.weight: Font.Bold }
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: "#35FFFFFF" }

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true

                        ListView {
                            id: recordsList
                            anchors.fill: parent
                            clip: true
                            spacing: 7
                            model: page.records
                            boundsBehavior: Flickable.StopAtBounds
                            ScrollBar.vertical: ScrollBar {
                                active: true
                                policy: ScrollBar.AsNeeded
                            }

                            delegate: Rectangle {
                                required property var modelData
                                width: recordsList.width - 8
                                height: 73
                                radius: 11
                                color: "#18FFFFFF"
                                border.width: 1
                                border.color: "#25FFFFFF"

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
                                        Text { anchors.centerIn: parent; text: "⚙"; color: page.statusColor(modelData.status); font.pixelSize: 17 }
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 3
                                        Text {
                                            Layout.fillWidth: true
                                            text: page.textValue(modelData.asset_name, "Unnamed asset")
                                            color: "#FFFFFF"
                                            font.pixelSize: 12
                                            font.weight: Font.DemiBold
                                            elide: Text.ElideRight
                                        }
                                        Text {
                                            Layout.fillWidth: true
                                            text: page.textValue(modelData.description, "Maintenance work")
                                            color: "#D7E2F1"
                                            font.pixelSize: 10
                                            elide: Text.ElideRight
                                        }
                                        Text {
                                            Layout.fillWidth: true
                                            text: page.textValue(modelData.maintenance_date, "Date not recorded")
                                                  + "  ·  " + page.textValue(modelData.asset_code, "—")
                                            color: "#AFC0D5"
                                            font.pixelSize: 9
                                            elide: Text.ElideRight
                                        }
                                    }

                                    ColumnLayout {
                                        Layout.preferredWidth: 105
                                        spacing: 4
                                        Text {
                                            text: page.money(modelData.cost)
                                            color: "#FFFFFF"
                                            font.pixelSize: 11
                                            font.weight: Font.Bold
                                            horizontalAlignment: Text.AlignRight
                                        }
                                        Text {
                                            text: page.textValue(modelData.status, "Unknown")
                                            color: page.statusColor(modelData.status)
                                            font.pixelSize: 9
                                            horizontalAlignment: Text.AlignRight
                                        }
                                    }
                                }
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            visible: page.records.length === 0
                            text: "No maintenance records yet. Register a service or repair to begin tracking actual costs."
                            color: "#D7E2F1"
                            font.pixelSize: 12
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.WordWrap
                            width: parent.width * 0.75
                        }
                    }
                }
            }
        }
    }
}
