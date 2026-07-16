{inputs, ...}: {
  # LLM services for rpi5-homelab:
  # - ollama serves local models over an OpenAI-compatible API
  # - Hermes Agent (NousResearch) runs as a systemd service and can talk to
  #   Anthropic/OpenAI or the local ollama endpoint
  #
  # See nix/hosts/rpi5-homelab/README.md ("Hermes Agent + local LLM") for the
  # one-time secrets setup and usage/access instructions.
  imports = [inputs.hermes-agent.nixosModules.default];

  # ========================================================================
  # LOCAL LLM SERVING (OLLAMA)
  # ========================================================================
  # OpenAI-compatible endpoint at http://<host>:11434/v1
  services.ollama = {
    enable = true;
    # Bind to all interfaces so other Tailscale machines can use the endpoint
    # (tailscale+ is a trusted firewall interface). NOT reachable from the
    # LAN/internet: port 11434 is deliberately not in allowedTCPPorts.
    host = "0.0.0.0";
    port = 11434;
    # Models pulled automatically when the service starts. Pick small models:
    # CPU-only inference on the Pi 5 (16 GB) is a few tokens/s at these sizes.
    loadModels = ["qwen3:4b"];
    environmentVariables = {
      # Hermes recommends >= 64k context, but CPU-only prefill and KV-cache
      # memory make that impractical on the Pi; 16k is a usable compromise
      # for short local-model sessions.
      OLLAMA_CONTEXT_LENGTH = "16384";
    };
  };

  # ========================================================================
  # HERMES AGENT
  # ========================================================================
  # Runs the gateway as hermes:hermes with state in /var/lib/hermes.
  # Managed mode: `hermes setup` / `hermes config set` are disabled on the
  # host — configuration lives here instead.
  services.hermes-agent = {
    enable = true;

    # Put the `hermes` CLI on every user's PATH and set HERMES_HOME globally,
    # so `ssh fredrik@rpi5-homelab` + `hermes` attaches to the service state.
    addToSystemPackages = true;

    # Native Anthropic API support (otherwise Anthropic models go through the
    # OpenAI-compatible fallback). Add "messaging" here to enable the
    # Telegram/Discord/Slack gateway extras.
    extraDependencyGroups = ["anthropic"];

    # Deep-merged into $HERMES_HOME/config.yaml. ${VAR} references resolve
    # from $HERMES_HOME/.env at runtime (see environmentFiles below), so no
    # secrets end up in the nix store.
    settings = {
      model = {
        # Daily driver. Switch per-session with `/model`, e.g.
        # `/model openai/gpt-5` or a local ollama model.
        provider = "anthropic";
        default = "claude-sonnet-5";
      };
      providers = {
        anthropic.api_key = "\${ANTHROPIC_API_KEY}";
        openai.api_key = "\${OPENAI_API_KEY}";
        # Local models served by ollama on this host.
        local = {
          base_url = "http://127.0.0.1:11434/v1";
          api_key = "ollama"; # any non-empty value; ollama ignores it
        };
      };
    };

    # API keys live outside the repo and the nix store, same pattern as
    # /etc/cloudflared/tunnel.json. A missing file is skipped at activation,
    # so the first rebuild succeeds before the secrets exist.
    environmentFiles = ["/etc/hermes/secrets.env"];
  };
}
