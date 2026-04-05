return {
  {
    "andymass/vim-matchup",
    enabled = false,
    dependencies = {
      {
        -- "nvim-treesitter/nvim-treesitter",
        -- opts = {
        --   matchup = {
        --     enable = true, -- mandatory, false will disable the whole extension
        --     -- disable = { "c", "ruby" }, -- optional, list of language that will be disabled
        --   },
        -- },
      },
    },
    init = function()
      -- disable matchup offscreen
      vim.g.matchup_matchparen_offscreen = { method = "status-manual" }
    end,
    opts = {},
  },

  -- Lightweight alternative to vim-matchup.
  -- Highlights the matching bracket/keyword pair using CursorHold,
  -- so it only triggers after the cursor is idle (governed by 'updatetime'),
  -- rather than on every CursorMoved event.
  --
  -- Highlight group: "MatchParen" (reuses the built-in group).
  {
    "matchparen-lite",
    virtual = true,
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      -- Disable the built-in matchparen plugin so we don't double-highlight.
      vim.g.loaded_matchparen = 1
      pcall(function()
        vim.cmd("NoMatchParen")
      end)

      local ns = vim.api.nvim_create_namespace("matchparen_lite")

      local function clear()
        vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)
      end

      local function highlight()
        clear()
        local line = vim.fn.line(".")
        local col = vim.fn.col(".")
        local char = vim.fn.getline(line):sub(col, col)

        -- Check if cursor is on a matchable bracket character.
        if not char:match("[%(%)%[%]{}]") then
          -- Try the character before the cursor (common for closing brackets).
          if col > 1 then
            char = vim.fn.getline(line):sub(col - 1, col - 1)
            if not char:match("[%(%)%[%]{}]") then
              return
            end
            col = col - 1
          else
            return
          end
        end

        -- Save cursor, jump to match with %, get position, restore cursor.
        local save = vim.fn.winsaveview()
        vim.fn.cursor(line, col)
        vim.cmd("normal! %")
        local match_line = vim.fn.line(".")
        local match_col = vim.fn.col(".")
        vim.fn.winrestview(save)

        -- If % didn't move, there's no match.
        if match_line == line and match_col == col then
          return
        end

        -- Highlight the matching character.
        vim.api.nvim_buf_set_extmark(0, ns, match_line - 1, match_col - 1, {
          end_col = match_col,
          hl_group = "MatchParen",
        })
        -- Also highlight the character under the cursor.
        vim.api.nvim_buf_set_extmark(0, ns, line - 1, col - 1, {
          end_col = col,
          hl_group = "MatchParen",
        })
      end

      local group = vim.api.nvim_create_augroup("MatchParenLite", { clear = true })
      vim.api.nvim_create_autocmd("CursorHold", {
        group = group,
        callback = highlight,
      })
      vim.api.nvim_create_autocmd("CursorMoved", {
        group = group,
        callback = clear,
      })
    end,
  },
}
