-- Minimal init.lua to reproduce this issue. Save as repro.lua and run with nvim -u repro.lua

vim.env.LAZY_STDPATH = ".repro"
load(vim.fn.system("curl -s https://raw.githubusercontent.com/folke/lazy.nvim/main/bootstrap.lua"))()

require("lazy.minit").repro({
  spec = {
    { "folke/snacks.nvim", opts = {} },
    -- add any other plugins here
  },
})
