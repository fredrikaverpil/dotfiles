local plugins = {

  -- Treesitter
  -- https://nvchad.com/docs/config/syntax
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        -- defaults
        "vim",
        "lua",

        -- web dev
        "html",
        "css",
        "javascript",
        "typescript",
        "tsx",
        "json",
        -- "vue", "svelte",

       -- noice
       "python",
       "rust",

       -- low level
        "c",
        "zig"
      },
    },
  },



  -- In order to modify the `lspconfig` configuration
  -- https://nvchad.com/docs/config/lsp
  {
    "neovim/nvim-lspconfig",
    config = function()
        require "plugins.configs.lspconfig"
        require "custom.plugins.lspconfig"
    end,
  },


  -- Mason
  -- https://nvchad.com/docs/config/lsp
  {
    "williamboman/mason.nvim",
    opts = {
       ensure_installed = {
         "lua-language-server",
         "html-lsp",
         "prettier",
         "stylua",
         "pyright",
         "rust-analyzer",
       },
     },
   },


   -- Null-ls
   -- https://nvchad.com/docs/config/format_lint
   {
    "neovim/nvim-lspconfig",

     dependencies = {
       "jose-elias-alvarez/null-ls.nvim",
       config = function()
         require "custom.configs.null-ls"
       end,
     },

     config = function()
        require "plugins.configs.lspconfig"
        require "custom.configs.lspconfig"
     end,
  },






}

return plugins
