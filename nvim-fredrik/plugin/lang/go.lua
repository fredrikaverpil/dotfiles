-- Custom gotmpl filetype (also covers .gohtml and *.go.tmpl). Registered at file
-- scope (step 11) so detection applies to the first buffer opened, not only
-- buffers opened after VimEnter.
vim.filetype.add({
  extension = {
    gotmpl = "gotmpl",
    gohtml = "gotmpl",
  },
  pattern = {
    [".*%.go%.tmpl"] = "gotmpl",
  },
})

require("lazyload").on_vim_enter(function()
  -- tree-sitter dependent plugins
  do
    if Config.use_treesitter_parser then
      vim.pack.add({
        { src = "https://github.com/maxandron/goplements.nvim" },
      })
      require("goplements").setup()

      vim.pack.add({
        { src = "https://github.com/edte/blink-go-import.nvim" },
      })
      require("blink-go-import").setup()
    end
  end

  -- go-impl (uses "impl" from mason and "symbolScope", "symbolMatcher" setting in gopls)
  do
    vim.pack.add({
      { src = "https://github.com/fang2hou/go-impl.nvim", version = vim.version.range("*") },
      { src = "https://github.com/MunifTanjim/nui.nvim", version = vim.version.range("*") },
    })
    require("go-impl").setup({
      picker = "snacks",
      insert = {
        position = "after",
        before_newline = true,
        after_newline = false,
      },
    })
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

    --require("dev").load_local("~/code/public/godoc.nvim")
    --
    vim.pack.add({
      { src = "https://github.com/fredrikaverpil/godoc.nvim" },
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
