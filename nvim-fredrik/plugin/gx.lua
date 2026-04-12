-- TODO: investigate why we cannot emply lazyloading
--
-- Error in UIEnter Autocommands for "*":
-- Lua callback: ...ite/pack/core/opt/nvim-coverage/lua/coverage/summary.lua:4: module 'plenary.path' not found:
-- 	no field package.preload['plenary.path']
-- 	cache_loader: module 'plenary.path' not found
-- 	cache_loader_lib: module 'plenary.path' not found
-- 	no file './plenary/path.lua'
-- 	no file '/Users/runner/work/neovim/neovim/.deps/usr/share/luajit-2.1/plenary/path.lua'
-- 	no file '/usr/local/share/lua/5.1/plenary/path.lua'
-- 	no file '/usr/local/share/lua/5.1/plenary/path/init.lua'
-- 	no file '/Users/runner/work/neovim/neovim/.deps/usr/share/lua/5.1/plenary/path.lua'
-- 	no file '/Users/runner/work/neovim/neovim/.deps/usr/share/lua/5.1/plenary/path/init.lua'
-- 	no file './plenary/path.so'
-- 	no file '/usr/local/lib/lua/5.1/plenary/path.so'
-- 	no file '/Users/runner/work/neovim/neovim/.deps/usr/lib/lua/5.1/plenary/path.so'
-- 	no file '/usr/local/lib/lua/5.1/loadall.so'
-- 	no file './plenary.so'
-- 	no file '/usr/local/lib/lua/5.1/plenary.so'
-- 	no file '/Users/runner/work/neovim/neovim/.deps/usr/lib/lua/5.1/plenary.so'
-- 	no file '/usr/local/lib/lua/5.1/loadall.so'
-- stack traceback:
-- 	[C]: in function 'require'
-- 	...ite/pack/core/opt/nvim-coverage/lua/coverage/summary.lua:4: in main chunk
-- 	[C]: in function 'require'
-- 	...e/site/pack/core/opt/nvim-coverage/lua/coverage/init.lua:6: in main chunk
-- 	[C]: in function 'require'
-- 	...s/fredrik/.dotfiles/nvim-native/plugin/nvim_coverage.lua:9: in function <...s/fredrik/.dotfiles/nvim-native/plugin/nvim_coverage.lua:8>

vim.pack.add({
  { src = "https://github.com/chrishrb/gx.nvim" },
  { src = "https://github.com/nvim-lua/plenary.nvim" },
})

require("gx").setup({})

vim.keymap.set({ "n", "x" }, "gx", "<cmd>Browse<cr>", { desc = "Browse URL" })
