import { expect, test } from 'claude-code/testing'

test('warns once past 200k tokens or 20%, again after a drop or /clear', async ($, on) => {
  // Arrange
  let usage = { startedAt: 1, tokens: 0, window: 1_000_000 }
  on('session.usage', () => {
    const { startedAt, tokens, window } = usage
    const percent = Math.round((tokens / window) * 100)
    return { value: { startedAt, context: { tokens, window, percent }, rateLimits: [] } }
  })
  on('tool.call', () => ({ result: { stdout: '', stderr: '', interrupted: false } }))
  const toasts: string[] = []
  on('ui.toast', ($, e, next) => (toasts.push(e.text), next(e)))
  const call = async (next: Partial<typeof usage>) => {
    usage = { ...usage, ...next }
    const ran = await $.tool.call({ tool: 'Bash', command: 'true' })
    return ran.context ?? []
  }

  // Act
  const notes = [
    await call({ tokens: 150_000 }),
    await call({ tokens: 210_000 }),
    await call({ tokens: 300_000 }),
    await call({ tokens: 30_000 }),
    await call({ tokens: 220_000 }),
    await call({ startedAt: 2, tokens: 20_000 }),
    await call({ tokens: 45_000, window: 200_000 }),
    await call({ startedAt: 3, tokens: 205_000, window: 2_000_000 }),
  ]

  // Assert
  const warn = (p: number, t: number, w: number) =>
    `Context window: ${p}% used (${t}k of ${w}k tokens), past 200k tokens or 20%.`
  const want = [
    [],
    [warn(21, 210, 1000)],
    [],
    [],
    [warn(22, 220, 1000)],
    [],
    [warn(23, 45, 200)],
    [warn(10, 205, 2000)],
  ]
  expect({ notes, toasts }).toEqual({ notes: want, toasts: want.flat() })
})
