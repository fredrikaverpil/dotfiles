{ pkgs, ... }:
{
  imports = [
    ../../../shared/home/linux.nix
    ../../../shared/home/webapps.nix
  ];

  home.stateVersion = "26.05";

  # Host-only user packages; shared ones live in nix/shared/home/.
  home.packages = with pkgs; [ ];

  # pass-cli keeps its session key in gnome-keyring; the default kernel keyring is cleared on reboot.
  home.sessionVariables.PROTON_PASS_LINUX_KEYRING = "dbus";

  llmAgents = [ ];

  home.file = { };

  programs = { };
}
