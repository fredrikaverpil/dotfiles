{
  description = "Fredrik's unified Nix configurations";

  # NOTE: To eliminate substituter warnings, add your username to trusted users:
  # Edit /etc/nix/nix.conf: change "trusted-users = root" to "trusted-users = root fredrik"
  # Then restart nix daemon: sudo launchctl kickstart -k system/org.nixos.nix-daemon
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
      # NOTE: All dev shells use unstable nixpkgs, regardless of platform.
      # This intentionally diverges from the mixed-stability policy for system
      # builds (Pi = nixos-raspberrypi's pin, Darwin = unstable): dev shells
      # are for local toolchain work and benefit from latest packages on
      # every platform.
      mkDevShells = system: {
        default = unstable.${system}.mkShell {
          packages = [
            unstable.${system}.nixfmt
          ];
        };
        dotfiles-toolchain = unstable.${system}.mkShell {
          packages = [
            # Stable packages
            # stable.${system}.xxx

            # Unstable packages
            unstable.${system}.bun
            unstable.${system}.go_latest
            unstable.${system}.nodejs
            unstable.${system}.pnpm
            unstable.${system}.python3
            unstable.${system}.ruby
          ];
          shellHook = ''
            echo -e "\033[32m[dotfiles-toolchain] bun $(bun --version) | $(go version | awk '{print $1" "$3}') | lua $(lua -v 2>&1 | awk '{print $2}') | node $(node -v) (npm $(npm -v)) | pnpm $(pnpm -v) | python $(python --version | awk '{print $2}') | $(ruby -v | cut -d' ' -f1-2)\033[0m"
          '';
        };
      };
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

      # Development shells for `nix develop` or direnv's `use flake` - provides toolchains for each architecture
      devShells = {
        x86_64-linux = mkDevShells "x86_64-linux";
        aarch64-linux = mkDevShells "aarch64-linux";
        aarch64-darwin = mkDevShells "aarch64-darwin";
      };
    };
}
