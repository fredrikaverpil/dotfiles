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
    # Rationale: Darwin ecosystem moves faster, benefits from latest packages
    # Linux systems (especially Pi) prioritize stability
    #
    # Version alignment references:
    # - home-manager releases: https://github.com/nix-community/home-manager/releases
    # - Darwin state versions: https://github.com/LnL7/nix-darwin/blob/master/modules/system/default.nix
    
    # Stable nixpkgs for Linux/NixOS systems
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    # Unstable nixpkgs for macOS/Darwin systems  
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    # Unstable nixos (currently unused - available for future Linux systems)
    nixos-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    
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
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    dotfiles = {
      url = "github:fredrikaverpil/dotfiles";
      flake = false;
      # Used by home-manager for dotfiles bootstrapping and git submodule init
    };
  };

  outputs = { self, ... }@inputs:
    let
      lib = import ./nix/lib { inherit inputs; };
    in
    {
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

      formatter.x86_64-linux = inputs.nixpkgs.legacyPackages.x86_64-linux.nixfmt;
      formatter.aarch64-darwin = inputs.nixpkgs-unstable.legacyPackages.aarch64-darwin.nixfmt;

      devShells = {
        x86_64-linux.default = inputs.nixpkgs.legacyPackages.x86_64-linux.mkShell {
          packages = [
            inputs.nixpkgs.legacyPackages.x86_64-linux.nixfmt
          ];
        };
      };
    };
}
