return {

  -- add more treesitter parsers
  {
    "nvim-treesitter/nvim-treesitter",
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

  -- change trouble config
  {
    "folke/trouble.nvim",
    -- opts will be merged with the parent spec
    opts = { use_diagnostic_signs = true },
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



}
