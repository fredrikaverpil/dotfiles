return {

  {
    "nvim-telescope/telescope.nvim",
    tag = "0.1.5",
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
      { "rcarriga/nvim-notify" },
    },

    opts = {
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
      },
      -- extensions = {
      --   --   fzf = {},
      --   --   live_grep_args = {
      --   --   },
      -- },
    },

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
      -- telescope.load_extension("projects")
      telescope.load_extension("ui-select")
      telescope.load_extension("recent_files")
      telescope.load_extension("notify")

      require("config.keymaps").setup_telescope_keymaps()
    end,
  },
}
