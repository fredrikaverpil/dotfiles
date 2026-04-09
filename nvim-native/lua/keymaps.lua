-- General keymaps not tied to any specific plugin.
-- Sourced from init.lua before any plugin/ files.

-- Windows
vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "Go to left window", silent = true })
vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "Go to lower window", silent = true })
vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "Go to upper window", silent = true })
vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "Go to right window", silent = true })
vim.keymap.set("n", "<C-Up>", ":resize +2<CR>", { desc = "Increase window height", silent = true })
vim.keymap.set("n", "<C-Down>", ":resize -2<CR>", { desc = "Decrease window height", silent = true })
vim.keymap.set("n", "<C-Right>", ":vertical resize +2<CR>", { desc = "Increase window width", silent = true })
vim.keymap.set("n", "<C-Left>", ":vertical resize -2<CR>", { desc = "Decrease window width", silent = true })

-- Move lines (alt+j/k)
local is_mac = vim.fn.has("macunix") == 1
local down_keys = is_mac and { "∆", "<M-j>", "<A-j>" } or { "<M-j>" }
local up_keys = is_mac and { "˚", "<M-k>", "<A-k>" } or { "<M-k>" }
local function map_multiple(mode, keys, command, opts)
  for _, key in ipairs(keys) do
    vim.keymap.set(mode, key, command, opts)
  end
end
map_multiple("n", down_keys, ":m .+1<CR>==", { desc = "Move line down", silent = true })
map_multiple("n", up_keys, ":m .-2<CR>==", { desc = "Move line up", silent = true })
map_multiple("i", down_keys, "<Esc>:m .+1<CR>==gi", { desc = "Move line down", silent = true })
map_multiple("i", up_keys, "<Esc>:m .-2<CR>==gi", { desc = "Move line up", silent = true })
map_multiple("v", down_keys, ":m '>+1<CR>gv=gv", { desc = "Move selection down", silent = true })
map_multiple("v", up_keys, ":m '<-2<CR>gv=gv", { desc = "Move selection up", silent = true })

-- Buffers
vim.keymap.set("n", "<leader>`", "<C-^>", { desc = "Alternate buffers" })
vim.keymap.set("n", "<leader>bN", "<cmd>enew<cr>", { desc = "New buffer" })
for _, key in ipairs({ "<S-l>", "<leader>bn", "]b" }) do
  vim.keymap.set("n", key, "<cmd>bnext<cr>", { desc = "Next buffer" })
end
for _, key in ipairs({ "<S-h>", "<leader>bp", "[b" }) do
  vim.keymap.set("n", key, "<cmd>bprevious<cr>", { desc = "Prev buffer" })
end
vim.keymap.set("n", "<leader>bq", "<cmd>bd %<cr>", { desc = "Delete buffer" })
vim.keymap.set("n", "<leader>bo", function()
  local visible = {}
  for _, win in pairs(vim.api.nvim_list_wins()) do
    visible[vim.api.nvim_win_get_buf(win)] = true
  end
  for _, buf in pairs(vim.api.nvim_list_bufs()) do
    if not visible[buf] then
      vim.api.nvim_buf_delete(buf, {})
    end
  end
end, { desc = "Close all other buffers" })
vim.keymap.set("n", "<leader>by", function()
  local path = vim.fn.fnamemodify(vim.fn.expand("%"), ":.")
  vim.fn.setreg("+", path)
  vim.notify("Copied to clipboard: " .. path, vim.log.levels.INFO)
end, { desc = "Yank buffer filepath (relative)" })
vim.keymap.set("n", "<leader>bY", function()
  local path = vim.fn.expand("%:p")
  vim.fn.setreg("+", path)
  vim.notify("Copied to clipboard: " .. path, vim.log.levels.INFO)
end, { desc = "Yank buffer filepath (absolute)" })

-- Tabs
vim.keymap.set("n", "<leader><tab>n", "<cmd>tabnew<cr>", { desc = "New Tab", silent = true })
vim.keymap.set("n", "<leader><tab>q", "<cmd>tabclose<cr>", { desc = "Close Tab", silent = true })
vim.keymap.set("n", "<leader><tab>[", "<cmd>tabprevious<cr>", { desc = "Previous Tab", silent = true })
vim.keymap.set("n", "<leader><tab>]", "<cmd>tabnext<cr>", { desc = "Next Tab", silent = true })
vim.keymap.set("n", "[<tab>", "<cmd>tabprevious<cr>", { desc = "Previous Tab", silent = true })
vim.keymap.set("n", "]<tab>", "<cmd>tabnext<cr>", { desc = "Next Tab", silent = true })

-- Clear search with <esc>
vim.keymap.set({ "n", "i" }, "<esc>", "<cmd>noh<cr><esc>", { desc = "Escape and clear hlsearch" })

-- Save file
vim.keymap.set({ "i", "x", "n", "s" }, "<C-s>", "<cmd>w<cr><esc>", { desc = "Save file" })

-- Better indenting
vim.keymap.set("v", "<", "<gv", { desc = "Indent left" })
vim.keymap.set("v", ">", ">gv", { desc = "Indent right" })

-- Lists
local qf = require("quickfix")
qf.setup()
vim.keymap.set("n", "<leader>xq", "<cmd>copen<cr>", { desc = "Quickfix List" })
vim.keymap.set("n", "<leader>xl", "<cmd>lopen<cr>", { desc = "Location List" })
vim.keymap.set("n", "<leader>xc", function()
  vim.fn.setloclist(0, {})
end, { desc = "Clear location list" })
vim.keymap.set("n", "<leader>xC", function()
  vim.fn.setqflist({})
end, { desc = "Clear quickfix list" })
vim.keymap.set("n", "<leader>xx", function()
  qf.toggle_loclist()
end, { desc = "Toggle buffer diagnostics (location list)", silent = true })
vim.keymap.set("n", "<leader>xX", function()
  qf.toggle_qflist()
end, { desc = "Toggle workspace diagnostics (quickfix list)", silent = true })
vim.keymap.set("n", "[q", function()
  pcall(vim.cmd.cprev)
end, { desc = "Previous quickfix" })
vim.keymap.set("n", "]q", function()
  pcall(vim.cmd.cnext)
end, { desc = "Next quickfix" })
vim.keymap.set("n", "[l", function()
  pcall(vim.cmd.lprev)
end, { desc = "Previous location" })
vim.keymap.set("n", "]l", function()
  pcall(vim.cmd.lnext)
end, { desc = "Next location" })

-- Diagnostics
vim.keymap.set("n", "<leader>cd", vim.diagnostic.open_float, { desc = "Line Diagnostics" })
vim.keymap.set("n", "]e", function()
  vim.diagnostic.jump({ count = 1, severity = vim.diagnostic.severity.ERROR })
end, { desc = "Next Error", silent = true })
vim.keymap.set("n", "[e", function()
  vim.diagnostic.jump({ count = -1, severity = vim.diagnostic.severity.ERROR })
end, { desc = "Prev Error", silent = true })
vim.keymap.set("n", "]w", function()
  vim.diagnostic.jump({ count = 1, severity = vim.diagnostic.severity.WARN })
end, { desc = "Next Warning", silent = true })
vim.keymap.set("n", "[w", function()
  vim.diagnostic.jump({ count = -1, severity = vim.diagnostic.severity.WARN })
end, { desc = "Prev Warning", silent = true })

-- Toggles
vim.keymap.set("n", "<leader>ud", require("toggle").diagnostics, { desc = "Toggle diagnostics", silent = true })

-- Shada
vim.keymap.set("n", "<leader>us", function()
  local stdpath = vim.fn.stdpath("state")
  local files_removed = 0
  local shada_file = stdpath .. "/shada/main.shada"
  if vim.fn.filereadable(shada_file) == 1 then
    vim.fn.delete(shada_file)
    files_removed = files_removed + 1
  end
  for _, file in ipairs(vim.fn.glob(stdpath .. "/shada/main.shada.tmp.*", false, true)) do
    vim.fn.delete(file)
    files_removed = files_removed + 1
  end
  if files_removed > 0 then
    vim.notify("Removed " .. files_removed .. " shada file(s)", vim.log.levels.INFO)
  else
    vim.notify("No shada files found to remove", vim.log.levels.WARN)
  end
end, { desc = "Remove shada files", silent = true })

-- Folding
vim.keymap.set("v", "zf", function()
  vim.wo.foldmethod = "manual"
  vim.notify("Foldmethod set to manual", vim.log.levels.INFO)
  return "zf"
end, { desc = "Create manual fold", expr = true, silent = true })
vim.keymap.set("n", "<leader>uf", function()
  vim.wo.foldmethod = "expr"
  vim.notify("Foldmethod set to expr", vim.log.levels.INFO)
end, { desc = "Reset to expr folding", silent = true })
