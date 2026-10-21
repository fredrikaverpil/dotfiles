# This file contains system-level settings that are common
# across all hosts (macOS and Linux).
{
  pkgs,
  inputs,
  ...
}:
{
  environment.systemPackages = with pkgs; [
  ];

  # eMudhra intermediate CA compromise (CVE-2026-111943).
  # Mirrors the list nixpkgs now appends in nixos/modules/security/ca.nix,
  # which the locked revisions lack.
  # https://github.com/NixOS/nixpkgs/issues/576485
  security.pki.caCertificateBlacklist = [
    "Comodo AAA Services root"
    "emSign ECC Root CA - G3"
    "emSign Root CA - C1"
    "emSign ECC Root CA - C3"
  ];

  # Nix registry for easy access to stable and unstable packages
  #
  # Example usage:
  # nix shell u#neovim
  # nix run u#nodejs_22 -- --version
  #
  nix.registry = {
    n.to = {
      type = "path";
      path = inputs.nixpkgs;
    };
    u.to = {
      type = "path";
      path = inputs.nixpkgs-unstable;
    };
  };
}
