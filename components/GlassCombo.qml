
import QtQuick
import QtQuick.Controls

ComboBox {
    id: control

    implicitHeight: 40

    font.family: appFontFamily
    font.pixelSize: 13 * assetBackend.fontScale
    font.weight: Font.Medium

    // =====================================
    // DROPDOWN ITEMS
    // =====================================

    delegate: ItemDelegate {
        width: control.width - 12
        height: 37

        highlighted: control.highlightedIndex === index

        contentItem: Text {
            text: modelData

            color: assetBackend.themeColor("#EDF4FF", assetBackend.theme)

            font.family: appFontFamily
            font.pixelSize: 12 * assetBackend.fontScale
            font.weight: Font.Medium

            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
        }

        background: Rectangle {
            radius: 8

            color: highlighted
                   ? "#4383CFFF"
                   : hovered
                     ? "#25FFFFFF"
                     : "transparent"

            Behavior on color {
                ColorAnimation {
                    duration: 120
                }
            }
        }
    }

    // =====================================
    // DROPDOWN ARROW
    // =====================================

    indicator: Text {
        x: control.width - width - 13
        y: (control.height - height) / 2

        text: assetBackend.translateText("⌄", assetBackend.language)

        color: control.popup.visible
               ? "#EAF5FF"
               : "#B9CBE5"

        font.pixelSize: 17 * assetBackend.fontScale

        Behavior on color {
            ColorAnimation {
                duration: 140
            }
        }
    }

    // =====================================
    // SELECTED VALUE
    // =====================================

    contentItem: Text {
        leftPadding: 13
        rightPadding: 34

        text: control.displayText

        color: assetBackend.themeColor("#EDF4FF", assetBackend.theme)

        font: control.font

        elide: Text.ElideRight
        verticalAlignment: Text.AlignVCenter
    }

    // =====================================
    // CLOSED COMBOBOX MATERIAL
    // =====================================

    background: Rectangle {
        radius: 11

        color: control.activeFocus || control.popup.visible
               ? "#2AFFFFFF"
               : "#18FFFFFF"

        border.width: 1

        border.color: control.popup.visible
                      ? "#8ACFFFFF"
                      : control.activeFocus
                        ? "#78CFFFFF"
                        : "#45FFFFFF"

        Behavior on color {
            ColorAnimation {
                duration: 140
            }
        }

        Behavior on border.color {
            ColorAnimation {
                duration: 140
            }
        }
    }

    // =====================================
    // POPUP
    // =====================================

    popup: Popup {
        y: control.height + 6
        width: control.width

        implicitHeight: Math.min(
            contentItem.implicitHeight + 12,
            260
        )

        padding: 6

        contentItem: ListView {
            clip: true

            implicitHeight: contentHeight

            model: control.popup.visible
                   ? control.delegateModel
                   : null

            currentIndex: control.highlightedIndex

            ScrollIndicator.vertical: ScrollIndicator {}
        }

        background: Rectangle {
            radius: 14

            color: assetBackend.themeColor("#ED192A43", assetBackend.theme)

            border.width: 1
            border.color: assetBackend.themeColor("#69FFFFFF", assetBackend.theme)

            // Subtle top-to-bottom depth
            gradient: Gradient {
                GradientStop {
                    position: 0.0
                    color: assetBackend.themeColor("#F1243552", assetBackend.theme)
                }

                GradientStop {
                    position: 1.0
                    color: assetBackend.themeColor("#ED142239", assetBackend.theme)
                }
            }
        }
    }
}
