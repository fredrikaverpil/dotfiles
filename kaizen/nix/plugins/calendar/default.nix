{ inputs, pkgs, ... }:
# dcal, the daemon the calendar plugin queries. Its unit, kaizen-dcal, lives in
# kaizen/stow/. Not dux-calendar's modules: they add a plain quickshell and
# dcal's own unit.
{
  # OAuth tokens stay in gnome-keyring (from programs.niri), unlocked by the login PAM stack.
  # Calendar credentials and feed URLs are private user state, never Nix/Stow values.
  environment.systemPackages = [
    # TODO: drop once duxlabs-dev/dux-calendar#151 lands; upstream's vendorHash is stale.
    ((inputs.dux-calendar.lib.mkDcal pkgs).overrideAttrs {
      vendorHash = "sha256-JT6mHK52mIJh4lzVWYVpqNY2S2oeinSWBIKaI3TiY34=";
    })
  ];
}
