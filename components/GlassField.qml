
import QtQuick
import QtQuick.Controls

TextField {
    id: control

    color: assetBackend.themeColor("#F1F6FF", assetBackend.theme)
    placeholderTextColor: "#AABBD2"

    selectionColor: "#6683CFFF"
    selectedTextColor: "#FFFFFF"

    font.family: appFontFamily
    font.pixelSize: 13 * assetBackend.fontScale
    font.weight: Font.Normal

    leftPadding: 13
    rightPadding: 13

    implicitHeight: 40

    background: Rectangle {
        radius: 11

        color: control.activeFocus
               ? "#2AFFFFFF"
               : "#18FFFFFF"

        border.width: 1

        border.color: control.activeFocus
                      ? "#9ACFFFFF"
                      : "#45FFFFFF"

        Behavior on color {
            ColorAnimation {
                duration: 150
            }
        }

        Behavior on border.color {
            ColorAnimation {
                duration: 150
            }
        }
    }
}
