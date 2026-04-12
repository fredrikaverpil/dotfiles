vim.api.nvim_create_autocmd("FileType", {
  pattern = { "html" },
  callback = function()
    vim.opt_local.tabstop = 2
    vim.opt_local.softtabstop = 2
    vim.opt_local.shiftwidth = 2
    vim.opt_local.expandtab = true
  end,
})

return {
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
