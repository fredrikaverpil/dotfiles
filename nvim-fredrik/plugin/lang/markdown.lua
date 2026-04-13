require("lazyload").on_vim_enter(function()
  vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("markdown-opts", { clear = true }),
    pattern = "markdown",
    callback = function()
      vim.opt_local.wrap = true
      vim.opt_local.conceallevel = 2
    end,
  })

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
end)

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
