{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
let
  unstable = inputs.nixpkgs-unstable.legacyPackages.${pkgs.system};
in
{
  imports = [
    ../../../shared/home/darwin.nix
  ];

  home.stateVersion = "25.05";

  home.packages = with pkgs; [
  ];

  home.file = {
  };

  programs = {
  };

  npmTools = [
  ];

  # Plumbus-specific user settings for Raycast integration
  # Disable Spotlight keyboard shortcut (Cmd+Space) to allow Raycast usage
  home.activation.disableSpotlightShortcut = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    echo "Disabling Spotlight shortcut (Cmd+Space) for fredrik user on plumbus..."

    # Disable Spotlight keyboard shortcut (Cmd+Space) to allow Raycast usage
    $DRY_RUN_CMD /usr/bin/defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 64 "
      <dict>
        <key>enabled</key><false/>
        <key>value</key><dict>
          <key>type</key><string>standard</string>
          <key>parameters</key>
          <array>
            <integer>32</integer>
            <integer>49</integer>
            <integer>1048576</integer>
          </array>
        </dict>
      </dict>
    "
  '';
}
