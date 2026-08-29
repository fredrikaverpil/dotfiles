{ pkgs, ... }:
let
  session = {
    command = "${pkgs.hyprland}/bin/start-hyprland";
    user = "fredrik";
  };
in
{
  programs.hyprland.enable = true;

  # Autologin straight into Hyprland: no greeter UI, greetd only supplies the
  # session. greetd refuses to start without default_session, so both point at
  # the same command. SSH stays up independently, so a crashing session is
  # recoverable.
  services.greetd = {
    enable = true;
    settings = {
      initial_session = session;
      default_session = session;
    };
  };

  host.extraSystemPackages = with pkgs; [
    foot # terminal
    grim # screenshots, for verifying the session over SSH
    quickshell
  ];
}
