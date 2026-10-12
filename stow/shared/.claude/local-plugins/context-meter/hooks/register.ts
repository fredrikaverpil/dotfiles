import type { Register, SessionContextUsage } from 'claude-code'

const TOOL = 'mcp__context-meter__usage'
const TOKENS = 200_000
const PERCENT = 20

const k = (n: number) => `${Math.round(n / 1000)}k`

const describe = ({ percent, tokens, window }: SessionContextUsage) =>
  percent === undefined || tokens === undefined
    ? 'Context window: not measured yet'
    : `Context window: ${percent}% used (${k(tokens)} of ${k(window)} tokens)`

export const register: Register = on => {
  // Conversation the warning belongs to; /clear starts a new one.
  let started: number | undefined
  let warned = false

  on('session.start', async ($, e, next) => {
    await $.tool.register({
      name: 'usage',
      description: 'How full the context window is, as a percentage and in tokens.',
    })
    return next(e)
  })

  on('tool.call', { tool: TOOL }, async $ => ({
    result: `${describe((await $.session.usage()).context)}.`,
  })).catch(() => ({ result: 'Context window: unavailable.' }))

  on('tool.call', async ($, e, next) => {
    const ran = await next(e)
    if (e.agentId !== undefined || ran.deny !== undefined) return ran

    const { startedAt, context } = await $.session.usage()
    const { percent, tokens } = context
    if (percent === undefined || tokens === undefined) return ran

    const isOver = tokens >= TOKENS || percent >= PERCENT
    if (startedAt !== started || !isOver) warned = false
    started = startedAt
    if (!isOver || warned) return ran
    warned = true

    const note = `${describe(context)}, past ${k(TOKENS)} tokens or ${PERCENT}%.`
    $.ui.toast(note)
    return { ...ran, context: [...(ran.context ?? []), note] }
  }).catch(($, e, next) => next(e))
}
