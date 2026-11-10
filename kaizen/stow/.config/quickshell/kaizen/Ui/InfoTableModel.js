// The grid's cells for entries ([{ label, value }]), perLine side by side:
// each a label, then its value.
function cells(entries, perLine) {
  const result = [];
  entries.forEach((entry, index) => {
    const column = (index % perLine) * 2;
    result.push({ text: entry.label, label: true, column: column });
    result.push({ text: entry.value, label: false, column: column + 1 });
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
