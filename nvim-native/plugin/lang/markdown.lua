vim.pack.add({
  { src = "https://github.com/iamcco/markdown-preview.nvim" },
  { src = "https://github.com/MeanderingProgrammer/render-markdown.nvim" },
})

require("defer").on_ui_enter(function()
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

require("registry").add({
  mason_tools = { "prettier", "markdownlint" },
  conform = {
    formatters_by_ft = {
      markdown = { "prettier" },
    },
    formatters = {
      prettier = {
        prepend_args = { "--prose-wrap", "always", "--print-width", "80", "--tab-width", "2" },
      },
      mdformat = {
        prepend_args = { "--number", "--wrap", "80" },
      },
    },
  },
  lint = {
    linters_by_ft = { markdown = { "markdownlint" } },
    linters = {
      markdownlint = {
        args = {
          "--config",
          vim.env.DOTFILES .. "/extras/templates/.markdownlint.json",
          "--stdin",
        },
      },
    },
  },
  blink = {
    sources = {
      providers = {
        markdown = {
          name = "RenderMarkdown",
          module = "render-markdown.integ.blink",
        },
      },
    },
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
