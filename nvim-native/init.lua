vim.loader.enable()

-- Native Neovim config using vim.pack + native directories.
-- No plugin manager framework — just Neovim's built-in conventions:
--   lsp/       — LSP server configs (auto-discovered by vim.lsp.config)
--   plugin/    — auto-sourced at startup (step 11 of :h initialization)
--   ftplugin/  — sourced when filetype is set
--   after/lsp/ — override LSP configs from plugins

-- Debugging of config:
-- 1. start neovim: nvim --cmd "lua init_debug=true" (starts server)
-- 2. start another neovim instance normally, set break points
-- 3. run require("dap").continue() (<leader>dc)
---@diagnostic disable-next-line: undefined-global
if init_debug then
  vim.pack.add({
    { src = "https://github.com/jbyuki/one-small-step-for-vimkind" },
  })
  require("osv").launch({ port = 8086, blocking = true })
end

-- Profiling with profile.nvim
-- Run with: NVIM_PROFILE=1 nvim       (instrument, then press <F1> to record)
-- Run with: NVIM_PROFILE=start nvim   (record from startup, press <F1> to stop)
-- Press <F1> to start/stop recording and save the profile as JSON.
-- View the profile at https://ui.perfetto.dev/
local should_profile = os.getenv("NVIM_PROFILE")
if should_profile then
  vim.pack.add({
    { src = "https://github.com/stevearc/profile.nvim" },
  })

  local prof = require("profile")
  prof.instrument_autocmds()
  prof.ignore("vim.*")
  prof.ignore("blink.cmp.completion.windows.render.*")
  prof.ignore("blink.cmp.fuzzy.sort.*")

  if should_profile:lower():match("^start") then
    prof.start("*")
  else
    prof.instrument("*")
  end

  vim.keymap.set("", "<f1>", function()
    if prof.is_recording() then
      prof.stop()
      vim.ui.input({ prompt = "Save profile to:", completion = "file", default = "profile.json" }, function(filename)
        if filename then
          prof.export(filename)
          vim.notify(string.format("Wrote %s", filename))
        end
      end)
    else
      prof.start("*")
    end
  end)
end

-- Capture startup time as early as possible for the dashboard.
_G._nvim_start_time = vim.uv.hrtime()

vim.g.mapleader = " "
vim.g.maplocalleader = ","
vim.g.use_nvim_treesitter = true

require("options")

require("diagnostics")

require("keymaps")

require("exrc").load()

-- Plugins are installed via vim.pack.add() in each plugin/*.lua file.
-- LSP server configs live in lsp/*.lua (auto-discovered by vim.lsp.config).
