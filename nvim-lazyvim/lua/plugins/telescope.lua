return {

  -- change telescope config
  {
    "nvim-telescope/telescope.nvim",

    -- opts will be merged with the parent spec
    opts = {
      defaults = {
        file_ignore_patterns = { "^.git/", "^node_modules/", "^poetry.lock" },
      },
    },
  },

  -- https://github.com/nvim-telescope/telescope-live-grep-args.nvim
  {
    "nvim-telescope/telescope-live-grep-args.nvim",
    dependencies = {
      "nvim-telescope/telescope.nvim",
    },
    config = function()
      -- https://github.com/nvim-telescope/telescope-live-grep-args.nvim
      -- Uses ripgrep args (rg) for live_grep
      -- Command examples:
      -- -i "Data"  # case insensitive
      -- -g "!*.md" # ignore md files
      -- -w # whole word
      -- -e # regex
      -- see 'man rg' for more
      require("telescope").load_extension("live_grep_args")
    end,
    keys = {
      {
        "<leader>/",
        ":lua require('telescope').extensions.live_grep_args.live_grep_args()<CR>",
        desc = "Live Grep (Args)",
      },
    },

    -- opts will be merged with the parent spec
    opts = {
      pickers = {
        live_grep = {
          additional_args = function()
            return { "--hidden" }
          end,
        },
      },
    },
  },

  -- https://www.lazyvim.org/configuration/recipes#add-telescope-fzf-native
  {
    "nvim-telescope/telescope-fzf-native.nvim",
    dependencies = {
      "nvim-telescope/telescope.nvim",
    },
    build = "make",
    config = function()
      require("telescope").load_extension("fzf")
    end,
  },
}
