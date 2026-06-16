-- Custom filetypes for GitHub Actions and Dependabot. Registered at file scope
-- (step 11) so detection applies to the first buffer opened, not only buffers
-- opened after VimEnter.
vim.filetype.add({
  pattern = {
    [".*/%.github/dependabot.yml"] = "dependabot",
    [".*/%.github/dependabot.yaml"] = "dependabot",
    [".*/%.github/workflows[%w/]+.*%.yml"] = "gha",
    [".*/%.github/workflows/[%w/]+.*%.yaml"] = "gha",
  },
})

-- Use the yaml treesitter parser for the custom filetypes
vim.treesitter.language.register("yaml", "gha")
vim.treesitter.language.register("yaml", "dependabot")
