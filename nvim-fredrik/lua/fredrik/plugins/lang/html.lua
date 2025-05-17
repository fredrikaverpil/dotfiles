return {

  {
    "nvim-treesitter/nvim-treesitter",
    opts = { ensure_installed = { "html" } },
  },

  {
    "virtual-lsp-config",
    dependencies = {
      {
        "mason-org/mason-lspconfig.nvim",
        dependencies = { "mason-org/mason.nvim" },
        opts = function(_, opts)
          opts.ensure_installed = opts.ensure_installed or {}
          vim.list_extend(opts.ensure_installed, {
            "superhtml",
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
      },
    },
    opts_extend = {
      "servers.superhtml.filetypes",
    },
  },
}
