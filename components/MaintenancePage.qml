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
                    text: assetBackend.translateText("Maintenance Management", assetBackend.language)
                    color: assetBackend.themeColor("#FFFFFF", assetBackend.theme)
                    font.pixelSize: 27 * assetBackend.fontScale
                    font.weight: Font.Bold
                }
                Text {
                    text: assetBackend.translateText("Register repair and service work and track actual expenses.", assetBackend.language)
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
                    Text { text: assetBackend.translateText("←", assetBackend.language); color: assetBackend.themeColor("#FFFFFF", assetBackend.theme); font.pixelSize: 17 * assetBackend.fontScale }
                    Text { text: assetBackend.translateText("Overview", assetBackend.language); color: assetBackend.themeColor("#FFFFFF", assetBackend.theme); font.pixelSize: 12 * assetBackend.fontScale; font.weight: Font.DemiBold }
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
                    Text { text: assetBackend.translateText("TOTAL MAINTENANCE COST", assetBackend.language); color: assetBackend.themeColor("#B9CBE0", assetBackend.theme); font.pixelSize: 9 * assetBackend.fontScale; font.weight: Font.Bold; font.letterSpacing: 0.8 }
                    Text { text: page.money(page.totalCost()); color: assetBackend.themeColor("#FFFFFF", assetBackend.theme); font.pixelSize: 23 * assetBackend.fontScale; font.weight: Font.Bold }
                    Text { text: page.records.length + " recorded maintenance entries"; color: assetBackend.themeColor("#D7E2F1", assetBackend.theme); font.pixelSize: 10 * assetBackend.fontScale }
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
                    Text { text: assetBackend.translateText("MAINTENANCE RECORDS", assetBackend.language); color: assetBackend.themeColor("#B9CBE0", assetBackend.theme); font.pixelSize: 9 * assetBackend.fontScale; font.weight: Font.Bold; font.letterSpacing: 0.8 }
                    Text { text: String(page.records.length); color: assetBackend.themeColor("#FFFFFF", assetBackend.theme); font.pixelSize: 23 * assetBackend.fontScale; font.weight: Font.Bold }
                    Text { text: assetBackend.translateText("Stored in local SQLite database", assetBackend.language); color: assetBackend.themeColor("#D7E2F1", assetBackend.theme); font.pixelSize: 10 * assetBackend.fontScale }
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
                        text: assetBackend.translateText("Register maintenance", assetBackend.language)
                        color: assetBackend.themeColor("#FFFFFF", assetBackend.theme)
                        font.pixelSize: 18 * assetBackend.fontScale
                        font.weight: Font.DemiBold
                    }
                    Text {
                        text: assetBackend.translateText("Record the actual work and amount spent.", assetBackend.language)
                        color: assetBackend.themeColor("#D7E2F1", assetBackend.theme)
                        font.pixelSize: 11 * assetBackend.fontScale
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: assetBackend.themeColor("#35FFFFFF", assetBackend.theme) }

                    Text { text: assetBackend.translateText("SELECT ASSET", assetBackend.language); color: assetBackend.themeColor("#C2D0E2", assetBackend.theme); font.pixelSize: 9 * assetBackend.fontScale; font.weight: Font.Bold; font.letterSpacing: 0.7 }
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
                            color: assetBackend.themeColor("#FFFFFF", assetBackend.theme)
                            font.pixelSize: 11 * assetBackend.fontScale
                            verticalAlignment: Text.AlignVCenter
                            elide: Text.ElideRight
                        }
                        indicator: Text {
                            x: assetPicker.width - width - 10
                            y: (assetPicker.height - height) / 2
                            text: assetBackend.translateText("⌄", assetBackend.language)
                            color: assetBackend.themeColor("#D7E2F1", assetBackend.theme)
                            font.pixelSize: 17 * assetBackend.fontScale
                        }
                        background: Rectangle {
                            radius: 10
                            color: assetBackend.themeColor("#29101D30", assetBackend.theme)
                            border.color: assetBackend.themeColor("#45FFFFFF", assetBackend.theme)
                        }
                        delegate: ItemDelegate {
                            width: assetPicker.width
                            contentItem: Text {
                                text: modelData.label
                                color: assetBackend.themeColor("#FFFFFF", assetBackend.theme)
                                font.pixelSize: 11 * assetBackend.fontScale
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
                            background: Rectangle { color: assetBackend.themeColor("#172943", assetBackend.theme); radius: 10; border.color: assetBackend.themeColor("#52708F", assetBackend.theme) }
                        }
                    }

                    Text { text: assetBackend.translateText("MAINTENANCE DATE", assetBackend.language); color: assetBackend.themeColor("#C2D0E2", assetBackend.theme); font.pixelSize: 9 * assetBackend.fontScale; font.weight: Font.Bold; font.letterSpacing: 0.7 }
                    TextField {
                        id: dateField
                        Layout.fillWidth: true
                        Layout.preferredHeight: 40
                        text: Qt.formatDate(new Date(), "yyyy-MM-dd")
                        placeholderText: assetBackend.translateText("YYYY-MM-DD", assetBackend.language)
                        color: assetBackend.themeColor("#FFFFFF", assetBackend.theme)
                        font.pixelSize: 11 * assetBackend.fontScale
                        selectByMouse: true
                        background: Rectangle { radius: 10; color: assetBackend.themeColor("#29101D30", assetBackend.theme); border.color: assetBackend.themeColor("#45FFFFFF", assetBackend.theme) }
                    }

                    Text { text: assetBackend.translateText("WORK / PROBLEM DESCRIPTION", assetBackend.language); color: assetBackend.themeColor("#C2D0E2", assetBackend.theme); font.pixelSize: 9 * assetBackend.fontScale; font.weight: Font.Bold; font.letterSpacing: 0.7 }
                    TextField {
                        id: descriptionField
                        Layout.fillWidth: true
                        Layout.preferredHeight: 42
                        placeholderText: assetBackend.translateText("e.g. Motherboard repair and testing", assetBackend.language)
                        color: assetBackend.themeColor("#FFFFFF", assetBackend.theme)
                        font.pixelSize: 11 * assetBackend.fontScale
                        selectByMouse: true
                        background: Rectangle { radius: 10; color: assetBackend.themeColor("#29101D30", assetBackend.theme); border.color: assetBackend.themeColor("#45FFFFFF", assetBackend.theme) }
                    }

                    Text { text: assetBackend.translateText("ACTUAL MAINTENANCE COST (৳)", assetBackend.language); color: assetBackend.themeColor("#C2D0E2", assetBackend.theme); font.pixelSize: 9 * assetBackend.fontScale; font.weight: Font.Bold; font.letterSpacing: 0.7 }
                    TextField {
                        id: costField
                        Layout.fillWidth: true
                        Layout.preferredHeight: 40
                        text: assetBackend.translateText("0", assetBackend.language)
                        placeholderText: assetBackend.translateText("Enter actual amount spent", assetBackend.language)
                        color: assetBackend.themeColor("#FFFFFF", assetBackend.theme)
                        font.pixelSize: 12 * assetBackend.fontScale
                        selectByMouse: true
                        validator: DoubleValidator { bottom: 0; decimals: 2; notation: DoubleValidator.StandardNotation }
                        background: Rectangle { radius: 10; color: assetBackend.themeColor("#29101D30", assetBackend.theme); border.color: assetBackend.themeColor("#45FFFFFF", assetBackend.theme) }
                    }

                    Text { text: assetBackend.translateText("STATUS", assetBackend.language); color: assetBackend.themeColor("#C2D0E2", assetBackend.theme); font.pixelSize: 9 * assetBackend.fontScale; font.weight: Font.Bold; font.letterSpacing: 0.7 }
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
                            color: assetBackend.themeColor("#FFFFFF", assetBackend.theme)
                            font.pixelSize: 11 * assetBackend.fontScale
                            verticalAlignment: Text.AlignVCenter
                        }
                        indicator: Text { x: statusPicker.width - width - 10; y: (statusPicker.height - height) / 2; text: assetBackend.translateText("⌄", assetBackend.language); color: assetBackend.themeColor("#D7E2F1", assetBackend.theme); font.pixelSize: 17 * assetBackend.fontScale }
                        background: Rectangle { radius: 10; color: assetBackend.themeColor("#29101D30", assetBackend.theme); border.color: assetBackend.themeColor("#45FFFFFF", assetBackend.theme) }
                    }

                    Item { Layout.fillHeight: true }

                    Text {
                        Layout.fillWidth: true
                        visible: page.noticeText !== ""
                        text: page.noticeText
                        color: page.noticeIsError ? "#F3A5B2" : "#88E5C0"
                        font.pixelSize: 10 * assetBackend.fontScale
                        wrapMode: Text.WordWrap
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 43
                        radius: 11
                        color: saveMouse.containsMouse ? "#579BD9" : "#397FBF"
                        border.width: 1
                        border.color: assetBackend.themeColor("#82C9F5", assetBackend.theme)
                        Text {
                            anchors.centerIn: parent
                            text: assetBackend.translateText("SAVE MAINTENANCE RECORD", assetBackend.language)
                            color: assetBackend.themeColor("#FFFFFF", assetBackend.theme)
                            font.pixelSize: 10 * assetBackend.fontScale
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
                            Text { text: assetBackend.translateText("Maintenance history", assetBackend.language); color: assetBackend.themeColor("#FFFFFF", assetBackend.theme); font.pixelSize: 18 * assetBackend.fontScale; font.weight: Font.DemiBold }
                            Text { text: assetBackend.translateText("All recorded maintenance expenses", assetBackend.language); color: assetBackend.themeColor("#D7E2F1", assetBackend.theme); font.pixelSize: 11 * assetBackend.fontScale }
                        }
                        Text { text: page.records.length + " RECORDS"; color: assetBackend.themeColor("#B9DFFF", assetBackend.theme); font.pixelSize: 10 * assetBackend.fontScale; font.weight: Font.Bold }
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: assetBackend.themeColor("#35FFFFFF", assetBackend.theme) }

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
                                color: assetBackend.themeColor("#18FFFFFF", assetBackend.theme)
                                border.width: 1
                                border.color: assetBackend.themeColor("#25FFFFFF", assetBackend.theme)

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 12
                                    anchors.rightMargin: 12
                                    spacing: 10

                                    Rectangle {
                                        Layout.preferredWidth: 34
                                        Layout.preferredHeight: 34
                                        radius: 10
                                        color: assetBackend.themeColor("#263D6490", assetBackend.theme)
                                        Text { anchors.centerIn: parent; text: assetBackend.translateText("⚙", assetBackend.language); color: page.statusColor(modelData.status); font.pixelSize: 17 * assetBackend.fontScale }
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 3
                                        Text {
                                            Layout.fillWidth: true
                                            text: page.textValue(modelData.asset_name, "Unnamed asset")
                                            color: assetBackend.themeColor("#FFFFFF", assetBackend.theme)
                                            font.pixelSize: 12 * assetBackend.fontScale
                                            font.weight: Font.DemiBold
                                            elide: Text.ElideRight
                                        }
                                        Text {
                                            Layout.fillWidth: true
                                            text: page.textValue(modelData.description, "Maintenance work")
                                            color: assetBackend.themeColor("#D7E2F1", assetBackend.theme)
                                            font.pixelSize: 10 * assetBackend.fontScale
                                            elide: Text.ElideRight
                                        }
                                        Text {
                                            Layout.fillWidth: true
                                            text: page.textValue(assetBackend.formatDate(modelData.maintenance_date) || "Date not recorded")
                                                  + "  ·  " + page.textValue(modelData.asset_code, "—")
                                            color: assetBackend.themeColor("#AFC0D5", assetBackend.theme)
                                            font.pixelSize: 9 * assetBackend.fontScale
                                            elide: Text.ElideRight
                                        }
                                    }

                                    ColumnLayout {
                                        Layout.preferredWidth: 105
                                        spacing: 4
                                        Text {
                                            text: page.money(modelData.cost)
                                            color: assetBackend.themeColor("#FFFFFF", assetBackend.theme)
                                            font.pixelSize: 11 * assetBackend.fontScale
                                            font.weight: Font.Bold
                                            horizontalAlignment: Text.AlignRight
                                        }
                                        Text {
                                            text: page.textValue(modelData.status, "Unknown")
                                            color: page.statusColor(modelData.status)
                                            font.pixelSize: 9 * assetBackend.fontScale
                                            horizontalAlignment: Text.AlignRight
                                        }
                                    }
                                }
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            visible: page.records.length === 0
                            text: assetBackend.translateText("No maintenance records yet. Register a service or repair to begin tracking actual costs.", assetBackend.language)
                            color: assetBackend.themeColor("#D7E2F1", assetBackend.theme)
                            font.pixelSize: 12 * assetBackend.fontScale
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
