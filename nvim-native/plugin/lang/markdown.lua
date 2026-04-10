vim.pack.add({
  { src = "https://github.com/iamcco/markdown-preview.nvim" },
  { src = "https://github.com/MeanderingProgrammer/render-markdown.nvim" },
})

vim.api.nvim_create_autocmd("PackChanged", {
  callback = function(ev)
    if ev.data.spec.name == "markdown-preview.nvim" then
      vim.fn["mkdp#util#install"]()
    end
  end,
})

require("registry").add({
  mason = { ensure_installed = { "prettier", "markdownlint" } },
  conform = {
    opts = {
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
    opts = {
      sources = {
        default = { "markdown" },
        providers = {
          markdown = {
            name = "RenderMarkdown",
            module = "render-markdown.integ.blink",
          },
        },
      },
    },
  },
})

require("startup").on_vim_enter(function()
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
