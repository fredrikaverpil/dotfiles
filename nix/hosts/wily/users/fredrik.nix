{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ../../../shared/home/linux.nix
    ../../../shared/home/webapps.nix
  ];

  home.stateVersion = "26.05";

  # Host-only user packages; shared ones live in nix/shared/home/.
  home.packages = with pkgs; [
    jira-cli-go
    google-cloud-sdk
  ];

  # pass-cli keeps its session key in gnome-keyring; the default kernel keyring is cleared on reboot.
  home.sessionVariables.PROTON_PASS_LINUX_KEYRING = "dbus";

  llmAgents = [ ];

  home.file = { };

  # Chromium web apps on the work profile.
  xdg.desktopEntries = {
    calendar = {
      name = "Google Calendar";
      exec = "chromium --profile-directory=Work --app=https://calendar.google.com";
      icon = ../webapps/calendar.png;
    };
    linear = {
      name = "Linear";
      exec = "chromium --profile-directory=Work --app=https://linear.app";
      icon = ../webapps/linear.png;
    };
    meet = {
      name = "Google Meet";
      exec = "chromium --profile-directory=Work --app=https://meet.google.com";
      icon = ../webapps/meet.png;
    };
    miro = {
      name = "Miro";
      exec = "chromium --profile-directory=Work --app=https://miro.com/app/dashboard/";
      icon = ../webapps/miro.png;
    };
  };

  programs = {
    # `?submodules=1` pulls in the private submodule at nix/hosts/wily/einride;
    # `inputs.self.submodules` cannot be used, it makes public clones and CI
    # try to fetch the private repo.
    nh.flake = lib.mkForce "${config.home.homeDirectory}/.dotfiles?submodules=1";
  };
}
