return {
  {
    "yetone/avante.nvim",
    enabled = require("utils.private").enable_ai(),
    -- build = "make", -- This is Optional, only if you want to use tiktoken_core to calculate tokens count
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
    cmd = { "AvanteAsk", "AvanteChat", "AvanteEdit", "AvanteToggle", "AvanteClear", "AvanteFocus", "AvanteRefresh", "AvanteSwitchProvider" },
    keys = require("config.keymaps").setup_avante_keymaps(),
  },
}
