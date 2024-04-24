return {

  {
    "nvim-telescope/telescope.nvim",
    event = "VeryLazy",
    tag = "0.1.6",
    dependencies = {
      { "nvim-lua/plenary.nvim" },
      { "nvim-telescope/telescope-ui-select.nvim" },
      {
        "nvim-telescope/telescope-fzf-native.nvim",
        enabled = vim.fn.executable("make") == 1,
        build = "cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release && cmake --install build --prefix build",
      },
      {
        "nvim-telescope/telescope-live-grep-args.nvim",
      },
      { "smartpde/telescope-recent-files" },
      {
        "ahmedkhalf/project.nvim",
        opts = {
          {
            -- Manual mode doesn't automatically change your root directory, so you have
            -- the option to manually do so using `:ProjectRoot` command.
            manual_mode = true,

            -- Methods of detecting the root directory. **"lsp"** uses the native neovim
            -- lsp, while **"pattern"** uses vim-rooter like glob pattern matching. Here
            -- order matters: if one is not detected, the other is used as fallback. You
            -- can also delete or rearangne the detection methods.
            detection_methods = { "lsp", "pattern" },

            -- All the patterns used to detect root dir, when **"pattern"** is in
            -- detection_methods
            patterns = { ".git" },

            -- Table of lsp clients to ignore by name
            -- eg: { "efm", ... }
            ignore_lsp = {},

            -- Don't calculate root dir on specific directories
            -- Ex: { "~/.cargo/*", ... }
            exclude_dirs = {},

            -- Show hidden files in telescope
            show_hidden = true,

            -- When set to false, you will get a message when project.nvim changes your
            -- directory.
            silent_chdir = false,

            -- What scope to change the directory, valid options are
            -- * global (default)
            -- * tab
            -- * win
            scope_chdir = "win",

            -- Path where project.nvim will store the project history for use in
            -- telescope
            datapath = vim.fn.stdpath("data"),
          },
        },
        event = "VeryLazy",
        config = function(_, opts)
          require("project_nvim").setup(opts)
        end,
      },
      { "rcarriga/nvim-notify" },
      { "folke/trouble.nvim" }, -- for trouble.sources.telescope
    },
    opts = function(_, opts)
      local custom_opts = {
        defaults = {
          file_ignore_patterns = { ".git/", "node_modules", "poetry.lock" },
          vimgrep_arguments = {
            "rg",
            "--color=never",
            "--no-heading",
            "--hidden",
            "--with-filename",
            "--line-number",
            "--column",
            "--smart-case",
            "--trim",
          },
          mappings = {
            i = {
              ["<c-t>"] = require("trouble.sources.telescope").open,
              ["<a-t>"] = require("trouble.sources.telescope").open,
            },
          },
        },
        -- extensions = {
        --   --   fzf = {},
        --   --   live_grep_args = {
        --   --   },
        -- },
      }
      return vim.tbl_deep_extend("force", custom_opts, opts)
    end,
    config = function(_, opts)
      local telescope = require("telescope")

      opts.extensions = {
        ["ui-select"] = {
          require("telescope.themes").get_dropdown({}),
        },
        recent_files = {
          -- This extension's options, see below.
          only_cwd = true,
        },
      }

      telescope.setup(opts)

      telescope.load_extension("fzf")
      telescope.load_extension("live_grep_args")
      telescope.load_extension("ui-select")
      telescope.load_extension("recent_files")
      telescope.load_extension("projects")
      telescope.load_extension("notify")

      require("config.keymaps").setup_telescope_keymaps()
    end,
  },
}
