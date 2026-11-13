import QtQuick
import QtTest
import "../modules/services/media/MediaModel.js" as Media

TestCase {
    name: "MediaModel"

    function test_metadata_data() {
        return [
            {
                tag: "track",
                player: {
                    trackTitle: "Song"
                },
                hasMetadata: true,
                hasTrack: true
            },
            {
                tag: "identity only",
                player: {
                    identity: "Firefox"
                },
                hasMetadata: true,
                hasTrack: false
            },
            {
                tag: "controls only",
                player: {
                    canPlay: true
                },
                hasMetadata: false,
                hasTrack: false
            },
            {
                tag: "empty",
                player: {},
                hasMetadata: false,
                hasTrack: false
            }
        ];
    }

    function test_metadata(data) {
        compare(Media.hasMetadata(data.player), data.hasMetadata);
        compare(Media.hasTrackMetadata(data.player), data.hasTrack);
    }

    function test_actions() {
        verify(Media.playerCanControl({
            canPause: true
        }));
        verify(Media.isProxyPlayer({
            desktopEntry: "playerctld"
        }));
        verify(Media.canHandleAction({
            canTogglePlaying: true
        }, "playPause"));
        verify(Media.canHandleAction({
            canGoNext: true
        }, "next"));
        verify(Media.canHandleAction({
            canGoPrevious: true
        }, "previous"));
        verify(Media.canHandleAction({
            canPlay: true
        }, "play"));
        verify(Media.canHandleAction({
            canPause: true
        }, "pause"));
        verify(!Media.canHandleAction({
            canGoNext: true
        }, "previous"));
        compare(Media.playerKey({
            dbusName: "org.mpris.MediaPlayer2.spotify"
        }), "org.mpris.MediaPlayer2.spotify");
        compare(Media.playerKey({
            desktopEntry: "spotify"
        }), "spotify");
    }

    function test_source_players_preserve_input() {
        const players = [
            {
                identity: "Proxy",
                dbusName: "org.mpris.MediaPlayer2.playerctld",
                isPlaying: true
            },
            {
                identity: "Paused",
                isPlaying: false
            },
            {
                identity: "Playing",
                isPlaying: true
            }
        ];
        compare(Media.sourcePlayers(players).map(player => player.identity), ["Playing", "Proxy", "Paused"]);
        compare(players.map(player => player.identity), ["Proxy", "Paused", "Playing"]);
        const arrayLike = {
            0: {
                identity: "Array-like list"
            },
            length: 1
        };
        compare(Media.sourcePlayers(arrayLike).map(player => player.identity), ["Array-like list"]);
    }

    function test_active_player_follows_selection_then_playback() {
        const players = [
            {
                identity: "Paused",
                dbusName: "paused",
                isPlaying: false,
                canPlay: true
            },
            {
                identity: "Playing",
                dbusName: "playing",
                isPlaying: true
            }
        ];
        compare(Media.activePlayer(players, "paused").identity, "Paused");
        compare(Media.activePlayer(players, "playing").identity, "Playing");
        compare(Media.activePlayer(players, "gone").identity, "Playing");
        const stale = {
            identity: "Chromium",
            dbusName: "stale",
            isPlaying: false
        };
        compare(Media.activePlayer([stale].concat(players), "stale").identity, "Playing");
        compare(Media.activePlayer([
            {
                identity: "Only",
                dbusName: "only"
            }
        ], "only").identity, "Only");
        compare(Media.activePlayer([], ""), null);
    }

    function test_player_lookups() {
        const paused = {
            identity: "Paused",
            dbusName: "paused",
            canPlay: true
        };
        const playing = {
            identity: "Playing",
            dbusName: "playing",
            isPlaying: true,
            canGoNext: true
        };
        verify(Media.playerForKey([paused, playing], "playing") === playing);
        compare(Media.playerForKey([paused], "missing"), null);
        verify(Media.selectablePlayer([paused], "paused") === paused);
        compare(Media.selectablePlayer([
            {
                dbusName: "empty"
            }
        ], "empty"), null);
        verify(Media.playerForAction([paused, playing], [paused, playing], paused, "next", "missing") === playing);
        verify(Media.playerForAction([paused], [paused], paused, "play", "missing") === paused);
    }

    function test_labels() {
        compare(Media.labelFor({
            trackTitle: "Song",
            identity: "Spotify"
        }), "Song");
        compare(Media.labelFor({
            desktopEntry: "spotify"
        }), "spotify");
        compare(Media.detailFor({
            trackArtist: "Artist",
            identity: "Spotify"
        }), "Artist");
        compare(Media.detailFor({
            identity: "Spotify"
        }), "Spotify");
    }

    function test_has_length_data() {
        return [
            {
                tag: "no player",
                player: null,
                want: false
            },
            {
                tag: "length",
                player: {
                    lengthSupported: true,
                    length: 330
                },
                want: true
            },
            {
                tag: "length unsupported",
                player: {
                    lengthSupported: false,
                    length: 12
                },
                want: false
            },
            {
                tag: "zero length",
                player: {
                    lengthSupported: true,
                    length: 0
                },
                want: false
            }
        ];
    }

    function test_has_length(data) {
        const got = Media.hasLength(data.player);

        compare(got, data.want);
    }

    function test_can_seek_data() {
        return [
            {
                tag: "no player",
                player: null,
                want: false
            },
            {
                tag: "seekable",
                player: {
                    canSeek: true,
                    positionSupported: true
                },
                want: true
            },
            {
                tag: "position unsupported",
                player: {
                    canSeek: true,
                    positionSupported: false
                },
                want: false
            }
        ];
    }

    function test_can_seek(data) {
        const got = Media.canSeek(data.player);

        compare(got, data.want);
    }

    function test_format_position_data() {
        return [
            {
                tag: "zero",
                seconds: 0,
                text: "0:00"
            },
            {
                tag: "minutes",
                seconds: 83.7,
                text: "1:23"
            },
            {
                tag: "hours",
                seconds: 3725,
                text: "1:02:05"
            },
            {
                tag: "negative",
                seconds: -4,
                text: "0:00"
            }
        ];
    }

    function test_format_position(data) {
        compare(Media.formatPosition(data.seconds), data.text);
    }
}
