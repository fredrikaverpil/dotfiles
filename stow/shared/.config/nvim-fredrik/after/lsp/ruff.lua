---@type vim.lsp.Config
return {
  cmd = { "ruff", "server" },
  filetypes = { "python" },
  root_markers = {
    "pyproject.toml",
    "ruff.toml",
    ".ruff.toml",
    ".git",
  },
  on_attach = function(client)
    -- Disable hover in favor of basedpyright
    client.server_capabilities.hoverProvider = false
  end,
  -- HACK: explicitly setting offset encoding:
  -- https://github.com/astral-sh/ruff/issues/14483#issuecomment-2526717736
  capabilities = {
    general = {
      positionEncodings = { "utf-16" },
    },
  },
  init_options = {
    settings = {
      configurationPreference = "filesystemFirst",
      lineLength = 88,
    },
  },
}
