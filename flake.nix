{
  description = "Fredrik's unified Nix configurations";

  nixConfig = {
    extra-substituters = [
      "https://nixos-raspberrypi.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nixos-raspberrypi.cachix.org-1:4iMO9LXa8BqhU+Rpg6LQKiGa2lsNh/j2oiYLNOQ5sPI="
    ];
  };

  inputs = {
    # Mixed stability approach:
    # - Linux/NixOS: Uses stable (nixos-25.05 + home-manager/release-25.05)
    # - Darwin/macOS: Uses unstable (nixpkgs-unstable + home-manager-unstable + nix-darwin)
    #
    # Rationale: Darwin ecosystem moves faster, benefits from latest packages.
    # Linux systems prioritize stability.
    #
    # Version alignment references:
    # - home-manager releases: https://github.com/nix-community/home-manager/releases
    # - Darwin state versions: https://github.com/LnL7/nix-darwin/blob/master/modules/system/default.nix

    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    # nixos-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    nixos-raspberrypi.url = "github:nvmd/nixos-raspberrypi/main";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager-unstable = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
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

      formatter.x86_64-linux = inputs.nixpkgs.legacyPackages.x86_64-linux.nixfmt-rfc-style;
      formatter.aarch64-linux = inputs.nixpkgs.legacyPackages.aarch64-linux.nixfmt-rfc-style;
      formatter.aarch64-darwin = inputs.nixpkgs-unstable.legacyPackages.aarch64-darwin.nixfmt-rfc-style;

      devShells = {
        x86_64-linux = {
          default = inputs.nixpkgs.legacyPackages.x86_64-linux.mkShell {
            packages = [
              inputs.nixpkgs.legacyPackages.x86_64-linux.nixfmt-rfc-style
            ];
          };
          pkgxReplacement = inputs.nixpkgs.legacyPackages.x86_64-linux.mkShell {
            packages = with inputs.nixpkgs.legacyPackages.x86_64-linux; [
              ruby
              nodejs
              pnpm
              bun
              python3
              go
              lua5_4
            ];
            shellHook = ''
              # echo "[pkgxReplacement] ruby $(ruby -v | cut -d' ' -f1-2) | node $(node -v) (npm $(npm -v)) | pnpm $(pnpm -v) | bun $(bun --version) | python $(python --version | awk '{print $2}') | $(go version | awk '{print $1" "$3}') | lua $(lua -v 2>&1 | awk '{print $2}')"
            '';
          };
        };
        aarch64-linux = {
          default = inputs.nixpkgs.legacyPackages.aarch64-linux.mkShell {
            packages = [
              inputs.nixpkgs.legacyPackages.aarch64-linux.nixfmt-rfc-style
            ];
          };
          pkgxReplacement = inputs.nixpkgs.legacyPackages.aarch64-linux.mkShell {
            packages = with inputs.nixpkgs.legacyPackages.aarch64-linux; [
              ruby
              nodejs
              pnpm
              bun
              python3
              go
              lua5_4
            ];
            shellHook = ''
              # echo "[pkgxReplacement] ruby $(ruby -v | cut -d' ' -f1-2) | node $(node -v) (npm $(npm -v)) | pnpm $(pnpm -v) | bun $(bun --version) | python $(python --version | awk '{print $2}') | $(go version | awk '{print $1" "$3}') | lua $(lua -v 2>&1 | awk '{print $2}')"
            '';
          };
        };
        aarch64-darwin = {
          default = inputs.nixpkgs-unstable.legacyPackages.aarch64-darwin.mkShell {
            packages = [
              inputs.nixpkgs-unstable.legacyPackages.aarch64-darwin.nixfmt-rfc-style
            ];
          };
          pkgxReplacement = inputs.nixpkgs-unstable.legacyPackages.aarch64-darwin.mkShell {
            packages = with inputs.nixpkgs-unstable.legacyPackages.aarch64-darwin; [
              ruby
              nodejs
              pnpm
              bun
              python3
              go
              lua5_4
            ];
            shellHook = ''
              # echo "[pkgxReplacement] ruby $(ruby -v | cut -d' ' -f1-2) | node $(node -v) (npm $(npm -v)) | pnpm $(pnpm -v) | bun $(bun --version) | python $(python --version | awk '{print $2}') | $(go version | awk '{print $1" "$3}') | lua $(lua -v 2>&1 | awk '{print $2}')"
            '';
          };
        };
      };
    };
}
