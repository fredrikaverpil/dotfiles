{ inputs, pkgs, ... }:
# dcal, the daemon the calendar plugin queries. Its unit, kaizen-dcal, lives in
# stow/kaizen/. Not dankcalendar's modules: they add a plain quickshell and
# dcal's own unit.
{
  # OAuth tokens stay in gnome-keyring (from programs.niri), unlocked by the login PAM stack.
  # Calendar credentials and feed URLs are private user state, never Nix/Stow values.
  environment.systemPackages = [ (inputs.dankcalendar.lib.mkDcal pkgs) ];
}
