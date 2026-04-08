local USE_NVIM_TREESITTER = true

if USE_NVIM_TREESITTER then
  vim.pack.add({
    { src = "https://github.com/nvim-treesitter/nvim-treesitter", branch = "main" },
    { src = "https://github.com/nvim-treesitter/nvim-treesitter-context" },
  })
end

--- Sign parser .so on macOS to prevent code-signature crashes.
---@param parser_name string
local function sign_parser_macos(parser_name)
  if vim.fn.has("mac") ~= 1 then
    return
  end
  local parser_path = vim.fn.stdpath("data") .. "/site/parser/" .. parser_name .. ".so"
  if vim.fn.filereadable(parser_path) == 1 then
    vim.fn.system({ "codesign", "--force", "--sign", "-", parser_path })
  end
end

--- Install a parser via nvim-treesitter.
--- Replace this function to use a different parser provider.
---@param lang string parser/language name
---@return boolean success
local function install_parser(lang)
  if not USE_NVIM_TREESITTER then
    return false
  end
  local parsers = require("nvim-treesitter.parsers")
  if not parsers[lang] then
    return false
  end
  require("nvim-treesitter").install({ lang }):wait(30000)
  sign_parser_macos(lang)
  return true
end

--- Auto-start treesitter highlighting for every buffer.
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("treesitter-start", { clear = true }),
  callback = function(event)
    local bufnr = event.buf
    local ft = event.match
    if ft == "" then
      return
    end

    local lang = vim.treesitter.language.get_lang(ft)
    if not lang then
      return
    end

    -- Start treesitter (succeeds if parser .so is already available)
    local ok = pcall(vim.treesitter.start, bufnr, lang)
    if ok then
      return
    end

    -- Parser not available — try to install it, then retry
    if install_parser(lang) then
      pcall(vim.treesitter.start, bufnr, lang)
    end
  end,
})

--- Sticky context lines at the top of the window.
if USE_NVIM_TREESITTER then
  require("treesitter-context").setup({
    multiwindow = true,
  })
end
