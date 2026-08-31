// Same helper path as Omarchy's agent. Fingerprint-specific parsing remains
// there for a later ThinkPad port; this desktop only needs the request label.

function authorizationLabel(message) {
  var text = String(message || "")
  var match = text.match(/^Authentication is (?:needed|required) to run [`']([^`']+)[`'] as /i)
  return match ? "Authorize running '" + match[1] + "'" : text
}

if (typeof module !== "undefined") {
  module.exports = {
    authorizationLabel: authorizationLabel
  }
}
