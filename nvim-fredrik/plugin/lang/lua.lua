require("lazyload").on_vim_enter(function()
  vim.pack.add({
    { src = "https://github.com/folke/lazydev.nvim", version = vim.version.range("*") },
    { src = "https://github.com/Bilal2453/luvit-meta" }, -- vim.uv typings
  })

  require("lazydev").setup({
    library = {
      { path = "${3rd}/luv/library", words = { "vim%.uv" } },
      { path = "snacks.nvim", words = { "Snacks" } },
      "neotest",
      "plenary.nvim",
    },
  })

  -- By default lazydev registers `<root>/lua` as a LuaLS *library* and ignores
  -- it in the workspace. In Lua plugin repos that stops LuaLS from resolving
  -- intra-project `require()`, which silently breaks goto-definition and
  -- references across files. Opting out switches lazydev to
  -- `runtime.path = { "lua/?.lua", "lua/?/init.lua" }`, which resolves fine.
  -- Not exposed through setup(), hence the direct assignment.
  -- See also the seeded `workspace.library` in after/lsp/lua_ls.lua.
  require("lazydev.config").lua_root = false
end)
