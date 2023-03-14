return {

  -- NOTE: also see treesitter.lua for languages with improved syntax highlighting

  -- tokyonight, style: night
  {
    "folke/tokyonight.nvim",
    -- opts will be merged with the parent spec
    opts = {
      -- style
      style = "night", -- can be: storm, night, moon, day
      -- disable the background color
      transparent = false,
      -- change the default "italic_comment" style to be underlined
      styles = { italic_comment = "underline" },
      -- disable bolding and italicizing keywords (if you are using another plugin that bolds keywords, you may want to disable this)
      disable = { bold = true, italic = true },
    },
  },
}
