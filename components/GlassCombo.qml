import QtQuick
import QtQuick.Controls

ComboBox {
    id: control

    implicitHeight: 39
    font.pixelSize: 11

    delegate: ItemDelegate {
        width: control.width - 12
        height: 35

        highlighted: control.highlightedIndex === index

        contentItem: Text {
            text: modelData

            color: "#EAF2FF"
            font: control.font

            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
        }

        background: Rectangle {
            radius: 8

            color: highlighted
                   ? "#3B83CFFF"
                   : hovered
                     ? "#20FFFFFF"
                     : "transparent"
        }
    }

    indicator: Text {
        x: control.width - width - 12
        y: (control.height - height) / 2

        text: "⌄"
        color: "#B9CBE5"

        font.pixelSize: 16
    }

    contentItem: Text {
        leftPadding: 12
        rightPadding: 30

        text: control.displayText

        color: "#EDF4FF"
        font: control.font

        elide: Text.ElideRight
        verticalAlignment: Text.AlignVCenter
    }

    background: Rectangle {
        radius: 10

        color: control.hovered || control.popup.visible
               ? "#25FFFFFF"
               : "#14FFFFFF"

        border.width: 1

        border.color: control.popup.visible
                      ? "#99BDEBFF"
                      : "#38FFFFFF"

        Behavior on color {
            ColorAnimation { duration: 140 }
        }

        Behavior on border.color {
            ColorAnimation { duration: 140 }
        }
    }

    popup: Popup {
        y: control.height + 5
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
            radius: 12

            color: "#F01B2842"

            border.width: 1
            border.color: "#55FFFFFF"
        }
    }
}