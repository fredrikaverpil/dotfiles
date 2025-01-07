vim.filetype.add({
  extension = {
    gotmpl = "gotmpl",
    gohtml = "gotmpl",
  },
  -- filename = {},
  -- pattern = {},
})

local filetypes = { "gotmpl", "gohtml" }

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
    opts = { ensure_installed = { "gotmpl", "html" } },
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
            "gopls",
            "html-lsp",
            -- "htmx-lsp",
          })
        end,
      },
    },
    opts = {
      servers = {
        -- TODO: evaluate https://github.com/yayolande/go-template-lsp

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
        html = { filetypes = filetypes, settings = { html = {} } },
        -- htmx = { filetypes = filetypes, settings = { htmx = {} } },
      },
    },
    opts_extend = {
      "servers.gopls.filetypes",
      "servers.gopls.settings.gopls.templateExtensions",
    },
  },
}
