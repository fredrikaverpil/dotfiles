require("lazyload").on_vim_enter(function()
  vim.g.auto_format = true

  vim.pack.add({
    { src = "https://github.com/stevearc/conform.nvim" },
  })

  require("conform").setup({
    format_on_save = function()
      if not vim.g.auto_format then
        return
      end
      return { timeout_ms = 5000, lsp_format = "fallback" }
    end,
    formatters_by_ft = {
      dependabot = { "yamlfmt" },
      elixir = { "mix" },
      gha = { "yamlfmt" },
      go = { "goimports", "gci", "gofumpt", "golines" },
      heex = { "mix" },
      javascript = { "prettier" },
      javascriptreact = { "prettier" },
      json = { "biome" },
      json5 = { "biome" },
      jsonc = { "biome" },
      lua = { "stylua" },
      markdown = { "rumdl" },
      nix = { "nixfmt" },
      proto = { "buf" },
      sh = { "shfmt" },
      terraform = { "terraform_fmt" },
      ["terraform-vars"] = { "terraform_fmt" },
      tf = { "terraform_fmt" },
      typescript = { "prettier" },
      typescriptreact = { "prettier" },
      yaml = { "yamlfmt" },
    },
    formatters = {
      biome = {
        args = { "format", "--indent-style", "space", "--stdin-file-path", "$FILENAME" },
      },
      gci = {
        args = { "write", "--skip-generated", "-s", "standard", "-s", "default", "--skip-vendor", "$FILENAME" },
      },
      gofumpt = {
        prepend_args = { "-extra", "-w", "$FILENAME" },
        stdin = false,
      },
      goimports = {
        args = { "-srcdir", "$FILENAME" },
      },
      golines = {
        prepend_args = { "--base-formatter=gofumpt", "--ignore-generated", "--tab-len=1", "--max-len=120" },
      },
      prettier = {
        prepend_args = { "--prose-wrap", "always", "--print-width", "80", "--tab-width", "2" },
      },
      rumdl = {
        prepend_args = { "--config", "MD013.line-length = 80", "--config", "MD013.reflow = true" },
      },
      yamlfmt = {
        prepend_args = {
          "-formatter",
          "retain_line_breaks_single=true",
          "-formatter",
          "pad_line_comments=2",
        },
      },
    },
  })

  vim.keymap.set("n", "<leader>uf", function()
    vim.g.auto_format = not vim.g.auto_format
    vim.notify("Auto-format: " .. (vim.g.auto_format and "on" or "off"))
  end, { desc = "Toggle auto-format" })
end)
