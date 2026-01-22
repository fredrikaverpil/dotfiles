{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
let
  unstable = inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system};
in
{
  imports = [
    ../../../shared/home/darwin.nix
  ];

  home.stateVersion = "25.05";

  home.packages = with pkgs; [
  ];

  # User/host-specific self-managed CLI tools
  # Example (uncomment to add tools specific to this user/host):
  # selfManagedCLIs = [
  #   {
  #     name = "user-specific-tool";
  #     description = "Tool only for this user/host";
  #     installScript = ''
  #       ${pkgs.curl}/bin/curl -fsSL https://example.com/install.sh | ${pkgs.bash}/bin/bash
  #     '';
  #   }
  # ];

  home.file = {
  };

  programs = {
  };

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
