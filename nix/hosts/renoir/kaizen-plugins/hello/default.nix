{ config, ... }:
# The minimal shell plugin: one launcher node under Plugins.
{
  # Read from the checkout, so `qs ipc call shell reload` applies edits.
  home-manager.sharedModules = [
    {
      kaizen.plugins = [
        "${config.users.users.fredrik.home}/.dotfiles/nix/hosts/renoir/kaizen-plugins/hello"
      ];
    }
  ];
}
