-- clone plugin manager (lazy.nvim) if it doesn't exist
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- plugins to lazy load, and their settings
rose = {
  'rose-pine/neovim',
  name = 'rose-pine',
  lazy = false,
  priority = 1000,
  config = function()
      require("rose-pine").setup()
      vim.cmd('colorscheme rose-pine')
  end
}

treesitter = {
  'nvim-treesitter/nvim-treesitter',
  run = ':TSUpdate',
  config = function()
    require'nvim-treesitter.configs'.setup {
      ensure_installed = {
          "c", "lua", "vim", "help", "python", "javascript", "typescript", "rust"
      },
      sync_install = false,
      auto_install = true,
      highlight = {
        enable = true,
        additional_vim_regex_highlighting = false,
      },
    }
  end,
}

telescope = {
  'nvim-telescope/telescope.nvim',
  branch = '0.1.x',
  config = function()
    local builtin = require('telescope.builtin')
    vim.keymap.set('n', '<leader>ff', builtin.find_files, {})
    vim.keymap.set('n', '<leader>gf', builtin.git_files, {})
    vim.keymap.set('n', '<leader>fg', builtin.live_grep, {})
    vim.keymap.set('n', '<leader>fb', builtin.buffers, {})
    vim.keymap.set('n', '<leader>fh', builtin.help_tags, {})
    vim.keymap.set('n', '<leader>ps', function()
      builtin.grep_string({ search = vim.fn.input("Grep > ") });
    end)
  end,
  dependencies = { {'nvim-lua/plenary.nvim'} }
}

fugitive = {
  'tpope/vim-fugitive',
  config = function()
    vim.keymap.set("n", "<leader>gs", vim.cmd.Git)
  end,
}

lspzero = {
  'VonHeikemen/lsp-zero.nvim',
  config = function()
    local lsp = require('lsp-zero')
    lsp.preset('recommended')
    lsp.setup()

    vim.diagnostic.config({
      virtual_text = true,
      signs = true,
      update_in_insert = false,
      underline = true,
      severity_sort = false,
      float = true,
    })
  end,
  dependencies = {
    -- LSP Support
    {'neovim/nvim-lspconfig'},
    {'williamboman/mason.nvim'},
    {'williamboman/mason-lspconfig.nvim'},

    -- Autocompletion
    {'hrsh7th/nvim-cmp'},
    {'hrsh7th/cmp-buffer'},
    {'hrsh7th/cmp-path'},
    {'saadparwaiz1/cmp_luasnip'},
    {'hrsh7th/cmp-nvim-lsp'},
    {'hrsh7th/cmp-nvim-lua'},

    -- Snippets
    {'L3MON4D3/LuaSnip'},
    {'rafamadriz/friendly-snippets'},
  }
}

nvimtree = {
    'nvim-tree/nvim-tree.lua',
    tag = 'nightly', -- optional, updated every week. (see issue #1193)
    config = function()
      require("nvim-tree").setup({
        sort_by = "case_sensitive",
        view = {
          width = 30,
          mappings = {
            list = {
              { key = "u", action = "dir_up" },
            },
          },
        },
        renderer = {
          group_empty = true,
        },
        filters = {
          dotfiles = true,
        },
      })
    end,
    dependencies = {
       -- {'nvim-tree/nvim-web-devicons'}, -- optional, for file icons
    },
}

gitsigns = {
    'lewis6991/gitsigns.nvim',
    config = function()
        require('gitsigns').setup()
    end,
}

feline = {
    'feline-nvim/feline.nvim',
    config = function()
        require('feline').setup()
    end,
}

todo = {
    'folke/todo-comments.nvim',
    config = function()
        require("todo-comments").setup()
    end,
}


-- list of plugins to load
enabled_plugins = {
  rose,
  treesitter,
  telescope,
  fugitive,
  lspzero,
  nvimtree,
  gitsigns,
  feline,
  todo
}

-- load plugins
require("lazy").setup(enabled_plugins)
