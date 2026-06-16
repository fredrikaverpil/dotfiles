require("lang").register("terraform", {
  servers = { "terraformls" },
  mason = { "terraform-ls", "tflint" },
  linters_by_ft = {
    terraform = { "terraform_validate", "tflint" },
    tf = { "terraform_validate", "tflint" },
  },
})
