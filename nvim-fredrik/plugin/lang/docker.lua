require("lang").register("docker", {
  servers = { "dockerls" },
  mason = { "dockerfile-language-server", "hadolint" },
  linters_by_ft = { dockerfile = { "hadolint" } },
})
