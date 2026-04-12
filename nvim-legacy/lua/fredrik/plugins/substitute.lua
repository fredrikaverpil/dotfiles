return {
  {
    "gbprod/substitute.nvim",
    dependencies = {
      "gbprod/yanky.nvim",
    },
    opts = {},
    config = function(_, opts)
      opts.on_substitute = require("yanky.integration").substitute()
      require("substitute").setup(opts)
    end,
    keys = require("fredrik.config.keymaps").setup_substitute_keymaps(),
  },
}
