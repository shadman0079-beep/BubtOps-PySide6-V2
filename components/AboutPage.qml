import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "."

Item {
    property Item backdropSource: null
    ColumnLayout {
        anchors.fill: parent
        spacing: 16
        Text { text: assetBackend.translateText("About Application", assetBackend.language); color: assetBackend.themeColor("#FFFFFF", assetBackend.theme); font.pixelSize: 29 * assetBackend.fontScale; font.weight: Font.Bold }
        Text { text: assetBackend.translateText("Information about this software.", assetBackend.language); color: assetBackend.themeColor("#DCE7F5", assetBackend.theme); font.pixelSize: 13 * assetBackend.fontScale }
        GlassPanel {
            Layout.fillWidth: true
            Layout.fillHeight: true
            backdropSource: parent.parent.backdropSource
            glassTint: 0.11
            radius: 20
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 28
                spacing: 14
                Text { text: assetBackend.applicationName; color: assetBackend.themeColor("#FFFFFF", assetBackend.theme); font.pixelSize: 28 * assetBackend.fontScale; font.weight: Font.Bold }
                Text { text: assetBackend.translateText("CAMPUS OPERATIONS", assetBackend.language); color: assetBackend.themeColor("#BBDDF5", assetBackend.theme); font.pixelSize: 11 * assetBackend.fontScale; font.letterSpacing: 2 }
                Rectangle { Layout.fillWidth: true; height: 1; color: assetBackend.themeColor("#45FFFFFF", assetBackend.theme) }
                Repeater {
                    model: [
                        ["Application Name", assetBackend.applicationName],
                        ["Version", "1.0"],
                        ["Application Type", "Offline Desktop Application"],
                        ["Programming Language", "Python"],
                        ["GUI Framework", "PySide6 / Qt Quick (QML)"],
                        ["Database", "SQLite"],
                        ["Developed By", "Project Team"],
                        ["Purpose", "University Asset and Maintenance Management"]
                    ]
                    delegate: RowLayout {
                        Layout.fillWidth: true
                        Text { text: modelData[0]; color: assetBackend.themeColor("#C8D9EB", assetBackend.theme); font.pixelSize: 13 * assetBackend.fontScale; Layout.preferredWidth: 190 }
                        Text { text: modelData[1]; color: assetBackend.themeColor("#FFFFFF", assetBackend.theme); font.pixelSize: 13 * assetBackend.fontScale; font.weight: Font.DemiBold; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                    }
                }
                Item { Layout.fillHeight: true }
                Text { text: assetBackend.translateText("BubtOps • Campus Operations", assetBackend.language); color: assetBackend.themeColor("#B9CBE0", assetBackend.theme); font.pixelSize: 11 * assetBackend.fontScale }
            }
        }
    }
}
