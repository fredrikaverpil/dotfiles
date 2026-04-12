-- Setup and keymaps are in lua/fredrik/init.lua, where profile.nvim
-- must load before lazy.nvim to instrument startup.
return {
  {
    "stevearc/profile.nvim",
    lazy = true,
  },
}
