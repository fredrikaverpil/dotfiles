-- Options are automatically loaded before lazy.nvim startup
-- Docs: https://www.lazyvim.org/configuration/general
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.opt.listchars = "tab:▸ ,trail:·,nbsp:␣,extends:❯,precedes:❮" -- show symbols for whitespace
vim.opt.relativenumber = false -- relative line numbers
-- vim.opt.scrolloff = 10 -- keep 20 lines above and below the cursor

-- project specific settings
vim.opt.exrc = true -- allow local .nvim.lua .vimrc .exrc files
vim.opt.secure = true -- disable shell and write commands in local .nvim.lua .vimrc .exrc files

-- set autopairs disabled by default
vim.g.minipairs_disable = true

-- sync with system clipboard
vim.opt.clipboard = "unnamedplus"
if vim.fn.has("wsl") == 1 then
  vim.api.nvim_create_autocmd("TextYankPost", {

    group = vim.api.nvim_create_augroup("Yank", { clear = true }),

    callback = function()
      vim.fn.system("clip.exe", vim.fn.getreg('"'))
    end,
  })
end

vim.g.is_code_private = function()
  local current_dir = vim.fn.getcwd()
  local home_dir = os.getenv("HOME") or os.getenv("USERPROFILE")
  local code_path = home_dir .. "/code"

  -- if git repo is filed under ~/code/work/private, do not allow AI
  local private_path = code_path .. "/work/private"
  local is_code_private = string.find(current_dir, private_path) == 1

  if is_code_private then
    return true
  else
    return false
  end
end
