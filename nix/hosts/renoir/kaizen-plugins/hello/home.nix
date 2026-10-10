{ config, ... }:
# The minimal shell plugin: one launcher node under Plugins.
{
  # Read from the checkout, so `qs ipc call shell reload` applies edits.
  kaizen.plugins = [
    "${config.home.homeDirectory}/.dotfiles/nix/hosts/renoir/kaizen-plugins/hello"
  ];
}
