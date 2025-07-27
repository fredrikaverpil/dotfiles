# This file contains system-level settings that are common
# across all hosts (macOS and Linux).

{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # Add common packages here
  ];
}
