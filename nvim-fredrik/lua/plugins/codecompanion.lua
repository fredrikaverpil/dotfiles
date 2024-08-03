return {
  {
    "olimorris/codecompanion.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
      "nvim-telescope/telescope.nvim",
      {
        "stevearc/dressing.nvim",
        opts = {},
      },
    },

    config = function()
      local ollama_fn = function()
        return require("codecompanion.adapters").use("ollama", {
          schema = {
            model = {
              default = "llama3.1:8b",
              -- default = "codellama:7b",
              -- default = "codegemma:7b",
            },
          },
        })
      end

      local anthropic_fn = function()
        return require("codecompanion.adapters").use("anthropic", { env = { api_key = "cmd:op read op://Personal/Anthropic/tokens/neovim --no-newline" } })
      end

      local openai_fn = function()
        return require("codecompanion.adapters").use("openai", { env = { api_key = "cmd:op read op://Personal/OpenAI/tokens/neovim --no-newline" } })
      end

      require("codecompanion").setup({
        adapters = {
          ollama = ollama_fn,
          anthropic = anthropic_fn,
          openai = openai_fn,
        },
        strategies = {
          chat = {
            adapter = "ollama",
          },
          inline = {
            adapter = "ollama",
          },
          agent = {
            adapter = "ollama",
          },
        },
      })
    end,
  },
}
