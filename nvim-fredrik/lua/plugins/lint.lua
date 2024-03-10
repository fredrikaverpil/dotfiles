return {
  "mfussenegger/nvim-lint",
  dependencies = {
    {
      "williamboman/mason.nvim",
    },
  },

  config = function(_, opts)
    require("lint").linters_by_ft = opts.linters_by_ft
  end,
}
