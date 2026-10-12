import type { Register } from 'claude-code'

const TOOL = 'mcp__context-meter__usage'

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    await $.tool.register({
      name: 'usage',
      description: 'How full the context window is, as a percentage and in tokens.',
    })
    return next(e)
  })

  on('tool.call', { tool: TOOL }, async $ => {
    const { percent, tokens, window } = (await $.session.usage()).context
    const k = (n: number) => `${Math.round(n / 1000)}k`
    const text =
      percent === undefined || tokens === undefined
        ? 'Context window: not measured yet.'
        : `Context window: ${percent}% used (${k(tokens)} of ${k(window)} tokens).`
    $.ui.toast(text)
    return { result: text }
  }).catch(() => ({ result: 'Context window: unavailable.' }))
}
