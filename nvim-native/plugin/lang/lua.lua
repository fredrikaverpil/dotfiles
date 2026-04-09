vim.pack.add({
  { src = "https://github.com/folke/lazydev.nvim" },
  { src = "https://github.com/Bilal2453/luvit-meta" }, -- vim.uv typings
  { src = "https://github.com/jbyuki/one-small-step-for-vimkind" }, -- Lua DAP adapter
  { src = "https://github.com/nvim-neotest/neotest-plenary" },
})

require("registry").add({
  lsp = { servers = { "lua_ls" } },
  mason = { ensure_installed = { "lua-language-server", "stylua" } },
  conform = {
    opts = {
      formatters_by_ft = { lua = { "stylua" } },
    },
  },
  blink = {
    opts = {
      sources = {
        default = { "lazydev" },
        providers = {
          lazydev = {
            name = "LazyDev",
            module = "lazydev.integrations.blink",
            score_offset = 100,
          },
        },
      },
    },
  },
  neotest = {
    opts = {
      adapters = {
        { module = "neotest-plenary" },
      },
    },
  },
  dap = {
    adapters = {
      nlua = function(callback, config)
        callback({ type = "server", host = config.host or "127.0.0.1", port = config.port or 8086 })
      end,
    },
    configurations = {
      lua = {
        {
          type = "nlua",
          request = "attach",
          name = "Attach to running Neovim instance",
        },
      },
    },
  },
})

require("defer").on_ui_enter(function()
  require("lazydev").setup({
    library = {
      { path = "${3rd}/luv/library", words = { "vim%.uv" } },
      { path = "snacks.nvim", words = { "Snacks" } },
      "neotest",
      "plenary",
    },
  })
end)
