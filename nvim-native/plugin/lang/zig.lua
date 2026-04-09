vim.pack.add({
  { src = "https://github.com/lawrence-laz/neotest-zig", version = vim.version.range("1.*") },
})

require("registry").add({
  lsp = { servers = { "zls" } },
  mason = { ensure_installed = { "zls" } },
  code_runner = { opts = { filetype = { zig = { "zig run" } } } },
  neotest = {
    opts = {
      adapters = {
        {
          module = "neotest-zig",
          opts = {
            dap = { adapter = "lldb" },
          },
        },
      },
    },
  },
})
