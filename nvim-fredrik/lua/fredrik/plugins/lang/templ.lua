local filetypes = { "templ" }

vim.api.nvim_create_autocmd("FileType", {
  pattern = filetypes,
  callback = function()
    vim.opt_local.tabstop = 2
    vim.opt_local.softtabstop = 2
    vim.opt_local.shiftwidth = 2
    vim.opt_local.expandtab = false

    vim.opt_local.colorcolumn = "120"
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
            "templ",
            "superhtml",
          })
        end,
      },
    },
    opts = {
      servers = {
        ---@type vim.lsp.Config
        templ = {
          -- lsp: https://templ.guide/developer-tools/ide-support#neovim--050
          -- ref: https://github.com/neovim/nvim-lspconfig/blob/master/lua/lspconfig/configs/templ.lua
          cmd = { "templ", "lsp" },
          filetypes = filetypes,
          root_markers = { "go.work", "go.mod", ".git" },
          settings = {
            templ = {},
          },
        },
        ---@type vim.lsp.Config
        gopls = {
          filetypes = filetypes,
          settings = {
            gopls = {
              templateExtensions = filetypes, -- make sure this filetype is set in the buffer
            },
          },
        },

        ---@type vim.lsp.Config
        superhtml = { filetypes = filetypes, settings = { superhtml = {} } },
      },
    },
    opts_extend = {
      "servers.gopls.filetypes",
      "servers.gopls.settings.gopls.templateExtensions",
      "servers.superhtml.filetypes",
    },
  },
}
