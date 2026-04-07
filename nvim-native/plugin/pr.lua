-- pr.nvim: view PRs in browser.
-- Prefer local dev clone, fall back to GitHub.

local dev_path = vim.fn.expand("~/code/public/pr.nvim")
if vim.uv.fs_stat(dev_path) then
  vim.opt.runtimepath:append(dev_path)
else
  vim.pack.add({
    { src = "https://github.com/fredrikaverpil/pr.nvim" },
  })
end

require("pr").setup({})

vim.keymap.set("n", "<leader>gbv", function()
  require("pr").view()
end, { desc = "View PR in browser" })
