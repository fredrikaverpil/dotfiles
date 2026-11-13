function playerKey(player) {
  if (!player) return "";
  return String(
    player.dbusName || player.desktopEntry || player.identity || "",
  );
}

function isProxyPlayer(player) {
  var dbusName = String((player && player.dbusName) || "").toLowerCase();
  var desktopEntry = String(
    (player && player.desktopEntry) || "",
  ).toLowerCase();
  return dbusName.indexOf("playerctld") !== -1 || desktopEntry === "playerctld";
}

function hasMetadata(player) {
  return !!(
    player &&
    (player.trackTitle ||
      player.trackArtist ||
      player.trackAlbum ||
      player.trackArtUrl ||
      player.identity ||
      player.desktopEntry)
  );
}

function hasTrackMetadata(player) {
  return !!(player && (player.trackTitle || player.trackArtist));
}

function playerCanControl(player) {
  return !!(
    player &&
    (player.canTogglePlaying ||
      player.canPlay ||
      player.canPause ||
      player.canGoNext ||
      player.canGoPrevious)
  );
}

function canHandleAction(player, action) {
  if (!player) return false;
  if (action === "next") return !!player.canGoNext;
  if (action === "previous") return !!player.canGoPrevious;
  if (action === "play") return !!(player.canPlay || player.canTogglePlaying);
  if (action === "pause") return !!(player.canPause || player.canTogglePlaying);
  if (action === "playPause")
    return !!(player.canTogglePlaying || player.canPlay || player.canPause);
  return false;
}

function labelFor(player) {
  if (!player) return "";
  return String(
    player.trackTitle ||
      player.identity ||
      player.desktopEntry ||
      "Media source",
  );
}

function detailFor(player) {
  if (!player) return "";
  return String(
    player.trackArtist || player.identity || player.desktopEntry || "",
  );
}

// Quickshell's ObjectModel.values is list-like but not reliably an Array.
function sourcePlayers(players) {
  var list = [];
  var count =
    players && typeof players.length === "number" ? players.length : 0;
  for (var index = 0; index < count; index++) {
    var player = players[index];
    if (hasMetadata(player) || playerCanControl(player)) list.push(player);
  }

  list.sort(function (a, b) {
    if (!!a.isPlaying !== !!b.isPlaying) return a.isPlaying ? -1 : 1;
    if (isProxyPlayer(a) !== isProxyPlayer(b)) return isProxyPlayer(a) ? 1 : -1;
    return labelFor(a).localeCompare(labelFor(b));
  });
  return list;
}

function activePlayer(players, preferredKey) {
  var list = sourcePlayers(players);
  var preferred = list.find(function (player) {
    return playerKey(player) === preferredKey;
  });

  // An explicit selection wins even while paused, until it goes away or turns into a
  // bare shell with neither track nor controls (a browser tab that stopped holding media).
  if (preferred && (hasTrackMetadata(preferred) || playerCanControl(preferred)))
    return preferred;

  var playing = list.find(function (player) {
    return player.isPlaying && !isProxyPlayer(player);
  });
  if (playing) return playing;
  playing = list.find(function (player) {
    return player.isPlaying;
  });
  return playing || preferred || list[0] || null;
}

function playerForKey(players, key) {
  var count =
    players && typeof players.length === "number" ? players.length : 0;
  for (var index = 0; index < count; index++) {
    var player = players[index];
    if (playerKey(player) === key) return player;
  }
  return null;
}

function selectablePlayer(players, key) {
  var player = playerForKey(players, key);
  return player && (hasMetadata(player) || playerCanControl(player))
    ? player
    : null;
}

function playerForAction(players, source, active, action, targetKey) {
  var targeted = playerForKey(players, targetKey);
  if (canHandleAction(targeted, action)) return targeted;
  if (canHandleAction(active, action)) return active;

  var list = Array.isArray(source) ? source : [];
  for (var index = 0; index < list.length; index++) {
    if (canHandleAction(list[index], action)) return list[index];
  }
  return null;
}

// A track has a length to seek in; a live stream reports none.
function hasLength(player) {
  return !!(player && player.lengthSupported && player.length > 0);
}

function canSeek(player) {
  return !!(player && player.canSeek && player.positionSupported);
}

// Seconds as m:ss, or h:mm:ss from an hour.
function formatPosition(seconds) {
  var total = Math.max(0, Math.floor(seconds || 0));
  var hours = Math.floor(total / 3600);
  var minutes = Math.floor((total % 3600) / 60);
  var rest = String(total % 60).padStart(2, "0");
  if (hours > 0)
    return hours + ":" + String(minutes).padStart(2, "0") + ":" + rest;
  return minutes + ":" + rest;
}
