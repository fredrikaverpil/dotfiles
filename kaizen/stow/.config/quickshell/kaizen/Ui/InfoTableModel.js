// The grid's cells for entries ([{ label, value, role }]), perLine side by
// side: each a label, then its value. role is the value's palette role, `fg`
// when unset; labels are `off`.
function cells(entries, perLine) {
  const result = [];
  entries.forEach((entry, index) => {
    const column = (index % perLine) * 2;
    result.push({
      text: entry.label,
      label: true,
      column: column,
      role: "off",
    });
    result.push({
      text: entry.value,
      label: false,
      column: column + 1,
      role: entry.role || "fg",
    });
  });
  return result;
}

// Each grid column's width, its widest cell over every table in entrySets,
// so tables given the same widths line up. measure(text) is a cell's width.
function columnWidths(entrySets, perLine, measure) {
  const widths = new Array(perLine * 2).fill(0);
  for (const entries of entrySets)
    for (const cell of cells(entries, perLine))
      widths[cell.column] = Math.max(
        widths[cell.column],
        Math.ceil(measure(cell.text)),
      );
  return widths;
}

// widths shrunk to fit total, with spacing between columns: the widest value
// column (an SSID) gives up the overflow, so labels and the other values keep
// theirs and that value elides.
function fitWidths(widths, total, spacing) {
  const result = widths.slice();
  const used =
    result.reduce((sum, width) => sum + width, 0) +
    spacing * Math.max(0, result.length - 1);
  if (used <= total) return result;
  let widest = 1;
  for (let column = 3; column < result.length; column += 2)
    if (result[column] > result[widest]) widest = column;
  result[widest] = Math.max(0, result[widest] - (used - total));
  return result;
}
