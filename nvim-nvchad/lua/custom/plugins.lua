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


  {
    "folke/trouble.nvim",
    -- opts will be merged with the parent spec
    opts = {
      -- auto_open = false, -- automatically open the list when you have diagnostics
      -- auto_close = false, -- automatically close the list when you have no diagnostics
      -- use_diagnostic_signs = true, -- enabling this will use the signs defined in your lsp client
      -- auto_preview = true, -- automatically preview the location of the diagnostic. <esc> to close preview and go back to last window
    },
  },

	-- git signs
	{
		"lewis6991/gitsigns.nvim",
		config = function()
			require("gitsigns").setup()
		end,
	},

}




  return plugins
