require("lazyload").on_vim_enter(function()
  vim.pack.add({
    { src = "https://github.com/nvim-mini/mini.icons" },
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
end)
