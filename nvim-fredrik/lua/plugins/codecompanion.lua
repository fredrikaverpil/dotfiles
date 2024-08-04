local scan = require("plenary.scandir")
local Path = require("plenary.path")

local function get_all_files(dir, extensions)
  local all_files = scan.scan_dir(dir, {
    hidden = false,
    depth = math.huge,
    add_dirs = false,
  })

  return vim.tbl_filter(function(file)
    local ext = file:match("%.([^%.]+)$")
    return ext and vim.tbl_contains(extensions, ext)
  end, all_files)
end

-- Function to read file content
local function read_file(file_path)
  local file = io.open(file_path, "r")
  if not file then
    return nil
  end
  local content = file:read("*all")
  file:close()
  return content
end

local function generate_content(allowed_filetypes)
  return function()
    local cwd = vim.fn.getcwd()
    vim.notify("Scanning files in " .. cwd)
    local all_files = get_all_files(cwd, allowed_filetypes)
    local content = "You are a helpful coding assistant. The following code exists in the project:\n\n"

    for _, file_path in ipairs(all_files) do
      vim.notify(file_path)
      local relative_path = Path:new(file_path):make_relative(cwd)
      local filetype = vim.filetype.match({ filename = file_path }) or "text"

      if vim.tbl_contains(allowed_filetypes, filetype) then
        local file_content = read_file(file_path)
        if file_content then
          content = content .. "File: " .. relative_path .. "\n```" .. filetype .. "\n" .. file_content .. "\n```\n\n"
        end
      end
    end

    return content
  end
end

local custom_prompts = {
  ["Go API developer"] = {
    allowed_filetypes = { "go", "proto", "sql", "md" },
    excluded_folders = { ".git" },
    system_message = "You are a senior software engineer, working with APIs written in Go, gRPC for GCP and always try to adhere to Google AIPs.",
  },
  ["Neotest/Go developer"] = {
    allowed_filetypes = { "go", "lua", "md" },
    excluded_folders = { ".git" },
    system_message = "You are a Neotest adapter developer, working on Go and Lua.",
  },
  ["Python Data Scientist"] = {
    allowed_filetypes = { "py", "ipynb", "md" },
    excluded_folders = { ".venv", "venv", ".git", "data" },
    system_message = "You are a data scientist specializing in Python, machine learning, and data analysis.",
  },
}

local default_prompts = {}
for prompt_name, prompt_config in pairs(custom_prompts) do
  default_prompts[prompt_name] = {
    strategy = "chat",
    description = "custom!",
    opts = {
      slash_cmd = prompt_name:lower():gsub("%s+", "_"),
    },
    prompts = {
      {
        role = "system",
        -- TODO: include system_message
        content = generate_content(prompt_config.allowed_filetypes),
      },
    },
  }
end

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

    config = function(_, opts)
      local ollama_fn = function()
        return require("codecompanion.adapters").use("ollama", {
          schema = {
            model = {
              default = "llama3.1:8b",
              -- default = "codellama:7b",
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
        default_prompts = default_prompts,

        adapters = {
          ollama = ollama_fn,
          anthropic = anthropic_fn,
          openai = openai_fn,
        },
        strategies = {
          chat = {
            adapter = "ollama",
            roles = {
              llm = "CodeCompanion", -- The markdown header content for the LLM's responses
              user = "Me", -- The markdown header for your questions
            },
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
