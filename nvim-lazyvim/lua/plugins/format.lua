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

        -- rust
        -- rustfmt via rustup

        -- see lazy.lua for LazyVim extras
      }

      -- extend opts.ensure_installed
      for _, package in ipairs(ensure_installed) do
        table.insert(opts.ensure_installed, package)
      end
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
        },
      })
    end,
  },
}
