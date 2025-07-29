vim.api.nvim_create_autocmd("FileType", {
  pattern = { "nix" },
  callback = function()
    vim.opt_local.tabstop = 2
    vim.opt_local.softtabstop = 2
    vim.opt_local.shiftwidth = 2
    vim.opt_local.expandtab = true

    vim.opt_local.colorcolumn = "120"
  end,
})

local function has_nix()
  return vim.fn.executable("nix") == 1
end

return {
  {
    "stevearc/conform.nvim",
    dependencies = {
      {
        "mason-org/mason.nvim",
        opts = function(_, opts)
          opts.ensure_installed = opts.ensure_installed or {}
          vim.list_extend(opts.ensure_installed, { "alejandra" })
        end,
      },
    },
    opts = {
      formatters_by_ft = {
        nix = { "alejandra" }, -- NOTE: nixfmt not supported on macOS
      },
    },
  },

  {
    "virtual-lsp-config",
    dependencies = {
      {
        "mason-org/mason-lspconfig.nvim",
        dependencies = {
          {
            "mason-org/mason.nvim",
          },
        },
        opts = function(_, opts)
          opts.ensure_installed = opts.ensure_installed or {}
          if has_nix() then
            vim.list_extend(opts.ensure_installed, { "nil_ls" })
          end
        end,
      },
    },
    opts = function(_, opts)
      opts.servers = opts.servers or {}

      if has_nix() then
        local nix_servers = {
          servers = {
            ---@type vim.lsp.Config
            nil_ls = {
              -- lsp: https://github.com/oxalica/nil
              -- ref: https://github.com/neovim/nvim-lspconfig/blob/master/lua/lspconfig/configs/nil_ls.lua
              cmd = { "nil" },
              filetypes = { "nix" },
              root_markers = { "flake.nix", "default.nix", "shell.nix", ".git" },
              settings = {
                ["nil"] = {
                  formatting = {
                    command = { "nixfmt" },
                  },
                },
              },
            },
          },
        }

        opts = require("fredrik.utils.table").deep_merge(opts, nix_servers)
        return opts
      end

      return opts
    end,
  },
}
