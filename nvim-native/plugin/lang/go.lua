vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("native-go-opts", { clear = true }),
  pattern = { "go", "gomod", "gowork", "gohtml" },
  callback = function()
    vim.opt_local.expandtab = false
  end,
})

if vim.g.use_nvim_treesitter then
  vim.pack.add({
    { src = "https://github.com/edte/blink-go-import.nvim" },
    { src = "https://github.com/maxandron/goplements.nvim" },
  })
end

require("dev").use({
  dev = "~/code/public/godoc.nvim",
  fallback = function()
    vim.pack.add({
      { src = "https://github.com/fredrikaverpil/godoc.nvim" },
    })
  end,
})

vim.api.nvim_create_autocmd("PackChanged", {
  callback = function(ev)
    if ev.data.spec.name == "godoc.nvim" then
      vim.system({ "go", "install", "github.com/lotusirous/gostdsym/stdsym@latest" })
    end
  end,
})

-- Register tree-sitter-godoc parser so it can be installed via nvim-treesitter
local ts_ok, ts_parsers = pcall(require, "nvim-treesitter.parsers")
if ts_ok then
  ts_parsers.godoc = {
    install_info = {
      url = "https://github.com/fredrikaverpil/tree-sitter-godoc",
      files = { "src/parser.c" },
      version = "*",
    },
    filetype = "godoc",
  }
end
vim.treesitter.language.register("godoc", "godoc")

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

if vim.g.use_nvim_treesitter then
  vim.api.nvim_create_autocmd("FileType", {
    pattern = "go",
    once = true,
    callback = function()
      require("goplements").setup()
    end,
  })
  require("blink-go-import").setup()
end
