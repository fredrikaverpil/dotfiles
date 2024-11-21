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
        -- used for switching between projects
        "nvim-telescope/telescope-project.nvim",
      },
      {
        -- used for opening files in another project
        "ahmedkhalf/project.nvim", -- NOTE: add projects with :AddProject
        event = "VeryLazy",
        config = function()
          local opts = {
            manual_mode = true,
            silent_chdir = false,
            scope_chdir = "win",
          }
          require("project_nvim").setup(opts)
        end,
      },
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
        extensions = {
          ["ui-select"] = {
            require("telescope.themes").get_dropdown({}),
          },
          recent_files = {
            only_cwd = true,
          },
          project = {
            base_dirs = {
              { path = "~/.dotfiles", max_depth = 1 },
              { path = "~/code", max_depth = 1 },
            },
            sync_with_nvim_tree = true,
            on_project_selected = function(prompt_bufnr)
              if vim.g.project_set_cwd then
                vim.cmd([[:SessionSave]])
                require("telescope._extensions.project.actions").change_working_directory(prompt_bufnr, false)
                vim.cmd([[:SessionRestore]])
              else
                local builtin = require("telescope.builtin")
                local path = require("telescope._extensions.project.actions").get_selected_path(prompt_bufnr)
                builtin.find_files({ cwd = path })
              end
            end,
          },
          --   fzf = {},
          --   live_grep_args = {
          --   },
        },
      }
      return vim.tbl_deep_extend("force", custom_opts, opts)
    end,
    config = function(_, opts)
      local telescope = require("telescope")

      telescope.setup(opts)

      telescope.load_extension("fzf")
      telescope.load_extension("live_grep_args")
      telescope.load_extension("ui-select")
      telescope.load_extension("recent_files")
      telescope.load_extension("project") -- telescope-project.nvim
      telescope.load_extension("projects") -- ahmedkhalf/project.nvim

      require("config.keymaps").setup_telescope_keymaps()
    end,
  },
}
