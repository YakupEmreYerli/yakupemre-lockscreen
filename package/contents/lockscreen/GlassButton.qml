/*
    SPDX-FileCopyrightText: 2026 Yakup Emre Yerli

    SPDX-License-Identifier: GPL-3.0-or-later
*/

import QtQuick
import QtQuick.Controls.Basic

import org.kde.kirigami as Kirigami

// Round glass button, the same shape as the power buttons in yakupemre-sddm.
AbstractButton {
    id: button

    property real s: 1
    property real size: 44
    property string iconName

    width: size
    height: size
    hoverEnabled: true
    focusPolicy: Qt.TabFocus

    background: Rectangle {
        radius: width / 2
        color: button.down ? Qt.rgba(1, 1, 1, 0.22)
             : button.hovered || button.activeFocus ? Qt.rgba(1, 1, 1, 0.16)
             : Qt.rgba(1, 1, 1, 0.08)
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.18)

        Behavior on color { ColorAnimation { duration: 150 } }
    }

    contentItem: Item {
        Kirigami.Icon {
            anchors.centerIn: parent
            width: button.size * 0.42
            height: width
            source: button.iconName
            isMask: true
            color: button.hovered ? "#9fb6cc" : "#b7cef1"
            opacity: button.enabled ? 1 : 0.4
        }
    }
}
