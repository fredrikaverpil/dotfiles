# This file contains system-level settings that are common
# across all hosts (macOS and Linux).

{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    bandwhich # Network monitoring tool (cross-platform alternative to iftop)
    gzip # Compression utility (needed for backup scripts)
  ];
}
