{ pkgs, ... }:
let
  # VM-only. UTM's virgl runs on ANGLE over Metal, which exposes desktop
  # OpenGL 2.1 (GLES tops out at 3.0). Ghostty is GTK4 and sets
  # GDK_DISABLE=gles-api itself, so it demands desktop GL >= 3.3 and dies with
  # "Unable to acquire an OpenGL context". llvmpipe gives it 4.6. Hyprland is
  # unaffected — it uses GLES 3.0 — so the override is scoped to this one
  # program rather than the session. Drop it on real hardware.
  ghostty-softgl = pkgs.symlinkJoin {
    name = "ghostty-softgl";
    paths = [ pkgs.ghostty ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/ghostty --set LIBGL_ALWAYS_SOFTWARE 1
    '';
  };
in
{
  # uwsm wraps the session in systemd units so graphical-session.target is
  # actually activated, which is what the Quickshell service below binds to.
  # Running the shell as its own unit also means it can be restarted without
  # touching the compositor — useful when iterating on the QML.
  programs.hyprland = {
    enable = true;
    withUWSM = true;
  };

  # Autologin straight into Hyprland: no greeter UI, greetd only supplies the
  # session. greetd refuses to start unless default_session is set, even when
  # only initial_session is wanted. SSH stays up independently, so a crashing
  # session is recoverable.
  services.greetd = {
    enable = true;
    settings =
      let
        session = {
          command = "${pkgs.uwsm}/bin/uwsm start -F -e -D Hyprland ${pkgs.hyprland}/bin/start-hyprland";
          user = "fredrik";
        };
      in
      {
        initial_session = session;
        default_session = session;
      };
  };

  systemd.user.services.quickshell = {
    description = "Quickshell desktop shell";
    partOf = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    wantedBy = [ "graphical-session.target" ];
    # A user unit gets systemd's bare PATH, so the launcher cannot find
    # uwsm-app to start apps with.
    path = [ pkgs.uwsm ];
    serviceConfig = {
      ExecStart = "${pkgs.quickshell}/bin/quickshell";
      Restart = "on-failure";
    };
  };

  host.extraSystemPackages = with pkgs; [
    ghostty-softgl # terminal; see the let-block above
    grim # screenshots, for verifying the session over SSH
    quickshell
  ];
}
