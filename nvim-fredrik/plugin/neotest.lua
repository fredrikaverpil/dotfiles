-- Neotest packages — registered on disk now, loaded on first keymap press.
-- This avoids sourcing each plugin's plugin/ files for sessions where you
-- never run a test. neotest-golang is handled separately inside init() so the
-- local dev clone takes precedence over the upstream package.
local packages = {
  -- Core
  { src = "https://github.com/nvim-neotest/neotest", name = "neotest" },
  { src = "https://github.com/nvim-neotest/nvim-nio", name = "nvim-nio" },
  { src = "https://github.com/nvim-lua/plenary.nvim", name = "plenary.nvim" },
  { src = "https://github.com/antoinemadec/FixCursorHold.nvim", name = "FixCursorHold.nvim" },
  -- Adapters
  { src = "https://github.com/nvim-neotest/neotest-plenary", name = "neotest-plenary" },
  { src = "https://github.com/nvim-neotest/neotest-python", name = "neotest-python" },
  {
    src = "https://github.com/lawrence-laz/neotest-zig",
    name = "neotest-zig",
    version = vim.version.range("1.*"),
  },
  -- neotest-golang dependency
  { src = "https://github.com/uga-rosa/utf8.nvim", name = "utf8.nvim" },
}
vim.pack.add(packages, { load = function() end })

local initialized = false

local function init()
  if initialized then
    return
  end
  initialized = true

  for _, p in ipairs(packages) do
    vim.cmd.packadd(p.name)
  end

  -- neotest-golang: prefer local dev clone if it exists, otherwise install
  -- the upstream package. Handled here (not in `packages`) because dev.use
  -- appends to runtimepath instead of going through vim.pack.
  require("dev").use({
    dev = "~/code/public/neotest-golang",
    fallback = function()
      vim.pack.add({
        { src = "https://github.com/fredrikaverpil/neotest-golang", name = "neotest-golang" },
      })
    end,
  })

  require("neotest").setup({
    adapters = {
      require("neotest-golang")({
        go_test_args = {
          "-v",
          "-count=1",
          "-race",
          "-coverprofile=" .. vim.fn.getcwd() .. "/coverage.out",
          "-parallel=1",
        },
        runner = "gotestsum",
        gotestsum_args = { "--format=standard-verbose" },
      }),
      require("neotest-plenary"),
      require("neotest-python")({
        runner = "pytest",
        args = { "--log-level", "INFO", "--color", "yes", "-vv", "-s" },
        dap = { justMyCode = false },
      }),
      require("neotest-zig")({
        dap = { adapter = "lldb" },
      }),
    },
    discovery = {
      enabled = true,
      concurrent = 0,
    },
    running = { concurrent = true },
    summary = { animated = true },
    log_level = vim.log.levels.WARN,
  })
end

-- Open file under cursor in the widest window when in neotest-output.
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("neotest-output", { clear = true }),
  pattern = "neotest-output",
  callback = function()
    vim.keymap.set("n", "gF", function()
      local current_word = vim.fn.expand("<cWORD>")
      local tokens = vim.split(current_word, ":", { trimempty = true })
      local widest_win_id, widest_win_width = -1, -1
      for _, win_id in ipairs(vim.api.nvim_list_wins()) do
        if not vim.api.nvim_win_get_config(win_id).zindex then
          local w = vim.api.nvim_win_get_width(win_id)
          if w > widest_win_width then
            widest_win_width = w
            widest_win_id = win_id
          end
        end
      end
      vim.api.nvim_set_current_win(widest_win_id)
      if #tokens == 1 then
        vim.cmd("e " .. tokens[1])
      else
        vim.cmd("e +" .. tokens[2] .. " " .. tokens[1])
      end
    end, { remap = true, buffer = true })
  end,
})

vim.keymap.set("n", "<leader>tn", function()
  init()
  require("neotest").run.run()
end, { desc = "Run nearest test" })
vim.keymap.set("n", "<leader>tT", function()
  init()
  require("neotest").run.run({ suite = true })
end, { desc = "Run test suite" })
vim.keymap.set("n", "<leader>tl", function()
  init()
  require("neotest").run.run_last()
end, { desc = "Run last test" })
vim.keymap.set("n", "<leader>ts", function()
  init()
  require("neotest").summary.toggle()
end, { desc = "Toggle test summary" })
vim.keymap.set("n", "<leader>to", function()
  init()
  require("neotest").output.open({ enter = true, auto_close = true })
end, { desc = "Show test output" })
vim.keymap.set("n", "<leader>tO", function()
  init()
  require("neotest").output_panel.toggle()
end, { desc = "Toggle output panel" })
vim.keymap.set("n", "<leader>tt", function()
  init()
  require("neotest").run.stop()
end, { desc = "Terminate test" })
vim.keymap.set("n", "<leader>td", function()
  init()
  require("neotest").summary.close()
  require("neotest").output_panel.close()
  require("neotest").run.run({ suite = false, strategy = "dap" })
end, { desc = "Debug nearest test" })
