return {

  -- add more treesitter parsers
  {
    "nvim-treesitter/nvim-treesitter",
    -- opts will be merged with the parent spec
    opts = {
        ensure_installed = {
        "bash",
        "help",
        "html",
        "javascript",
        "json",
        "lua",
        "markdown",
        "markdown_inline",
        "python",
        "query",
        "regex",
        "tsx",
        "typescript",
        "vim",
        "yaml",
        },
    },
  },

  -- add any tools you want to have installed below
  {
    "williamboman/mason.nvim",
    -- opts will be merged with the parent spec
    opts = {
        ensure_installed = {
        -- python
        "ruff-lsp",
        "debugpy",
        -- lua
        "stylua",
        -- shell
        "shellcheck",
        "shfmt",
        -- javascript/typescript
        "prettier",
        },
    },
  },

  -- github copilot
  {
      'github/copilot.vim',
      -- automatically start github copilot
      config = function()
          vim.keymap.set("i", "<C-J>", 'copilot#Accept("<CR>")', { silent = true, expr = true })
          vim.keymap.set("i", "<C-H>", 'copilot#Previous()', { silent = true, expr = true })
          -- vim.keymap.set("i", "<C-K>", 'copilot#Next()', { silent = true, expr = true })
      end,
  },

  -- chatgpt
  {
      "jackMort/ChatGPT.nvim",
        config = function()
          require("chatgpt").setup({
            -- optional configuration
          })
        end,
        dependencies = {
          { "MunifTanjim/nui.nvim" },
          { "nvim-lua/plenary.nvim" },
          { "nvim-telescope/telescope.nvim"},
        }
  },


  -- git signs
  {
    "lewis6991/gitsigns.nvim",
    config = function()
        require('gitsigns').setup()
    end,
  },

  -- change trouble config
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

  -- change neo-tree config
  {
    "nvim-neo-tree/neo-tree.nvim",
    -- opts will be merged with the parent spec
    opts = {
      filesystem = {
        filtered_items = {
          visible = true, -- when true, they will just be displayed differently than normal items
          hide_dotfiles = false,
          hide_gitignored = true,
        }
      }
    },
  },


  -- change null-ls config
  {
    "jose-elias-alvarez/null-ls.nvim",
    opts = function(_, opts)
      local nls = require("null-ls")

      -- add black as formatter
      opts.sources = vim.list_extend(opts.sources, { nls.builtins.formatting.black })

      -- remove flake8 from opts.sources
      opts.sources = vim.tbl_filter(function(source)
        return source.name ~= "flake8"
      end, opts.sources)

    end,
  },


}
