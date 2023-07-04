-- https://www.lazyvim.org/plugins/lsp

return {

  -- change mason config
  -- note: don't forget to update treesitter for languages
  {
    "williamboman/mason.nvim",

    opts = function(_, opts)
      local ensure_installed = {
        -- python
        "ruff-lsp",
        "pyright",
        "mypy",
        "black",

        -- lua
        "lua-language-server",
        "stylua",

        -- shell
        "bash-language-server",
        "shellcheck",
        "shfmt",

        -- docker
        "dockerfile-language-server",

        -- javascript/typescript, see lazy.lua

        -- rust, also see lazy.lua
        "rust-analyzer", -- LSP
        "rustfmt",

        -- go, see lazy.lua
      }

      -- extend opts.ensure_installed
      for _, package in ipairs(ensure_installed) do
        table.insert(opts.ensure_installed, package)
      end
    end,

    -- opts = {
    --   ensure_installed = {
    --     -- python
    --     "ruff-lsp",
    --     "pyright",
    --     "mypy",
    --     "black",
    --
    --     -- lua
    --     "lua-language-server",
    --     "stylua",
    --
    --     -- shell
    --     "bash-language-server",
    --     "shellcheck",
    --     "shfmt",
    --
    --     -- docker
    --     "dockerfile-language-server",
    --
    --     -- javascript/typescript, see lazy.lua
    --
    --     -- rust, also see lazy.lua
    --     "rust-analyzer", -- LSP
    --     "rustfmt",
    --
    --     -- go, see lazy.lua
    --   },
    -- },
  },

  -- change null-ls config
  {
    "jose-elias-alvarez/null-ls.nvim",
    dependencies = { "mason.nvim" },
    event = { "BufReadPre", "BufNewFile" },
    opts = function(_, opts)
      local null_ls = require("null-ls")
      local formatting = null_ls.builtins.formatting
      local diagnostics = null_ls.builtins.diagnostics
      local code_actions = null_ls.builtins.code_actions

      local function get_path_from_python_venv(executable_name)
        -- Return the path to the executable if $VIRTUAL_ENV is set and the binary exists somewhere beneath the $VIRTUAL_ENV path, otherwise get it from Mason
        if vim.env.VIRTUAL_ENV then
          local executable_path = vim.fn.glob(vim.env.VIRTUAL_ENV .. "/**/" .. executable_name, true, true)
          if executable_path ~= "" then
            return executable_path
          end
        end

        local mason_registry = require("mason-registry")
        return mason_registry.get_package(executable_name):get_install_path()
      end

      -- null_ls.setup({
      --   debug = false, -- Turn on debug for :NullLsLog
      --   -- diagnostics_format = "#{m} #{s}[#{c}]",
      -- })

      local sources = {
        -- list of supported sources:
        -- https://github.com/jose-elias-alvarez/null-ls.nvim/blob/main/doc/BUILTINS.md

        diagnostics.mypy.with({
          command = get_path_from_python_venv("mypy"),
        }),
        formatting.black.with({
          command = get_path_from_python_venv("black"),
        }),

        -- installed via Mason
        formatting.stylua.with({
          extra_args = { "--indent-type", "Spaces", "--indent-width", "2" },
        }),
        formatting.shfmt,
        formatting.rustfmt,
        formatting.yamlfix, -- requires python
        diagnostics.yamllint,
        diagnostics.shellcheck,
        code_actions.shellcheck,
        code_actions.gitsigns,
      }

      -- extend opts.sources
      for _, source in ipairs(sources) do
        table.insert(opts.sources, source)
      end
    end,
  },
}
