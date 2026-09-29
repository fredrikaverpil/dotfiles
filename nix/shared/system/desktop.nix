{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  cliamp-desktop = pkgs.makeDesktopItem {
    name = "cliamp";
    desktopName = "cliamp";
    comment = "Terminal Winamp";
    exec = "cliamp";
    terminal = true;
    categories = [
      "Audio"
      "Player"
    ];
  };
in
# Apps and defaults every desktop host wants. The desktop session (kaizen) is
# imported separately.
{
  # gnome-keyring would also start gcr-ssh-agent as the SSH agent.
  services.gnome.gcr-ssh-agent.enable = false;
  # Nautilus's trash, network locations and removable media.
  services.gvfs.enable = true;

  # Opens port 53317 for receiving files and text from phones.
  programs.localsend.enable = true;

  # CUPS on loopback only; Avahi discovers driverless (IPP Everywhere) printers.
  services.printing.enable = true;
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };
  programs.system-config-printer.enable = true;

  # KService builds Dolphin's application list from an applications menu, which only Plasma ships.
  # Plasma's own menu would pull in plasma-workspace; KService only needs every app listed.
  environment.etc."xdg/menus/applications.menu".text = ''
    <!DOCTYPE Menu PUBLIC "-//freedesktop//DTD Menu 1.0//EN"
      "http://www.freedesktop.org/standards/menu-spec/1.0/menu.dtd">
    <Menu>
      <Name>Applications</Name>
      <DefaultAppDirs/>
      <DefaultDirectoryDirs/>
      <Include><All/></Include>
    </Menu>
  '';

  xdg.mime.defaultApplications =
    lib.genAttrs [
      "image/png"
      "image/jpeg"
      "image/gif"
      "image/webp"
      "image/bmp"
      "image/tiff"
    ] (_: "imv.desktop")
    // lib.genAttrs [
      "video/mp4"
      "video/webm"
      "video/x-matroska"
      "video/quicktime"
      "video/x-msvideo"
    ] (_: "mpv.desktop")
    # Same types zen-browser's home-manager setAsDefaultBrowser claims. Firefox
    # and Chromium also claim html/xhtml/http/https; without a default either may win.
    // lib.genAttrs [
      "application/x-extension-shtml"
      "application/x-extension-xhtml"
      "application/x-extension-html"
      "application/x-extension-xht"
      "application/x-extension-htm"
      "x-scheme-handler/unknown"
      "x-scheme-handler/mailto"
      "x-scheme-handler/chrome"
      "x-scheme-handler/about"
      "x-scheme-handler/https"
      "x-scheme-handler/http"
      "application/xhtml+xml"
      "application/json"
      "text/plain"
      "text/html"
    ] (_: "zen-beta.desktop");

  environment.sessionVariables = {
    # The Proton Pass app's SSH agent; the socket exists only while the app runs.
    SSH_AUTH_SOCK = "$HOME/.ssh/proton-pass-ssh-agent.sock";
    # pass-cli keeps its session key in gnome-keyring; the default kernel keyring is cleared on reboot.
    PROTON_PASS_LINUX_KEYRING = "dbus";
  };

  systemd.user.services.gitify = {
    description = "Gitify";
    partOf = [ "graphical-session.target" ];
    # The kaizen shell hosts the StatusNotifierWatcher its tray icon registers with.
    after = [ "quickshell.service" ];
    wantedBy = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = lib.getExe' (pkgs.withGnomeLibsecret pkgs.gitify) "gitify";
      Restart = "on-failure";
      Slice = "app.slice";
    };
  };

  host.extraSystemPackages = with pkgs; [
    kdePackages.dolphin
    # Dolphin thumbnails for images and videos.
    kdePackages.kio-extras
    kdePackages.ffmpegthumbs
    # Trialled side by side with Dolphin; yazi stays the inode/directory handler.
    # programs.niri only registers Nautilus's D-Bus services, not its launcher entry.
    # Both provide org.freedesktop.FileManager1, so "Show in folder" may open either.
    nautilus
    ffmpegthumbnailer # Nautilus video thumbnails.
    sushi # Nautilus quick preview (Space).
    (withGnomeLibsecret gitify)
    gnome-calculator
    # Chromium picks its password store per desktop; switching stores drops cookies and logins.
    # The last --enable-features wins, so repeat the wrapper's WaylandWindowDecorations.
    (chromium.override {
      commandLineArgs = lib.concatStringsSep " " [
        "--no-first-run"
        "--password-store=gnome-libsecret"
        "--enable-features=${
          lib.concatStringsSep "," ([ "WaylandWindowDecorations" ] ++ config.host.chromiumFeatures)
        }"
      ];
    })
    blanket
    cliamp
    cliamp-desktop
    firefox
    inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.beta
    imv
    # Trims recordings by stream copy, without re-encoding.
    losslesscut-bin
    resources
    # The kaizen shell's system alert indicator opens it.
    mission-center
    # niri cannot mirror outputs; wl-mirror shows one in a fullscreen window.
    # TODO: add mirror controls to kaizen's Display panel.
    wl-mirror
    (withGnomeLibsecret inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.claude-desktop)
    (withGnomeLibsecret proton-pass)
    proton-pass-cli
    # uwsm-app rejects the upstream entry ID, which contains a space.
    (symlinkJoin {
      inherit (proton-authenticator) name;
      paths = [ proton-authenticator ];
      postBuild = ''
        mv "$out/share/applications/Proton Authenticator.desktop" \
          $out/share/applications/proton-authenticator.desktop
      '';
    })
    proton-vpn
    (withGnomeLibsecret signal-desktop)
    # Sluggish? Check Preferences → Advanced → "Disable hardware acceleration" is
    # unticked; ticked, Slack renders on the CPU (`--use-gl=disabled`).
    (withGnomeLibsecret slack)
    spotify
    zed-editor
  ];
}
