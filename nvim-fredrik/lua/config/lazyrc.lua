--[[
Enable project-specific plugin specs.
File .lazy.lua:
  is read when present in the current working directory
  should return a plugin spec
  has to be manually trusted for each instance of the file
This extra should be the last plugin spec added to lazy.nvim
See:
  :h 'exrc'
  :h :trust

Discussion: https://github.com/LazyVim/LazyVim/pull/2115
Upstream source: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/plugins/extras/lazyrc.lua
--]]
local filepath = vim.fn.fnamemodify(".lazy.lua", ":p")
local file = vim.secure.read(filepath)
if not file then
  return {}
end

-- NOTE: the below is not needed for non-LazyVim installations
--
-- vim.api.nvim_create_autocmd("User", {
--   pattern = "VeryLazy",
--   once = true,
--   callback = function()
--     local Config = require("lazy.core.config")
--     local Util = require("lazyvim.util")
--     local lazyrc_idx = Util.plugin.extra_idx("lazyrc")
--
--     if lazyrc_idx and lazyrc_idx ~= #Config.spec.modules then
--       print({
--         "The `lazyrc` extra must be the last plugin spec added to **lazy.nvim**. ",
--         "",
--         "Add `{ import = 'lazyvim.plugins.extras.lazyrc' }` to file `config.lazy`. ",
--         "Do not use the `LazyExtras` command. ",
--       }, { title = "LazyVim", once = true })
--     end
--   end,
-- })

return loadstring(file)()
