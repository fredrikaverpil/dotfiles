return {
  {
    "jackMort/ChatGPT.nvim",
    enabled = false, -- use codecompanion instead.
    dependencies = {
      { "MunifTanjim/nui.nvim" },
      { "nvim-lua/plenary.nvim" },
      { "nvim-telescope/telescope.nvim" },
    },
    cmd = { "ChatGPT", "ChatGPTRun", "ChatGPTActAs", "ChatGPTCompleteCode", "ChatGPTEditWithInstructions" },
    config = function()
      require("chatgpt").setup({
        api_key_cmd = "op read op://Personal/OpenAI/tokens/neovim --no-newline",
        actions_paths = { "~/code/dotfiles/nvim-lazyvim/chatgpt-actions.json" },
        openai_params = {
          model = "gpt-4",
          max_tokens = 4000,
        },
        openai_edit_params = {
          model = "gpt-3.5-turbo",
          temperature = 0,
          top_p = 1,
          n = 1,
        },
      })
    end,
    keys = require("config.keymaps").setup_chatgpt_keymaps(),
  },
}
