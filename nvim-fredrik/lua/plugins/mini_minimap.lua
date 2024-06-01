return {

  {
    "echasnovski/mini.map",
    event = "VeryLazy",
    main = "mini.map",
    opts = function()
      local minimap = require("mini.map")
      return {
        integrations = {
          minimap.gen_integration.diagnostic(),
          minimap.gen_integration.builtin_search(),
          minimap.gen_integration.gitsigns(),
        },
        window = { winblend = 50 },
      }
    end,
    keys = require("config.keymaps").setup_minimap_keymaps(),
  },
}
