local M = {}

local loaded_clients = {}

--- Populate workspace-wide diagnostics for an LSP client.
---
--- For servers that support the `workspace/diagnostic` pull method, uses the
--- native Neovim API.  For all others, falls back to sending
--- `textDocument/didOpen` for every git-tracked file that matches the client's
--- filetypes so the server pushes `publishDiagnostics` for the whole workspace.
---
---@param client vim.lsp.Client
---@param bufnr integer
function M.populate(client, bufnr)
  if loaded_clients[client.id] then
    return
  end
  loaded_clients[client.id] = true

  if client:supports_method("workspace/diagnostic", bufnr) then
    vim.lsp.buf.workspace_diagnostics({ client_id = client.id })
    return
  end

  local filetypes = client.config.filetypes
  if not filetypes or #filetypes == 0 then
    return
  end

  local cwd = vim.fn.getcwd()
  local handle = io.popen("git -C " .. vim.fn.shellescape(cwd) .. " ls-files 2>/dev/null")
  if not handle then
    return
  end
  local output = handle:read("*a")
  handle:close()

  local current_file = vim.api.nvim_buf_get_name(bufnr)

  for line in output:gmatch("[^\n]+") do
    local path = cwd .. "/" .. line
    if path ~= current_file and vim.fn.filereadable(path) == 1 then
      local ft = vim.filetype.match({ filename = path })
      if ft and vim.tbl_contains(filetypes, ft) then
        vim.defer_fn(function()
          local text = table.concat(vim.fn.readfile(path), "\n")
          client:notify("textDocument/didOpen", {
            textDocument = {
              uri = vim.uri_from_fname(path),
              version = 0,
              text = text,
              languageId = ft,
            },
          })
        end, 0)
      end
    end
  end
end

return M
