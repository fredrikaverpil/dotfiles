vim.filetype.add({
  extension = {
    ghostty = "ghostty", -- For files ending in .ghostty
  },
  pattern = {
    [".*/ghostty%.conf"] = "ghostty", -- For ghostty.conf files
  },
})
