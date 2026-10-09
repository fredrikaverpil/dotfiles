// Backend-neutral firmware state. Each backend's parse() returns
// { updates, error }, with updates shaped as in Fwupd.js.

var URGENCY_RANK = { critical: 3, high: 2, medium: 1 };

// KAIZEN_FIRMWARE_BACKENDS, ":"-separated; names without a backend are dropped.
function backends(value, known) {
  return String(value || "")
    .split(":")
    .filter(function (backend) {
      return known.indexOf(backend) >= 0;
    });
}

// The SecureBoot EFI variable: 4 attribute bytes, then 1 when enforcing.
function secureBootEnabled(bytes) {
  return !!bytes && bytes.length === 5 && bytes[4] === 1;
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

// Secure Boot databases go unread while Secure Boot is off, so they never
// count as pending; they are still listed and can be applied.
function counts(update, secureBoot) {
  return !update.secureBoot || secureBoot;
}

function pending(updates, secureBoot) {
  return updates.filter(function (update) {
    return counts(update, secureBoot);
  });
}

function rank(urgency) {
  return URGENCY_RANK[urgency] || 0;
}

// Pending first, then most urgent, then by name.
function order(updates, secureBoot) {
  return updates.slice().sort(function (a, b) {
    return (
      Number(counts(b, secureBoot)) - Number(counts(a, secureBoot)) ||
      rank(b.urgency) - rank(a.urgency) ||
      a.name.localeCompare(b.name)
    );
  });
}

// Palette role for an urgency label.
function urgencyRole(urgency) {
  var value = rank(urgency);
  return value >= URGENCY_RANK.high ? "rose" : value > 0 ? "wood" : "off";
}

// "0 → 0.1.15 · 5 CVEs · needs AC · reboot · Secure Boot off"
function detail(update, secureBoot) {
  var parts = [update.current + " → " + update.version];
  var cves = update.issues.filter(function (issue) {
    return issue.indexOf("CVE-") === 0;
  }).length;
  if (cves > 0) parts.push(cves + (cves === 1 ? " CVE" : " CVEs"));
  if (update.needsAc) parts.push("needs AC");
  if (update.needsReboot) parts.push("reboot");
  if (!counts(update, secureBoot)) parts.push("Secure Boot off");
  return parts.join(" · ");
}
