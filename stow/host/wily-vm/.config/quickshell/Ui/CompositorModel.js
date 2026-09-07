.import "compositors/Hyprland.js" as Hyprland
.import "compositors/Niri.js" as Niri

var backends = [Hyprland, Niri]

// env: function(name) -> value, e.g. Quickshell.env.
function select(env) {
  var active = backends.filter(function(backend) { return !!env(backend.sessionVariable) })
  if (active.length !== 1) {
    throw new Error("Unsupported or ambiguous compositor session: "
      + (active.map(function(backend) { return backend.id }).join(", ") || "none detected"))
  }
  return active[0]
}
