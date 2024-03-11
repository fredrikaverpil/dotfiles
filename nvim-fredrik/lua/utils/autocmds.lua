-- Highlight on yank
vim.api.nvim_create_autocmd("TextYankPost", {
  group = vim.api.nvim_create_augroup("Yank", { clear = true }),
  callback = function()
    if vim.fn.has("wsl") == 1 then
      vim.fn.system("clip.exe", vim.fn.getreg('"'))
    else
      vim.highlight.on_yank()
    end
  end,
})
