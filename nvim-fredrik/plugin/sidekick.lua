require("lazyload").on_vim_enter(function()
  vim.pack.add({
    { src = "https://github.com/folke/sidekick.nvim", version = vim.version.range("*") },
  })

  -- taken from sidekick.nvim
  -- https://github.com/folke/sidekick.nvim/blob/main/sk/cli/claude.lua
  local claude_format = function(text)
    local Text = require("sidekick.text")

    Text.transform(text, function(str)
      return str:find("[^%w/_%.%-]") and ('"' .. str .. '"') or str
    end, "SidekickLocFile")

    local ret = Text.to_string(text)

    -- transform line ranges to a format that Claude understands
    ret = ret:gsub("@([^@]-) :L(%d+)%-L(%d+)", "@%1#L%2-%3")

    return ret
  end

  require("sidekick").setup({
    cli = {
      win = {
        split = {
          width = 140,
        },
      },
      ---@type table<string, sidekick.cli.Config|{}>
      tools = {
        amp = { cmd = { "amp", "threads", "continue" } },
        -- antigravity = { cmd = { "agy", "--continue" } },
        codex = { cmd = { "codex", "resume", "--last" } },
        opencode = { cmd = { "opencode", "--continue" } },
        gemini = { cmd = { "gemini", "--resume" } },
        pi = { cmd = { "pi", "--continue" } },
        -- vibe = { cmd = { "vibe", "--continue" } },

        claude = {
          cmd = {
            "claude",
            "--continue",
            "--allowedTools=Bash(gh:*)",
            "--allowedTools=RunBash(go:*)",
            "--allowedTools=Read(~/code/public)",
          },
        },

        ["pi via omlx"] = {
          cmd = { "omlx", "launch", "pi", "--continue" },
        },
      },
    },
  })

  -- Keymaps
  local map = vim.keymap.set

  map({ "n", "t", "i", "x" }, "<c-.>", function()
    require("sidekick.cli").toggle()
  end, { desc = "Sidekick Toggle" })

  map("n", "<leader>aa", function()
    require("sidekick.cli").toggle()
  end, { desc = "Sidekick Toggle CLI" })

  map("n", "<leader>as", function()
    require("sidekick.cli").select()
  end, { desc = "Select CLI" })

  map("n", "<leader>ad", function()
    require("sidekick.cli").close()
  end, { desc = "Detach a CLI Session" })

  map({ "x", "n" }, "<leader>at", function()
    require("sidekick.cli").send({ msg = "{this}" })
  end, { desc = "Send This" })

  map("n", "<leader>af", function()
    require("sidekick.cli").send({ msg = "{file}" })
  end, { desc = "Send File" })

  map("x", "<leader>av", function()
    require("sidekick.cli").send({ msg = "{selection}" })
  end, { desc = "Send Visual Selection" })

  map({ "n", "x" }, "<leader>ap", function()
    require("sidekick.cli").prompt()
  end, { desc = "Sidekick Select Prompt" })

  map("n", "<leader>ac", function()
    require("sidekick.cli").toggle({ name = "claude", focus = true })
  end, { desc = "Sidekick Toggle Claude" })
end)
