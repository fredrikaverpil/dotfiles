# Personal-machine only; a work host imports desktop.nix without this file.
{ pkgs, ... }:
{
  # ente-desktop pins EOL electron; drop once nixpkgs bumps it.
  nixpkgs.config.permittedInsecurePackages = [ "electron-41.10.6" ];

  host.extraSystemPackages = with pkgs; [
    ente-desktop
  ];
}
