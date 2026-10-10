{ pkgs, inputs, ... }:
let
  unstable = inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system};
in
{
  imports = [
    ../../../shared/home/linux.nix
    ../../../shared/home/linux-desktop.nix
  ];

  home.stateVersion = "26.05";

  # Never miss a message from family.
  kaizen.notificationRules = [
    {
      match = {
        app = "^Signal$";
        summary = " Averpil$";
      };
      urgency = "critical";
      border = "rose";
      borderAnimation = "glow";
      badgeEmoji = "❤️";
    }
  ];

  # Host-only user packages; shared ones live in nix/shared/home/.
  home.packages = with pkgs; [
    # Newer than nixpkgs; drop once NixOS/nixpkgs#572220 lands.
    (unstable.wrapNeovim (unstable.neovim-unwrapped.overrideAttrs (old: {
      version = "0.12.6";
      src = old.src.override {
        hash = "sha256-lK1gbJyESMN3C/i8cyPFzzlJDYZHzEXugGhCwPVEbNk=";
      };
    })) { })
  ];

  llmAgents = [ ];

  home.file = { };

  programs = { };
}
