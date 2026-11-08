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
  options = {
    host.chromiumFeatures = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Extra Chromium --enable-features for this host";
    };
  };

  config = {
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

    xdg.mime.defaultApplications =
      lib.genAttrs [
        "image/png"
        "image/jpeg"
        "image/gif"
        "image/webp"
        "image/bmp"
        "image/tiff"
        "image/heif"
        "image/heic"
        "image/avif"
        "image/jxl"
      ] (_: "org.gnome.Loupe.desktop")
      // {
        "inode/directory" = "org.gnome.Nautilus.desktop";
      }
      // lib.genAttrs [
        "video/mp4"
        "video/webm"
        "video/x-matroska"
        "video/quicktime"
        "video/x-msvideo"
        "video/mpeg"
        "video/ogg"
        "video/3gpp"
        "video/3gpp2"
        "video/x-flv"
        "video/x-ms-wmv"
        "video/x-ms-asf"
        "video/x-ogm+ogg"
        "video/x-theora+ogg"
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

    # NOTE: Berkeley Mono is installed manually, as it requires a license.
    fonts.packages = with pkgs; [
      # GTK's default UI font (`font-name`); without it fontconfig falls back to Noto Sans.
      adwaita-fonts
      nerd-fonts.jetbrains-mono
      maple-mono.truetype
      maple-mono.variable
      nerd-fonts.symbols-only
      noto-fonts
      noto-fonts-color-emoji
    ];

    # Berkeley Mono is licensed, so it is copied into ~/.local/share/fonts by
    # hand. Both rules below name JetBrains Mono as the next candidate, so a
    # host without Berkeley Mono falls back to it instead of DejaVu.
    fonts.fontconfig.defaultFonts.monospace = [
      "Berkeley Mono Variable"
      "JetBrainsMono Nerd Font"
    ];

    # Applications that ask for JetBrains Mono by name bypass the generic
    # monospace alias. Qt resolves an installed family directly, so this rule
    # never reaches Quickshell; kaizen's Ui/Fonts.qml picks the family there
    # instead.
    fonts.fontconfig.localConf = ''
      <?xml version="1.0"?>
      <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
      <fontconfig>
        <match target="pattern">
          <test name="family"><string>JetBrainsMono Nerd Font</string></test>
          <edit name="family" mode="prepend" binding="strong">
            <string>Berkeley Mono Variable</string>
          </edit>
        </match>
      </fontconfig>
    '';

    environment.systemPackages = with pkgs; [
      alsa-utils # For Claude Code's /voice.
      # programs.niri only registers Nautilus's D-Bus services, not its launcher entry.
      # Opens folders (inode/directory) and "Show in folder" (org.freedesktop.FileManager1).
      nautilus
      sushi # Quick preview (Space); decodes with gdk-pixbuf, so no HEIC.
      ffmpegthumbnailer # Video thumbnails.
      glycin-thumbnailer # Image thumbnails, HEIC included; same decoders as Loupe.
      loupe # Opens images on double-click; see xdg.mime.defaultApplications.
      (withGnomeLibsecret gitify)
      (makeAutostartItem {
        name = "gitify";
        package = withGnomeLibsecret gitify;
      })
      gnome-calculator
      gnome-decoder
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
      mission-center
      (withGnomeLibsecret inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.claude-desktop)
      (withGnomeLibsecret proton-pass)
      proton-pass-cli
      # uwsm-app rejects the upstream entry ID, which contains a space.
      # TODO: drop once a release names its entry without a space.
      # https://github.com/ProtonMail/WebClients/issues/552
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
      spotifast
      photocraft
      pdfcraft
      zed-editor
      lumen
      hunk
    ];
  };
}
