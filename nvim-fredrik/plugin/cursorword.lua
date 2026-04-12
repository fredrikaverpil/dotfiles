require("lazyload").on_vim_enter(function()
  vim.api.nvim_set_hl(0, "Cursorword", { default = true, underline = true })

  local group = vim.api.nvim_create_augroup("Cursorword", { clear = true })

  vim.api.nvim_create_autocmd("CursorHold", {
    group = group,
    callback = function()
      -- Clear any previous match to prevent accumulation
      local prev_id = vim.w.minicursorword_match_id
      if prev_id then
        pcall(vim.fn.matchdelete, prev_id)
      end
      local word = vim.fn.expand("<cword>")
      if word == "" or #word < 2 or not word:match("^[%w_]+$") then
        vim.w.minicursorword_match_id = nil
        return
      end
      vim.w.minicursorword_match_id = vim.fn.matchadd("Cursorword", "\\<" .. vim.fn.escape(word, "\\") .. "\\>", -1)
    end,
  })

  vim.api.nvim_create_autocmd("CursorMoved", {
    group = group,
    callback = function()
      local id = vim.w.minicursorword_match_id
      if id then
        pcall(vim.fn.matchdelete, id)
        vim.w.minicursorword_match_id = nil
      end
    end,
  })
end)
