return {
  {
    "esmuellert/vscode-diff.nvim",
    -- "fredrikaverpil/vscode-diff.nvim",
    -- dev = true, -- see lazy.lua for local path details
    dependencies = { "MunifTanjim/nui.nvim" },
    opts = {
      -- Highlight configuration
      highlights = {
        -- Line-level: accepts highlight group names or hex colors (e.g., "#2ea043")
        line_insert = "DiffAdd", -- Line-level insertions
        line_delete = "DiffDelete", -- Line-level deletions

        -- Character-level: accepts highlight group names or hex colors
        -- If specified, these override char_brightness calculation
        char_insert = nil, -- Character-level insertions (nil = auto-derive)
        char_delete = nil, -- Character-level deletions (nil = auto-derive)

        -- Brightness multiplier (only used when char_insert/char_delete are nil)
        -- nil = auto-detect based on background (1.4 for dark, 0.92 for light)
        char_brightness = nil, -- Auto-adjust based on your colorscheme
      },

      -- Diff view behavior
      diff = {
        disable_inlay_hints = true, -- Disable inlay hints in diff windows for cleaner view
        max_computation_time_ms = 5000, -- Maximum time for diff computation (VSCode default)
      },

      -- Explorer panel configuration
      explorer = {
        view_mode = "tree",
        file_filter = {
          ignore = { "*.pb.go" },
        },
      },

      -- Keymaps in diff view
      keymaps = {
        view = {
          next_hunk = "]c", -- Jump to next change
          prev_hunk = "[c", -- Jump to previous change
          next_file = "<Tab>", -- Next file in explorer mode
          prev_file = "<S-Tab>", -- Previous file in explorer mode
        },
        explorer = {
          select = "<CR>", -- Open diff for selected file
          hover = "K", -- Show file diff preview
          refresh = "R", -- Refresh git status
        },
      },
    },
  },
}
