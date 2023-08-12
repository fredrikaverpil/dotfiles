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

        -- lua
        "lua-language-server",

        -- shell
        "bash-language-server",

        -- docker
        "dockerfile-language-server",

        -- rust
        "rust-analyzer",

        -- go
        "gopls",

        -- protobuf
        "buf",
        "protolint",
        "buf-language-server",

        -- see lazy.lua for LazyVim extras
      }

      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, ensure_installed)
    end,
  },

  {
    "jose-elias-alvarez/null-ls.nvim",
    dependencies = { "mason.nvim" },
    event = { "BufReadPre", "BufNewFile" },
    opts = function(_, opts)
      local null_ls = require("null-ls")
      local formatting = null_ls.builtins.formatting
      local diagnostics = null_ls.builtins.diagnostics
      local code_actions = null_ls.builtins.code_actions

      -- null_ls.setup({
      --   debug = false, -- Turn on debug for :NullLsLog
      --   -- diagnostics_format = "#{m} #{s}[#{c}]",
      -- })

      local function prefer_bin_from_venv(executable_name)
        -- Return the path to the executable if $VIRTUAL_ENV is set and the binary exists somewhere beneath the $VIRTUAL_ENV path, otherwise get it from Mason
        if vim.env.VIRTUAL_ENV then
          local paths = vim.fn.glob(vim.env.VIRTUAL_ENV .. "/**/bin/" .. executable_name, true, true)
          local executable_path = table.concat(paths, ", ")
          if executable_path ~= "" then
            -- vim.api.nvim_echo(
            --   { { "Using path for " .. executable_name .. ": " .. executable_path, "None" } },
            --   false,
            --   {}
            -- )
            return executable_path
          end
        end

        local mason_registry = require("mason-registry")
        local mason_path = mason_registry.get_package(executable_name):get_install_path()
          .. "/venv/bin/"
          .. executable_name
        -- vim.api.nvim_echo({ { "Using Mason for " .. executable_name .. ": " .. mason_path, "None" } }, false, {})
        return mason_path
      end

      local sources = {
        -- list of supported sources:
        -- https://github.com/jose-elias-alvarez/null-ls.nvim/blob/main/doc/BUILTINS.md

        diagnostics.mypy.with({
          filetypes = { "python" },
          command = prefer_bin_from_venv("mypy"),
        }),
        formatting.black.with({
          filetypes = { "python" },
          command = prefer_bin_from_venv("black"),
        }),

        -- installed via Mason
        formatting.stylua.with({
          extra_args = { "--indent-type", "Spaces", "--indent-width", "2" },
        }),
        formatting.shfmt,
        formatting.rustfmt,
        formatting.yamlfix, -- requires python
        formatting.buf,
        diagnostics.yamllint,
        diagnostics.shellcheck,
        diagnostics.sqlfluff.with({
          extra_args = { "--dialect", "postgres" },
        }),
        diagnostics.buf,
        diagnostics.protolint,
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
