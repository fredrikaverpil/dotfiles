-- Terraform: formatters and linters.

require("conform").setup({
  formatters_by_ft = {
    terraform = { "terraform_fmt" },
    tf = { "terraform_fmt" },
    ["terraform-vars"] = { "terraform_fmt" },
  },
})

require("lint").linters_by_ft.terraform = {
  "terraform_validate",
  "tflint",
  -- "trivy", -- WARNING: disabled due to 2026 security incidents
}
require("lint").linters_by_ft.tf = {
  "terraform_validate",
  "tflint",
  -- "trivy", -- WARNING: disabled due to 2026 security incidents
}
