---@type vim.lsp.Config
return {
  -- buf's `serve` defaults to --timeout=2m0s, which shuts the server down on
  -- idle and orphans already-open proto buffers (no auto re-attach). Disable it.
  cmd = { "buf", "lsp", "serve", "--timeout=0", "--log-format=text" },
}
