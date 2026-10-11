/*
    SPDX-FileCopyrightText: 2026 Yakup Emre Yerli

    SPDX-License-Identifier: GPL-3.0-or-later
*/

import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Effects

import org.kde.plasma.private.keyboardindicator as KeyboardIndicator

// Same layout and palette as yakupemre-sddm: glacier lake background, frosted
// left panel, large Inter Display clock, round avatar, pill password field.
Item {
    id: ui

    // Everything is laid out for 1080p and scaled to the real screen height.
    readonly property real s: height / 1080

    readonly property bool turkish: Qt.locale().name.startsWith("tr")
    readonly property var strings: turkish ? {
        password: "Şifre",
        unlock: "Kilidi aç",
        wrongPassword: "Şifre yanlış",
        capsLock: "Büyük harf açık",
        dateFormat: "d MMMM dddd"
    } : {
        password: "Password",
        unlock: "Unlock",
        wrongPassword: "Wrong password",
        capsLock: "Caps Lock is on",
        dateFormat: "dddd, d MMMM"
    }

    readonly property color textColor: "#f3f7fb"
    readonly property color softTextColor: "#dfe8f2"
    readonly property color fieldColor: "#9fb6cc"
    readonly property color accentColor: "#5d7c99"
    readonly property color panelColor: "#16222e"

    // True after a password was sent and before the answer arrives.
    property bool waiting: false
    // Set when PAM unlocked without asking for a password (e.g. no password set).
    property bool unlockedWithoutPrompt: false

    function submit() {
        if (waiting || passwordField.text.length === 0) {
            return;
        }
        waiting = true;
        authenticator.respond(passwordField.text);
    }

    function showMessage(text) {
        root.notification = text;
        messageTimer.restart();
    }

    Connections {
        target: authenticator

        function onFailed(kind) {
            // kind != 0 comes from non-interactive authenticators (fingerprint, smartcard)
            if (kind !== 0) {
                return;
            }
            ui.waiting = false;
            ui.showMessage(ui.strings.wrongPassword);
            shake.restart();
            graceTimer.restart();
        }

        function onSucceeded() {
            if (authenticator.hadPrompt) {
                Qt.quit();
            } else {
                ui.unlockedWithoutPrompt = true;
            }
        }

        function onInfoMessageChanged() {
            ui.showMessage(authenticator.infoMessage);
        }

        function onErrorMessageChanged() {
            ui.showMessage(authenticator.errorMessage);
        }

        function onPromptForSecretChanged() {
            passwordField.forceActiveFocus();
        }
    }

    Connections {
        target: root

        function onClearPassword() {
            passwordField.clear();
            passwordField.forceActiveFocus();
        }
    }

    KeyboardIndicator.KeyState {
        id: capsLockState
        key: Qt.Key_CapsLock
    }

    Timer {
        id: graceTimer
        interval: 3000
        onTriggered: {
            passwordField.clear();
            passwordField.forceActiveFocus();
            authenticator.startAuthenticating();
        }
    }

    Timer {
        id: messageTimer
        interval: 3000
        onTriggered: root.notification = ""
    }

    Component.onCompleted: {
        authenticator.startAuthenticating();
        passwordField.forceActiveFocus();
    }

    // Background

    Rectangle {
        anchors.fill: parent
        color: "#2c3e50"
    }

    Image {
        id: background
        anchors.fill: parent
        source: "assets/glacier-lake.jpg"
        fillMode: Image.PreserveAspectCrop
        asynchronous: false
        cache: true
        mipmap: true
    }

    // Frosted panel

    ShaderEffectSource {
        id: panelSource
        x: panel.x
        y: panel.y
        width: panel.width
        height: panel.height
        sourceItem: background
        sourceRect: Qt.rect(x, y, width, height)
        visible: false
    }

    MultiEffect {
        anchors.fill: panelSource
        source: panelSource
        blurEnabled: true
        autoPaddingEnabled: false
        blur: 1.0
        blurMax: 32
    }

    Rectangle {
        id: panel
        anchors {
            top: parent.top
            bottom: parent.bottom
            left: parent.left
        }
        width: parent.width / 2.5
        color: ui.panelColor
        opacity: 0.3
    }

    MouseArea {
        anchors.fill: parent
        onClicked: passwordField.forceActiveFocus()
    }

    Item {
        id: content
        anchors.fill: panel

        // Clock

        Column {
            id: clock
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.top
            anchors.bottomMargin: -parent.height / 3
            spacing: 0

            property date now: new Date()

            Timer {
                interval: 1000
                repeat: true
                running: true
                triggeredOnStart: true
                onTriggered: clock.now = new Date()
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatTime(clock.now, "HH:mm")
                color: ui.textColor
                font.family: "Inter Display"
                font.weight: Font.DemiBold
                font.pixelSize: 150 * ui.s
                renderType: Text.QtRendering
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: clock.now.toLocaleDateString(Qt.locale(), ui.strings.dateFormat)
                color: ui.softTextColor
                font.family: "Inter Display"
                font.weight: Font.Medium
                font.pixelSize: 32 * ui.s
                renderType: Text.QtRendering
            }
        }

        // User and password

        Column {
            id: form
            anchors.horizontalCenter: parent.horizontalCenter
            y: 586 * ui.s
            width: 386 * ui.s
            spacing: 0

            transform: Translate { id: shakeOffset }

            Avatar {
                anchors.horizontalCenter: parent.horizontalCenter
                size: 108 * ui.s
                userName: kscreenlocker_userName
                imagePath: kscreenlocker_userImage
            }

            Item { width: 1; height: 18 * ui.s }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: kscreenlocker_userName
                color: ui.textColor
                font.family: "Inter"
                font.weight: Font.DemiBold
                font.pixelSize: 26 * ui.s
                renderType: Text.QtRendering
            }

            Item { width: 1; height: 22 * ui.s }

            Item {
                width: parent.width
                height: 36 * ui.s
                visible: !ui.unlockedWithoutPrompt

                TextField {
                    id: passwordField
                    anchors.fill: parent
                    horizontalAlignment: TextInput.AlignHCenter
                    verticalAlignment: TextInput.AlignVCenter
                    leftPadding: height
                    rightPadding: height
                    echoMode: revealButton.checked ? TextInput.Normal : TextInput.Password
                    passwordCharacter: "•"
                    color: ui.textColor
                    font.family: "Inter"
                    font.bold: true
                    font.pixelSize: 16 * ui.s
                    enabled: !ui.waiting && !graceTimer.running
                    focus: true
                    selectByMouse: true
                    inputMethodHints: Qt.ImhSensitiveData | Qt.ImhNoPredictiveText

                    background: Rectangle {
                        radius: height / 2
                        color: Qt.rgba(0.62, 0.71, 0.80, 0.2) // fieldColor at 20 %
                        border.width: passwordField.activeFocus ? 2 : 1
                        border.color: passwordField.activeFocus ? ui.accentColor : "transparent"

                        Behavior on border.color { ColorAnimation { duration: 150 } }
                    }

                    onAccepted: ui.submit()
                    Keys.onEscapePressed: clear()

                    // The Basic style hides a centered placeholder on focus; keep it until typing starts.
                    Text {
                        anchors.centerIn: parent
                        visible: passwordField.text.length === 0 && passwordField.preeditText.length === 0
                        text: ui.strings.password
                        color: "#bbbbbb"
                        font: passwordField.font
                    }
                }

                AbstractButton {
                    id: revealButton
                    anchors.left: parent.left
                    anchors.leftMargin: 8 * ui.s
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.height
                    height: parent.height
                    checkable: true
                    focusPolicy: Qt.NoFocus

                    contentItem: Image {
                        source: revealButton.checked ? "assets/Password.svg" : "assets/Password2.svg"
                        sourceSize.width: 16 * ui.s
                        sourceSize.height: 16 * ui.s
                        fillMode: Image.Pad
                        opacity: revealButton.hovered || revealButton.checked ? 1 : 0.7
                    }
                    background: null
                }
            }

            Item { width: 1; height: 46 * ui.s }

            Button {
                id: unlockButton
                width: parent.width
                height: 36 * ui.s
                text: ui.strings.unlock
                hoverEnabled: true
                focusPolicy: Qt.TabFocus
                enabled: ui.unlockedWithoutPrompt || (passwordField.text.length > 0 && !ui.waiting)

                contentItem: Text {
                    text: unlockButton.text
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    color: "#ffffff"
                    opacity: unlockButton.enabled ? 1 : 0.5
                    font.family: "Inter"
                    font.bold: true
                    font.pixelSize: 16 * ui.s
                }

                background: Rectangle {
                    radius: height / 2
                    color: unlockButton.down ? Qt.darker(ui.accentColor, 1.1)
                         : unlockButton.hovered || unlockButton.activeFocus ? Qt.lighter(ui.accentColor, 1.15)
                         : ui.accentColor
                    opacity: unlockButton.enabled ? 1 : 0.2

                    Behavior on opacity { NumberAnimation { duration: 150 } }
                }

                onClicked: ui.unlockedWithoutPrompt ? Qt.quit() : ui.submit()
            }

            Item { width: 1; height: 24 * ui.s }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                text: {
                    const parts = [];
                    if (capsLockState.locked) {
                        parts.push(ui.strings.capsLock);
                    }
                    if (root.notification) {
                        parts.push(root.notification);
                    }
                    return parts.join(" • ");
                }
                color: "#ffffff"
                font.family: "Inter"
                font.italic: true
                font.pixelSize: 15 * ui.s
                opacity: text.length > 0 ? 1 : 0

                Behavior on opacity { NumberAnimation { duration: 200 } }
            }
        }
    }

    MediaControls {
        anchors {
            horizontalCenter: content.horizontalCenter
            bottom: parent.bottom
            bottomMargin: 56 * ui.s
        }
        width: 420 * ui.s
        height: implicitHeight
        s: ui.s
        turkish: ui.turkish
    }

    SequentialAnimation {
        id: shake
        loops: 1
        NumberAnimation { target: shakeOffset; property: "x"; to: -14 * ui.s; duration: 50 }
        NumberAnimation { target: shakeOffset; property: "x"; to: 14 * ui.s; duration: 70 }
        NumberAnimation { target: shakeOffset; property: "x"; to: -8 * ui.s; duration: 60 }
        NumberAnimation { target: shakeOffset; property: "x"; to: 0; duration: 50 }
    }
}
