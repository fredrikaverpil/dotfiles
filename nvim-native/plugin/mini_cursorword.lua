-- Lightweight cursorword highlight using CursorHold.
-- Highlights all occurrences of word under cursor after idle (governed by 'updatetime').
-- Uses "MiniCursorword" highlight group (underline by default).

vim.api.nvim_set_hl(0, "MiniCursorword", { default = true, underline = true })

local group = vim.api.nvim_create_augroup("MiniCursorword", { clear = true })

vim.api.nvim_create_autocmd("CursorHold", {
  group = group,
  callback = function()
    local word = vim.fn.expand("<cword>")
    if word == "" or #word < 2 or not word:match("^[%w_]+$") then
      return
    end
    vim.w.minicursorword_match_id = vim.fn.matchadd("MiniCursorword", "\\<" .. vim.fn.escape(word, "\\") .. "\\>", -1)
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
