return {
  "nvim-lualine/lualine.nvim",
  dependencies = {},
  opts = {

    -- see copilot.lua...
    -- copilot = {
    --   lualine_component = "filename",
    -- },

    options = {
      theme = "auto",
    },
    sections = {
      lualine_a = { "mode" },
      lualine_b = { "branch", "diagnostics" },
      lualine_c = {
        {
          "filename",
          path = 1,
        },
      },
      lualine_x = { "encoding", "filetype" },
      lualine_y = { "progress" },
      lualine_z = { "location" },
    },
  },
  config = function(_, opts)
    if opts.copilot then
      table.insert(opts.sections.lualine_x, 1, opts.copilot.lualine_component)
    end

    require("lualine").setup(opts)
  end,
}
