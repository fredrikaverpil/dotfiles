{ inputs, ... }:
# dcal, the daemon the calendar plugin queries. Its unit, kaizen-dcal, lives in
# stow/kaizen/; dcal's own option stays off.
{
  imports = [ inputs.dankcalendar.homeModules.default ];

  # OAuth tokens stay in gnome-keyring (from programs.niri), unlocked by the login PAM stack.
  # Calendar credentials and feed URLs are private user state, never Nix/Stow values.
  programs.dank-calendar.enable = true;
}
