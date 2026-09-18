// Curtain state only. Authentication reuses LockModel.js, which is already
// tested; this file owns the black/awake distinction the lock has no notion of.

function hidden() {
  return { active: false, awake: false }
}

function activate(state) {
  if (state.active) return state
  return { active: true, awake: false }
}

function dismiss(state) {
  return hidden()
}

// Any local input reveals the prompt. Restoring the backlight is driven off
// this, so a prompt is never drawn onto a dark panel.
function wake(state) {
  if (!state.active || state.awake) return state
  return { active: true, awake: true }
}

function sleep(state) {
  if (!state.active || !state.awake) return state
  return { active: true, awake: false }
}

function shouldShowPrompt(state) {
  return !!(state.active && state.awake)
}

// The backlight is dimmed only while black. Never DPMS: disabling the output
// breaks wlr-screencopy, which is the whole point of the curtain.
function shouldDimBacklight(state) {
  return !!(state.active && !state.awake)
}

// Authenticating must hold the prompt open even past the idle timeout.
function shouldSleepOnTimeout(state, authenticating) {
  return !!(state.active && state.awake && !authenticating)
}
