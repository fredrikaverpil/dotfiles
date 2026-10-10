.pragma library

// Parses JSONC: JSON with `//` and `/* */` comments and trailing commas. Throws
// as JSON.parse does.
function parse(text) {
  return JSON.parse(strip(String(text)));
}

// The text as JSON: comments and trailing commas dropped, strings kept whole,
// so a URL's `//` stays. A line comment keeps its newline.
function strip(text) {
  var out = "";
  // Where in `out` a comma waits for a value; a closing bracket drops it.
  var comma = -1;
  for (var i = 0; i < text.length; i++) {
    var c = text[i];
    if (c === "/" && text[i + 1] === "/") {
      while (i + 1 < text.length && text[i + 1] !== "\n") i++;
      continue;
    }
    if (c === "/" && text[i + 1] === "*") {
      var end = text.indexOf("*/", i + 2);
      i = end < 0 ? text.length : end + 1;
      continue;
    }
    if (c === '"') {
      var start = i;
      for (i++; i < text.length && text[i] !== '"'; i++) {
        if (text[i] === "\\") i++;
      }
      out += text.slice(start, i + 1);
      comma = -1;
      continue;
    }
    if ((c === "]" || c === "}") && comma >= 0)
      out = out.slice(0, comma) + out.slice(comma + 1);
    if (c === ",") comma = out.length;
    else if (!/\s/.test(c)) comma = -1;
    out += c;
  }
  return out;
}
