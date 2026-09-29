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
