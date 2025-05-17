return {

  {
    "mrcjkb/rustaceanvim",
    lazy = true,
    ft = { "rust" },
    version = "*",
  },

  {
    "nvim-neotest/neotest",
    lazy = true,
    ft = { "rust" },
    dependencies = {
      "mrcjkb/rustaceanvim",
    },
    optional = true,
    opts = function(_, opts)
      opts.adapters = opts.adapters or {}
      vim.list_extend(opts.adapters, {
        require("rustaceanvim.neotest"),
      })
    end,
  },

  -- Ensure Rust debugger is installed
  {
    "mason-org/mason.nvim",
    optional = true,
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, { "codelldb" })
    end,
  },
}
