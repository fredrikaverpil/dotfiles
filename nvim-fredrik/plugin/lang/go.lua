require("lang").register("go", {
  neotest = {
    packs = {
      -- neotest-golang dep; the adapter itself is loaded via dev.load_local below.
      { src = "https://github.com/uga-rosa/utf8.nvim" },
    },
    adapter = function()
      require("dev").load_local("~/code/public/neotest-golang")
      -- vim.pack.add({ { src = "https://github.com/fredrikaverpil/neotest-golang" } })
      return require("neotest-golang")({
        -- Resolved at use time so :cd after startup writes the profile where
        -- nvim-coverage (plugin/nvim_coverage.lua) looks for it.
        go_test_args = function()
          return {
            "-v",
            "-count=1",
            "-race",
            "-coverprofile=" .. vim.fs.joinpath(vim.fn.getcwd(), "coverage.out"),
            "-parallel=1",
          }
        end,
        runner = "gotestsum",
        gotestsum_args = { "--format=standard-verbose" },
      })
    end,
  },
  dap = {
    packs = {
      { src = "https://github.com/leoluz/nvim-dap-go" },
    },
    setup = function()
      require("dap-go").setup({
        dap_configurations = {
          {
            type = "go",
            name = "Delve: debug opened file's cmd/cli",
            request = "launch",
            cwd = "${fileDirname}",
            program = "./${relativeFileDirname}",
            args = {},
          },
          {
            type = "go",
            name = "Delve: debug test (manually enter test name)",
            request = "launch",
            mode = "test",
            program = "./${relativeFileDirname}",
            args = function()
              local testname = vim.fn.input("Test name (^regexp$ ok): ")
              return { "-test.run", testname }
            end,
          },
        },
      })
    end,
  },
})

require("lazyload").on_vim_enter(function()
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
      group = vim.api.nvim_create_augroup("go-opts", { clear = true }),
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

    require("dev").load_local("~/code/public/godoc.nvim")
    -- vim.pack.add({
    --   { src = "https://github.com/fredrikaverpil/godoc.nvim" },
    -- })

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
