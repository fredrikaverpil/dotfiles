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

function cveCount(update) {
  return update.issues.filter(function (issue) {
    return issue.indexOf("CVE-") === 0;
  }).length;
}

// "0 → 0.1.15 · 5 CVEs · needs AC · reboot"
function detail(update) {
  var parts = [update.current + " → " + update.version];
  var cves = cveCount(update);
  if (cves > 0) parts.push(cves + (cves === 1 ? " CVE" : " CVEs"));
  if (update.needsAc) parts.push("needs AC");
  if (update.needsReboot) parts.push("reboot");
  return parts.join(" · ");
}

// A panel's details table ([{ label, value, role }]): Urgency, Security and
// Requires only when they say something.
function details(update) {
  var entries = [
    { label: "Vendor", value: update.vendor || "--" },
    { label: "Version", value: update.current + " → " + update.version },
  ];
  if (update.urgency !== "" && update.urgency !== "unknown")
    entries.push({
      label: "Urgency",
      value: update.urgency.charAt(0).toUpperCase() + update.urgency.slice(1),
      role: urgencyRole(update.urgency),
    });
  var cves = cveCount(update);
  if (cves > 0)
    entries.push({
      label: "Security",
      value: cves + (cves === 1 ? " CVE" : " CVEs"),
    });
  var needs = [];
  if (update.needsAc) needs.push("AC power");
  if (update.needsReboot) needs.push(needs.length > 0 ? "reboot" : "Reboot");
  if (needs.length > 0)
    entries.push({ label: "Requires", value: needs.join(", ") });
  return entries;
}
