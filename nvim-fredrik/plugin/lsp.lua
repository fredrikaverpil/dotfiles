require("lazyload").on_vim_enter(function()
  vim.pack.add({
    { src = "https://github.com/neovim/nvim-lspconfig" },
    { src = "https://github.com/artemave/workspace-diagnostics.nvim" },
  })

  -- Extend LSP capabilities with blink.cmp completions for all servers.
  vim.lsp.config("*", {
    capabilities = require("blink.cmp").get_lsp_capabilities(),
  })

  local servers = {
    "bashls",
    "basedpyright",
    "buf_ls",
    "dockerls",
    "gopls",
    "graphql",
    "jsonls",
    "lua_ls",
    "nil_ls",
    "ruff",
    "rust_analyzer",
    "superhtml",
    "taplo",
    "templ",
    "terraformls",
    "ts_query_ls",
    "vtsls",
    "yamlls",
    "zls",
  }
  vim.lsp.enable(servers)

  -- Enable codelens globally
  vim.lsp.codelens.enable(true)

  vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("lsp-attach", { clear = true }),
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
        else
          require("workspace-diagnostics").populate_workspace_diagnostics(client, buf)
        end

        -- Inline completion
        if client:supports_method("textDocument/inlineCompletion", buf) then
          vim.lsp.inline_completion.enable(true)
        end

        -- Linked editing (e.g., paired HTML tags)
        if client:supports_method("textDocument/linkedEditingRange", buf) then
          vim.lsp.linked_editing_range.enable(true, { bufnr = buf })
        end

        -- Inline color swatches
        if client:supports_method("textDocument/documentColor", buf) then
          vim.lsp.document_color.enable(true, { bufnr = buf })
        end

        -- Format on typing trigger characters
        -- NOTE: I think I rather use conform.nvim as otherwise this yields unexpected results.
        -- if client:supports_method("textDocument/onTypeFormatting", buf) then
        --   vim.lsp.on_type_formatting.enable(true, { bufnr = buf })
        -- end
      end

      -- Keymaps
      -- LSP keymaps not covered by snacks picker (gd, gD, gr, gI, gt are in snacks.lua)
      vim.keymap.set("n", "K", vim.lsp.buf.hover, { buffer = buf, desc = "Hover" })
      vim.keymap.set("n", "<leader>cr", vim.lsp.buf.rename, { buffer = buf, desc = "Rename" })
      vim.keymap.set("n", "<leader>cR", Snacks.rename.rename_file, { buffer = buf, desc = "Rename file" })
      vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, { buffer = buf, desc = "Code action" })
      vim.keymap.set("n", "<leader>cc", vim.lsp.codelens.run, { buffer = buf, desc = "Run codelens" })
      vim.keymap.set({ "n", "x" }, "<M-o>", function()
        vim.lsp.buf.selection_range(1)
      end, { buffer = buf, desc = "Expand selection (LSP)" })
      vim.keymap.set("x", "<M-i>", function()
        vim.lsp.buf.selection_range(-1)
      end, { buffer = buf, desc = "Shrink selection (LSP)" })
      vim.keymap.set("n", "<leader>uh", require("toggle").inlay_hints, { buffer = buf, desc = "Toggle inlay hints" })
      vim.keymap.set("n", "<leader>ul", require("toggle").codelens, { buffer = buf, desc = "Toggle codelens" })
      vim.keymap.set("n", "[d", function()
        vim.diagnostic.jump({ count = -1 })
      end, { buffer = buf, desc = "Prev diagnostic" })
      vim.keymap.set("n", "]d", function()
        vim.diagnostic.jump({ count = 1 })
      end, { buffer = buf, desc = "Next diagnostic" })
    end,
  })

  -- Reset diagnostics and codelens on detach so :LspRestart/:LspStop don't leave stale state
  vim.api.nvim_create_autocmd("LspDetach", {
    group = vim.api.nvim_create_augroup("lsp-detach-cleanup", { clear = true }),
    callback = function(args)
      local client = vim.lsp.get_client_by_id(args.data.client_id)
      if not client then
        return
      end
      vim.diagnostic.reset(vim.lsp.diagnostic.get_namespace(client.id))
      vim.lsp.codelens.clear(client.id, args.buf)
    end,
  })

  -- LSP progress spinner
  vim.api.nvim_create_autocmd("LspProgress", {
    group = vim.api.nvim_create_augroup("lsp-progress", { clear = true }),
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
end)
