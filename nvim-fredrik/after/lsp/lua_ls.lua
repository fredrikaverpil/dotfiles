--- Runtimepath directories, with symlinks resolved and duplicates dropped.
---
--- LuaLS only scans `workspace.library` while it starts up, so the paths have
--- to be in `settings` before its first `workspace/configuration` pull.
---
--- Symlinks must be resolved: `~/.config/nvim-fredrik` is stowed from this
--- repo, so without `fs_realpath` LuaLS sees the same files twice — once as
--- the workspace (`~/.dotfiles/nvim-fredrik`) and once as a library
--- (`~/.config/nvim-fredrik`). Definitions then bind to the library copy while
--- the cursor sits in the workspace copy, and references find nothing.
---@return string[]
local function runtime_library()
  local seen = {} ---@type table<string, true>
  local paths = {} ---@type string[]
  for _, dir in ipairs(vim.api.nvim_get_runtime_file("", true)) do
    local path = vim.uv.fs_realpath(dir) or dir
    if not seen[path] then
      seen[path] = true
      table.insert(paths, path)
    end
  end
  return paths
end

---@type vim.lsp.Config
return {
  cmd = { "lua-language-server" },
  filetypes = { "lua" },
  root_markers = {
    ".luarc.json",
    ".luarc.jsonc",
    ".luacheckrc",
    ".stylua.toml",
    "stylua.toml",
    "selene.toml",
    "selene.yml",
    ".git",
  },
  settings = {
    Lua = {
      runtime = { version = "LuaJIT" },
      workspace = {
        checkThirdParty = false,
        library = runtime_library(), -- instead of lazydev.nvim
        ignoreDir = { ".vscode", ".pocket", ".tests", ".venv", "node_modules" }, -- avoid >10k scanned files
      },
      codeLens = { enable = false }, -- causes annoying flickering
      completion = { callSnippet = "Replace" },
      doc = { privateName = { "^_" } },
      hint = {
        enable = true,
        setType = false,
        paramType = true,
        paramName = "Disable",
        semicolon = "Disable",
        arrayIndex = "Disable",
      },
      format = { enable = false }, -- use stylua via conform
    },
  },
}
