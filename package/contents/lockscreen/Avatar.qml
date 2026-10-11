/*
    SPDX-FileCopyrightText: 2026 Yakup Emre Yerli

    SPDX-License-Identifier: GPL-3.0-or-later
*/

import QtQuick
import QtQuick.Effects

// Round avatar. Uses the user's face icon when there is one, otherwise the
// initials of the user's name on a glacier-blue disc.
Item {
    id: avatar

    property real size: 108
    property string userName
    property string imagePath

    width: size
    height: size

    readonly property string initials: {
        const words = userName.trim().split(/\s+/).filter(w => w.length > 0);
        if (words.length === 0) {
            return "";
        }
        const first = words[0][0];
        const second = words.length > 1 ? words[1][0] : "";
        return (first + second).toLocaleUpperCase(Qt.locale());
    }

    Rectangle {
        id: disc
        anchors.fill: parent
        radius: width / 2
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#9fb6cc" }
            GradientStop { position: 1.0; color: "#5d7c99" }
        }
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.18)

        Text {
            anchors.centerIn: parent
            visible: photo.status !== Image.Ready
            text: avatar.initials
            color: "#f3f7fb"
            font.family: "Inter"
            font.weight: Font.DemiBold
            font.pixelSize: avatar.size * 0.36
        }
    }

    Image {
        id: photo
        anchors.fill: parent
        visible: false
        source: avatar.imagePath === "" ? ""
              : "file://" + avatar.imagePath.split("/").map(encodeURIComponent).join("/")
        sourceSize.width: 512
        sourceSize.height: 512
        fillMode: Image.PreserveAspectCrop
    }

    Rectangle {
        id: mask
        anchors.fill: parent
        radius: width / 2
        visible: false
        layer.enabled: true
    }

    MultiEffect {
        anchors.fill: parent
        source: photo
        maskEnabled: true
        maskSource: mask
        visible: photo.status === Image.Ready
    }
}
