local function get_branch()
  if require("utils.version").is_neovim_0_10_0() then
    -- https://github.com/NeogitOrg/neogit/tree/nightly
    return "nightly"
  else
    return "master"
  end
end

return {

  {
    "NeogitOrg/neogit",
    branch = get_branch(),
    event = "VeryLazy",
    dependencies = {
      "nvim-lua/plenary.nvim", -- required
      "sindrets/diffview.nvim", -- optional - Diff integration

      -- Only one of these is needed, not both.
      "nvim-telescope/telescope.nvim", -- optional
    },
    config = function()
      require("neogit").setup({})
      require("config.keymaps").setup_neogit_keymaps()
    end,
  },
}
