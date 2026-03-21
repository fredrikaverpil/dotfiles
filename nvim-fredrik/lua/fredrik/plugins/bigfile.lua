-- Disable expensive features for big files.
--
-- Why not snacks.nvim bigfile?
--
-- Snacks bigfile uses vim.filetype.add to set ft="bigfile" early, which is
-- the right idea — it prevents syntax/treesitter from loading rather than
-- undoing them after the fact. However, it has two limitations:
--
--   1. Neovim's legacy filetypedetect autocmds (BufRead) can override the
--      filetype after vim.filetype.add has matched. For example, the built-in
--      "*{.,_}log" pattern sets ft=log after the "bigfile" pattern matched,
--      so .log files never get bigfile treatment. This plugin adds a
--      BufReadPost fallback to catch and correct this.
--
--   2. Snacks only checks file size and average line length. It misses files
--      where individual lines are extremely long (e.g. log files with embedded
--      JSON). This plugin adds a max_line_length check that samples the first
--      N lines for any single line exceeding the threshold.
--
-- Detection: sets filetype to "bigfile" when any of these triggers:
--   1. "size"            — file size exceeds `size` bytes
--   2. "line_length"     — average line length exceeds `line_length` characters
--   3. "max_line_length" — any single line in first `sample_lines` exceeds `max_line_length`
--
-- What gets disabled depends on which criteria triggered (in default setup):
--   - Always: completion, swapfile, undofile, foldmethod, statuscolumn, conceallevel
--   - "size" or "line_length": also syntax and treesitter (unless ft is in keep_highlighting)
--   - "max_line_length" only: keeps syntax and treesitter (most lines are fine,
--     only a few are long — disabling syntax for the whole buffer is overkill)

---@alias bigfile.Reason "size"|"line_length"|"max_line_length"

---@class bigfile.Ctx
---@field buf number
---@field ft string original filetype
---@field reasons bigfile.Reason[]

---@class bigfile.Opts
---@field size number file size threshold in bytes
---@field line_length number average line length threshold
---@field max_line_length number max single line length threshold (0 to disable)
---@field sample_lines number how many lines to sample for max_line_length
---@field notify boolean show notification when bigfile detected
---@field keep_highlighting string[] filetypes where syntax is kept even for size/line_length
---@field setup fun(ctx: bigfile.Ctx) called when a bigfile is detected

---@type bigfile.Opts
local defaults = {
  size = 1024 * 1024, -- 1MB
  line_length = 500,
  max_line_length = 1000,
  sample_lines = 500,
  notify = true,
  keep_highlighting = { "json", "yaml", "xml" },
  setup = function(ctx)
    -- Always disable these for any bigfile.
    vim.b[ctx.buf].completion = false
    vim.bo[ctx.buf].swapfile = false
    vim.bo[ctx.buf].undofile = false
    vim.api.nvim_buf_call(ctx.buf, function()
      vim.wo[0].foldmethod = "manual"
      vim.wo[0].statuscolumn = ""
      vim.wo[0].conceallevel = 0
    end)
  end,
}

--- Detect if a buffer qualifies as a big file.
---@param path string
---@param buf number
---@param opts bigfile.Opts
---@return bigfile.Reason[]|nil
local function detect(path, buf, opts)
  local fsize = vim.fn.getfsize(path)
  if fsize <= 0 then
    return nil
  end
  local reasons = {}
  if fsize > opts.size then
    table.insert(reasons, "size")
  end
  local lines = vim.api.nvim_buf_line_count(buf)
  if lines > 0 and (fsize - lines) / lines > opts.line_length then
    table.insert(reasons, "line_length")
  end
  if opts.max_line_length > 0 then
    local sample = vim.api.nvim_buf_get_lines(buf, 0, math.min(opts.sample_lines, lines), false)
    for _, line in ipairs(sample) do
      if #line > opts.max_line_length then
        table.insert(reasons, "max_line_length")
        break
      end
    end
  end
  if #reasons == 0 then
    return nil
  end
  return reasons
end

--- Apply bigfile settings to a buffer.
---@param buf number
---@param ft string
---@param reasons bigfile.Reason[]
---@param opts bigfile.Opts
local function apply(buf, ft, reasons, opts)
  opts.setup({ buf = buf, ft = ft, reasons = reasons })

  -- Determine whether syntax/treesitter should be cleared.
  -- Only "size" and "line_length" warrant clearing — "max_line_length" alone
  -- means most lines are fine and syntax is still useful.
  local clear_syntax = vim.tbl_contains(reasons, "size") or vim.tbl_contains(reasons, "line_length")

  if clear_syntax and not vim.tbl_contains(opts.keep_highlighting, ft) then
    vim.treesitter.stop(buf)
    -- Clear any regex-based syntax that may have loaded before the bigfile
    -- fallback kicked in (e.g. log-highlight.nvim).
    vim.api.nvim_buf_call(buf, function()
      vim.cmd("syntax clear")
    end)
  elseif clear_syntax then
    -- Allowlisted filetype: restore syntax after the bigfile ft override.
    vim.schedule(function()
      if vim.api.nvim_buf_is_valid(buf) then
        vim.bo[buf].syntax = ft
      end
    end)
  end

  if opts.notify then
    local path = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ":p:~:.")
    local reason_str = table.concat(reasons, ", ")
    vim.notify("bigfile (" .. reason_str .. "): disabled expensive features for " .. path, vim.log.levels.WARN)
  end
end

return {
  {
    "bigfile",
    virtual = true,
    event = "BufReadPre",
    opts = {},
    config = function(_, user_opts)
      local opts = vim.tbl_deep_extend("force", defaults, user_opts)

      -- Primary detection: vim.filetype.add runs before syntax/treesitter load.
      vim.filetype.add({
        pattern = {
          [".*"] = {
            function(path, buf)
              if not path or not buf or vim.bo[buf].filetype == "bigfile" then
                return
              end
              if path ~= vim.fs.normalize(vim.api.nvim_buf_get_name(buf)) then
                return
              end
              local reasons = detect(path, buf, opts)
              if reasons then
                vim.b[buf].bigfile_reasons = reasons
                return "bigfile"
              end
            end,
          },
        },
      })

      -- Apply settings when filetype becomes "bigfile".
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("bigfile", { clear = true }),
        pattern = "bigfile",
        callback = function(ev)
          local ft = vim.b[ev.buf].bigfile_ft or vim.filetype.match({ buf = ev.buf }) or ""
          local reasons = vim.b[ev.buf].bigfile_reasons or { "size" }
          apply(ev.buf, ft, reasons, opts)
        end,
      })

      -- Fallback: legacy filetypedetect (BufRead autocmds) can override the
      -- filetype after vim.filetype.add already matched "bigfile". Re-check
      -- after filetype detection is complete and force bigfile if needed.
      vim.api.nvim_create_autocmd("BufReadPost", {
        group = vim.api.nvim_create_augroup("bigfile_fallback", { clear = true }),
        callback = function(ev)
          if vim.bo[ev.buf].filetype == "bigfile" then
            return
          end
          local path = vim.api.nvim_buf_get_name(ev.buf)
          if path == "" then
            return
          end
          local reasons = detect(path, ev.buf, opts)
          if reasons then
            vim.b[ev.buf].bigfile_ft = vim.bo[ev.buf].filetype
            vim.b[ev.buf].bigfile_reasons = reasons
            vim.bo[ev.buf].filetype = "bigfile"
          end
        end,
      })
    end,
  },
}
