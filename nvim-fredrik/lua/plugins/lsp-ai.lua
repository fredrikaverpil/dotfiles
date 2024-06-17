-- NOTE: instructions:
--
-- For local llama_cpp:
-- - https://github.com/SilasMarvin/lsp-ai/wiki/Installation
-- Then download model file, e.g. https://huggingface.co/Qwen/CodeQwen1.5-7B-Chat-GGUF/tree/main
-- and place it somewhere. Then update the `file_path` below.
--
-- See additional configs and possibilities:
-- https://github.com/SilasMarvin/lsp-ai/wiki/Configuration

--- Ollama FIM.
--- https://github.com/SilasMarvin/lsp-ai/wiki/Configuration#fim-2
local function fim_ollama()
  local server = {
    memory = {
      file_store = {},
    },
    models = {
      model1 = {
        type = "ollama",
        model = "codellama:7b",
      },
    },
    completion = {
      model = "model1",
      parameters = {
        fim = {
          start = "<｜fim▁begin｜>",
          middle = "<｜fim▁hole｜>",
          ["end"] = "<｜fim▁end｜>",
        },
        max_context = 1024 * 2,
        options = {
          num_predict = 32,
        },
      },
    },
  }
  return server
end

--- Llama_cpp FIM.
--- https://github.com/SilasMarvin/lsp-ai/wiki/Configuration#fim-1
local function fim_llama_cpp()
  local server = {
    memory = {
      file_store = {},
    },
    models = {
      model1 = {
        type = "llama_cpp",
        file_path = vim.fn.expand("~/code/public/CodeQwen1.5-7B-Chat-GGUF/codeqwen-1_5-7b-chat-q4_k_m.gguf"),
        n_ctx = 1024 * 2,
        n_gpu_layers = 500,
      },
    },
    completion = {
      model = "model1",
      parameters = {
        fim = {
          start = "<｜fim▁prefix｜>",
          middle = "<｜fim▁suffix｜>",
          ["end"] = "<｜fim▁middle｜>",
        },
        max_context = 1024 * 2,
        options = {
          num_predict = 32,
        },
      },
    },
  }
  return server
end

-- Ollama completion.
-- https://github.com/SilasMarvin/lsp-ai/wiki/Configuration#completion-2
local function completion_ollama()
  local server = {
    memory = {
      file_store = {},
    },
    models = {
      model1 = {
        type = "ollama",
        model = "codegemma",
      },
    },
    completion = {
      model = "model1",
      parameters = {
        max_context = 1024 * 2,
        options = {
          num_predict = 32,
        },
      },
    },
  }
  return server
end

-- Llama_cpp completion.
-- https://github.com/SilasMarvin/lsp-ai/wiki/Configuration#completion-1
local function completion_llama_cpp()
  local server = {
    memory = {
      file_store = {},
    },
    models = {
      model1 = {
        type = "llama_cpp",
        file_path = vim.fn.expand("~/code/public/CodeQwen1.5-7B-Chat-GGUF/codeqwen-1_5-7b-chat-q4_k_m.gguf"),
        n_ctx = 1024 * 2,
        n_gpu_layers = 500,
      },
    },
    completion = {
      model = "model1",
      parameters = {
        max_context = 1024 * 2,
        max_tokens = 32,
      },
    },
  }
  return server
end

return {
  {
    -- 1. Open up e.g. a Go file.
    -- 2. Invoke with `:LSPAIComplete`
    "SuperBo/lsp-ai.nvim",
    dependencies = { "neovim/nvim-lspconfig" },
    opts = {
      autostart = true,
      server = fim_ollama(),
      -- server = fim_llama_cpp(),
      -- server = completion_ollama(),
      -- server = completion_llama_cpp(),
    },
    config = function(_, opts)
      require("lsp_ai").setup(opts)
    end,
  },
}
