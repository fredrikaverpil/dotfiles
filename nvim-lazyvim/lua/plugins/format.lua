return {

  {
    "williamboman/mason.nvim",

    opts = function(_, opts)
      local ensure_installed = {
        -- python
        "black",

        -- lua
        "stylua",

        -- shell
        "shfmt",

        -- yaml
        "yamlfix",
        "yamlfmt",

        -- rust
        -- rustfmt via rustup

        -- go
        "gofumpt",
        "goimports-reviser",
        "gomodifytags",
        "impl",

        -- protobuf
        "buf",

        -- see lazy.lua for LazyVim extras
      }

      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, ensure_installed)
    end,
  },

  {
    "mhartington/formatter.nvim",
    enabled = false, -- let's see what happens with null-ls and LazyVim
    config = function()
      local formatter = require("formatter")
      formatter.setup({
        filetype = {
          lua = {
            require("formatter.filetypes.lua").stylua,
          },
          python = {
            require("formatter.filetypes.python").black,
          },
          sh = {
            require("formatter.filetypes.sh").shfmt,
          },
          yaml = {
            require("formatter.filetypes.yaml").yamlfix,
            require("formatter.filetypes.yaml").yamlfmt,
          },
          go = {
            require("formatter.filetypes.go").gofumpt,
            require("formatter.filetypes.go").goimports_reviser,
            require("formatter.filetypes.go").gomodifytags,
            require("formatter.filetypes.go").impl,
          },
          protobuf = {
            require("formatter.filetypes.protobuf").buf,
          },
        },
      })
    end,
  },
}
