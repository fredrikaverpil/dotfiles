# `nix run`: kaizen from a console login, without the NixOS module. The host
# must have uwsm's user units (NixOS `programs.uwsm.enable`). The shell runs as
# kaizen-trial.service, so a masked kaizen-shell.service cannot block it.
{
  lib,
  writeShellApplication,
  linkFarm,
  makeFontsConf,
  kaizen,
  niri,
  quickshell,
  xwayland-satellite,
  xdg-terminal-exec,
  nerd-fonts,
  noto-fonts-color-emoji,
}:
let
  # `quickshell -c kaizen` searches XDG_CONFIG_DIRS; ~/.config/quickshell/kaizen
  # takes precedence.
  xdg = linkFarm "kaizen-xdg" { "quickshell/kaizen" = "${kaizen}/share/kaizen/shell"; };

  # The shell's fonts on top of the host's, for the shell only.
  fonts = makeFontsConf {
    fontDirectories = [
      nerd-fonts.jetbrains-mono
      nerd-fonts.symbols-only
      noto-fonts-color-emoji
    ];
  };
in
writeShellApplication {
  name = "kaizen-trial";
  runtimeInputs = [
    kaizen
    niri
    quickshell
    xwayland-satellite
    xdg-terminal-exec
  ];
  # uwsm exports the caller's environment to the session; niri reads
  # NIRI_CONFIG, and so does the shell's keybindings list.
  text = ''
    # Its parent is this script, not the login shell.
    uwsm check may-start -i
    # The module's StateDirectory creates it when installed.
    mkdir -p "''${XDG_STATE_HOME:-$HOME/.local/state}/kaizen-shell"
    export XDG_CONFIG_DIRS="${xdg}:''${XDG_CONFIG_DIRS:-/etc/xdg}"
    export NIRI_CONFIG=${kaizen}/share/kaizen/niri/trial.kdl
    exec uwsm start -e -D niri -- niri --session -- \
      uwsm-app -t service -u kaizen-trial.service -- \
      env FONTCONFIG_FILE=${fonts} ${lib.getExe' kaizen "kaizen-shell"}
  '';
}
