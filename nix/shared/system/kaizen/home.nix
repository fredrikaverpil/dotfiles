{ lib, pkgs, ... }:
let
  # The shell's emoji data, found as share/kaizen/emoji.json in the XDG data dirs.
  emoji =
    pkgs.runCommand "kaizen-emoji"
      {
        nativeBuildInputs = [ pkgs.jq ];
        names = "${pkgs.unicode-emoji}/share/unicode/emoji/emoji-test.txt";
        shortcodes = pkgs.fetchurl {
          url = "https://raw.githubusercontent.com/iamcal/emoji-data/v16.0.0/emoji.json";
          hash = "sha256-HWAuZb6Idyv4zDaM4WuFXXGe7duv4SjUcbgCA/SU0p8=";
        };
      }
      ''
        mkdir -p $out/share/kaizen
        bash ${../../../../stow/kaizen/.local/bin/kaizen-emoji} "$names" "$shortcodes" > $out/share/kaizen/emoji.json
      '';

  # qtimageformats supplies Quickshell's WebP decoder.
  quickshell = pkgs.symlinkJoin {
    inherit (pkgs.quickshell) name meta;
    paths = [ pkgs.quickshell ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      for bin in $out/bin/*; do
        wrapProgram "$bin" --prefix QT_PLUGIN_PATH : ${pkgs.qt6.qtimageformats}/lib/qt-6/plugins
      done
    '';
  };
in
# The packages and data the kaizen session's shell, binds, scripts and units
# use. A home-manager module, so it also runs on a distro other than NixOS;
# session.nix holds the system half and adds this module to every home-manager
# user. Units, scripts, compositor config, QML and notification rules live in
# stow/kaizen/.
{
  config = {
    home.packages = with pkgs; [
      # The wrapper above (let outranks with); the shell's unit finds it on PATH.
      # Wins over the plain quickshell the calendar's module installs.
      (lib.hiPrio quickshell)
      # niri's terminal binds and xdg-terminal-exec open it.
      ghostty
      # Nightlight: drives zwlr_gamma_control_v1, so it is compositor-agnostic.
      wl-gammarelay-rs
      libnotify
      sound-theme-freedesktop
      kdePackages.kconfig
      gnome-themes-extra
      # Cursor theme for niri, GTK and Qt; without one niri draws a fixed 64px fallback.
      bibata-cursors
      iproute2
      iputils
      bluetui
      emoji
      grim
      imagemagick # Wallpaper thumbnails.
      jq # The clipboard watcher's JSON encoding, kaizen-focus and kaizen-log.
      mpv
      # nm-connection-editor edits wired, static-IP and other connection settings;
      # the network panel launches it. nm-applet runs via XDG autostart for its tray menu.
      networkmanagerapplet
      # Annotates screenshots from the notification's Edit action.
      satty
      wl-clipboard
      # niri cannot mirror outputs; the mirror service runs it fullscreen on the target.
      wl-mirror
    ];
  };
}
