import type { Register } from 'claude-code'

const TOKENS = 200_000
const PERCENT = 20

export const register: Register = on => {
  // Conversation the warning belongs to; /clear starts a new one.
  let started: number | undefined
  let warned = false

  on('tool.call', async ($, e, next) => {
    const ran = await next(e)
    if (e.agentId !== undefined || ran.deny !== undefined) return ran

    const { startedAt, context } = await $.session.usage()
    const { percent, tokens, window } = context
    if (percent === undefined || tokens === undefined) return ran

    const isOver = tokens >= TOKENS || percent >= PERCENT
    if (startedAt !== started || !isOver) warned = false
    started = startedAt
    if (!isOver || warned) return ran
    warned = true

    const k = (n: number) => `${Math.round(n / 1000)}k`
    const note =
      `Context window: ${percent}% used (${k(tokens)} of ${k(window)} tokens), ` +
      `past ${k(TOKENS)} tokens or ${PERCENT}%.`
    $.ui.toast(note)
    return { ...ran, context: [...(ran.context ?? []), note] }
  }).catch(($, e, next) => next(e))
}
