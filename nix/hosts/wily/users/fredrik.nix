{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ../../../shared/home/linux.nix
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

  programs = {
    # `?submodules=1` pulls in the private submodule at nix/hosts/wily/einride;
    # `inputs.self.submodules` cannot be used, it makes public clones and CI
    # try to fetch the private repo.
    nh.flake = lib.mkForce "${config.home.homeDirectory}/.dotfiles?submodules=1";
  };
}
