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
            "html-lsp",
            -- "htmx-lsp"
          })
        end,
      },
    },
    opts = {
      servers = {
        -- lsp: https://github.com/microsoft/vscode-html-languageservice
        -- ref: https://github.com/neovim/nvim-lspconfig/blob/master/lua/lspconfig/configs/html.lua
        ---@type vim.lsp.Config
        html = {
          cmd = { "vscode-html-language-server", "--stdio" },
          filetypes = { "html" },
          root_markers = { ".git" },
          init_options = {
            provideFormatter = true, -- TODO: replace with prettier?
            embeddedLanguages = { css = true, javascript = true },
            configurationSection = { "html", "css", "javascript" },
          },
          settings = {
            html = {},
          },
        },
        -- https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#htmx
        -- FIXME: if enabling htmx, snippets stops working (blink.lua)
        -- htmx = { filetypes = { "html" }, settings = { htmx = {} } },
      },
    },
  },
}
