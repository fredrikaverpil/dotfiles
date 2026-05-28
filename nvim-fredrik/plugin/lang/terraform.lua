require("lang").register("terraform", {
  servers = { "terraformls" },
  mason = { "terraform-ls", "tflint" },
  formatters_by_ft = {
    terraform = { "terraform_fmt" },
    ["terraform-vars"] = { "terraform_fmt" },
    tf = { "terraform_fmt" },
  },
  linters_by_ft = {
    terraform = { "terraform_validate", "tflint" },
    tf = { "terraform_validate", "tflint" },
  },
})
