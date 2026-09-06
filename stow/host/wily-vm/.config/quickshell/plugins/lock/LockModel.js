function reset(state) {
  return {
    lockRequested: false,
    authenticating: false,
    pendingPassword: "",
    enteredPassword: "",
    failureMessage: "",
    failedAttempts: state.failedAttempts || 0,
  }
}

function begin(state, passwordPamConfigured, locked) {
  if (!passwordPamConfigured) return { started: false, state: state }
  if (locked) return { started: true, state: state }

  return {
    started: true,
    state: {
      lockRequested: true,
      authenticating: false,
      pendingPassword: "",
      enteredPassword: "",
      failureMessage: "",
      failedAttempts: 0,
    },
  }
}

function submit(state, password) {
  var value = String(password || "")
  if (!state.lockRequested || state.authenticating || value.length === 0) return null

  return {
    lockRequested: state.lockRequested,
    authenticating: true,
    pendingPassword: value,
    enteredPassword: "",
    failureMessage: "",
    failedAttempts: state.failedAttempts || 0,
  }
}

function fail(state) {
  if (!state.lockRequested) return state
  var attempts = (state.failedAttempts || 0) + 1
  return {
    lockRequested: true,
    authenticating: false,
    pendingPassword: "",
    enteredPassword: "",
    failureMessage: "Authentication failed (" + attempts + ")",
    failedAttempts: attempts,
  }
}

function unlocked(state) {
  return reset(state)
}

function cancelled(state) {
  return reset(state)
}

function shouldBlank(state) {
  return !!(state.lockRequested && !state.authenticating)
}

function shouldSetDpms(running, blanked, on) {
  return !running && blanked === on
}

if (typeof module !== "undefined") {
  module.exports = {
    begin: begin,
    submit: submit,
    fail: fail,
    unlocked: unlocked,
    cancelled: cancelled,
    shouldBlank: shouldBlank,
    shouldSetDpms: shouldSetDpms,
  }
}
