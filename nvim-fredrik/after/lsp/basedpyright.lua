---@type vim.lsp.Config
return {
  cmd = { "basedpyright-langserver", "--stdio" },
  filetypes = { "python" },
  root_markers = {
    "pyproject.toml",
    "ruff.toml",
    ".ruff.toml",
    "requirements.txt",
    "uv.lock",
    "setup.py",
    "setup.cfg",
    "Pipfile",
    "pyrightconfig.json",
    ".git",
  },
  settings = {
    python = {
      venvPath = os.getenv("VIRTUAL_ENV"),
      pythonPath = vim.fn.exepath("python"),
    },
    basedpyright = {
      disableOrganizeImports = true, -- delegate to ruff
      analysis = {
        autoSearchPaths = true,
        useLibraryCodeForTypes = true,
        diagnosticMode = "openFilesOnly",
      },
    },
  },
}
