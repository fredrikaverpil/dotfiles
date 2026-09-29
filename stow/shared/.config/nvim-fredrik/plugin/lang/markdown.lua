require("lazyload").on_vim_enter(function()
  -- NOTE: the plugin auto-calls setup(vim.g.render_markdown_config), so we need to set it here first
  vim.g.render_markdown_config = {
    code = {
      sign = false,
      width = "block",
      right_pad = 1,
    },
    heading = {
      enabled = false,
    },
  }

  vim.pack.add({
    { src = "https://github.com/MeanderingProgrammer/render-markdown.nvim", version = vim.version.range("*") },
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
end)
