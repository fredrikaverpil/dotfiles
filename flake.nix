{
  description = "Fredrik's unified Nix configurations";

  # NOTE: To eliminate substituter warnings, add your username to trusted users:
  # Edit /etc/nix/nix.conf: change "trusted-users = root" to "trusted-users = root fredrik"
  # Then restart nix daemon: sudo launchctl kickstart -k system/org.nixos.nix-daemon
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
      stable = inputs.nixpkgs.legacyPackages;
      unstable = inputs.nixpkgs-unstable.legacyPackages;
      mkDevShells = system: {
        default = stable.${system}.mkShell {
          packages = [
            stable.${system}.nixfmt-rfc-style
          ];
        };
        dotfiles-toolchain = unstable.${system}.mkShell {
          packages = [
            # Stable packages
            # stable.${system}.xxx

            # Unstable packages
            unstable.${system}.bun
            unstable.${system}.go_1_25
            unstable.${system}.lua
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

      # Formatters for `nix fmt` - uses nixfmt-rfc-style for each architecture
      formatter.x86_64-linux = stable.x86_64-linux.nixfmt-rfc-style;
      formatter.aarch64-linux = stable.aarch64-linux.nixfmt-rfc-style;
      formatter.aarch64-darwin = unstable.aarch64-darwin.nixfmt-rfc-style;

      # Development shells for `nix develop` or direnv's `use flake` - provides toolchains for each architecture
      devShells = {
        x86_64-linux = mkDevShells "x86_64-linux";
        aarch64-linux = mkDevShells "aarch64-linux";
        aarch64-darwin = mkDevShells "aarch64-darwin";
      };
    };
}
