{
  description = "kaizen: a niri + Quickshell desktop";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs =
    { self, nixpkgs }:
    let
      forAllSystems =
        f:
        nixpkgs.lib.genAttrs [ "x86_64-linux" "aarch64-linux" ] (
          system: f nixpkgs.legacyPackages.${system}
        );
    in
    {
      nixosModules.default = ./nix/module.nix;

      packages = forAllSystems (pkgs: {
        default = pkgs.callPackage ./nix/package.nix { };
      });

      devShells = forAllSystems (pkgs: {
        default = pkgs.callPackage ./nix/devshell.nix { };
      });

      # The devshell's tasks, run against this flake's copy of the tree.
      checks = forAllSystems (
        pkgs:
        let
          shell = self.devShells.${pkgs.stdenv.hostPlatform.system}.default;
          check =
            name:
            pkgs.runCommand name {
              inherit (shell) nativeBuildInputs QML_IMPORT_PATH;
              KAIZEN_SHELL = ./shell;
            } "HOME=$TMPDIR ${name} && touch $out";
        in
        {
          qml-lint = check "qml-lint";
          qml-test = check "qml-test";
        }
      );
    };
}
