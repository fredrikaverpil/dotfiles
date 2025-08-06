{inputs, ...}: let
  systems = import ./systems.nix {inherit inputs;};
  users = import ./users.nix;
in {
  inherit
    (systems)
    mkDarwin
    mkRpiNixos
    ;
  inherit users;
}
