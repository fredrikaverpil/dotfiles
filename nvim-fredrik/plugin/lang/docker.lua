require("lang").register("docker", {
  servers = { "dockerls" },
  mason = { "dockerfile-language-server", "hadolint" },
})
