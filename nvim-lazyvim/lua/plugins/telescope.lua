return {

  -- change telescope config
  {
    "nvim-telescope/telescope.nvim",

    -- opts will be merged with the parent spec
    opts = {
      defaults = {
        file_ignore_patterns = { "^./.git/", "^node_modules/", "^poetry.lock" },
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
        function()
          require("telescope").extensions.live_grep_args.live_grep_args({
            vimgrep_arguments = {
              "rg",
              "--color=never",
              "--no-heading",
              "--with-filename",
              "--line-number",
              "--column",
              "--smart-case",
              "--hidden",
            },
          })
        end,
        desc = "Live Grep (Args)",
      },
    },
  },

  -- https://www.lazyvim.org/configuration/recipes#add-telescope-fzf-native
  {
    "nvim-telescope/telescope-fzf-native.nvim",
    enabled = false, -- testing zf-native for while
    dependencies = {
      "nvim-telescope/telescope.nvim",
    },
    build = "make",
    config = function()
      require("telescope").load_extension("fzf")
    end,
  },

  {
    -- https://github.com/natecraddock/telescope-zf-native.nvim
    "natecraddock/telescope-zf-native.nvim",
    enabled = true,
    dependencies = {
      "nvim-telescope/telescope.nvim",
    },
    config = function()
      require("telescope").load_extension("zf-native")
    end,
  },
}
