return {
  -- extends/modifies https://www.lazyvim.org/plugins/ui#lualinenvim

  "nvim-lualine/lualine.nvim",
  opts = function(_, opts)
    local lazy_sections = opts.sections

    -- replace os.date (time)
    lazy_sections.lualine_z = { "encoding" }
  end,
}
