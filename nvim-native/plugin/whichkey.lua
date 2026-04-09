vim.pack.add({
  { src = "https://github.com/folke/which-key.nvim" },
})

require("which-key").setup({
  preset = "helix",
})

require("which-key").add({
  { "<leader><tab>", group = "tab" },
  { "<leader>a", group = "ai" },
  { "<leader>c", group = "code" },
  { "<leader>d", group = "debug" },
  { "<leader>dL", group = "debug lua" },
  { "<leader>n", group = "notes" },
  { "<leader>g", group = "git" },
  { "<leader>gb", group = "blame" },
  { "<leader>gd", group = "diffview" },
  { "<leader>gh", group = "hunks" },
  { "<leader>r", group = "run" },
  { "<leader>s", group = "search" },
  { "<leader>t", group = "test" },
  { "<leader>u", group = "ui" },
  { "<leader>x", group = "diagnostics/quickfix" },
  { "<leader>w", group = "windows", proxy = "<C-w>" },
  {
    "<leader>b",
    group = "buffers",
    expand = function()
      return require("which-key.extras").expand.buf()
    end,
  },
})
