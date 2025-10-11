vim.api.nvim_create_autocmd("FileType", {
  pattern = { "query" },
  callback = function()
    vim.opt_local.tabstop = 2
    vim.opt_local.softtabstop = 2
    vim.opt_local.shiftwidth = 2
    vim.opt_local.expandtab = true

    vim.opt_local.colorcolumn = "120"
  end,
})

return {
  {
    "virtual-lsp-config",
    dependencies = {
      {
        "mason-org/mason-lspconfig.nvim",
        dependencies = {
          {
            "mason-org/mason.nvim",
          },
        },
        opts = function(_, opts)
          opts.ensure_installed = opts.ensure_installed or {}
          vim.list_extend(opts.ensure_installed, { "ts_query_ls" })
        end,
      },
    },
    opts = {
      servers = {
        ---@type vim.lsp.Config
        ts_query_ls = {
          -- lsp: https://github.com/ribru17/ts_query_ls
          cmd = { "ts_query_ls" },
          filetypes = { "query" },
          root_markers = { ".tsqueryrc.json", ".git" },
          init_options = {
            parser_install_directories = {
              vim.fn.stdpath("data") .. "/site/parser",
              -- vim.fn.stdpath("data") .. "/lazy/nvim-treesitter/parser/",
            },
            parser_aliases = {},
            language_retrieval_patterns = {},
          },
          settings = {},
        },
      },
    },
  },
}
