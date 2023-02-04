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
local rose = {
  'rose-pine/neovim',
  name = 'rose-pine',
  lazy = false,
  priority = 1000,
  config = function()
      require("rose-pine").setup()
      vim.cmd('colorscheme rose-pine')
  end
}

local treesitter = {
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

local telescope = {
    'nvim-telescope/telescope.nvim',
    branch = '0.1.x',
    config = function()
        local builtin = require('telescope.builtin')
        vim.keymap.set('n', '<leader>sf', builtin.find_files, { desc = '[S]earch [F]iles' } )
        vim.keymap.set('n', '<leader>sh', builtin.help_tags, { desc = '[S]earch [H]elp' } )
        vim.keymap.set('n', '<leader>sw', builtin.grep_string, { desc = '[S]earch current [W]ord' } )
        vim.keymap.set('n', '<leader>sg', builtin.live_grep, { desc = '[S]earch by [G]rep' } )
        vim.keymap.set('n', '<leader>sd', builtin.diagnostics, { desc = '[S]earch [D]iagnostics' } )
        vim.keymap.set('n', '<leader>gf', builtin.git_files, { desc = '[G]it [F]iles' } )

        vim.keymap.set('n', '<leader><space>', builtin.buffers, { desc = '[ ] Find existing buffers' } )
        vim.keymap.set('n', '<leader>?', builtin.oldfiles, { desc = '[?] Find recently opened files' })
        vim.keymap.set('n', '<leader>/', function()
            builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
                winblend = 10,
                previewer = false,
            })
        end, { desc = '[/] Fuzzily search in current buffer]' })

        -- vim.keymap.set('n', '<leader>sgs', function()
        --     builtin.grep_string({ search = vim.fn.input("Grep > ") });
        -- end)
    end,
    dependencies = { {'nvim-lua/plenary.nvim'} }
}

local fugitive = {
  'tpope/vim-fugitive',
  config = function()
    vim.keymap.set("n", "<leader>gs", vim.cmd.Git)
  end,
}

local lspzero = {
    'VonHeikemen/lsp-zero.nvim',
    config = function()
        local lsp = require('lsp-zero')
        lsp.preset('recommended')
        lsp.setup()
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

local nvimtree = {
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

local gitsigns = {
    'lewis6991/gitsigns.nvim',
    config = function()
        require('gitsigns').setup()
    end,
}

local lualine = {
    'nvim-lualine/lualine.nvim',
    config = function()
        require('lualine').setup {
            options = {
                icons_enabled = true,
                theme = 'rose-pine',
                component_separators = '|',
                section_separators = '',
            },
        }
    end,
}

local todo_comments = {
    'folke/todo-comments.nvim',
    config = function()
        require("todo-comments").setup()
    end,
}

local which_key = {
    'folke/which-key.nvim',
    config = function()
      vim.o.timeout = true
      vim.o.timeoutlen = 300
      require("which-key").setup()
    end,
}

local trouble = {
    'folke/trouble.nvim',
    config = function()
        require("trouble").setup()

        vim.keymap.set("n", "<leader>xx", "<cmd>TroubleToggle<cr>",
        {silent = true, noremap = true}
        )
        vim.keymap.set("n", "<leader>xw", "<cmd>TroubleToggle workspace_diagnostics<cr>",
        {silent = true, noremap = true}
        )
        vim.keymap.set("n", "<leader>xd", "<cmd>TroubleToggle document_diagnostics<cr>",
        {silent = true, noremap = true}
        )
        vim.keymap.set("n", "<leader>xl", "<cmd>TroubleToggle loclist<cr>",
        {silent = true, noremap = true}
        )
        vim.keymap.set("n", "<leader>xq", "<cmd>TroubleToggle quickfix<cr>",
        {silent = true, noremap = true}
        )
        vim.keymap.set("n", "gR", "<cmd>TroubleToggle lsp_references<cr>",
        {silent = true, noremap = true}
        )
    end,
    dependencies = {
        { 'nvim-tree/nvim-web-devicons' }
    }
}

local move = {
    'fedepujol/move.nvim',
    config = function()
        local opts = { noremap = true, silent = true }
        -- If using iTerm2, go into Settings -> Profile -> Keys
        -- and set left option key to send Esc+

        -- Normal-mode commands
        vim.keymap.set('n', '<A-j>', ':MoveLine(1)<CR>', opts)
        vim.keymap.set('n', '<A-k>', ':MoveLine(-1)<CR>', opts)
        vim.keymap.set('n', '<A-h>', ':MoveHChar(-1)<CR>', opts)
        vim.keymap.set('n', '<A-l>', ':MoveHChar(1)<CR>', opts)

        -- Visual-mode commands
        vim.keymap.set('v', '<A-j>', ':MoveBlock(1)<CR>', opts)
        vim.keymap.set('v', '<A-k>', ':MoveBlock(-1)<CR>', opts)
        vim.keymap.set('v', '<A-h>', ':MoveHBlock(-1)<CR>', opts)
        vim.keymap.set('v', '<A-l>', ':MoveHBlock(1)<CR>', opts)
    end,
}

local copilot = {
    'github/copilot.vim',
    -- automatically start github copilot
    config = function()
        vim.keymap.set("i", "<C-J>", 'copilot#Accept("<CR>")', { silent = true, expr = true })
        vim.keymap.set("i", "<C-H>", 'copilot#Previous()', { silent = true, expr = true })
        vim.keymap.set("i", "<C-K>", 'copilot#Next()', { silent = true, expr = true })
    end,
}


-- list of plugins to load
local enabled_plugins = {
  rose,
  treesitter,
  telescope,
  fugitive,
  lspzero,
  nvimtree,
  gitsigns,
  lualine,
  todo_comments,
  which_key,
  trouble,
  move,
  copilot
}

-- load plugins
require("lazy").setup(enabled_plugins)
