import QtQuick
import QtTest
import "../plugins/lock/LockModel.js" as Lock

TestCase {
  name: "LockModel"

  readonly property var unlocked: ({
    lockRequested: false, authenticating: false, pendingPassword: "", enteredPassword: "", failureMessage: "", failedAttempts: 0,
  })

  function test_lock_begin_respects_pam_setup_and_resets_a_new_session() {
    compare(Lock.begin(unlocked, false, false), { started: false, state: unlocked })
    compare(Lock.begin(Object.assign({}, unlocked, { failedAttempts: 2 }), true, false), {
      started: true,
      state: Object.assign({}, unlocked, { lockRequested: true }),
    })
    compare(Lock.begin(unlocked, true, true), { started: true, state: unlocked })
  }

  function test_lock_authentication_accepts_one_nonempty_pending_password() {
    const requested = Object.assign({}, unlocked, { lockRequested: true, enteredPassword: "typing" })
    compare(Lock.submit(requested, "secret"), {
      lockRequested: true, authenticating: true, pendingPassword: "secret", enteredPassword: "", failureMessage: "", failedAttempts: 0,
    })
    compare(Lock.submit(requested, ""), null)
    compare(Lock.submit(Object.assign({}, requested, { authenticating: true }), "secret"), null)
  }

  function test_lock_failures_and_cancellation_clear_secrets_while_retaining_attempt_count() {
    const failed = Lock.fail(Object.assign({}, unlocked, { lockRequested: true, failedAttempts: 1, pendingPassword: "secret" }))
    compare(failed, {
      lockRequested: true, authenticating: false, pendingPassword: "", enteredPassword: "", failureMessage: "Authentication failed (2)", failedAttempts: 2,
    })
    compare(Lock.unlocked(failed), Object.assign({}, unlocked, { failedAttempts: 2 }))
    compare(Lock.cancelled(failed), Object.assign({}, unlocked, { failedAttempts: 2 }))
    compare(Lock.shouldBlank(failed), true)
    compare(Lock.shouldBlank(Object.assign({}, failed, { authenticating: true })), false)
  }

  function test_dpms_commands_run_only_for_a_real_state_transition() {
    compare(Lock.shouldSetDpms(false, true, true), true)
    compare(Lock.shouldSetDpms(false, false, false), true)
    compare(Lock.shouldSetDpms(false, false, true), false)
    compare(Lock.shouldSetDpms(true, true, true), false)
  }
}
