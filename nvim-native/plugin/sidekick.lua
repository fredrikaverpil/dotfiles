-- Sidekick: AI CLI integration.

vim.pack.add({
  { src = "https://github.com/folke/sidekick.nvim" },
})

require("sidekick").setup({
  cli = {
    win = {
      split = {
        width = 140,
      },
    },
    ---@type table<string, sidekick.cli.Config|{}>
    tools = {
      amp = {
        cmd = { "amp", "threads", "continue" },
      },
      copilot = {
        cmd = { "copilot", "--continue" },
      },
      claude = {
        cmd = {
          "claude",
          "--continue",
          "--allow-dangerously-skip-permissions",
          "--allowedTools=mcp__github",
          "--allowedTools=Bash(gh:*)",
          "--allowedTools=RunBash(go:*)",
          "--allowedTools=Read(~/code)",
        },
      },
      codex = {
        cmd = { "codex", "--continue" },
      },
      opencode = {
        cmd = { "opencode", "--continue" },
      },
      gemini = {
        cmd = { "gemini", "--resume" },
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
