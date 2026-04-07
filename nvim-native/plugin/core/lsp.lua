-- LSP attach behavior and keymaps.
-- Server configs live in lsp/*.lua (auto-discovered by vim.lsp.config).

vim.pack.add({
  { src = "https://github.com/neovim/nvim-lspconfig" },
})

-- Enable LSP servers (configs come from lsp/*.lua files)
vim.lsp.enable({ "lua_ls", "gopls" })

vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("native-lsp-attach", { clear = true }),
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    local buf = args.buf

    -- LSP folding (override treesitter default from init.lua)
    if client and client:supports_method("textDocument/foldingRange", buf) then
      require("fold").lsp_foldexpr(vim.api.nvim_get_current_win())
    end

    -- Keymaps
    -- LSP keymaps not covered by snacks picker (gd, gD, gr, gI, gt are in snacks.lua)
    local map = function(mode, lhs, rhs, desc)
      vim.keymap.set(mode, lhs, rhs, { buffer = buf, desc = desc })
    end
    map("n", "K", vim.lsp.buf.hover, "Hover")
    map("n", "<leader>cr", vim.lsp.buf.rename, "Rename")
    map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, "Code action")
    map("n", "<leader>uh", require("toggle").inlay_hints, "Toggle inlay hints")
    map("n", "<leader>ul", require("toggle").codelens, "Toggle codelens")
    map("n", "[d", function()
      vim.diagnostic.jump({ count = -1 })
    end, "Prev diagnostic")
    map("n", "]d", function()
      vim.diagnostic.jump({ count = 1 })
    end, "Next diagnostic")
  end,
})

-- LSP progress spinner
vim.api.nvim_create_autocmd("LspProgress", {
  ---@param ev {data: {client_id: integer, params: lsp.ProgressParams}}
  callback = function(ev)
    local spinner = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }
    vim.notify(vim.lsp.status(), vim.log.levels.INFO, {
      id = "lsp_progress",
      title = "LSP Progress",
      opts = function(notif)
        notif.icon = ev.data.params.value.kind == "end" and " "
          or spinner[math.floor(vim.uv.hrtime() / (1e6 * 80)) % #spinner + 1]
      end,
    })
  end,
})
