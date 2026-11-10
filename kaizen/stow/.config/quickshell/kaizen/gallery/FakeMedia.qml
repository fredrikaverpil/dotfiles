import QtQuick

import "../modules/services/media/MediaModel.js" as Model

// The media service's members the view and bar button read, without MPRIS.
QtObject {
    id: fake

    readonly property list<QtObject> all: [
        Player {
            dbusName: "org.mpris.MediaPlayer2.spotify"
            desktopEntry: "spotify"
            identity: "Spotify"
        },
        Player {
            dbusName: "org.mpris.MediaPlayer2.firefox.instance_1_42"
            desktopEntry: "firefox"
            identity: "Mozilla Firefox"
        }
    ]
    readonly property var spotify: ({
            trackTitle: "Teardrop",
            trackArtist: "Massive Attack",
            trackAlbum: "Mezzanine",
            canGoNext: true,
            canGoPrevious: true,
            canSeek: true,
            position: 83,
            length: 330
        })
    readonly property var scenarios: ({
            "Playing": {
                sources: {
                    "Spotify": Object.assign({
                        isPlaying: true
                    }, spotify)
                }
            },
            "Paused": {
                sources: {
                    "Spotify": spotify
                }
            },
            "Several sources": {
                sources: {
                    "Spotify": Object.assign({
                        isPlaying: true
                    }, spotify),
                    "Mozilla Firefox": {
                        trackTitle: "Lofi hip hop radio",
                        trackArtist: "Lofi Girl"
                    }
                }
            },
            "Long names": {
                sources: {
                    "Spotify": {
                        isPlaying: true,
                        trackTitle: "Concerto for Two Violins, Strings and Continuo in D Minor, BWV 1043: I. Vivace",
                        trackArtist: "Johann Sebastian Bach, Academy of St Martin in the Fields, Neville Marriner",
                        trackAlbum: "Bach: Violin Concertos (Remastered Anniversary Edition)",
                        canGoNext: true,
                        canGoPrevious: true,
                        canSeek: true,
                        position: 3725,
                        length: 4810
                    }
                }
            },
            "No seeking": {
                sources: {
                    "Mozilla Firefox": {
                        isPlaying: true,
                        trackTitle: "How the Internet Works",
                        trackArtist: "Example Channel",
                        position: 412,
                        length: 1083
                    }
                }
            },
            "Live stream": {
                sources: {
                    "Mozilla Firefox": {
                        isPlaying: true,
                        trackTitle: "Lofi hip hop radio",
                        trackArtist: "Lofi Girl",
                        canSeek: true,
                        position: 5400
                    }
                }
            },
            "No previous or next": {
                sources: {
                    "Mozilla Firefox": {
                        isPlaying: true,
                        trackTitle: "Lofi hip hop radio",
                        trackArtist: "Lofi Girl"
                    }
                }
            },
            "No track": {
                sources: {
                    "Spotify": {}
                }
            },
            "No player": {
                sources: {}
            }
        })

    // Player identity to its track and abilities; a player left out is not running.
    property var sources: scenarios["Playing"].sources
    property string preferredPlayerKey: ""

    readonly property var players: Array.from(all).filter(player => sources[player.identity] !== undefined)
    readonly property var sourcePlayers: Model.sourcePlayers(players)
    readonly property var activePlayer: Model.activePlayer(players, preferredPlayerKey)
    readonly property bool hasMedia: Model.hasTrackMetadata(activePlayer)
    readonly property bool playing: activePlayer ? !!activePlayer.isPlaying : false
    readonly property string title: activePlayer ? activePlayer.trackTitle : ""
    readonly property string artist: activePlayer ? activePlayer.trackArtist : ""
    readonly property string album: activePlayer ? activePlayer.trackAlbum : ""
    readonly property string artUrl: ""
    readonly property string identity: activePlayer ? activePlayer.identity : ""
    readonly property string icon: playing ? "󰏤" : "󰐊"
    readonly property bool hasLength: Model.hasLength(activePlayer)
    readonly property bool canSeek: Model.canSeek(activePlayer)
    readonly property real position: activePlayer ? activePlayer.position : 0
    readonly property real length: hasLength ? activePlayer.length : 0

    onSourcesChanged: applySources()
    Component.onCompleted: applySources()

    function applySources() {
        for (const player of all) {
            const source = sources[player.identity] || {};
            player.isPlaying = !!source.isPlaying;
            player.trackTitle = source.trackTitle || "";
            player.trackArtist = source.trackArtist || "";
            player.trackAlbum = source.trackAlbum || "";
            player.canGoNext = !!source.canGoNext;
            player.canGoPrevious = !!source.canGoPrevious;
            player.canSeek = !!source.canSeek;
            player.position = source.position || 0;
            player.length = source.length || 0;
        }
    }

    function playerKey(player) {
        return Model.playerKey(player);
    }

    function selectPlayer(key) {
        const player = Model.selectablePlayer(players, key);
        if (!player)
            return false;
        preferredPlayerKey = Model.playerKey(player);
        return true;
    }

    function seek(seconds) {
        if (!canSeek)
            return false;
        activePlayer.position = Math.max(0, Math.min(length, seconds));
        return true;
    }

    function runAction(action, targetKey) {
        const player = Model.playerForAction(players, sourcePlayers, activePlayer, action, targetKey);
        if (!player)
            return false;
        if (action === "playPause" || action === "play" || action === "pause")
            player.isPlaying = action === "playPause" ? !player.isPlaying : action === "play";
        preferredPlayerKey = Model.playerKey(player);
        return true;
    }

    component Player: QtObject {
        property string dbusName
        property string desktopEntry
        property string identity
        property bool isPlaying: false
        property string trackTitle: ""
        property string trackArtist: ""
        property string trackAlbum: ""
        property bool canGoNext: false
        property bool canGoPrevious: false
        property bool canSeek: false
        property real position: 0
        // 0: none reported, as a live stream.
        property real length: 0
        readonly property bool positionSupported: true
        readonly property bool lengthSupported: length > 0
        readonly property bool canTogglePlaying: trackTitle !== ""
        readonly property bool canPlay: canTogglePlaying
        readonly property bool canPause: canTogglePlaying
    }
}
