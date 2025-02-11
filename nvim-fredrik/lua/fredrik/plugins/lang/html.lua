return {

  {
    "nvim-treesitter/nvim-treesitter",
    opts = { ensure_installed = { "html" } },
  },

  {
    "neovim/nvim-lspconfig",
    dependencies = {
      {
        "williamboman/mason-lspconfig.nvim",
        dependencies = { "williamboman/mason.nvim" },
        opts = function(_, opts)
          opts.ensure_installed = opts.ensure_installed or {}
          vim.list_extend(opts.ensure_installed, {
            "superhtml",
            -- "htmx-lsp"
          })
        end,
      },
    },
    opts = {
      servers = {

        --- https://github.com/kristoff-it/superhtml
        ---@type vim.lsp.Config
        superhtml = {
          cmd = { "superhtml", "lsp" },
          filetypes = { "html", "shtml", "htm" },
          root_markers = { ".git" },
          settings = {
            superhtml = {},
          },
        },

        -- https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#htmx
        -- FIXME: if enabling htmx, snippets stops working (blink.lua)
        -- htmx = { filetypes = { "html" }, settings = { htmx = {} } },
      },
    },
    opts_extend = {
      "servers.superhtml.filetypes",
    },
  },
}
