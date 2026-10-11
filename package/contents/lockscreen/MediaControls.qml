/*
    SPDX-FileCopyrightText: 2016 Kai Uwe Broulik <kde@privat.broulik.de>
    SPDX-FileCopyrightText: 2026 Yakup Emre Yerli

    SPDX-License-Identifier: GPL-3.0-or-later
*/

import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Effects

import org.kde.kirigami as Kirigami
import org.kde.plasma.private.mpris as Mpris

// Now-playing card: album art, title, artist and previous / play-pause / next
// as round glass buttons. Follows whichever player Plasma considers active.
Item {
    id: media

    property real s: 1
    property bool turkish: false

    visible: players.count > 0
    implicitHeight: 72 * s

    Repeater {
        id: players
        model: Mpris.MultiplexerModel { }

        Item {
            anchors.fill: parent
            enabled: model.canControl

            Rectangle {
                anchors.fill: parent
                radius: 20 * media.s
                color: Qt.rgba(0.62, 0.71, 0.80, 0.14)
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.12)
            }

            Item {
                id: art
                anchors {
                    left: parent.left
                    leftMargin: 12 * media.s
                    verticalCenter: parent.verticalCenter
                }
                width: 48 * media.s
                height: width
                visible: cover.status === Image.Ready

                Image {
                    id: cover
                    anchors.fill: parent
                    visible: false
                    asynchronous: true
                    fillMode: Image.PreserveAspectCrop
                    source: model.artUrl
                    sourceSize.width: width * Screen.devicePixelRatio
                    sourceSize.height: height * Screen.devicePixelRatio
                }

                Rectangle {
                    id: coverMask
                    anchors.fill: parent
                    radius: 10 * media.s
                    visible: false
                    layer.enabled: true
                }

                MultiEffect {
                    anchors.fill: parent
                    source: cover
                    maskEnabled: true
                    maskSource: coverMask
                }
            }

            Column {
                anchors {
                    left: art.visible ? art.right : parent.left
                    leftMargin: art.visible ? 12 * media.s : 18 * media.s
                    right: buttons.left
                    rightMargin: 8 * media.s
                    verticalCenter: parent.verticalCenter
                }
                spacing: 2 * media.s

                Text {
                    width: parent.width
                    elide: Text.ElideRight
                    text: model.track.length > 0 ? model.track
                        : model.playbackStatus > Mpris.PlaybackStatus.Stopped
                            ? (media.turkish ? "Başlıksız" : "No title")
                            : (media.turkish ? "Çalan bir şey yok" : "Nothing playing")
                    textFormat: Text.PlainText
                    color: "#f3f7fb"
                    font.family: "Inter"
                    font.weight: Font.DemiBold
                    font.pixelSize: 15 * media.s
                }

                Text {
                    width: parent.width
                    elide: Text.ElideRight
                    // Fall back to the player's name when the track has no artist
                    text: model.artist || model.identity
                    textFormat: Text.PlainText
                    color: "#dfe8f2"
                    opacity: 0.75
                    font.family: "Inter"
                    font.pixelSize: 13 * media.s
                }
            }

            Row {
                id: buttons
                anchors {
                    right: parent.right
                    rightMargin: 12 * media.s
                    verticalCenter: parent.verticalCenter
                }
                spacing: 8 * media.s

                GlassButton {
                    s: media.s
                    size: 36 * media.s
                    visible: model.canGoBack || model.canGoNext
                    enabled: model.canGoPrevious
                    iconName: "media-skip-backward"
                    Accessible.name: media.turkish ? "Önceki parça" : "Previous track"
                    onClicked: model.container.Previous()
                }

                GlassButton {
                    s: media.s
                    size: 44 * media.s
                    iconName: model.playbackStatus === Mpris.PlaybackStatus.Playing
                              ? "media-playback-pause" : "media-playback-start"
                    Accessible.name: media.turkish ? "Oynat ya da duraklat" : "Play or pause"
                    onClicked: model.container.PlayPause()
                }

                GlassButton {
                    s: media.s
                    size: 36 * media.s
                    visible: model.canGoBack || model.canGoNext
                    enabled: model.canGoNext
                    iconName: "media-skip-forward"
                    Accessible.name: media.turkish ? "Sonraki parça" : "Next track"
                    onClicked: model.container.Next()
                }
            }
        }
    }
}
