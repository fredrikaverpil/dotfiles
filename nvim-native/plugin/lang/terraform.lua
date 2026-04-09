require("registry").add({
  lsp_servers = { "terraformls" },
  mason_ensure_installed = { "terraform-ls", "tflint" },
  conform = {
    formatters_by_ft = {
      terraform = { "terraform_fmt" },
      tf = { "terraform_fmt" },
      ["terraform-vars"] = { "terraform_fmt" },
    },
  },
  lint = {
    linters_by_ft = {
      terraform = {
        "terraform_validate",
        "tflint",
        -- "trivy", -- WARNING: disabled due to 2026 security incidents
      },
      tf = {
        "terraform_validate",
        "tflint",
        -- "trivy", -- WARNING: disabled due to 2026 security incidents
      },
    },
  },
})
