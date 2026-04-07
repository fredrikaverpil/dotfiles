-- bufferline: tab bar for vim tabpages.

vim.pack.add({
  { src = "https://github.com/akinsho/bufferline.nvim" },
})

require("bufferline").setup({
  options = {
    mode = "tabs",
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
})

vim.keymap.set("n", "<leader><tab>r", ":BufferLineTabRename ", { desc = "Rename tab" })
