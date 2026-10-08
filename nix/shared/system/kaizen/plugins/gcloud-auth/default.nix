{ config, ... }:
# A shell plugin showing whether the active gcloud account is logged in. It runs
# gcloud from the session PATH, which kaizen-shell.service inherits.
{
  # Read from the checkout, so `qs ipc call shell reload` applies edits.
  host.kaizenPlugins = [
    "${config.users.users.fredrik.home}/.dotfiles/nix/shared/system/kaizen/plugins/gcloud-auth"
  ];
}
