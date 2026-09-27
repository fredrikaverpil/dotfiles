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
# The kaizen hosts' apps, defaults and personal settings on top of the kaizen
# module (kaizen/nix/module.nix). The niri config lives in stow/kaizen/.
{
  imports = [
    inputs.dankcalendar.nixosModules.default
    ../fonts.nix
    ../../../../kaizen/nix/module.nix
    # The einride submodule sets host.notificationRules.
    (lib.mkAliasOptionModule [ "host" "notificationRules" ] [ "programs" "kaizen" "notificationRules" ])
  ];

  programs.kaizen.enable = true;

  # OAuth tokens stay in gnome-keyring (from programs.niri), unlocked by the login PAM stack.
  # Calendar credentials and feed URLs are private user state, never Nix/Stow values.
  programs.dank-calendar.enable = true;

  # gnome-keyring would also start gcr-ssh-agent as the SSH agent.
  services.gnome.gcr-ssh-agent.enable = false;
  # Nautilus's trash, network locations and removable media.
  services.gvfs.enable = true;

  # Opens port 53317 for receiving files and text from phones.
  programs.localsend.enable = true;

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

  xdg.terminal-exec.settings.default = [ "com.mitchellh.ghostty.desktop" ];

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

  # The Proton Pass app's SSH agent; the socket exists only while the app runs.
  environment.sessionVariables.SSH_AUTH_SOCK = "$HOME/.ssh/proton-pass-ssh-agent.sock";

  # Keep the upstream systemd option off: its unit orders after graphical-session.target.
  # Sync and reminders outlive the calendar window and run independently of our shell.
  systemd.user.services.dcal = {
    description = "DankCalendar sync and reminders";
    partOf = [ "graphical-session.target" ];
    after = [
      "dbus.socket"
      "kaizen-shell.service"
      "wayland-wm@niri.service"
      "wayland-session-waitenv.service"
    ];
    wantedBy = [ "wayland-session@niri.target" ];
    # NixOS pins a sparse user-unit PATH; inherit UWSM's session PATH so dcal can
    # launch its Quickshell UI and open OAuth URLs with the session's tools.
    environment.PATH = lib.mkForce null;
    # Retry indefinitely, e.g. while the keyring is not yet unlocked.
    unitConfig.StartLimitIntervalSec = 0;
    serviceConfig = {
      # dcal must see Secret Service before starting: its local keyring fallback uses a fixed password.
      # OpenSession prevents that fallback; the collection probe catches first-use keyring
      # initialization that advertises `login` without exporting it. Manually launched
      # instances bypass both probes.
      ExecStartPre = [
        "${pkgs.systemd}/bin/busctl --user --timeout=15 --quiet call org.freedesktop.secrets /org/freedesktop/secrets org.freedesktop.Secret.Service OpenSession sv plain s \"\""
        "${pkgs.systemd}/bin/busctl --user --timeout=15 --quiet get-property org.freedesktop.secrets /org/freedesktop/secrets/collection/login org.freedesktop.Secret.Collection Locked"
      ];
      ExecStart = "${lib.getExe config.programs.dank-calendar.package} run --session --hidden";
      # The UI's Quit makes the daemon SIGTERM itself and exit 0.
      Restart = "always";
      RestartSec = "2s";
      Slice = "app.slice";
      UMask = "0077";
    };
  };

  nixpkgs.overlays = [
    (final: _: {
      # NOTE: Chromium and Electron pick their secret store from XDG_CURRENT_DESKTOP and do not
      # recognise niri. They fall back to basic_text: a hardcoded key, and apps using safeStorage
      # (Claude Desktop, Signal, ente, ...) do not persist logins or secrets. Forcing
      # gnome-libsecret uses gnome-keyring instead. Adding GNOME to XDG_CURRENT_DESKTOP would
      # also work, but stops autostart entries with NotShowIn=GNOME (nm-applet, print-applet).
      # Removing the flag from an app that has migrated its secrets locks it out of them.
      # TODO: drop once Chromium/Electron detect niri or use Secret Service when present.
      # https://github.com/electron/electron/issues/39789
      # https://github.com/microsoft/vscode/issues/187338
      # https://github.com/microsoft/vscode/issues/285777
      # https://chromium.googlesource.com/chromium/src/+/main/docs/linux/password_storage.md
      withGnomeLibsecret =
        pkg:
        final.symlinkJoin {
          inherit (pkg) name;
          paths = [ pkg ];
          nativeBuildInputs = [ final.makeWrapper ];
          postBuild = ''
            for f in $out/bin/*; do
              wrapProgram "$f" --add-flags --password-store=gnome-libsecret
            done
            # Desktop entries may exec the unwrapped store path.
            shopt -s nullglob
            for f in $out/share/applications/*.desktop; do
              grep -q ${pkg} "$f" || continue
              cp --remove-destination "$(readlink -f "$f")" "$f"
              substituteInPlace "$f" --replace-quiet ${pkg} $out
            done
          '';
        };
    })
  ];

  programs.kaizen.notificationRules = [
    # Google Calendar reminders arrive from both Slack and Chromium; Chromium's
    # copy carries the buttons.
    {
      # Chromium prefixes the body with the origin.
      match = {
        app = "^Chromium$";
        body = "^calendar\\.google\\.com\\n";
      };
      critical = true;
      dedup = {
        group = "calendar";
        keep = true;
      };
    }
    # Slack titles messages from its apps "[workspace] from <app>", as it does a
    # person's. Icons are simple-icons 16.32.0 (CC0) glyphs from
    # https://cdn.jsdelivr.net/npm/simple-icons@16.32.0/icons/<slug>.svg, filled
    # with the slug's `hex` from the package's data/simple-icons.json and scaled
    # onto a white circle:
    #   <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
    #     <circle cx="12" cy="12" r="12" fill="#fff"/>
    #     <path transform="translate(5 5) scale(.5833)" fill="#<hex>" d="<path>"/>
    #   </svg>
    {
      match = {
        app = "^Slack$";
        summary = " from Google Calendar$";
      };
      critical = true;
      dedup.group = "calendar";
      icon = ./icons/google-calendar.svg;
    }
    {
      match = {
        app = "^Slack$";
        summary = " from GitHub$";
      };
      icon = ./icons/github.svg;
    }
    {
      match = {
        app = "^Slack$";
        summary = " from Linear$";
      };
      icon = ./icons/linear.svg;
    }
  ];

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
    ghostty

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
    # niri cannot mirror outputs; wl-mirror shows one in a fullscreen window.
    wl-mirror
    wtype
    (withGnomeLibsecret inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.claude-desktop)
    (withGnomeLibsecret obsidian)
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
