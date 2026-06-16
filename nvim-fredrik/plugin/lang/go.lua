local blink_packs = {}
local blink_per_filetype = {}
local blink_providers = {}
local blink_setup = nil
if Config.use_treesitter_parser then
  blink_packs = {
    { src = "https://github.com/edte/blink-go-import.nvim" },
  }
  blink_per_filetype = {
    go = { inherit_defaults = true, "go_pkgs" },
  }
  blink_providers = {
    go_pkgs = {
      name = "Import",
      module = "blink-go-import",
    },
  }
  blink_setup = function()
    require("blink-go-import").setup()
  end
end

require("lang").register("go", {
  servers = { "gopls" },
  mason = { "gopls", "goimports", "gci", "gofumpt", "golines", "golangci-lint", "delve", "gotestsum", "impl" },
  formatters_by_ft = { go = { "goimports", "gci", "gofumpt", "golines" } },
  blink_packs = blink_packs,
  blink_per_filetype = blink_per_filetype,
  blink_providers = blink_providers,
  blink_setup = blink_setup,
  treesitter_custom_parsers = {
    godoc = {
      filetype = "godoc",
      install_info = {
        url = "https://github.com/fredrikaverpil/tree-sitter-godoc",
        branch = "main",
        generate = false,
        queries = "queries",
      },
    },
  },
  formatters = {
    gci = {
      args = { "write", "--skip-generated", "-s", "standard", "-s", "default", "--skip-vendor", "$FILENAME" },
    },
    gofumpt = {
      prepend_args = { "-extra", "-w", "$FILENAME" },
      stdin = false,
    },
    goimports = {
      args = { "-srcdir", "$FILENAME" },
    },
    golines = {
      prepend_args = { "--base-formatter=gofumpt", "--ignore-generated", "--tab-len=1", "--max-len=120" },
    },
  },
  -- golangci-lint with cwd at the nearest go.mod (handles nested modules)
  lint_setup = function(lint)
    local find = require("find")
    local go_mod_dir_cache = {}

    local function go_mod_dir()
      local buffer_parent_dir = vim.fn.expand("%:p:h")
      local cached = go_mod_dir_cache[buffer_parent_dir]
      if cached == false then
        return nil
      end
      if cached then
        return cached
      end
      local dir = find.dir_upward("go.mod", { path = buffer_parent_dir })
      if dir == nil then
        go_mod_dir_cache[buffer_parent_dir] = false
        return nil
      end
      go_mod_dir_cache[buffer_parent_dir] = dir
      return dir
    end

    vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost" }, {
      group = vim.api.nvim_create_augroup("lint-go", { clear = true }),
      pattern = { "*.go" },
      callback = function()
        local cwd = go_mod_dir()
        if cwd == nil then
          return
        end
        lint.try_lint("golangcilint", { cwd = cwd })
      end,
    })
  end,
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
