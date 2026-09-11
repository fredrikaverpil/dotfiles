import QtQuick
import QtTest
import "../plugins/services/media/MediaModel.js" as Media

TestCase {
  name: "MediaModel"

  function test_metadata_data() {
    return [
      { tag: "track", player: { trackTitle: "Song" }, hasMetadata: true, hasTrack: true },
      { tag: "identity only", player: { identity: "Firefox" }, hasMetadata: true, hasTrack: false },
      { tag: "controls only", player: { canPlay: true }, hasMetadata: false, hasTrack: false },
      { tag: "empty", player: {}, hasMetadata: false, hasTrack: false }
    ]
  }

  function test_metadata(data) {
    compare(Media.hasMetadata(data.player), data.hasMetadata)
    compare(Media.hasTrackMetadata(data.player), data.hasTrack)
  }

  function test_actions() {
    verify(Media.playerCanControl({ canPause: true }))
    verify(Media.isProxyPlayer({ desktopEntry: "playerctld" }))
    verify(Media.canHandleAction({ canTogglePlaying: true }, "playPause"))
    verify(Media.canHandleAction({ canGoNext: true }, "next"))
    verify(Media.canHandleAction({ canGoPrevious: true }, "previous"))
    verify(Media.canHandleAction({ canPlay: true }, "play"))
    verify(Media.canHandleAction({ canPause: true }, "pause"))
    verify(!Media.canHandleAction({ canGoNext: true }, "previous"))
    compare(Media.playerKey({ dbusName: "org.mpris.MediaPlayer2.spotify" }), "org.mpris.MediaPlayer2.spotify")
    compare(Media.playerKey({ desktopEntry: "spotify" }), "spotify")
  }

  function test_source_players_preserve_input() {
    const players = [
      { identity: "Proxy", dbusName: "org.mpris.MediaPlayer2.playerctld", isPlaying: true },
      { identity: "Paused", isPlaying: false },
      { identity: "Playing", isPlaying: true }
    ]
    compare(Media.sourcePlayers(players).map(player => player.identity), ["Playing", "Proxy", "Paused"])
    compare(players.map(player => player.identity), ["Proxy", "Paused", "Playing"])
    const arrayLike = { 0: { identity: "Array-like list" }, length: 1 }
    compare(Media.sourcePlayers(arrayLike).map(player => player.identity), ["Array-like list"])
  }

  function test_active_player_prefers_playback() {
    const players = [
      { identity: "Paused", dbusName: "paused", isPlaying: false },
      { identity: "Playing", dbusName: "playing", isPlaying: true }
    ]
    compare(Media.activePlayer(players, "paused").identity, "Playing")
    compare(Media.activePlayer(players, "playing").identity, "Playing")
    compare(Media.activePlayer([{ identity: "Only", dbusName: "only" }], "only").identity, "Only")
    compare(Media.activePlayer([], ""), null)
  }

  function test_player_lookups() {
    const paused = { identity: "Paused", dbusName: "paused", canPlay: true }
    const playing = { identity: "Playing", dbusName: "playing", isPlaying: true, canGoNext: true }
    verify(Media.playerForKey([paused, playing], "playing") === playing)
    compare(Media.playerForKey([paused], "missing"), null)
    verify(Media.selectablePlayer([paused], "paused") === paused)
    compare(Media.selectablePlayer([{ dbusName: "empty" }], "empty"), null)
    verify(Media.playerForAction([paused, playing], [paused, playing], paused, "next", "missing") === playing)
    verify(Media.playerForAction([paused], [paused], paused, "play", "missing") === paused)
  }

  function test_labels() {
    compare(Media.labelFor({ trackTitle: "Song", identity: "Spotify" }), "Song")
    compare(Media.labelFor({ desktopEntry: "spotify" }), "spotify")
    compare(Media.detailFor({ trackArtist: "Artist", identity: "Spotify" }), "Artist")
    compare(Media.detailFor({ identity: "Spotify" }), "Spotify")
  }
}
