return {
  {
    "yetone/avante.nvim",
    lazy = true,
    build = "make",
    opts = {
      claude = {
        api_key_name = "cmd:op read op://Personal/Anthropic/tokens/neovim --no-newline",
      },
    },
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "stevearc/dressing.nvim",
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      "nvim-tree/nvim-web-devicons",
      {
        "MeanderingProgrammer/render-markdown.nvim",
        opts = {
          file_types = { "markdown", "Avante" },
        },
        ft = { "markdown", "Avante" },
      },
    },
    -- keymaps: https://github.com/yetone/avante.nvim/blob/main/lua/avante/init.lua#L26
    -- NOTE: use slash commands in avante for help, clear etc.
    cmd = { "AvanteAsk", "AvanteChat", "AvanteEdit", "AvanteToggle", "AvanteClear", "AvanteFocus", "AvanteRefresh", "AvanteSwitchProvider" },
    keys = require("config.keymaps").setup_avante_keymaps(),
  },
}
