-- Eager: the nvim-web-devicons mock must be in place before consumers load —
-- lualine sets up synchronously at VimEnter, before async lazyload callbacks.
vim.pack.add({
  { src = "https://github.com/nvim-mini/mini.icons", version = vim.version.range("*") },
})

require("mini.icons").setup({
  file = {
    [".keep"] = { glyph = "󰊢", hl = "MiniIconsGrey" },
    ["devcontainer.json"] = { glyph = "", hl = "MiniIconsAzure" },
  },
  filetype = {
    dotenv = { glyph = "", hl = "MiniIconsYellow" },
  },
})

-- Mock nvim-web-devicons for plugins that depend on it.
package.preload["nvim-web-devicons"] = function()
  require("mini.icons").mock_nvim_web_devicons()
  return package.loaded["nvim-web-devicons"]
end
