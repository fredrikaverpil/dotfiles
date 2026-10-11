# Combines all overlays into a single overlay function
final: prev: {
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
}
# Add other overlays here as needed by merging their results
# // (import ./other-overlay.nix final prev)
