return {
  "nvim-neo-tree/neo-tree.nvim",
  event = "VeryLazy",
  branch = "v3.x",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons",
    "MunifTanjim/nui.nvim",
  },
  opts = {
    -- sources = { "filesystem", "buffers", "git_status", "document_symbols" },
    -- open_files_do_not_replace_types = { "terminal", "Trouble", "trouble", "qf", "Outline" },
    filesystem = {
      bind_to_cwd = false,
      follow_current_file = { enabled = true },

      -- This will use the OS level file watchers to detect changes
      -- instead of relying on nvim autocmd events.
      use_libuv_file_watcher = true,

      filtered_items = {
        visible = true, -- when true, they will just be displayed differently than normal items
        hide_dotfiles = false,
        hide_gitignored = true,
      },
    },
  },
  config = function(_, opts)
    require("neo-tree").setup(opts)
    require("config.keymaps").setup_neotree_keymaps()
  end,
}
