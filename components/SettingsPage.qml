import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "."

Item {
    id: root
    property var backend
    property Item backdropSource: null
    property int selectedSection: 0
    property var settingsData: ({})
    property var historyRows: []
    property var backupRows: []
    property int selectedHistoryId: 0
    property string feedback: ""

    function comboIndex(combo, wanted) {
        for (var i = 0; i < combo.count; ++i) {
            if (combo.textAt(i) === wanted)
                return i
        }
        return 0
    }

    function refreshSettings() {
        settingsData = backend.getSettings()
        var profile = backend.getAdminProfile()
        adminNameField.text = profile.admin_name || "Administrator"
        usernameField.text = profile.username || "admin"
        applicationNameField.text = settingsData.application_name || "BubtOps"
        languageCombo.currentIndex = root.comboIndex(languageCombo, settingsData.language || "English")
        dateFormatCombo.currentIndex = root.comboIndex(dateFormatCombo, settingsData.date_format || "YYYY-MM-DD")
        dashboardCombo.currentIndex = root.comboIndex(dashboardCombo, settingsData.default_dashboard || "Overview")
        var savedTheme = settingsData.theme || "Dark Mode"
        if (savedTheme === "Dark Glass") savedTheme = "Dark Mode"
        if (savedTheme === "Light") savedTheme = "Light Mode"
        themeCombo.currentIndex = root.comboIndex(themeCombo, savedTheme)
        fontSizeCombo.currentIndex = root.comboIndex(fontSizeCombo, settingsData.font_size || "10")
        refreshHistory()
        refreshBackupHistory(false)
    }

    function refreshHistory() {
        historyRows = backend.getAssetHistory(historySearch.text, historyAction.currentText)
        selectedHistoryId = 0
    }

    function refreshBackupHistory(last30) {
        backupRows = backend.getBackupHistory(last30)
    }

    // Every entry into Settings starts from the first section.
    function resetToGeneralSettings() {
        selectedSection = 0
        feedback = ""
    }

    onVisibleChanged: {
        if (visible)
            resetToGeneralSettings()
    }

    function saveOne(key, value) {
        var result = backend.saveSetting(key, value)
        feedback = result.message || (result.success ? "Saved." : "Could not save setting.")
    }

    Component.onCompleted: refreshSettings()

    ColumnLayout {
        anchors.fill: parent
        spacing: 16

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: (58 * assetBackend.fontScale)
            ColumnLayout {
                spacing: 3
                Text { text: assetBackend.translateText("Settings", assetBackend.language); color: assetBackend.themeColor("#FFFFFF", assetBackend.theme); font.pixelSize: 29 * assetBackend.fontScale; font.weight: Font.Bold }
                Text { text: assetBackend.translateText("Manage your BubtOps application preferences.", assetBackend.language); color: assetBackend.themeColor("#DCE7F5", assetBackend.theme); font.pixelSize: 13 * assetBackend.fontScale }
            }
            Item { Layout.fillWidth: true }
            Text { text: feedback; color: assetBackend.themeColor("#A8E8D0", assetBackend.theme); font.pixelSize: 12 * assetBackend.fontScale; elide: Text.ElideRight; Layout.maximumWidth: 300 }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 16

            GlassPanel {
                Layout.preferredWidth: 235
                Layout.minimumWidth: 205
                Layout.fillHeight: true
                backdropSource: root.backdropSource
                glassTint: 0.10
                radius: 18

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 13
                    spacing: 7
                    Text {
                        text: assetBackend.translateText("SETTINGS MENU", assetBackend.language)
                        color: assetBackend.themeColor("#D9E8F7", assetBackend.theme)
                        font.pixelSize: 10 * assetBackend.fontScale
                        font.weight: Font.Bold
                        font.letterSpacing: 1.3
                        Layout.leftMargin: 8
                        Layout.bottomMargin: 5
                    }
                    Repeater {
                        model: ["General Settings", "Account Settings", "Asset Configuration History", "Appearance Settings", "Database Settings"]
                        delegate: Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: Math.max(46, 46 * assetBackend.fontScale)
                            radius: 12
                            color: root.selectedSection === index ? "#3A78A8" : (sectionMouse.containsMouse ? "#25FFFFFF" : "#08FFFFFF")
                            border.width: root.selectedSection === index ? 1 : 0
                            border.color: assetBackend.themeColor("#8DDCFF", assetBackend.theme)
                            Text {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                verticalAlignment: Text.AlignVCenter
                                text: assetBackend.translateText(modelData, assetBackend.language)
                                color: assetBackend.themeColor("#FFFFFF", assetBackend.theme)
                                font.pixelSize: 12 * assetBackend.fontScale
                                font.weight: root.selectedSection === index ? Font.DemiBold : Font.Medium
                                wrapMode: Text.WordWrap
                            }
                            MouseArea {
                                id: sectionMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.selectedSection = index
                                    root.feedback = ""
                                    if (index === 2) root.refreshHistory()
                                    if (index === 4) root.refreshBackupHistory(false)
                                }
                            }
                        }
                    }
                    Item { Layout.fillHeight: true }
                    Text { text: assetBackend.translateText("Only the selected section is shown.", assetBackend.language); color: assetBackend.themeColor("#C6D5E6", assetBackend.theme); font.pixelSize: 10 * assetBackend.fontScale; wrapMode: Text.WordWrap; Layout.fillWidth: true; Layout.leftMargin: 7 }
                }
            }

            StackLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: root.selectedSection

                // GENERAL SETTINGS
                GlassPanel {
                    backdropSource: root.backdropSource
                    glassTint: 0.105
                    radius: 18
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 22
                        spacing: 15
                        Text { text: assetBackend.translateText("General Settings", assetBackend.language); color: assetBackend.themeColor("#FFFFFF", assetBackend.theme); font.pixelSize: 21 * assetBackend.fontScale; font.weight: Font.Bold }
                        Text { text: assetBackend.translateText("Basic application preferences.", assetBackend.language); color: assetBackend.themeColor("#DCE7F5", assetBackend.theme); font.pixelSize: 12 * assetBackend.fontScale }
                        Text { text: assetBackend.translateText("Application Name", assetBackend.language); color: assetBackend.themeColor("#F3F7FF", assetBackend.theme); font.pixelSize: 12 * assetBackend.fontScale }
                        TextField { id: applicationNameField; Layout.fillWidth: true; color: assetBackend.themeColor("#FFFFFF", assetBackend.theme); placeholderText: assetBackend.translateText("Application name", assetBackend.language); background: Rectangle { radius: 9; color: assetBackend.themeColor("#26364C", assetBackend.theme); border.color: assetBackend.themeColor("#6484A8", assetBackend.theme) } }
                        Text { text: assetBackend.translateText("Language", assetBackend.language); color: assetBackend.themeColor("#F3F7FF", assetBackend.theme); font.pixelSize: 12 * assetBackend.fontScale }
                        ComboBox {
                            id: languageCombo
                            Layout.fillWidth: true
                            model: ["English", "Bangla"]
                            contentItem: Text {
                                leftPadding: 9
                                text: assetBackend.translateText(parent.displayText, assetBackend.language)
                                color: assetBackend.themeColor("#FFFFFF", assetBackend.theme)
                                verticalAlignment: Text.AlignVCenter
                                elide: Text.ElideRight
                            }
                            background: Rectangle {
                                radius: 8
                                color: assetBackend.themeColor("#26364C", assetBackend.theme)
                                border.color: assetBackend.themeColor("#6484A8", assetBackend.theme)
                            }
                        }
                        Text { text: assetBackend.translateText("Date Format", assetBackend.language); color: assetBackend.themeColor("#F3F7FF", assetBackend.theme); font.pixelSize: 12 * assetBackend.fontScale }
                        ComboBox {
                            id: dateFormatCombo
                            Layout.fillWidth: true
                            model: ["YYYY-MM-DD", "DD-MM-YYYY", "MM-DD-YYYY"]
                            contentItem: Text {
                                leftPadding: 9
                                text: assetBackend.translateText(parent.displayText, assetBackend.language)
                                color: assetBackend.themeColor("#FFFFFF", assetBackend.theme)
                                verticalAlignment: Text.AlignVCenter
                                elide: Text.ElideRight
                            }
                            background: Rectangle {
                                radius: 8
                                color: assetBackend.themeColor("#26364C", assetBackend.theme)
                                border.color: assetBackend.themeColor("#6484A8", assetBackend.theme)
                            }
                        }
                        Text { text: assetBackend.translateText("Default Dashboard", assetBackend.language); color: assetBackend.themeColor("#F3F7FF", assetBackend.theme); font.pixelSize: 12 * assetBackend.fontScale }
                        ComboBox {
                            id: dashboardCombo
                            Layout.fillWidth: true
                            model: ["Overview", "Asset Registry"]
                            contentItem: Text {
                                leftPadding: 9
                                text: assetBackend.translateText(parent.displayText, assetBackend.language)
                                color: assetBackend.themeColor("#FFFFFF", assetBackend.theme)
                                verticalAlignment: Text.AlignVCenter
                                elide: Text.ElideRight
                            }
                            background: Rectangle {
                                radius: 8
                                color: assetBackend.themeColor("#26364C", assetBackend.theme)
                                border.color: assetBackend.themeColor("#6484A8", assetBackend.theme)
                            }
                        }
                        Item { Layout.fillHeight: true }
                        GlassButton {
                            label: "Save Changes"
                            primary: true
                            Layout.preferredWidth: 145
                            onClicked: {
                                var ok = true
                                var a = backend.saveSetting("application_name", applicationNameField.text)
                                var b = backend.saveSetting("language", languageCombo.currentText)
                                var c = backend.saveSetting("date_format", dateFormatCombo.currentText)
                                var d = backend.saveSetting("default_dashboard", dashboardCombo.currentText)
                                ok = a.success && b.success && c.success && d.success
                                root.feedback = ok ? "General settings saved and applied. Some changes (language/date) refresh immediately; startup page applies next launch." : "Some settings could not be saved."
                            }
                        }
                    }
                }

                // ACCOUNT SETTINGS
                GlassPanel {
                    backdropSource: root.backdropSource
                    glassTint: 0.105
                    radius: 18
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 22
                        spacing: 14
                        Text { text: assetBackend.translateText("Account Settings", assetBackend.language); color: assetBackend.themeColor("#FFFFFF", assetBackend.theme); font.pixelSize: 21 * assetBackend.fontScale; font.weight: Font.Bold }
                        Text { text: assetBackend.translateText("Update the administrator profile information.", assetBackend.language); color: assetBackend.themeColor("#DCE7F5", assetBackend.theme); font.pixelSize: 12 * assetBackend.fontScale }
                        Text { text: assetBackend.translateText("Admin Name", assetBackend.language); color: assetBackend.themeColor("#F3F7FF", assetBackend.theme); font.pixelSize: 12 * assetBackend.fontScale }
                        TextField { id: adminNameField; Layout.fillWidth: true; color: assetBackend.themeColor("#FFFFFF", assetBackend.theme); background: Rectangle { radius: 9; color: assetBackend.themeColor("#26364C", assetBackend.theme); border.color: assetBackend.themeColor("#6484A8", assetBackend.theme) } }
                        Text { text: assetBackend.translateText("Username", assetBackend.language); color: assetBackend.themeColor("#F3F7FF", assetBackend.theme); font.pixelSize: 12 * assetBackend.fontScale }
                        TextField { id: usernameField; Layout.fillWidth: true; color: assetBackend.themeColor("#FFFFFF", assetBackend.theme); background: Rectangle { radius: 9; color: assetBackend.themeColor("#26364C", assetBackend.theme); border.color: assetBackend.themeColor("#6484A8", assetBackend.theme) } }
                        Text { text: assetBackend.translateText("New Password (optional)", assetBackend.language); color: assetBackend.themeColor("#F3F7FF", assetBackend.theme); font.pixelSize: 12 * assetBackend.fontScale }
                        TextField { id: newPasswordField; Layout.fillWidth: true; color: assetBackend.themeColor("#FFFFFF", assetBackend.theme); echoMode: TextInput.Password; placeholderText: assetBackend.translateText("Leave blank to keep current value", assetBackend.language); background: Rectangle { radius: 9; color: assetBackend.themeColor("#26364C", assetBackend.theme); border.color: assetBackend.themeColor("#6484A8", assetBackend.theme) } }
                        Item { Layout.fillHeight: true }
                        GlassButton {
                            label: "Save Account"
                            primary: true
                            Layout.preferredWidth: 145
                            onClicked: {
                                var result = backend.saveAdminProfile({"admin_name": adminNameField.text, "username": usernameField.text, "password": newPasswordField.text})
                                root.feedback = result.message || "Account settings saved."
                                if (result.success) newPasswordField.text = ""
                            }
                        }
                        Text { text: assetBackend.translateText("Note: this profile is stored locally; the current app does not use a login screen.", assetBackend.language); color: assetBackend.themeColor("#C8D6E8", assetBackend.theme); font.pixelSize: 10 * assetBackend.fontScale; wrapMode: Text.WordWrap; Layout.fillWidth: true }
                    }
                }

                // ASSET HISTORY
                GlassPanel {
                    backdropSource: root.backdropSource
                    glassTint: 0.105
                    radius: 18
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 18
                        spacing: 10
                        Text { text: assetBackend.translateText("Asset Configuration History", assetBackend.language); color: assetBackend.themeColor("#FFFFFF", assetBackend.theme); font.pixelSize: 21 * assetBackend.fontScale; font.weight: Font.Bold }
                        Text { text: assetBackend.translateText("Records are created automatically when an asset is added, updated or deleted.", assetBackend.language); color: assetBackend.themeColor("#DCE7F5", assetBackend.theme); font.pixelSize: 11 * assetBackend.fontScale; wrapMode: Text.WordWrap; Layout.fillWidth: true }
                        RowLayout {
                            Layout.fillWidth: true
                            TextField { id: historySearch; Layout.fillWidth: true; placeholderText: assetBackend.translateText("Search asset code or name", assetBackend.language); color: assetBackend.themeColor("#FFFFFF", assetBackend.theme); background: Rectangle { radius: 8; color: assetBackend.themeColor("#26364C", assetBackend.theme); border.color: assetBackend.themeColor("#6484A8", assetBackend.theme) } }
                            ComboBox {
                                id: historyAction
                                model: ["All", "Added", "Updated", "Deleted"]
                                contentItem: Text {
                                    leftPadding: 9
                                    text: assetBackend.translateText(parent.displayText, assetBackend.language)
                                    color: assetBackend.themeColor("#FFFFFF", assetBackend.theme)
                                    verticalAlignment: Text.AlignVCenter
                                    elide: Text.ElideRight
                                }
                                background: Rectangle {
                                    radius: 8
                                    color: assetBackend.themeColor("#26364C", assetBackend.theme)
                                    border.color: assetBackend.themeColor("#6484A8", assetBackend.theme)
                                }
                                Layout.preferredWidth: 115
                                onActivated: root.refreshHistory()
                            }
                            GlassButton { label: "Search"; Layout.preferredWidth: 88; onClicked: root.refreshHistory() }
                        }
                        ListView {
                            id: historyList
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            spacing: 6
                            model: root.historyRows
                            focus: true
                            activeFocusOnTab: true
                            keyNavigationEnabled: true
                            boundsBehavior: Flickable.StopAtBounds
                            flickDeceleration: 2200
                            maximumFlickVelocity: 5200
                            Keys.onPressed: function(event) {
                                var target = currentIndex < 0 ? 0 : currentIndex
                                if (event.key === Qt.Key_Down) target = Math.min(count - 1, target + 1)
                                else if (event.key === Qt.Key_Up) target = Math.max(0, target - 1)
                                else if (event.key === Qt.Key_PageDown) target = Math.min(count - 1, target + Math.max(1, Math.floor(height / 69)))
                                else if (event.key === Qt.Key_PageUp) target = Math.max(0, target - Math.max(1, Math.floor(height / 69)))
                                else if (event.key === Qt.Key_Home) target = 0
                                else if (event.key === Qt.Key_End) target = count - 1
                                else return
                                if (count > 0) {
                                    currentIndex = target
                                    root.selectedHistoryId = root.historyRows[target].history_id
                                    positionViewAtIndex(target, ListView.Contain)
                                }
                                event.accepted = true
                            }
                            Behavior on contentY { NumberAnimation { duration: 170; easing.type: Easing.OutCubic } }
                            delegate: Rectangle {
                                required property var modelData
                                width: historyList.width
                                height: 63
                                radius: 10
                                color: root.selectedHistoryId === modelData.history_id ? "#3A78A8" : "#1EFFFFFF"
                                border.color: assetBackend.themeColor("#45FFFFFF", assetBackend.theme)
                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    spacing: 10
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 3
                                        Text { text: modelData.asset_code + "  •  " + modelData.asset_name; color: assetBackend.themeColor("#FFFFFF", assetBackend.theme); font.pixelSize: 12 * assetBackend.fontScale; font.weight: Font.DemiBold; elide: Text.ElideRight; Layout.fillWidth: true }
                                        Text { text: modelData.action_type + "  •  " + assetBackend.formatDate(modelData.action_time); color: assetBackend.themeColor("#D7E5F4", assetBackend.theme); font.pixelSize: 10 * assetBackend.fontScale }
                                    }
                                    Text { text: modelData.performed_by; color: assetBackend.themeColor("#D7E5F4", assetBackend.theme); font.pixelSize: 10 * assetBackend.fontScale }
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        root.selectedHistoryId = modelData.history_id
                                        historyList.currentIndex = index
                                        historyList.forceActiveFocus()
                                    }
                                }
                            }
                            ScrollBar.vertical: ScrollBar {
                                policy: ScrollBar.AsNeeded
                                interactive: true
                                width: 10
                                minimumSize: 0.10
                                background: Rectangle { radius: 5; color: assetBackend.themeColor("#142A4058", assetBackend.theme) }
                                contentItem: Rectangle {
                                    radius: 5
                                    color: parent.pressed ? assetBackend.themeColor("#8BD8FF", assetBackend.theme) : parent.hovered ? assetBackend.themeColor("#61B8EA", assetBackend.theme) : assetBackend.themeColor("#3989C9", assetBackend.theme)
                                    border.width: 1
                                    border.color: assetBackend.themeColor("#9ADFFFFF", assetBackend.theme)
                                }
                            }
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            Text { text: root.historyRows.length + " record(s)"; color: assetBackend.themeColor("#DCE7F5", assetBackend.theme); font.pixelSize: 11 * assetBackend.fontScale }
                            Item { Layout.fillWidth: true }
                            GlassButton { label: "Refresh"; Layout.preferredWidth: 95; onClicked: root.refreshHistory() }
                            GlassButton {
                                label: "Delete Selected"
                                primary: false
                                Layout.preferredWidth: 145
                                enabled: root.selectedHistoryId > 0
                                onClicked: deleteHistoryDialog.open()
                            }
                        }
                    }
                }

                // APPEARANCE SETTINGS
                GlassPanel {
                    backdropSource: root.backdropSource
                    glassTint: 0.105
                    radius: 18
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 22
                        spacing: 14
                        Text { text: assetBackend.translateText("Appearance Settings", assetBackend.language); color: assetBackend.themeColor("#FFFFFF", assetBackend.theme); font.pixelSize: 21 * assetBackend.fontScale; font.weight: Font.Bold }
                        Text { text: assetBackend.translateText("Choose your preferred visual options.", assetBackend.language); color: assetBackend.themeColor("#DCE7F5", assetBackend.theme); font.pixelSize: 12 * assetBackend.fontScale }
                        Text { text: assetBackend.translateText("Theme", assetBackend.language); color: assetBackend.themeColor("#F3F7FF", assetBackend.theme); font.pixelSize: 12 * assetBackend.fontScale }
                        ComboBox {
                            id: themeCombo
                            Layout.fillWidth: true
                            model: ["Dark Mode", "Light Mode", "System Mode"]
                            contentItem: Text {
                                leftPadding: 9
                                text: assetBackend.translateText(parent.displayText, assetBackend.language)
                                color: assetBackend.themeColor("#FFFFFF", assetBackend.theme)
                                verticalAlignment: Text.AlignVCenter
                                elide: Text.ElideRight
                            }
                            background: Rectangle {
                                radius: 8
                                color: assetBackend.themeColor("#26364C", assetBackend.theme)
                                border.color: assetBackend.themeColor("#6484A8", assetBackend.theme)
                            }
                        }
                        Text { text: assetBackend.translateText("Font Size", assetBackend.language); color: assetBackend.themeColor("#F3F7FF", assetBackend.theme); font.pixelSize: 12 * assetBackend.fontScale }
                        ComboBox {
                            id: fontSizeCombo
                            Layout.fillWidth: true
                            model: ["9", "10", "11", "12", "13", "14", "16"]
                            contentItem: Text {
                                leftPadding: 9
                                text: assetBackend.translateText(parent.displayText, assetBackend.language)
                                color: assetBackend.themeColor("#FFFFFF", assetBackend.theme)
                                verticalAlignment: Text.AlignVCenter
                                elide: Text.ElideRight
                            }
                            background: Rectangle {
                                radius: 8
                                color: assetBackend.themeColor("#26364C", assetBackend.theme)
                                border.color: assetBackend.themeColor("#6484A8", assetBackend.theme)
                            }
                        }
                        Item { Layout.fillHeight: true }
                        GlassButton {
                            label: "Save Appearance"
                            primary: true
                            Layout.preferredWidth: 160
                            onClicked: {
                                var a = backend.saveSetting("theme", themeCombo.currentText)
                                var b = backend.saveSetting("font_size", fontSizeCombo.currentText)
                                root.feedback = (a.success && b.success) ? "Appearance preferences saved and applied across the interface." : "Could not save appearance preferences."
                            }
                        }
                        Text { text: assetBackend.translateText("Theme and font changes are applied across the application immediately. System Mode follows your computer's appearance preference.", assetBackend.language); color: assetBackend.themeColor("#C8D6E8", assetBackend.theme); font.pixelSize: 10 * assetBackend.fontScale; wrapMode: Text.WordWrap; Layout.fillWidth: true }
                    }
                }

                // DATABASE SETTINGS
                GlassPanel {
                    backdropSource: root.backdropSource
                    glassTint: 0.105
                    radius: 18

                    Flickable {
                        id: databaseFlick
                        anchors.fill: parent
                        anchors.margins: 18
                        clip: true
                        contentWidth: width
                        contentHeight: databaseContent.implicitHeight + 12
                        boundsBehavior: Flickable.StopAtBounds
                        flickDeceleration: 2200
                        maximumFlickVelocity: 5200
                        focus: true
                        activeFocusOnTab: true

                        Keys.onPressed: function(event) {
                            var step = Math.max(80, height * 0.78)
                            if (event.key === Qt.Key_Down) contentY = Math.min(Math.max(0, contentHeight - height), contentY + 48)
                            else if (event.key === Qt.Key_Up) contentY = Math.max(0, contentY - 48)
                            else if (event.key === Qt.Key_PageDown) contentY = Math.min(Math.max(0, contentHeight - height), contentY + step)
                            else if (event.key === Qt.Key_PageUp) contentY = Math.max(0, contentY - step)
                            else if (event.key === Qt.Key_Home) contentY = 0
                            else if (event.key === Qt.Key_End) contentY = Math.max(0, contentHeight - height)
                            else return
                            event.accepted = true
                        }

                        Behavior on contentY {
                            NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
                        }

                        ColumnLayout {
                            id: databaseContent
                            width: databaseFlick.width
                            spacing: 10

                            Text { text: assetBackend.translateText("Database Settings", assetBackend.language); color: assetBackend.themeColor("#FFFFFF", assetBackend.theme); font.pixelSize: 21 * assetBackend.fontScale; font.weight: Font.Bold }
                            Text { text: assetBackend.translateText("Database Location", assetBackend.language); color: assetBackend.themeColor("#F3F7FF", assetBackend.theme); font.pixelSize: 12 * assetBackend.fontScale }
                            Text { text: backend.databasePath; color: assetBackend.themeColor("#CFE2F5", assetBackend.theme); font.pixelSize: 10 * assetBackend.fontScale; wrapMode: Text.WrapAnywhere; Layout.fillWidth: true }
                            RowLayout {
                                Layout.fillWidth: true
                                TextField { id: newDatabaseLocationField; Layout.fillWidth: true; color: assetBackend.themeColor("#FFFFFF", assetBackend.theme); placeholderText: "D:/BubtOps/data/bubtops.db"; background: Rectangle { radius: 8; color: assetBackend.themeColor("#26364C", assetBackend.theme); border.color: assetBackend.themeColor("#6484A8", assetBackend.theme) } }
                                GlassButton {
                                    label: "Set Database Location"
                                    Layout.preferredWidth: 185
                                    onClicked: {
                                        var moved = backend.setDatabaseLocation(newDatabaseLocationField.text)
                                        root.feedback = moved.message || "Database location update requested."
                                        if (moved.success) newDatabaseLocationField.text = ""
                                    }
                                }
                            }
                            Text { text: assetBackend.translateText("Connection Status:  ", assetBackend.language) + backend.databaseStatus; color: backend.databaseStatus === "Connected" ? "#8FE2C1" : "#FFB2B2"; font.pixelSize: 12 * assetBackend.fontScale; font.weight: Font.DemiBold }
                            Text { text: assetBackend.translateText("Backup / Restore file path (leave blank for automatic backup location)", assetBackend.language); color: assetBackend.themeColor("#F3F7FF", assetBackend.theme); font.pixelSize: 11 * assetBackend.fontScale; wrapMode: Text.WordWrap; Layout.fillWidth: true }
                            TextField { id: databasePathField; Layout.fillWidth: true; color: assetBackend.themeColor("#FFFFFF", assetBackend.theme); placeholderText: assetBackend.translateText("Example: D:/BubtOps/backups/my_backup.db", assetBackend.language); background: Rectangle { radius: 8; color: assetBackend.themeColor("#26364C", assetBackend.theme); border.color: assetBackend.themeColor("#6484A8", assetBackend.theme) } }
                            RowLayout {
                                Layout.fillWidth: true
                                GlassButton {
                                    label: "Backup Database"
                                    primary: true
                                    Layout.preferredWidth: 165
                                    onClicked: {
                                        var result = backend.backupDatabase(databasePathField.text)
                                        root.feedback = result.message + (result.path ? "  " + result.path : "")
                                        if (result.success) root.refreshBackupHistory(false)
                                    }
                                }
                                GlassButton {
                                    label: "Restore Database"
                                    Layout.preferredWidth: 165
                                    onClicked: restoreDatabaseDialog.open()
                                }
                                Item { Layout.fillWidth: true }
                                ComboBox {
                                    id: backupFilter
                                    model: ["All History", "Last 30 Days"]
                                    contentItem: Text {
                                        leftPadding: 9
                                        text: assetBackend.translateText(parent.displayText, assetBackend.language)
                                        color: assetBackend.themeColor("#FFFFFF", assetBackend.theme)
                                        verticalAlignment: Text.AlignVCenter
                                        elide: Text.ElideRight
                                    }
                                    background: Rectangle {
                                        radius: 8
                                        color: assetBackend.themeColor("#26364C", assetBackend.theme)
                                        border.color: assetBackend.themeColor("#6484A8", assetBackend.theme)
                                    }
                                    Layout.preferredWidth: 145
                                    onActivated: root.refreshBackupHistory(currentIndex === 1)
                                }
                            }
                            Text { text: assetBackend.translateText("Backup History", assetBackend.language); color: assetBackend.themeColor("#FFFFFF", assetBackend.theme); font.pixelSize: 14 * assetBackend.fontScale; font.weight: Font.DemiBold }
                            Repeater {
                                model: root.backupRows
                                delegate: Rectangle {
                                    required property var modelData
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: (48 * assetBackend.fontScale)
                                    radius: 8
                                    color: assetBackend.themeColor("#1EFFFFFF", assetBackend.theme)
                                    border.color: assetBackend.themeColor("#35FFFFFF", assetBackend.theme)
                                    ColumnLayout {
                                        anchors.fill: parent
                                        anchors.margins: 8
                                        spacing: 2
                                        Text { text: assetBackend.formatDate(modelData.backup_time); color: assetBackend.themeColor("#FFFFFF", assetBackend.theme); font.pixelSize: 11 * assetBackend.fontScale }
                                        Text { text: modelData.file_path; color: assetBackend.themeColor("#C8D6E8", assetBackend.theme); font.pixelSize: 9 * assetBackend.fontScale; elide: Text.ElideMiddle; Layout.fillWidth: true }
                                    }
                                    TapHandler {
                                        onTapped: {
                                            var result = backend.revealBackupFile(modelData.file_path)
                                            root.feedback = result.message || (result.success ? "Backup location opened." : "Could not open backup location.")
                                        }
                                    }
                                    HoverHandler { id: backupRowHover }
                                    ToolTip.visible: backupRowHover.hovered
                                    ToolTip.text: "Click to show this backup file in its folder"
                                }
                            }
                        }

                        ScrollBar.vertical: ScrollBar {
                            policy: ScrollBar.AsNeeded
                            interactive: true
                            width: 10
                            minimumSize: 0.08
                            background: Rectangle { radius: 5; color: assetBackend.themeColor("#142A4058", assetBackend.theme) }
                            contentItem: Rectangle {
                                radius: 5
                                color: parent.pressed ? assetBackend.themeColor("#8BD8FF", assetBackend.theme) : parent.hovered ? assetBackend.themeColor("#61B8EA", assetBackend.theme) : assetBackend.themeColor("#3989C9", assetBackend.theme)
                                border.width: 1
                                border.color: assetBackend.themeColor("#9ADFFFFF", assetBackend.theme)
                            }
                        }
                    }
                }
            }
        }
    }

    Dialog {
        id: deleteHistoryDialog
        title: "Confirm Permanent Delete"
        modal: true
        standardButtons: Dialog.Yes | Dialog.No
        Label { text: assetBackend.translateText("Permanently delete the selected history record? The actual asset will not be deleted.", assetBackend.language); wrapMode: Text.WordWrap }
        onAccepted: {
            var result = backend.deleteAssetHistory(root.selectedHistoryId)
            root.feedback = result.message || "History record deleted."
            root.refreshHistory()
        }
    }

    Dialog {
        id: restoreDatabaseDialog
        title: "Confirm Database Restore"
        modal: true
        standardButtons: Dialog.Yes | Dialog.No
        Label { text: assetBackend.translateText("Restore will replace the current database. Make sure you have a backup. Continue?", assetBackend.language); wrapMode: Text.WordWrap }
        onAccepted: {
            var result = backend.restoreDatabase(databasePathField.text)
            root.feedback = result.message || "Restore request completed."
        }
    }
}
