require("lang").register("lua", {
  servers = { "lua_ls" },
  mason = { "lua-language-server", "stylua" },
  formatters_by_ft = { lua = { "stylua" } },
  neotest = {
    packs = {
      { src = "https://github.com/nvim-neotest/neotest-plenary" },
    },
    adapter = function()
      -- neotest-plenary's module table is itself the adapter (no call needed)
      local adapter = require("neotest-plenary")
      return adapter
    end,
  },
  dap = {
    packs = {
      { src = "https://github.com/jbyuki/one-small-step-for-vimkind" }, -- Lua DAP adapter
    },
    setup = function(dap)
      local osv = require("osv")

      dap.adapters.nlua = function(callback, config)
        callback({ type = "server", host = config.host or "127.0.0.1", port = config.port or 8086 })
      end

      dap.configurations.lua = {
        {
          type = "nlua",
          request = "attach",
          name = "Attach to running Neovim instance",
        },
      }

      vim.keymap.set("n", "<leader>dLl", function()
        osv.launch({ port = 8086 })
      end, { desc = "Debug Lua: launch server" })
      vim.keymap.set("n", "<leader>dLr", function()
        osv.run_this()
      end, { desc = "Debug Lua: run this" })
    end,
  },
})

require("lazyload").on_vim_enter(function()
  vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("lua-opts", { clear = true }),
    pattern = { "lua" },
    callback = function()
      vim.opt_local.tabstop = 2
      vim.opt_local.softtabstop = 2
      vim.opt_local.shiftwidth = 2
      vim.opt_local.expandtab = true
    end,
  })

  vim.pack.add({
    { src = "https://github.com/folke/lazydev.nvim", version = vim.version.range("*") },
    { src = "https://github.com/Bilal2453/luvit-meta" }, -- vim.uv typings
  })

  require("lazydev").setup({
    library = {
      { path = "${3rd}/luv/library", words = { "vim%.uv" } },
      { path = "snacks.nvim", words = { "Snacks" } },
      "neotest",
      "plenary",
    },
  })
end)
