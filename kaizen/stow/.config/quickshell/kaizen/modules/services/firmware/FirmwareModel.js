// Backend-neutral firmware state. Each backend's parse() returns
// { updates, error }, with updates shaped as in Fwupd.js.

var URGENCY_RANK = { critical: 3, high: 2, medium: 1 };

// The backends whose daemon the system bus can activate, from busctl's
// ListActivatableNames in --json=short; known maps a backend to its module.
function backends(output, known) {
  var names;
  try {
    names = JSON.parse(output).data[0];
  } catch (e) {
    return [];
  }
  if (!Array.isArray(names)) return [];
  return Object.keys(known).filter(function (backend) {
    return names.indexOf(known[backend].busName) >= 0;
  });
}

function merge(backends, results) {
  var updates = [];
  var errors = [];
  backends.forEach(function (backend) {
    var result = results[backend];
    if (!result) return;
    updates = updates.concat(result.updates);
    if (result.error) errors.push({ backend: backend, error: result.error });
  });
  return { updates: updates, errors: errors };
}

function rank(urgency) {
  return URGENCY_RANK[urgency] || 0;
}

// Most urgent first, then by name.
function order(updates) {
  return updates.slice().sort(function (a, b) {
    return rank(b.urgency) - rank(a.urgency) || a.name.localeCompare(b.name);
  });
}

// Palette role for an urgency label.
function urgencyRole(urgency) {
  var value = rank(urgency);
  return value >= URGENCY_RANK.high ? "rose" : value > 0 ? "wood" : "off";
}

// "0 → 0.1.15 · 5 CVEs · needs AC · reboot"
function detail(update) {
  var parts = [update.current + " → " + update.version];
  var cves = update.issues.filter(function (issue) {
    return issue.indexOf("CVE-") === 0;
  }).length;
  if (cves > 0) parts.push(cves + (cves === 1 ? " CVE" : " CVEs"));
  if (update.needsAc) parts.push("needs AC");
  if (update.needsReboot) parts.push("reboot");
  return parts.join(" · ");
}
