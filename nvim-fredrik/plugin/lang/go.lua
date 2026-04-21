require("lazyload").on_vim_enter(function()
  local dev = require("dev")

  -- filetypes
  do
    vim.filetype.add({
      extension = {
        gotmpl = "gotmpl",
        gohtml = "gotmpl",
      },
      pattern = {
        [".*%.go%.tmpl"] = "gotmpl",
      },
    })

    vim.api.nvim_create_autocmd("FileType", {
      pattern = { "go", "gomod", "gowork", "gohtml", "gotmpl" },
      callback = function()
        vim.opt_local.expandtab = false
      end,
    })
  end

  -- tree-sitter dependent plugins
  do
    if Config.use_treesitter_parser then
      vim.pack.add({
        { src = "https://github.com/edte/blink-go-import.nvim" },
        { src = "https://github.com/maxandron/goplements.nvim" },
      })

      require("goplements").setup()
      require("blink-go-import").setup()
    end
  end

  -- godoc.nvim
  do
    vim.api.nvim_create_autocmd("PackChanged", {
      callback = function(ev)
        if ev.data.spec.name == "godoc.nvim" then
          vim.system({ "go", "install", "github.com/lotusirous/gostdsym/stdsym@latest" })
        end
      end,
    })

    vim.pack.add({
      { src = dev.prefer_local("~/code/public/godoc.nvim", "https://github.com/fredrikaverpil/godoc.nvim") },
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
  end
end)
