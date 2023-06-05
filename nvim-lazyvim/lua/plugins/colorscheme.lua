return {

  -- NOTE: also see treesitter.lua for languages with improved syntax highlighting

  -- tokyonight, style: night
  {
    "folke/tokyonight.nvim",
    -- opts will be merged with the parent spec
    opts = {
      -- style
      style = "night", -- can be: storm, night, moon, day
      -- transparent = true,
      -- styles = {
      --   sidebars = "transparent",
      --   floats = "transparent",
      -- },
    },
  },

  -- set the colorscheme
  {
    "LazyVim/LazyVim",
    -- lazy = false,
    opts = {
      colorscheme = "tokyonight",
    },
  },
}
