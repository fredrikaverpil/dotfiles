vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("native-go-opts", { clear = true }),
  pattern = { "go", "gomod", "gowork", "gohtml" },
  callback = function()
    vim.opt_local.expandtab = false
  end,
})

if Config.use_treesitter_parser then
  vim.pack.add({
    { src = "https://github.com/edte/blink-go-import.nvim" },
    { src = "https://github.com/maxandron/goplements.nvim" },
  })
end

if Config.use_treesitter_parser then
  vim.api.nvim_create_autocmd("FileType", {
    pattern = "go",
    once = true,
    callback = function()
      require("goplements").setup()
    end,
  })
  require("blink-go-import").setup()
end

vim.api.nvim_create_autocmd("PackChanged", {
  callback = function(ev)
    if ev.data.spec.name == "godoc.nvim" then
      vim.system({ "go", "install", "github.com/lotusirous/gostdsym/stdsym@latest" })
    end
  end,
})

require("dev").use({
  dev = "~/code/public/godoc.nvim",
  fallback = function()
    vim.pack.add({
      { src = "https://github.com/fredrikaverpil/godoc.nvim" },
    })
  end,
})

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
