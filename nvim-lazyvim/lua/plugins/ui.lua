return {

  {
    -- disable tabs
    "akinsho/bufferline.nvim",
    enabled = false,
  },

  {
    -- disable dashboard
    "nvimdev/dashboard-nvim",
    enabled = false,
  },

  {
    -- NOTE: colorschemes already installed in LazyVim: https://www.lazyvim.org/plugins/colorscheme

    "LazyVim/LazyVim",
    -- lazy = false,
    opts = {
      -- colorscheme = "tokyonight-storm",
      -- colorscheme = "tokyonight-night",
      colorscheme = "tokyonight-moon",
      -- colorscheme = "tokyonight-day",
      -- colorscheme = "catppuccin",
      -- colorscheme = "catppuccin-macchiato",
      -- colorscheme = "catppuccin-mocha",
      -- colorscheme = "catppuccin-frappe",
      -- colorscheme = "catppuccin-latte",
    },
  },

  {
    -- extends/modifies https://www.lazyvim.org/plugins/ui#lualinenvim
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
      local lazy_sections = opts.sections

      -- replace os.date (time)
      lazy_sections.lualine_z = { "encoding" }
    end,
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
        },

        -- This will use the OS level file watchers to detect changes
        -- instead of relying on nvim autocmd events.
        use_libuv_file_watcher = true,
      },
    },
  },

  {
    "folke/which-key.nvim",
    opts = function()
      require("which-key").register({
        ["<leader>t"] = {
          name = "+test",
        },
        ["<leader>gb"] = {
          name = "+blame",
        },
        ["<leader>gd"] = {
          name = "+diffview",
        },
        ["<leader>h"] = {
          name = "+harpoon",
        },
        ["<leader>r"] = {
          name = "+run",
        },
      })
    end,
  },

  {
    "folke/edgy.nvim",
    event = "VeryLazy",
    init = function()
      vim.opt.laststatus = 3
      vim.opt.splitkeep = "screen"
    end,
    opts = {

      animate = {
        enabled = false,
        fps = 100, -- frames per second
        cps = 120, -- cells per second
        on_begin = function()
          vim.g.minianimate_disable = true
        end,
        on_end = function()
          vim.g.minianimate_disable = false
        end,
        -- Spinner for pinned views that are loading.
        -- if you have noice.nvim installed, you can use any spinner from it, like:
        -- spinner = require("noice.util.spinners").spinners.circleFull,
        spinner = {
          frames = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" },
          interval = 80,
        },
      },
    },
  },

  {
    "mbbill/undotree",
    cmd = "UndotreeToggle",
    keys = {
      { "<leader>fu", "<cmd>UndotreeToggle<cr>", desc = "Undo tree" },
    },
  },

  {
    "s1n7ax/nvim-window-picker",
    name = "window-picker",
    event = "VeryLazy",
    version = "2.*",
    config = function()
      require("window-picker").setup()
    end,
  },

  { "sindrets/winshift.nvim" },

  {
    "kevinhwang91/nvim-ufo",
    enabled = true, -- can be disabled with neovim nightly as LazyVim implements folding too
    dependencies = {
      "kevinhwang91/promise-async",
      "nvim-treesitter/nvim-treesitter",
    },
    config = function()
      vim.o.foldcolumn = "0" -- '0' does not show the fold column, higher values increase the width
      vim.o.foldlevel = 99 -- Using ufo provider need a large value, feel free to decrease the value
      vim.o.foldlevelstart = 99
      vim.o.foldenable = true

      require("ufo").setup({
        provider_selector = function(bufnr, filetype, buftype)
          return { "treesitter", "indent" }
        end,
      })
    end,
  },

  { "folke/zen-mode.nvim" },
}
