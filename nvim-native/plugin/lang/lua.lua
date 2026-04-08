vim.pack.add({
  { src = "https://github.com/folke/lazydev.nvim" },
  { src = "https://github.com/Bilal2453/luvit-meta" }, -- vim.uv typings
  { src = "https://github.com/jbyuki/one-small-step-for-vimkind" }, -- Lua DAP adapter
  { src = "https://github.com/nvim-neotest/neotest-plenary" },
})

require("lazydev").setup({
  library = {
    { path = "${3rd}/luv/library", words = { "vim%.uv" } },
    { path = "snacks.nvim", words = { "Snacks" } },
    "neotest",
    "plenary",
  },
})

require("registry").add({
  lsp_servers = { "lua_ls" },
  mason_tools = { "lua-language-server", "stylua" },
  conform = {
    formatters_by_ft = { lua = { "stylua" } },
  },
  blink = {
    sources = {
      providers = {
        lazydev = {
          name = "LazyDev",
          module = "lazydev.integrations.blink",
          score_offset = 100,
        },
      },
    },
  },
  neotest = {
    adapters = {
      { module = "neotest-plenary" },
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
