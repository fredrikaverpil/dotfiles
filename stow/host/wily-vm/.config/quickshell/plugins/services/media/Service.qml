import QtQuick
import Quickshell.Services.Mpris

import "MediaModel.js" as Model

// The MPRIS half of media, with no UI dependency: the bar and panel read the
// same selected player, and it stays current when neither is visible.
Item {
  id: root

  property string preferredPlayerKey: ""

  readonly property var players: Mpris.players ? Mpris.players.values : []
  readonly property var sourcePlayers: Model.sourcePlayers(players)
  readonly property var activePlayer: Model.activePlayer(players, preferredPlayerKey)
  readonly property bool hasMedia: Model.hasTrackMetadata(activePlayer)
  readonly property bool playing: activePlayer ? !!activePlayer.isPlaying : false
  readonly property string title: activePlayer ? String(activePlayer.trackTitle || "") : ""
  readonly property string artist: activePlayer ? String(activePlayer.trackArtist || "") : ""
  readonly property string album: activePlayer ? String(activePlayer.trackAlbum || "") : ""
  readonly property string artUrl: activePlayer ? String(activePlayer.trackArtUrl || "") : ""
  readonly property string identity: activePlayer
    ? String(activePlayer.identity || activePlayer.desktopEntry || "")
    : ""
  readonly property string icon: playing ? "󰏤" : "󰐊"

  function playerKey(player) {
    return Model.playerKey(player)
  }

  function playerForKey(key) {
    for (var index = 0; index < players.length; index++) {
      var player = players[index]
      if (Model.playerKey(player) === key) return player
    }
    return null
  }

  function selectPlayer(key) {
    var player = playerForKey(key)
    if (!player || !(Model.hasMetadata(player) || Model.playerCanControl(player))) return false
    preferredPlayerKey = Model.playerKey(player)
    return true
  }

  function playerForAction(action, targetKey) {
    var targeted = playerForKey(targetKey)
    if (Model.canHandleAction(targeted, action)) return targeted
    if (Model.canHandleAction(activePlayer, action)) return activePlayer

    for (var index = 0; index < sourcePlayers.length; index++) {
      if (Model.canHandleAction(sourcePlayers[index], action)) return sourcePlayers[index]
    }
    return null
  }

  function runAction(action, targetKey) {
    var player = playerForAction(action, targetKey)
    if (!player) return false

    var handled = false
    if (action === "next" && player.canGoNext) {
      player.next()
      handled = true
    } else if (action === "previous" && player.canGoPrevious) {
      player.previous()
      handled = true
    } else if (action === "play" && player.canPlay) {
      player.play()
      handled = true
    } else if (action === "pause" && player.canPause) {
      player.pause()
      handled = true
    } else if (action === "playPause") {
      if (player.canTogglePlaying) {
        player.togglePlaying()
        handled = true
      } else if (player.isPlaying && player.canPause) {
        player.pause()
        handled = true
      } else if (!player.isPlaying && player.canPlay) {
        player.play()
        handled = true
      }
    }

    if (handled) preferredPlayerKey = Model.playerKey(player)
    return handled
  }

  function statusJson() {
    var player = activePlayer
    return JSON.stringify({
      hasPlayer: player !== null,
      hasMedia: hasMedia,
      playing: playing,
      identity: identity,
      title: title,
      artist: artist,
      album: album,
      artUrl: artUrl,
      canGoNext: player ? !!player.canGoNext : false,
      canGoPrevious: player ? !!player.canGoPrevious : false,
      canTogglePlaying: player ? !!player.canTogglePlaying : false,
    })
  }
}
