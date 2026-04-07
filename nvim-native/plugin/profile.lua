-- profile.nvim: profiling with perfetto UI.
-- Run with: NVIM_PROFILE=1 nvim       (instrument, then press <F1> to record)
-- Run with: NVIM_PROFILE=start nvim   (record from startup, press <F1> to stop)
-- View the profile at https://ui.perfetto.dev/

local should_profile = os.getenv("NVIM_PROFILE")
if not should_profile then
  return
end

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
end, { desc = "Toggle profiling" })
