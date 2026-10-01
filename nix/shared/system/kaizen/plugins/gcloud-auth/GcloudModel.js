// `gcloud auth list --format=json`, or null when it is not a list of accounts.
function parseAccounts(text) {
  try {
    var accounts = JSON.parse(text)
    return Array.isArray(accounts) ? accounts : null
  } catch (error) {
    return null
  }
}

function activeAccount(accounts) {
  var active = accounts.filter(function(account) { return account.status === "ACTIVE" })[0]
  return active ? active.account : ""
}

// The login as `gcloud auth print-access-token` reports it. Every error a new
// login fixes says to run `gcloud auth login`; any other, a timeout included,
// is a failed check (null).
function token(exitCode, stderr) {
  if (exitCode === 0) return { ok: true, reason: "" }
  if (stderr.indexOf("gcloud auth login") < 0) return null
  var line = stderr.trim().split("\n")[0]
  return { ok: false, reason: line.replace(/^ERROR: \([^)]*\) /, "") }
}

// Whether the same account went from a working token to none.
function loggedOut(prev, cur) {
  return prev !== null && prev.ok && !cur.ok && prev.active === cur.active
}
