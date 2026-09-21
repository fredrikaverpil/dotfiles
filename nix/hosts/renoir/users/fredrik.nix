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

  # Sets SSH_AUTH_SOCK in systemd and D-Bus; the stowed zsh config does not use its shell hook.
  services.proton-pass-agent.enable = true;
  systemd.user.services.proton-pass-agent.Service.Environment = [
    "PROTON_PASS_LINUX_KEYRING=dbus"
  ];

  llmAgents = [ ];

  home.file = { };

  xdg.desktopEntries.calendar = {
    name = "Google Calendar";
    exec = "chromium --profile-directory=Default --app=https://calendar.google.com";
    icon = ../../../shared/home/webapps/calendar.png;
  };

  programs = { };
}
