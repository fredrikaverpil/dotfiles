-- debugging of config;
-- 1. start neovim: nvim --cmd "lua init_debug=true" (starts server)
-- 2. start another neovim instance normally, set break points
-- 3. run require("dap").continue() (<leader>dc)
--
---@diagnostic disable-next-line: undefined-global
if init_debug then
  local osvpath = vim.fn.stdpath("data") .. "/lazy/one-small-step-for-vimkind"
  vim.opt.rtp:prepend(osvpath)
  require("osv").launch({ port = 8086, blocking = true })
end

-- profiling with profile.nvim
-- Run with: NVIM_PROFILE=1 nvim       (instrument, then press <F1> to record)
-- Run with: NVIM_PROFILE=start nvim   (record from startup, press <F1> to stop)
-- Press <F1> to start/stop recording and save the profile as JSON.
-- View the profile at https://ui.perfetto.dev/
local should_profile = os.getenv("NVIM_PROFILE")
if should_profile then
  vim.opt.rtp:append(vim.fn.stdpath("data") .. "/lazy/profile.nvim")

  local prof = require("profile")
  -- Instrument autocommands to capture their performance
  prof.instrument_autocmds()

  -- Ignore vim internals to reduce noise
  prof.ignore("vim.*")

  -- Ignore specific blink.cmp components for focused profiling
  -- Remove these lines if you want to profile render/sort performance
  prof.ignore("blink.cmp.completion.windows.render.*")
  prof.ignore("blink.cmp.fuzzy.sort.*")

  -- "start" mode: record from startup (for init.lua perf)
  -- "instrument" mode: instrument now, record later with <F1> (default)
  if should_profile:lower():match("^start") then
    prof.start("*")
  else
    prof.instrument("*")
  end

  -- <F1> toggles recording on/off and prompts to save the profile
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

-- set options
require("fredrik.config.options")

-- set auto commands
require("fredrik.config.autocmds")

-- set core keymaps
require("fredrik.config.keymaps")

-- setup up plugin manager, load plugin configs
require("fredrik.config.lazy")
