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
  -- Documented as unused when `root_dir` is defined, but Neovim still re-derives
  -- a root from it whenever `root_dir` yields nil — which would re-root every
  -- plugin buffer at its own git repo. `root_dir` does the marker search.
  root_markers = {},
  -- Vendored source gets no root, so `reuse_client` can fold it into a running
  -- client instead of starting one lua_ls per plugin repo.
  root_dir = function(bufnr, on_dir)
    if is_vendored(vim.api.nvim_buf_get_name(bufnr)) then
      on_dir(nil)
    else
      on_dir(vim.fs.root(bufnr, root_markers))
    end
  end,
  -- Rootless (vendored) buffers join any running lua_ls rather than starting a
  -- second one that would preload the whole library again.
  reuse_client = function(client, config)
    if client.name ~= config.name or client:is_stopped() then
      return false
    end
    if config.root_dir then
      return client.root_dir == config.root_dir
    end
    return true
  end,
  settings = {
    Lua = {
      runtime = {
        version = "LuaJIT",
        -- Matched against each library root, where plugin modules sit under
        -- `lua/` and the default `?.lua;?/init.lua` does not reach them.
        -- Without this, `require("conform").setup` resolves to nothing.
        path = { "lua/?.lua", "lua/?/init.lua" },
      },
      workspace = {
        checkThirdParty = false,
        library = runtime_library(),
        -- Applied per library root as well as to the workspace, so this prunes
        -- plugin trees too. Gitignore-style, matching at any depth.
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
