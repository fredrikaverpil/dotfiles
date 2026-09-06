// Unit tests for plugins/services/media/MediaModel.js. Player objects stand in
// for Quickshell's MprisPlayer type; selection and labels are intentionally
// pure data so Deno can cover them without a running D-Bus media player.

import { createRequire } from "node:module"
import { assertEquals } from "jsr:@std/assert"

const MediaModel = createRequire(import.meta.url)("../plugins/services/media/MediaModel.js")

Deno.test("player metadata and actions", async (t) => {
  const cases = [
    { name: "track metadata", player: { trackTitle: "Song" }, hasMetadata: true, hasTrack: true },
    { name: "identity is a source but not now playing", player: { identity: "Firefox" }, hasMetadata: true, hasTrack: false },
    { name: "a controllable player is a source", player: { canPlay: true }, hasMetadata: false, hasTrack: false },
    { name: "empty player", player: {}, hasMetadata: false, hasTrack: false },
  ]
  for (const c of cases) {
    await t.step(c.name, () => {
      assertEquals(MediaModel.hasMetadata(c.player), c.hasMetadata)
      assertEquals(MediaModel.hasTrackMetadata(c.player), c.hasTrack)
    })
  }

  assertEquals(MediaModel.canHandleAction({ canTogglePlaying: true }, "playPause"), true)
  assertEquals(MediaModel.canHandleAction({ canGoNext: true }, "next"), true)
  assertEquals(MediaModel.canHandleAction({ canGoNext: true }, "previous"), false)
  assertEquals(MediaModel.playerKey({ dbusName: "org.mpris.MediaPlayer2.spotify" }), "org.mpris.MediaPlayer2.spotify")
})

Deno.test("sourcePlayers orders playing real players first without mutation", () => {
  const players = [
    { identity: "Proxy", dbusName: "org.mpris.MediaPlayer2.playerctld", isPlaying: true },
    { identity: "Paused", isPlaying: false },
    { identity: "Playing", isPlaying: true },
  ]

  const sources = MediaModel.sourcePlayers(players)
  assertEquals(sources.map(player => player.identity), ["Playing", "Proxy", "Paused"])
  assertEquals(players.map(player => player.identity), ["Proxy", "Paused", "Playing"])

  const qmlList = { 0: { identity: "QML list" }, length: 1 }
  assertEquals(MediaModel.sourcePlayers(qmlList).map(player => player.identity), ["QML list"])
})

Deno.test("activePlayer follows playback before a paused explicit source", () => {
  const players = [
    { identity: "Paused", dbusName: "paused", isPlaying: false },
    { identity: "Playing", dbusName: "playing", isPlaying: true },
  ]

  assertEquals(MediaModel.activePlayer(players, "paused").identity, "Playing")
  assertEquals(MediaModel.activePlayer(players, "playing").identity, "Playing")
  assertEquals(MediaModel.activePlayer([{ identity: "Only", dbusName: "only" }], "only").identity, "Only")
  assertEquals(MediaModel.activePlayer([], ""), null)
})

Deno.test("labels prefer the track and avoid repeating the source", () => {
  assertEquals(MediaModel.labelFor({ trackTitle: "Song", identity: "Spotify" }), "Song")
  assertEquals(MediaModel.detailFor({ trackArtist: "Artist", identity: "Spotify" }), "Artist")
  assertEquals(MediaModel.detailFor({ identity: "Spotify" }), "Spotify")
})
