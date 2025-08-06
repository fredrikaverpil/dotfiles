{inputs, ...}: let
  helpers = import ./helpers.nix {inherit inputs;};
  users = import ./users.nix;
in {
  inherit
    (helpers)
    mkDarwin
    mkRpiNixos
    ;
  inherit users;
}
