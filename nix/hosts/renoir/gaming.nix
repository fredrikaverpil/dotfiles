{ pkgs, ... }:
{
  programs.steam = {
    # Also enables 32-bit graphics; Proton versions are picked in Steam.
    enable = true;
    # steam-gamescope: Big Picture in standalone gamescope, run from a TTY.
    gamescopeSession.enable = true;
  };

  # 0.8.2 closes Steam menus instantly (Supreeeme/xwayland-satellite#468, fixed
  # on main by #494); drop this pin once a newer release lands in nixpkgs.
  nixpkgs.overlays = [
    (_: prev: {
      xwayland-satellite = prev.xwayland-satellite.overrideAttrs (
        finalAttrs: _: {
          version = "0.8.1";
          src = prev.fetchFromGitHub {
            owner = "Supreeeme";
            repo = "xwayland-satellite";
            tag = "v${finalAttrs.version}";
            hash = "sha256-BUE41HjLIGPjq3U8VXPjf8asH8GaMI7FYdgrIHKFMXA=";
          };
          cargoDeps = prev.rustPlatform.fetchCargoVendor {
            inherit (finalAttrs) src;
            hash = "sha256-16L6gsvze+m7XCJlOA1lsPNELE3D364ef2FTdkh0rVY=";
          };
        }
      );
    })
  ];

  host.extraSystemPackages = with pkgs; [
    lutris # Battle.net and other non-Steam launchers.
  ];
}
