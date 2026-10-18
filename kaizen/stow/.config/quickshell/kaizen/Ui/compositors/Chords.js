// Chords as each backend's readBinds returns them: keys joined by +, Mod for
// the compositor's modifier, other keys by their xkb names.

// A chord's keys as keycaps: Mod is Super, an XF86 key drops the prefix and
// its Audio or Mon group (XF86AudioMute is Mute).
function keycaps(chord) {
  return String(chord || "")
    .split("+")
    .filter(Boolean)
    .map(function (key) {
      return /^mod$/i.test(key)
        ? "Super"
        : key.replace(/^XF86(Audio|Mon)?/i, "");
    });
}
