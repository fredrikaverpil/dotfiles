--- Directories LuaLS indexes, with symlinks resolved and duplicates dropped.
---
--- LuaLS only scans `workspace.library` while it starts up, so the paths have
--- to be in `settings` before its first `workspace/configuration` pull.
---
--- The package directories are globbed rather than read off `runtimepath`:
--- vim.pack installs plugins as `opt`, so at attach time the runtimepath holds
--- only whatever happened to load first, and goto-definition would resolve
--- differently from one session to the next.
---
--- Symlinks must be resolved: `~/.config/nvim-fredrik` is stowed from this
--- repo, so without `fs_realpath` LuaLS sees the same files twice — once as
--- the workspace (`~/.dotfiles/nvim-fredrik`) and once as a library
--- (`~/.config/nvim-fredrik`). Definitions then bind to the library copy while
--- the cursor sits in the workspace copy, and references find nothing.
---@return string[]
local function runtime_library()
  local dirs = { vim.env.VIMRUNTIME, vim.fn.stdpath("config") }
  for _, kind in ipairs({ "start", "opt" }) do
    local pattern = vim.fn.stdpath("data") .. "/site/pack/*/" .. kind .. "/*"
    vim.list_extend(dirs, vim.fn.glob(pattern, true, true))
  end

  local seen = {} ---@type table<string, true>
  local paths = {} ---@type string[]
  for _, dir in ipairs(dirs) do
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
