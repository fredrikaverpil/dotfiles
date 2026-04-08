local USE_NVIM_TREESITTER = vim.g.use_nvim_treesitter

if USE_NVIM_TREESITTER then
  vim.pack.add({
    { src = "https://github.com/nvim-treesitter/nvim-treesitter", branch = "main" },
    { src = "https://github.com/nvim-treesitter/nvim-treesitter-context" },
  })
end

require("defer").on_ui_enter(function()
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

      local ok = pcall(vim.treesitter.start, bufnr, lang)
      if ok then
        return
      end

      if install_parser(lang) then
        pcall(vim.treesitter.start, bufnr, lang)
      end
    end,
  })

  -- Start treesitter for buffers that loaded before this callback
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) then
      local ft = vim.bo[buf].filetype
      if ft ~= "" then
        local lang = vim.treesitter.language.get_lang(ft)
        if lang then
          pcall(vim.treesitter.start, buf, lang)
        end
      end
    end
  end

  if USE_NVIM_TREESITTER then
    require("treesitter-context").setup({
      multiwindow = true,
    })
  end
end)
