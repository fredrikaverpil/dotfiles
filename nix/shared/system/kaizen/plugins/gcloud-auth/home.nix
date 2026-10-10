{ config, ... }:
# A shell plugin showing whether the active gcloud account is logged in. It runs
# gcloud from the session PATH, which kaizen-shell.service inherits.
{
  # Read from the checkout, so `qs ipc call shell reload` applies edits.
  kaizen.plugins = [
    "${config.home.homeDirectory}/.dotfiles/nix/shared/system/kaizen/plugins/gcloud-auth"
  ];
}
