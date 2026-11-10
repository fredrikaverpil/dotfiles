function percent(raw, max) {
  return max > 0
    ? Math.round((Math.max(0, Math.min(max, raw)) * 100) / max)
    : 0;
}

// Never fully off: a black panel looks like a dead machine.
function rawFor(value, max) {
  var floor = Math.max(1, Math.round(max / 100));
  return Math.max(floor, Math.min(max, Math.round((value * max) / 100)));
}

// The connector a backlight belongs to, from its sysfs class link
// (`../../devices/…/drm/card0/card0-eDP-1/intel_backlight`); "" when it names none (acpi_video0).
function outputOf(link) {
  var match = /\/card\d+-([^/]+)\/[^/]+\/?$/.exec(String(link || "").trim());
  return match ? match[1] : "";
}
