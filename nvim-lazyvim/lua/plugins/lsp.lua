-- https://www.lazyvim.org/plugins/lsp
-- NOTE: don't forget to update treesitter for languages
-- NOTE: see lazy.lua for extras that configure LSPs, formatters, linters and code actions.

local function prefer_bin_from_venv(executable_name)
  -- Return the path to the executable if $VIRTUAL_ENV is set and the binary exists somewhere beneath the $VIRTUAL_ENV path, otherwise get it from Mason
  if vim.env.VIRTUAL_ENV then
    local paths = vim.fn.glob(vim.env.VIRTUAL_ENV .. "/**/bin/" .. executable_name, true, true)
    local executable_path = table.concat(paths, ", ")
    if executable_path ~= "" then
      -- vim.api.nvim_echo(
      -- 	{ { "Using path for " .. executable_name .. ": " .. executable_path, "None" } },
      -- 	false,
      -- 	{}
      -- )
      return executable_path
    end
  end

  local mason_registry = require("mason-registry")
  local mason_path = mason_registry.get_package(executable_name):get_install_path() .. "/venv/bin/" .. executable_name
  -- vim.api.nvim_echo({ { "Using path for " .. executable_name .. ": " .. mason_path, "None" } }, false, {})
  return mason_path
end

return {

  {
    "williamboman/mason.nvim",
    opts = function(_, opts)
      local ensure_installed = {
        -- python
        "ruff-lsp", -- lsp
        "ruff", -- linter (but used as formatter)
        "pyright", -- lsp
        "black", -- formatter
        "mypy", -- linter

        -- lua
        "lua-language-server", -- lsp
        "stylua", -- formatter

        -- shell
        "bash-language-server", -- lsp
        "shfmt", -- formatter
        -- "shellcheck",           -- linter

        -- yaml
        "yamllint", -- linter

        -- sql
        "sqlfluff", -- linter

        -- rust
        "rust-analyzer", -- lsp
        -- rustfmt -- formatter (install via rustup)

        -- go
        -- https://github.com/golang/tools/blob/master/gopls/doc/settings.md
        -- https://github.com/golang/tools/blob/master/gopls/internal/lsp/source/options.go
        "gopls", -- lsp
        "golangci-lint-langserver", -- lsp
        "gofumpt", -- formatter
        -- "goimports", -- formatter
        "gci", -- formatter, replaces goimports
        "golangci-lint", -- linter (its binary is required by golanci-lint-langserver?)
        -- "gomodifytags", -- code actions
        -- "impl", -- code actions

        -- protobuf
        "buf-language-server", -- lsp (prototype, not feature-complete yet, rely on buf for now)
        "buf", -- formatter, linter
        "protolint", -- linter

        -- containers
        -- "hadolint", -- linter
        "dockerfile-language-server",
        "docker-compose-language-service",
      }

      -- extend opts.ensure_installed
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, ensure_installed)

      -- remove from opts.ensure_installed
      -- NOTE: this removes tooling because Mason provides a version
      -- built for intel machines on macOS. Instead, these are provided
      -- with the proper architecture via brew.
      local ensure_not_installed = { "shellcheck", "hadolint" }
      opts.ensure_installed = vim.tbl_filter(function(tool)
        return not vim.tbl_contains(ensure_not_installed, tool)
      end, opts.ensure_installed)
    end,
  },

  {
    "stevearc/conform.nvim",
    -- https://github.com/stevearc/conform.nvim
    enabled = true,
    opts = function(_, opts)
      local formatters = require("conform.formatters")
      formatters.ruff_fix.command = prefer_bin_from_venv("ruff")
      formatters.ruff_format.command = prefer_bin_from_venv("ruff")
      formatters.isort.command = prefer_bin_from_venv("isort")
      formatters.black.command = prefer_bin_from_venv("black")
      formatters.stylua.args =
        vim.list_extend({ "--indent-type", "Spaces", "--indent-width", "2" }, formatters.stylua.args)

      local remove_from_formatters = {}
      local extend_formatters_with = {
        protobuf = { "buf" },
        python = { "ruff_fix", "ruff_format" },
        rust = { "rustfmt" },
      }
      local replace_formatters_with = {
        go = { "gofumpt", "goimports", "gci" },
      }

      -- NOTE: conform.nvim can use a sub-list to run only the first available formatter (see docs)

      -- remove from opts.formatters_by_ft
      for ft, formatters_ in pairs(remove_from_formatters) do
        opts.formatters_by_ft[ft] = vim.tbl_filter(function(formatter)
          return not vim.tbl_contains(formatters_, formatter)
        end, opts.formatters_by_ft[ft])
      end
      -- extend opts.formatters_by_ft
      for ft, formatters_ in pairs(extend_formatters_with) do
        opts.formatters_by_ft[ft] = opts.formatters_by_ft[ft] or {}
        vim.list_extend(opts.formatters_by_ft[ft], formatters_)
      end
      -- replace opts.formatters_by_ft
      for ft, formatters_ in pairs(replace_formatters_with) do
        opts.formatters_by_ft[ft] = formatters_
      end

      -- review opts.formatters_by_ft by uncommenting the below
      -- vim.api.nvim_echo(
      --   { { "opts.formatters_by_ft", "None" }, { vim.inspect(opts.formatters_by_ft), "None" } },
      --   false,
      --   {}
      -- )
    end,
  },

  {
    "mfussenegger/nvim-lint",
    -- https://github.com/mfussenegger/nvim-lint
    enabled = true,
    opts = function(_, opts)
      local linters = require("lint").linters
      linters.mypy.cmd = prefer_bin_from_venv("mypy")
      linters.sqlfluff.args = vim.list_extend({ "--dialect", "postgres" }, linters.sqlfluff.args)

      local linters_by_ft = {
        -- this extends lazyvim's nvim-lint setup
        -- https://www.lazyvim.org/extras/linting/nvim-lint
        protobuf = { "buf", "protolint" },
        python = { "mypy" },
        sh = { "shellcheck" },
        sql = { "sqlfluff" },
        yaml = { "yamllint" },
      }

      -- extend opts.linters_by_ft
      for ft, linters_ in pairs(linters_by_ft) do
        opts.linters_by_ft[ft] = opts.linters_by_ft[ft] or {}
        vim.list_extend(opts.linters_by_ft[ft], linters_)
      end
    end,
  },
}
