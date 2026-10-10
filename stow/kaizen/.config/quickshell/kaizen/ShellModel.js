.import "Ui/Jsonc.js" as Jsonc

function rgb(hex) {
  var value = String(hex || "");
  var match = /^#([0-9a-f]{6})$/i.exec(value);
  if (!match) return "";
  var packed = match[1];
  return [
    parseInt(packed.slice(0, 2), 16),
    parseInt(packed.slice(2, 4), 16),
    parseInt(packed.slice(4, 6), 16),
  ].join(",");
}

function kdeglobalsWrite(dark, darkPalette, lightPalette) {
  var palette = dark ? darkPalette : lightPalette;
  var set = function (key, hex) {
    return (
      "kwriteconfig6 --notify --file kdeglobals --group 'Colors:View' --key " +
      key +
      " '" +
      rgb(hex) +
      "'; "
    );
  };
  return (
    set("BackgroundNormal", palette.bg) + set("ForegroundNormal", palette.fg)
  );
}

function niriColors(palette) {
  return (
    'layout {\n    border {\n        active-color "' +
    palette.water +
    '"\n    }\n}\n'
  );
}

function textScale(value, minimum, maximum) {
  var scale = Number(value);
  var min = minimum === undefined ? 0.9 : minimum;
  var max = maximum === undefined ? 2 : maximum;
  return isFinite(scale) && scale >= min && scale <= max ? scale : null;
}

function observedTextScale(value) {
  var scale = parseFloat(String(value));
  return isFinite(scale) && scale > 0 ? scale : null;
}

// The config a plugin's JSONC file at `path` holds: an object, else {}, with a
// warning unless the text is empty.
function pluginConfig(text, path) {
  var value = String(text || "");
  if (!value.trim()) return {};
  var config;
  try {
    config = Jsonc.parse(value);
  } catch (error) {
    console.warn("plugins: " + path + ": " + error);
    return {};
  }
  if (!config || typeof config !== "object" || Array.isArray(config)) {
    console.warn("plugins: " + path + ": not an object");
    return {};
  }
  return config;
}
