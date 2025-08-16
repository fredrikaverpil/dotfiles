{ inputs, ... }:
let
  systems = import ./systems.nix { inherit inputs; };
  users = import ./users.nix;
  npmModule = import ./npm.nix;
in
{
  inherit (systems)
    mkDarwin
    mkRpiNixos
    ;
  inherit users npmModule;
}
