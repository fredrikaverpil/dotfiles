{
  description = "Fredrik's unified Nix configurations";

  # NOTE: The extra caches below are only honored for users in `trusted-users`,
  # which is set in the system config (Darwin: nix.settings.trusted-users in
  # nix/shared/system/darwin.nix; Pi: see nix/hosts/rpi5-homelab/README.md).
  # Do NOT hand-edit /etc/nix/nix.conf — nix-darwin regenerates it on rebuild.
  nixConfig = {
    extra-substituters = [
      "https://nixos-raspberrypi.cachix.org"
      "https://cache.numtide.com"
    ];
    extra-trusted-public-keys = [
      "nixos-raspberrypi.cachix.org-1:4iMO9LXa8BqhU+Rpg6LQKiGa2lsNh/j2oiYLNOQ5sPI="
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
    ];
  };

  inputs = {
    # Mixed stability approach:
    # - Raspberry Pi/NixOS: Anchored to nixos-raspberrypi's pinned nixpkgs
    #   (home-manager-rpi + disko follow that pin)
    # - Darwin/macOS: Uses unstable (nixpkgs-unstable + home-manager-unstable + nix-darwin)
    #
    # Rationale: Darwin ecosystem moves faster, benefits from latest packages.
    # The Pi has a single version anchor (the nixos-raspberrypi input), so
    # Darwin-motivated input updates cannot break the Pi, and kernel builds
    # hit the nixos-raspberrypi.cachix.org binary cache.
    #
    # Version alignment references:
    # - home-manager releases: https://github.com/nix-community/home-manager/releases
    # - Darwin state versions: https://github.com/LnL7/nix-darwin/blob/master/modules/system/default.nix

    # Stable nixpkgs: used for the Linux formatters and the `n` nix registry
    # entry — NOT for the Pi system (which uses nixos-raspberrypi's pin).
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    # nixos-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    # NOTE: Do NOT make nixos-raspberrypi follow another nixpkgs: the Pi
    # system is instantiated from its pinned nixpkgs, and the upstream binary
    # cache only serves kernels built against that pin.
    nixos-raspberrypi.url = "github:nvmd/nixos-raspberrypi/main";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixos-raspberrypi/nixpkgs";
    };
    home-manager-rpi = {
      # NOTE: The branch must match the release of nixos-raspberrypi's pinned
      # nixpkgs (check `nixpkgs.original.ref` under the nixos-raspberrypi node
      # in flake.lock). Bump this branch when updating nixos-raspberrypi.
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixos-raspberrypi/nixpkgs";
    };
    home-manager-unstable = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    # AI coding agent CLIs (codex, gemini-cli, pi, ...), updated daily upstream.
    # NOTE: Do NOT make this follow another nixpkgs: packages are built and
    # cached against its own pinned nixpkgs-unstable, and cache.numtide.com
    # only serves those builds.
    llm-agents.url = "github:numtide/llm-agents.nix";
    dotfiles = {
      # Used by home-manager for dotfiles bootstrapping.
      url = "github:fredrikaverpil/dotfiles";
      flake = false;
    };
  };

  outputs =
    { self, ... }@inputs:
    let
      lib = import ./nix/lib { inherit inputs; };
      stable = inputs.nixpkgs.legacyPackages;
      unstable = inputs.nixpkgs-unstable.legacyPackages;
    in
    {
      overlays.default = import ./nix/shared/overlays;
      nixosConfigurations = {
        rpi5-homelab = lib.mkRpiNixos {
          configPath = ./nix/hosts/rpi5-homelab/configuration.nix;
        };
        # Example standard NixOS configuration:
        # my-server = lib.mkNixos {
        #   configPath = ./nix/hosts/my-server/configuration.nix;
        # };
      };

      darwinConfigurations = {
        zap = lib.mkDarwin {
          configPath = ./nix/hosts/zap/configuration.nix;
        };
        plumbus = lib.mkDarwin {
          configPath = ./nix/hosts/plumbus/configuration.nix;
        };
      };

      # Formatters for `nix fmt` - uses nixfmt for each architecture
      formatter.x86_64-linux = stable.x86_64-linux.nixfmt;
      formatter.aarch64-linux = stable.aarch64-linux.nixfmt;
      formatter.aarch64-darwin = unstable.aarch64-darwin.nixfmt;

      # Dev shell exposing the shared Neovim toolchain (nix/shared/toolchain.nix)
      # for use outside Neovim, e.g. `nix develop ~/.dotfiles#dev -c <cmd>`.
      devShells =
        let
          mkDevShell =
            system:
            let
              channels = {
                stable = stable.${system};
                unstable = unstable.${system};
              };
            in
            {
              dev = channels.unstable.mkShell {
                packages =
                  (import ./nix/shared/toolchain.nix channels)
                  # Linux: nixpkgs replacements for Mason's prebuilt binaries,
                  # which fail on NixOS (stub-ld, no nix-ld). Unstable-only, so
                  # the whole devshell resolves to one nixpkgs generation — the
                  # same nixpkgs-unstable as the shared toolchain (and Neovim's
                  # nvim-deps-path). Reference each entry fully qualified as
                  # `channels.unstable.<name>`: a bare `with unstable;` would
                  # bind to the flake's top-level `unstable` (the by-system
                  # legacyPackages set) and break with `undefined variable`.
                  # Grow this list over time.
                  ++ channels.unstable.lib.optionals channels.unstable.stdenv.isLinux [
                    channels.unstable.gopls
                  ];
                # macOS: Mason binaries are native Mach-O — put them on PATH so
                # the devshell reaches the same tooling Neovim uses.
                shellHook = channels.unstable.lib.optionalString channels.unstable.stdenv.isDarwin ''
                  export PATH="$HOME/.local/share/nvim-fredrik/mason/bin:$PATH"
                '';
              };
            };
        in
        {
          x86_64-linux = mkDevShell "x86_64-linux";
          aarch64-linux = mkDevShell "aarch64-linux";
          aarch64-darwin = mkDevShell "aarch64-darwin";
        };
    };
}
