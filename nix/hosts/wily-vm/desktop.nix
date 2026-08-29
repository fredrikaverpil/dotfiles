{ pkgs, ... }:
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
    serviceConfig = {
      ExecStart = "${pkgs.quickshell}/bin/quickshell";
      Restart = "on-failure";
    };
  };

  host.extraSystemPackages = with pkgs; [
    ghostty # terminal
    grim # screenshots, for verifying the session over SSH
    quickshell
  ];
}
