-- godoc.nvim: Go documentation browser.
-- Prefer local dev clone, fall back to GitHub.

local dev_path = vim.fn.expand("~/code/public/godoc.nvim")
if vim.uv.fs_stat(dev_path) then
  vim.opt.runtimepath:append(dev_path)
else
  vim.pack.add({
    { src = "https://github.com/fredrikaverpil/godoc.nvim" },
  })
end

require("godoc").setup({
  adapters = {
    {
      name = "go",
      opts = {
        command = "GoDoc",
        get_syntax_info = function()
          return {
            filetype = "godoc",
            language = "godoc",
          }
        end,
      },
    },
  },
  window = { type = "vsplit" },
  picker = { type = "snacks" },
})
