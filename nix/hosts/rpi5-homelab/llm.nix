{
  pkgs,
  inputs,
  ...
}: let
  unstable = inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system};
  # Ternary Bonsai 27B (PrismML): 27B-class model in ternary {-1,0,+1}
  # weights at ~1.71 bits/weight — a ~7.2 GB GGUF that fits the Pi's 16 GB
  # alongside the other homelab services. https://prismml.com/news/bonsai-27b
  # Downloaded manually (see README), not fetched by nix: 7 GB doesn't
  # belong in the store, and HF quant filenames churn.
  bonsaiModel = "/var/lib/llama-cpp/ternary-bonsai-27b.gguf";
in {
  # LLM services for rpi5-homelab:
  # - llama.cpp serves Ternary Bonsai 27B over an OpenAI-compatible API
  # - Hermes Agent (NousResearch) runs as a systemd service and can talk to
  #   Anthropic/OpenAI or the local llama.cpp endpoint
  #
  # See nix/hosts/rpi5-homelab/README.md ("Hermes Agent + local LLM") for the
  # one-time secrets/model setup and usage/access instructions.
  imports = [inputs.hermes-agent.nixosModules.default];

  # ========================================================================
  # LOCAL LLM SERVING (LLAMA.CPP + TERNARY BONSAI 27B)
  # ========================================================================
  # OpenAI-compatible endpoint at http://<host>:8080/v1
  services.llama-cpp = {
    enable = true;
    # Ternary Q2_0 GGUFs need a recent llama.cpp; the Pi's pinned nixpkgs is
    # too old. App-level package from unstable is fine — the base system
    # (kernel/cache) anchoring is unaffected.
    package = unstable.llama-cpp;
    model = bonsaiModel;
    # Bind to all interfaces so other Tailscale machines can use the endpoint
    # (tailscale+ is a trusted firewall interface). NOT reachable from the
    # LAN/internet: port 8080 is deliberately not in allowedTCPPorts.
    host = "0.0.0.0";
    port = 8080;
    extraFlags = [
      # Hermes recommends >= 64k context (Bonsai supports 262k), but KV-cache
      # RAM (~3 GB f16 at 16k) and CPU-only prefill make that impractical
      # here; 16k is a usable compromise. If RAM gets tight next to
      # Immich/Jellyfin, quantize the KV cache (--cache-type-k/-v q8_0).
      "--ctx-size"
      "16384"
      # Use the model's chat template so tool/function calling works (Hermes
      # drives everything through tool calls).
      "--jinja"
      # Stable model id, referenced from Hermes config below.
      "--alias"
      "bonsai-27b"
    ];
  };

  # Don't crash-loop before the model file has been downloaded (same pattern
  # as cloudflared's ConditionPathExists on the tunnel token).
  systemd.services.llama-cpp.unitConfig.ConditionPathExists = bonsaiModel;

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
        # Ternary Bonsai 27B ("bonsai-27b") served by llama.cpp on this host.
        local = {
          base_url = "http://127.0.0.1:8080/v1";
          api_key = "none"; # llama-server runs without an API key
        };
      };
    };

    # API keys live outside the repo and the nix store, same pattern as
    # /etc/cloudflared/tunnel.json. A missing file is skipped at activation,
    # so the first rebuild succeeds before the secrets exist.
    environmentFiles = ["/etc/hermes/secrets.env"];
  };
}
