local filetypes = { "templ" }

vim.api.nvim_create_autocmd("FileType", {
  pattern = filetypes,
  callback = function()
    -- set go specific options
    vim.opt_local.tabstop = 2
    vim.opt_local.shiftwidth = 2
    vim.opt_local.colorcolumn = "120"
  end,
})

return {

  {
    "nvim-treesitter/nvim-treesitter",
    lazy = true,
    ft = filetypes,
    opts = { ensure_installed = { "templ", "html" } },
  },

  {
    "neovim/nvim-lspconfig",
    lazy = true,
    ft = filetypes,
    dependencies = {
      {
        "williamboman/mason-lspconfig.nvim",
        dependencies = { "williamboman/mason.nvim" },
        opts = function(_, opts)
          opts.ensure_installed = opts.ensure_installed or {}
          vim.list_extend(opts.ensure_installed, {
            "templ",
            "html-lsp",
            -- htmx-lsp,
          })
        end,
      },
    },
    opts = {
      servers = {
        templ = {
          filetypes = filetypes,
          settings = {
            templ = {},
          },
        },
      },
      extends = {
        -- extendee: templ
        templ = {
          -- extends: go.lua, html.lua
          servers = {
            gopls = {
              filetypes = filetypes,
              settings = {
                gopls = {
                  templateExtensions = filetypes, -- make sure this filetype is set in the buffer
                },
              },
            },
            html = { filetypes = filetypes, settings = { html = {} } },
            -- htmx = { filetypes = filetypes, settings = { htmx = {} } },
          },
        },
      },
    },
  },
}
