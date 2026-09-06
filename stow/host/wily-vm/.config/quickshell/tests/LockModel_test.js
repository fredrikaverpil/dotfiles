import { createRequire } from "node:module"
import { assertEquals } from "jsr:@std/assert"

const Lock = createRequire(import.meta.url)("../plugins/lock/LockModel.js")

const unlocked = {
  lockRequested: false, authenticating: false, pendingPassword: "", enteredPassword: "", failureMessage: "", failedAttempts: 0,
}

Deno.test("lock begin respects PAM setup and resets a new session", () => {
  assertEquals(Lock.begin(unlocked, false, false), { started: false, state: unlocked })
  assertEquals(Lock.begin({ ...unlocked, failedAttempts: 2 }, true, false), {
    started: true,
    state: { ...unlocked, lockRequested: true },
  })
  assertEquals(Lock.begin(unlocked, true, true), { started: true, state: unlocked })
})

Deno.test("lock authentication accepts one nonempty pending password", () => {
  const requested = { ...unlocked, lockRequested: true, enteredPassword: "typing" }
  assertEquals(Lock.submit(requested, "secret"), {
    lockRequested: true, authenticating: true, pendingPassword: "secret", enteredPassword: "", failureMessage: "", failedAttempts: 0,
  })
  assertEquals(Lock.submit(requested, ""), null)
  assertEquals(Lock.submit({ ...requested, authenticating: true }, "secret"), null)
})

Deno.test("lock failures and cancellation clear secrets while retaining attempt count", () => {
  const failed = Lock.fail({ ...unlocked, lockRequested: true, failedAttempts: 1, pendingPassword: "secret" })
  assertEquals(failed, {
    lockRequested: true, authenticating: false, pendingPassword: "", enteredPassword: "", failureMessage: "Authentication failed (2)", failedAttempts: 2,
  })
  assertEquals(Lock.unlocked(failed), { ...unlocked, failedAttempts: 2 })
  assertEquals(Lock.cancelled(failed), { ...unlocked, failedAttempts: 2 })
  assertEquals(Lock.shouldBlank(failed), true)
  assertEquals(Lock.shouldBlank({ ...failed, authenticating: true }), false)
})

Deno.test("DPMS commands run only for a real state transition", () => {
  assertEquals(Lock.shouldSetDpms(false, true, true), true)
  assertEquals(Lock.shouldSetDpms(false, false, false), true)
  assertEquals(Lock.shouldSetDpms(false, false, true), false)
  assertEquals(Lock.shouldSetDpms(true, true, true), false)
})
