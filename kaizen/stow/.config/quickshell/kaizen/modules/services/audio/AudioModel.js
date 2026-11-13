.pragma library

// A node's route key: its card, profile device and direction.
function key(card, device, sink) {
  return card + ":" + device + ":" + (sink ? "Output" : "Input");
}

// Keys of the profile devices whose every route is unplugged, from `pw-dump <card ids>`.
// A device no route lists (a USB or Bluetooth card's) is not among them.
function unplugged(dump) {
  var routes = {};
  for (var object of dump || []) {
    if (object.type !== "PipeWire:Interface:Device") continue;
    var params = object.info && object.info.params;
    for (var route of (params && params.EnumRoute) || []) {
      for (var device of route.devices || []) {
        var name = object.id + ":" + device + ":" + route.direction;
        (routes[name] = routes[name] || []).push(route.available);
      }
    }
  }
  return Object.keys(routes)
    .filter((name) => routes[name].every((available) => available === "no"))
    .sort();
}

// Whether node, a PwNode, is in keys from unplugged().
function isUnplugged(keys, node) {
  var props = node && node.properties;
  if (
    !props ||
    props["device.id"] === undefined ||
    props["card.profile.device"] === undefined
  )
    return false;
  return (
    keys.indexOf(
      key(props["device.id"], props["card.profile.device"], node.isSink),
    ) >= 0
  );
}

// The ALSA cards of nodes, for `pw-dump`; other cards report no jacks.
function cards(nodes) {
  var ids = [];
  for (var node of nodes) {
    var props = node && node.properties;
    if (
      !props ||
      props["device.api"] !== "alsa" ||
      props["device.id"] === undefined
    )
      continue;
    var id = String(props["device.id"]);
    if (ids.indexOf(id) < 0) ids.push(id);
  }
  return ids.sort();
}
