require("lazyload").on_vim_enter(function()
  -- `vim.uv` typings. On the rtp, so `after/lsp/lua_ls.lua` seeds it into
  -- LuaLS's `workspace.library` along with everything else.
  vim.pack.add({
    { src = "https://github.com/Bilal2453/luvit-meta" },
  })
end)
