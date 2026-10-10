// `gcloud auth list --format=json`, or null when it is not a list of accounts.
function parseAccounts(text) {
  try {
    var accounts = JSON.parse(text);
    return Array.isArray(accounts) ? accounts : null;
  } catch (error) {
    return null;
  }
}

function activeAccount(accounts) {
  var active = accounts.filter(function (account) {
    return account.status === "ACTIVE";
  })[0];
  return active ? active.account : "";
}

// The errors a new login fixes: they say which login to run, except missing
// application default credentials, whose error names none.
var LOGIN = /gcloud auth login/;
var ADC_LOGIN =
  /gcloud auth application-default login|default credentials were not found/;

// The login as `print-access-token` reports it. An error that login does not
// match, a timeout included, is a failed check (null).
function token(exitCode, stderr, login) {
  if (exitCode === 0) return { ok: true, reason: "" };
  if (!login.test(stderr)) return null;
  var line = stderr.trim().split("\n")[0];
  return { ok: false, reason: line.replace(/^ERROR: \([^)]*\) /, "") };
}

// Whether the same account went from a working token to none.
function loggedOut(prev, cur) {
  return prev !== null && prev.ok && !cur.ok && prev.active === cur.active;
}
