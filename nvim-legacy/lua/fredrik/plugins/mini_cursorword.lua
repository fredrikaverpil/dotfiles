return {

  {
    "echasnovski/mini.cursorword",
    enabled = false, -- sluggish in large log file for example
    version = "*",
    opts = {},
    config = function(_, opts)
      require("mini.cursorword").setup()
    end,
  },

  -- Lightweight alternative to mini.cursorword.
  -- Highlights all occurrences of the word under the cursor using CursorHold,
  -- so it only triggers after the cursor is idle (governed by 'updatetime'),
  -- rather than on every CursorMoved event.
  --
  -- Highlight group: "MiniCursorword" (underline by default).
  -- Override it in your colorscheme to customize, e.g.:
  --   vim.api.nvim_set_hl(0, "MiniCursorword", { bg = "#303030", underline = false })
  {
    "cursorword-lite",
    virtual = true,
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      local function clear()
        local id = vim.w.minicursorword_match_id
        if id then
          pcall(vim.fn.matchdelete, id)
          vim.w.minicursorword_match_id = nil
        end
      end

      local function highlight()
        clear()
        local word = vim.fn.expand("<cword>")
        if word == "" or #word < 2 then
          return
        end
        -- skip non-keyword characters
        if not word:match("^[%w_]+$") then
          return
        end
        vim.w.minicursorword_match_id =
          vim.fn.matchadd("MiniCursorword", "\\<" .. vim.fn.escape(word, "\\") .. "\\>", -1)
      end

      vim.api.nvim_set_hl(0, "MiniCursorword", { default = true, underline = true })

      local group = vim.api.nvim_create_augroup("MiniCursorword", { clear = true })
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
