return {
  {
    "neovim/nvim-lspconfig",
    lazy = false,
    dependencies = {
      {
        "williamboman/mason-lspconfig.nvim",
        -- NOTE: this is here because mason-lspconfig must install servers prior to running nvim-lspconfig
        lazy = false,
        dependencies = {
          {
            -- NOTE: this is here because mason.setup must run prior to running nvim-lspconfig
            -- see mason.lua for more settings.
            "williamboman/mason.nvim",
            lazy = false,
          },
        },
      },
      {
        "hrsh7th/nvim-cmp",
        -- NOTE: this is here because we get the default client capabilities from cmp_nvim_lsp
        -- see cmp.lua for more settings.
      },
    },

    config = function(_, opts)
      local lspconfig = require("lspconfig")
      local default_capabilities = require("cmp_nvim_lsp").default_capabilities()

      for server in pairs(opts.servers) do
        lspconfig[server].setup({
          capabilities = default_capabilities,
        })
      end

      require("config.keymaps").setup_lsp_keymaps()
    end,
  },
}
