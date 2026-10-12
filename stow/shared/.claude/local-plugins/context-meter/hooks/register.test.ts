import { expect, test } from 'claude-code/testing'

const usage = (context: { tokens?: number; window: number; percent?: number }) => () => ({
  value: { startedAt: 0, context, rateLimits: [] },
})

test('reports usage to the model and as a toast', async ($, on) => {
  // Arrange
  on('session.usage', usage({ tokens: 212_000, window: 1_000_000, percent: 21 }))
  const toasts: string[] = []
  on('ui.toast', ($, e, next) => (toasts.push(e.text), next(e)))

  // Act
  const ran = await $.tool.call({ tool: 'mcp__context-meter__usage' })

  // Assert
  const text = 'Context window: 21% used (212k of 1000k tokens).'
  expect({ result: ran.result, toasts }).toEqual({ result: text, toasts: [text] })
})

test('says so before the first response', async ($, on) => {
  // Arrange
  on('session.usage', usage({ window: 1_000_000 }))

  // Act
  const ran = await $.tool.call({ tool: 'mcp__context-meter__usage' })

  // Assert
  expect(ran.result).toEqual('Context window: not measured yet.')
})
