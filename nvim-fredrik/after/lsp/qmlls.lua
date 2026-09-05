-- `-E` reads QML_IMPORT_PATH, set by the repo's devshell (flake.nix `default`,
-- entered via .envrc) and inherited when Neovim is launched from that shell.
-- The same env drives `qmllint -E`, so editor and terminal resolve identically.
---@type vim.lsp.Config
return {
  cmd = { "qmlls", "-E" },
}
