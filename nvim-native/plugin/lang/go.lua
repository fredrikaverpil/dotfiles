vim.pack.add({
  { src = "https://github.com/leoluz/nvim-dap-go" },
})

if vim.g.use_nvim_treesitter then
  vim.pack.add({
    { src = "https://github.com/edte/blink-go-import.nvim" },
    { src = "https://github.com/uga-rosa/utf8.nvim" },
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

require("dev").use({
  dev = "~/code/public/neotest-golang",
  fallback = function()
    vim.pack.add({
      { src = "https://github.com/fredrikaverpil/neotest-golang" },
    })
  end,
})

require("registry").add({
  lsp = { servers = { "gopls" } },
  mason = {
    ensure_installed = {
      "gopls",
      "goimports",
      "gci",
      "gofumpt",
      "golines",
      "golangci-lint",
      "delve",
      "gotestsum",
    },
  },
  conform = {
    opts = {
      formatters_by_ft = {
        go = { "goimports", "gci", "gofumpt", "golines" },
      },
      formatters = {
        goimports = {
          args = { "-srcdir", "$FILENAME" },
        },
        gci = {
          args = { "write", "--skip-generated", "-s", "standard", "-s", "default", "--skip-vendor", "$FILENAME" },
        },
        gofumpt = {
          prepend_args = { "-extra", "-w", "$FILENAME" },
          stdin = false,
        },
        golines = {
          prepend_args = { "--base-formatter=gofumpt", "--ignore-generated", "--tab-len=1", "--max-len=120" },
        },
      },
    },
  },
  lint = {
    linters_by_ft = { go = { "golangcilint" } },
  },
  code_runner = { opts = { filetype = { go = { "go run" } } } },
  blink = vim.g.use_nvim_treesitter and {
    opts = {
      sources = {
        default = { "go_pkgs" },
        providers = {
          go_pkgs = {
            name = "Import",
            module = "blink-go-import",
          },
        },
      },
    },
  } or nil,
  neotest = {
    opts = {
      adapters = {
        {
          module = "neotest-golang",
          opts = {
            go_test_args = {
              "-v",
              "-count=1",
              "-race",
              "-coverprofile=" .. vim.fn.getcwd() .. "/coverage.out",
              "-parallel=1",
            },
            runner = "gotestsum",
            gotestsum_args = { "--format=standard-verbose" },
          },
        },
      },
    },
  },
  dap = {
    setups = {
      function()
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
  },
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
