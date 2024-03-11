return {

  {
    "nvim-telescope/telescope.nvim",
    tag = "0.1.5",
    dependencies = {
      { "nvim-lua/plenary.nvim" },
      { "nvim-telescope/telescope-ui-select.nvim" },
      {
        -- https://github.com/nvim-telescope/telescope-fzf-native.nvim
        "nvim-telescope/telescope-fzf-native.nvim",
        build = "cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release && cmake --install build --prefix build",
      },
      {
        -- https://github.com/nvim-telescope/telescope-live-grep-args.nvim
        "nvim-telescope/telescope-live-grep-args.nvim",
      },
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
      }

      telescope.setup(opts)

      telescope.load_extension("fzf")
      telescope.load_extension("live_grep_args")
      -- telescope.load_extension("projects")
      telescope.load_extension("ui-select")

      require("config.keymaps").setup_telescope_keymaps()
    end,
  },
}
