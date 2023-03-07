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
    "github/copilot.vim",
    -- automatically start github copilot
    config = function()
      vim.keymap.set("i", "<C-J>", 'copilot#Accept("<CR>")', { silent = true, expr = true })
      vim.keymap.set("i", "<C-H>", "copilot#Previous()", { silent = true, expr = true })
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
      { "nvim-telescope/telescope.nvim" },
    },
  },

  -- git signs
  {
    "lewis6991/gitsigns.nvim",
    config = function()
      require("gitsigns").setup()
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
        },
      },
    },
  },

  -- change null-ls config
  {
    "jose-elias-alvarez/null-ls.nvim",
    opts = function(_, opts)
      local null_ls = require("null-ls")
      local formatting = null_ls.builtins.formatting
      local diagnostics = null_ls.builtins.diagnostics

      null_ls.setup({
        -- debug = true, -- Turn on debug for :NullLsLog
        debug = false,
        diagnostics_format = "#{m} #{s}[#{c}]",
        sources = {
          formatting.black,  -- causes crash on multiple file save
          diagnostics.ruff,
          diagnostics.mypy,
        },
      })

      -- remove flake8 from opts.sources
      -- opts.sources = vim.tbl_filter(function(source)
      --   return source.name ~= "flake8"
      -- end, opts.sources)

    end,
  },

  -- disable tabs
  { "akinsho/bufferline.nvim", enabled = false },

  -- Use <tab> for completion via supertab
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-emoji",
    },
    ---@param opts cmp.ConfigSchema
    opts = function(_, opts)
      local has_words_before = function()
        unpack = unpack or table.unpack
        local line, col = unpack(vim.api.nvim_win_get_cursor(0))
        return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
      end

      local luasnip = require("luasnip")
      local cmp = require("cmp")

      opts.mapping = vim.tbl_extend("force", opts.mapping, {
        ["<Tab>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_next_item()
            -- You could replace the expand_or_jumpable() calls with expand_or_locally_jumpable()
            -- they way you will only jump inside the snippet region
          elseif luasnip.expand_or_jumpable() then
            luasnip.expand_or_jump()
          elseif has_words_before() then
            cmp.complete()
          else
            fallback()
          end
        end, { "i", "s" }),
        ["<S-Tab>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_prev_item()
          elseif luasnip.jumpable(-1) then
            luasnip.jump(-1)
          else
            fallback()
          end
        end, { "i", "s" }),
      })
    end,
  },

  -- neotest
  {
    "nvim-neotest/neotest",

    keys = {
      { "<leader>rr", ":lua require('neotest').run.run()<CR>", desc = "Run nearest test" },
      { "<leader>rl", ":lua require('neotest').run.run_last()<CR>", desc = "Run last test" },
      { "<leader>rf", ":lua require('neotest').run.run(vim.fn.expand('%'))<CR>", desc = "Run tests in file" },
      { "<leader>rs", ":lua require('neotest').summary.toggle()<CR>", desc = "Run test summary" },
      { "<leader>ro", ":lua require('neotest').output.open({ enter = true })<CR>", desc = "Run test output" },
      { "<leader>rp", ":lua require('neotest').output_panel.toggle()<CR>", desc = "Run test output panel" },

      -- debugging via nvim-dap
      -- { "<leader>rd", ":lua require('neotest').run.run({ strategy = 'dap' })<CR>", desc = "Debug nearest test" },
    },

    config = function()
      require("neotest").setup({
        adapters = {
          require("neotest-python")({
            dap = { justMyCode = false },
            -- runner = "pytest",
          }),
          require("neotest-plenary"),
          require("neotest-vim-test")({
            -- ignore file types for installed adapters (or use allow_file_types)
            ignore_file_types = { "python", "vim", "lua" },
          }),
        },
      })
    end,

    dependencies = {
      { "nvim-lua/plenary.nvim" },
      { "nvim-treesitter/nvim-treesitter" },
      { "antoinemadec/FixCursorHold.nvim" },

      -- python
      {
        "nvim-neotest/neotest-python",
        dependencies = {
          { "nvim-neotest/neotest-plenary" },
          { "nvim-neotest/neotest-vim-test" },
        },
      },
    },
  },
}
