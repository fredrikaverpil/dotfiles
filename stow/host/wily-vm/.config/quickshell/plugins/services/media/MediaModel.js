// MPRIS player selection and labels, kept Qt-free for tests/. A playing real
// player beats a proxy, and an explicit pick holds only until another player
// starts playback.

function playerKey(player) {
  if (!player) return ""
  return String(player.dbusName || player.desktopEntry || player.identity || "")
}

function isProxyPlayer(player) {
  var dbusName = String(player && player.dbusName || "").toLowerCase()
  var desktopEntry = String(player && player.desktopEntry || "").toLowerCase()
  return dbusName.indexOf("playerctld") !== -1 || desktopEntry === "playerctld"
}

function hasMetadata(player) {
  return !!(player && (player.trackTitle || player.trackArtist || player.trackAlbum
    || player.trackArtUrl || player.identity || player.desktopEntry))
}

function hasTrackMetadata(player) {
  return !!(player && (player.trackTitle || player.trackArtist))
}

function playerCanControl(player) {
  return !!(player && (player.canTogglePlaying || player.canPlay || player.canPause
    || player.canGoNext || player.canGoPrevious))
}

function canHandleAction(player, action) {
  if (!player) return false
  if (action === "next") return !!player.canGoNext
  if (action === "previous") return !!player.canGoPrevious
  if (action === "play") return !!(player.canPlay || player.canTogglePlaying)
  if (action === "pause") return !!(player.canPause || player.canTogglePlaying)
  if (action === "playPause") return !!(player.canTogglePlaying || player.canPlay || player.canPause)
  return false
}

function labelFor(player) {
  if (!player) return ""
  return String(player.trackTitle || player.identity || player.desktopEntry || "Media source")
}

function detailFor(player) {
  if (!player) return ""
  return String(player.trackArtist || player.identity || player.desktopEntry || "")
}

function sourcePlayers(players) {
  // ObjectModel.values is list-like but not an Array in every QML runtime, so
  // copy by index rather than trusting Array.isArray().
  var list = []
  var count = players && typeof players.length === "number" ? players.length : 0
  for (var index = 0; index < count; index++) {
    var player = players[index]
    if (hasMetadata(player) || playerCanControl(player)) list.push(player)
  }

  list.sort(function(a, b) {
    if (!!a.isPlaying !== !!b.isPlaying) return a.isPlaying ? -1 : 1
    if (isProxyPlayer(a) !== isProxyPlayer(b)) return isProxyPlayer(a) ? 1 : -1
    return labelFor(a).localeCompare(labelFor(b))
  })
  return list
}

function activePlayer(players, preferredKey) {
  var list = sourcePlayers(players)
  var preferred = list.find(function(player) { return playerKey(player) === preferredKey })

  // The explicit pick only wins while it is itself playing.
  if (preferred && preferred.isPlaying) return preferred

  var playing = list.find(function(player) { return player.isPlaying && !isProxyPlayer(player) })
  if (playing) return playing
  playing = list.find(function(player) { return player.isPlaying })
  return playing || preferred || list[0] || null
}

if (typeof module !== "undefined") {
  module.exports = {
    playerKey: playerKey,
    isProxyPlayer: isProxyPlayer,
    hasMetadata: hasMetadata,
    hasTrackMetadata: hasTrackMetadata,
    playerCanControl: playerCanControl,
    canHandleAction: canHandleAction,
    labelFor: labelFor,
    detailFor: detailFor,
    sourcePlayers: sourcePlayers,
    activePlayer: activePlayer,
  }
}
