vim.pack.add({
  { src = "https://github.com/neovim/nvim-lspconfig" },
})

require("defer").on_ui_enter(function()
  local registry = require("registry")

  -- Extend LSP capabilities with blink.cmp completions for all servers
  vim.lsp.config("*", {
    capabilities = require("blink.cmp").get_lsp_capabilities(),
  })

  vim.lsp.enable(registry.lsp_servers)

  -- Enable codelens globally
  vim.lsp.codelens.enable(true)

  vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("native-lsp-attach", { clear = true }),
    callback = function(args)
      local client = vim.lsp.get_client_by_id(args.data.client_id)
      local buf = args.buf

      if client then
        -- Disable codelens for lua (lua_ls "0 References" is noisy)
        if client.name == "lua_ls" then
          vim.lsp.codelens.enable(false, { bufnr = buf })
        end

        -- LSP folding (override treesitter default from init.lua)
        if client:supports_method("textDocument/foldingRange", buf) then
          require("fold").lsp_foldexpr(vim.api.nvim_get_current_win())
        end

        -- Workspace diagnostics
        if client:supports_method("workspace/diagnostic", buf) then
          vim.lsp.buf.workspace_diagnostics({ client_id = client.id })
        end

        -- Inline completion
        if client:supports_method("textDocument/inlineCompletion", buf) then
          vim.lsp.inline_completion.enable(true)
        end
      end

      -- Keymaps
      -- LSP keymaps not covered by snacks picker (gd, gD, gr, gI, gt are in snacks.lua)
      local map = function(mode, lhs, rhs, desc)
        vim.keymap.set(mode, lhs, rhs, { buffer = buf, desc = desc })
      end
      map("n", "K", vim.lsp.buf.hover, "Hover")
      map("n", "<leader>cr", vim.lsp.buf.rename, "Rename")
      map("n", "<leader>cR", Snacks.rename.rename_file, "Rename file")
      map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, "Code action")
      map("n", "<leader>cc", vim.lsp.codelens.run, "Run codelens")
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

  -- Override :LspRestart (from nvim-lspconfig) to also clear diagnostics and codelens.
  -- nvim-lspconfig's version just does disable → timer → enable; this adds cleanup
  -- to fix "sticky" diagnostics and codelens from the old client instance.
  vim.api.nvim_create_user_command("LspRestart", function(args)
    local names = {}
    if args.args ~= "" then
      names = { args.args }
    else
      for _, client in ipairs(vim.lsp.get_clients()) do
        if not vim.tbl_contains(names, client.name) then
          table.insert(names, client.name)
        end
      end
    end

    for _, client in ipairs(vim.lsp.get_clients()) do
      if vim.tbl_contains(names, client.name) then
        vim.diagnostic.reset(vim.api.nvim_create_namespace("vim.lsp." .. client.name .. "." .. client.id))
        vim.lsp.codelens.enable(false, { client_id = client.id })
        if args.bang then
          client:stop(true)
        end
      end
    end

    for _, name in ipairs(names) do
      vim.lsp.enable(name, false)
    end

    local timer = assert(vim.uv.new_timer())
    timer:start(500, 0, function()
      vim.schedule(function()
        for _, name in ipairs(names) do
          vim.lsp.enable(name)
        end
      end)
    end)
  end, {
    nargs = "?",
    bang = true,
    complete = function()
      local names = {}
      for _, client in ipairs(vim.lsp.get_clients()) do
        if not vim.tbl_contains(names, client.name) then
          table.insert(names, client.name)
        end
      end
      return names
    end,
    desc = "Restart LSP clients and clear diagnostics/codelens",
  })
end)
