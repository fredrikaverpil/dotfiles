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

local root_markers = {
  ".luarc.json",
  ".luarc.jsonc",
  ".luacheckrc",
  ".stylua.toml",
  "stylua.toml",
  "selene.toml",
  "selene.yml",
  ".git",
}

--- Roots of read-only source: installed plugins and the Neovim runtime.
local vendored = {} ---@type string[]
for _, dir in ipairs({ vim.fn.stdpath("data") .. "/site/pack", vim.env.VIMRUNTIME }) do
  local real = vim.uv.fs_realpath(dir)
  if real then
    table.insert(vendored, real)
  end
end

--- Whether `path` is vendored source rather than something being worked on.
---@param path string
---@return boolean
local function is_vendored(path)
  local real = vim.uv.fs_realpath(path)
  if not real then
    return false
  end
  for _, dir in ipairs(vendored) do
    if vim.startswith(real, dir .. "/") then
      return true
    end
  end
  return false
end

---@type vim.lsp.Config
return {
  cmd = { "lua-language-server" },
  filetypes = { "lua" },
  root_markers = root_markers, -- unused while `root_dir` is set, but kept in sync with it
  --- Every plugin is its own git repo and `.git` is a root marker, so opening
  --- plugin source — which goto-definition does constantly — would otherwise
  --- start a fresh lua_ls rooted at that plugin, each one parsing the whole
  --- library again. Neovim reuses a client only when the buffer's root is
  --- already one of that client's workspace folders, but it does reuse a
  --- rootless client for any other rootless buffer, so leaving vendored source
  --- without a root collapses it all onto one shared client. Definitions still
  --- resolve, since those come from `workspace.library` rather than the root.
  ---@param bufnr integer
  ---@param on_dir fun(dir?: string)
  root_dir = function(bufnr, on_dir)
    if is_vendored(vim.api.nvim_buf_get_name(bufnr)) then
      on_dir(nil)
    else
      on_dir(vim.fs.root(bufnr, root_markers))
    end
  end,
  settings = {
    Lua = {
      runtime = {
        version = "LuaJIT",
        -- Needed for `require("plugin")` to bind to that module's return value.
        -- These patterns are matched against each library root, and plugin
        -- modules sit under `lua/`, which the default `?.lua;?/init.lua` does
        -- not reach there. Without this LuaLS still jumps to the file from the
        -- require string, but member access on it — `require("conform").setup`
        -- — resolves to nothing. Workspace-local requires already worked.
        path = { "lua/?.lua", "lua/?/init.lua" },
      },
      workspace = {
        checkThirdParty = false,
        library = runtime_library(), -- instead of lazydev.nvim
        -- LuaLS builds one of these matchers per library root as well as for
        -- the workspace, so this prunes plugin trees too — vendored copies and
        -- test suites hold no definitions worth jumping to, and every entry is
        -- a file LuaLS would otherwise parse on startup. Patterns are
        -- gitignore-style and match at any depth.
        ignoreDir = {
          ".pocket",
          ".tests",
          ".venv",
          ".vscode",
          "node_modules",
          "spec",
          "test",
          "tests",
          "vendor",
        },
      },
      -- diagnostics = { libraryFiles = "Disable" }, -- if noisy, disable
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
