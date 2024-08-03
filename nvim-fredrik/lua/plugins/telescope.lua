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
        "ahmedkhalf/project.nvim", -- NOTE: add projects with :AddProject
        event = "VeryLazy",
        config = function()
          require("project_nvim").setup({ manual_mode = true, silent_chdir = false, scope_chdir = "win" })
        end,
      },
      { "rcarriga/nvim-notify" },
      { "folke/trouble.nvim" }, -- for trouble.sources.telescope
    },
    opts = function(_, opts)
      -- https://github.com/nvim-telescope/telescope.nvim/wiki/Configuration-Recipes
      local custom_opts = {
        defaults = {
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
            "--glob",
            "!**/.git/*",
            "--glob",
            "!**/node_modules/*",
          },
          mappings = {
            -- optionally, use tab to select file(s) and ...
            i = {
              ["<C-t>"] = require("trouble.sources.telescope").open,
              ["<a-t>"] = require("trouble.sources.telescope").open,
              ["<a-a>"] = require("trouble.sources.telescope").add,
            },
          },
        },
        pickers = {
          find_files = {
            find_command = { "rg", "--files", "--hidden", "--glob", "!**/.git/*" },
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
      telescope.load_extension("projects") -- ahmedkhalf/project.nvim
      telescope.load_extension("notify")

      require("config.keymaps").setup_telescope_keymaps()
    end,
  },
}
