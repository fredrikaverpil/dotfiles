return {

  {
    "akinsho/bufferline.nvim",
    lazy = true,
    event = "VeryLazy",
    opts = {
      options = {
        mode = "tabs", -- only show tabpages instead of buffers
        always_show_bufferline = false,
        name_formatter = function(buf)
          if buf.tabnr then
            local ok, name = pcall(vim.api.nvim_tabpage_get_var, buf.tabnr, "name")
            if ok and name then
              return name
            end
          end
        end,
      },
    },
    keys = require("fredrik.config.keymaps").setup_bufferline_keymaps(),
  },
}
