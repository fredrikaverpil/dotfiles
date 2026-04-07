-- render-markdown: rich markdown rendering in the buffer.

vim.pack.add({
  { src = "https://github.com/MeanderingProgrammer/render-markdown.nvim" },
})

require("render-markdown").setup({
  code = {
    sign = false,
    width = "block",
    right_pad = 1,
  },
  heading = {
    enabled = false,
  },
})

vim.keymap.set("n", "<leader>uM", function()
  local m = require("render-markdown")
  local enabled = require("render-markdown.state").enabled
  if enabled then
    m.disable()
    vim.cmd("setlocal conceallevel=0")
  else
    m.enable()
    vim.cmd("setlocal conceallevel=2")
  end
end, { desc = "Toggle markdown render", silent = true })
