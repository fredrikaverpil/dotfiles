# This file contains system-level settings specific to Linux/NixOS systems.

{ config, pkgs, lib, inputs, ... }:

{
  # Basic NixOS system settings
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Enable zsh system-wide
  programs.zsh.enable = true;

  # System-level packages (very few)
  environment.systemPackages = with pkgs; [
    vim # for recovery
  ];

  # Nix registry for easy access to stable and unstable packages
  # Note: This would require inputs to be passed as specialArgs
  # nix.registry = {
  #   n.to = {
  #     type = "path";
  #     path = inputs.nixpkgs;
  #   };
  #   u.to = {
  #     type = "path";
  #     path = inputs.nixos-unstable;
  #   };
  # };

  # Font management
  fonts.packages = with pkgs; [
    nerd-fonts.fira-code
    nerd-fonts.fira-mono
    nerd-fonts.hack
    nerd-fonts.jetbrains-mono
    maple-mono.NF
    noto-fonts-emoji
    nerd-fonts.symbols-only
  ];
}
