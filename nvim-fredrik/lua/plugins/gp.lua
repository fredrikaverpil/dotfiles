local system_prompt_chat = "You are a general AI assistant.\n\n"
  .. "The user provided the additional info about how they would like you to respond:\n\n"
  .. "- If you're unsure don't guess and say you don't know instead.\n"
  .. "- Ask question if you need clarification to provide better answer.\n"
  .. "- Think deeply and carefully from first principles step by step.\n"
  .. "- Zoom out first to see the big picture and then zoom in to details.\n"
  .. "- Use Socratic method to improve your thinking and coding skills.\n"
  .. "- Don't elide any code from your output if the answer requires coding.\n"
  .. "- Take a deep breath; You've got this!\n"

return {
  {
    "robitx/gp.nvim",
    enabled = true,
    opts = {
      providers = {

        ollama = {
          endpoint = "http://localhost:11434/v1/chat/completions",
        },

        anthropic = {
          endpoint = "https://api.anthropic.com/v1/messages",
          secret = { "op", "read", "op://Personal/Anthropic/tokens/neovim", "--no-newline" },
        },

        openai = {
          endpoint = "https://api.openai.com/v1/chat/completions",
          secret = { "op", "read", "op://Personal/OpenAI/tokens/neovim", "--no-newline" },
        },

        copilot = {
          endpoint = "https://api.githubcopilot.com/chat/completions",
          secret = {
            "bash",
            "-c",
            "cat ~/.config/github-copilot/hosts.json | sed -e 's/.*oauth_token...//;s/\".*//'",
          },
        },

        pplx = {
          endpoint = "https://api.perplexity.ai/chat/completions",
          secret = os.getenv("PPLX_API_KEY"),
        },

        -- googleai = {
        --   endpoint = "https://generativelanguage.googleapis.com/v1beta/models/{{model}}:streamGenerateContent?key={{secret}}",
        --   secret = os.getenv("GOOGLEAI_API_KEY"),
        -- },

        -- azure = {...},
      },
      agents = {
        {
          name = "ChatOllama",
          chat = true,
          provider = "ollama",
          command = false,
          -- string with model name or table with model name and parameters
          model = { model = "llama3:8b" },
          -- system prompt (use this to specify the persona/role of the AI)
          system_prompt = "You are a general AI assistant.\n\n"
            .. "The user provided the additional info about how they would like you to respond:\n\n"
            .. "- If you're unsure don't guess and say you don't know instead.\n"
            .. "- Ask question if you need clarification to provide better answer.\n"
            .. "- Think deeply and carefully from first principles step by step.\n"
            .. "- Zoom out first to see the big picture and then zoom in to details.\n"
            .. "- Use Socratic method to improve your thinking and coding skills.\n"
            .. "- Don't elide any code from your output if the answer requires coding.\n"
            .. "- Take a deep breath; You've got this!\n",
        },
        {
          name = "ChatCodeLlama",
          chat = true,
          provider = "ollama",
          command = false,
          -- string with model name or table with model name and parameters
          model = { model = "codellama:7b" },
          -- system prompt (use this to specify the persona/role of the AI)
          system_prompt = "You are a general AI assistant.\n\n"
            .. "The user provided the additional info about how they would like you to respond:\n\n"
            .. "- If you're unsure don't guess and say you don't know instead.\n"
            .. "- Ask question if you need clarification to provide better answer.\n"
            .. "- Think deeply and carefully from first principles step by step.\n"
            .. "- Zoom out first to see the big picture and then zoom in to details.\n"
            .. "- Use Socratic method to improve your thinking and coding skills.\n"
            .. "- Don't elide any code from your output if the answer requires coding.\n"
            .. "- Take a deep breath; You've got this!\n",
        },
      },
    },

    config = function(_, opts)
      require("gp").setup(opts)
    end,
  },
}
