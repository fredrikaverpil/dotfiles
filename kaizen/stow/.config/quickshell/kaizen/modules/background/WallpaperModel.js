// Folder of a wallpaper relative to root; "" for the root itself.
function dirOf(path, root) {
  var rel = path.slice(root.length + 1);
  var i = rel.lastIndexOf("/");
  return i < 0 ? "" : rel.slice(0, i);
}

// By folder, then path, so each folder is contiguous.
function sorted(paths, root) {
  return paths.slice().sort(function (a, b) {
    var da = dirOf(a, root);
    var db = dirOf(b, root);
    if (da !== db) return da < db ? -1 : 1;
    return a < b ? -1 : a > b ? 1 : 0;
  });
}

// Header rows ({header, label}) and image rows ({start, count}) for sorted
// paths; start indexes paths. rowOfIndex maps a path's index to its row.
function layout(paths, root, columns) {
  var rows = [];
  var rowOfIndex = [];
  var dir = null;
  paths.forEach(function (path, i) {
    var d = dirOf(path, root);
    if (d !== dir) {
      dir = d;
      rows.push({ header: true, label: d || "Wallpapers" });
    }
    var row = rows[rows.length - 1];
    if (row.header || row.count === columns) {
      row = { header: false, start: i, count: 0 };
      rows.push(row);
    }
    row.count++;
    rowOfIndex[i] = rows.length - 1;
  });
  return { rows: rows, rowOfIndex: rowOfIndex };
}
