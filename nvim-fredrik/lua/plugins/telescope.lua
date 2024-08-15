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
      { "nvim-telescope/telescope-project.nvim" },
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
      local project_actions = require("telescope._extensions.project.actions")

      -- ////

      local function change_dir_and_reload_env(directory)
        local function get_env_from_output(output)
          local env = {}
          for line in output:gmatch("[^\r\n]+") do
            local name, value = line:match("^(.+)=(.*)$")
            if name and value then
              env[name] = value
            end
          end
          return env
        end

        local function split_path(path_string)
          local result = {}
          for segment in path_string:gmatch("[^:]+") do
            table.insert(result, segment)
          end
          return result
        end

        local cmd = string.format(
          [[
        zsh -c '
        cd %s
        source ~/.zshrc
        env
        '
    ]],
          directory
        )

        print("Executing command: " .. cmd)
        local output = vim.fn.system(cmd)

        local new_env = get_env_from_output(output)

        -- Update Neovim's environment
        for name, value in pairs(new_env) do
          vim.fn.setenv(name, value)
        end

        -- Special handling for PATH
        if new_env.PATH then
          vim.env.PATH = new_env.PATH
          -- Split PATH and add each component to Neovim's runtimepath
          local path_segments = split_path(new_env.PATH)
          for _, path in ipairs(path_segments) do
            vim.opt.rtp:prepend(path)
          end
        end

        -- -- Change Neovim's working directory
        -- vim.cmd("cd " .. directory)

        print("Changed to " .. directory .. " and reloaded environment")
      end

      opts.extensions = {
        ["ui-select"] = {
          require("telescope.themes").get_dropdown({}),
        },
        recent_files = {
          -- This extension's options, see below.
          only_cwd = true,
        },
        project = {
          base_dirs = {
            "~/code/dotfiles",
            "~/code/public/",
            "~/code/work/",
          },
          on_project_selected = function(prompt_bufnr)
            require("persistence").save()
            project_actions.change_working_directory(prompt_bufnr, false)
            change_dir_and_reload_env(vim.fn.getcwd())
            require("persistence").load()
          end,
        },
      }

      telescope.setup(opts)
      telescope.load_extension("project")
      telescope.load_extension("fzf")
      telescope.load_extension("live_grep_args")
      telescope.load_extension("ui-select")
      telescope.load_extension("recent_files")
      -- telescope.load_extension("projects") -- ahmedkhalf/project.nvim
      telescope.load_extension("notify")

      require("config.keymaps").setup_telescope_keymaps()
    end,
  },
}
