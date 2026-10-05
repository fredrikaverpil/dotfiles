{
  config,
  lib,
  pkgs,
  ...
}:
let
  llama-router = pkgs.writeShellApplication {
    name = "llama-router";
    runtimeInputs = [ pkgs.llama-cpp-vulkan ];
    text = ''
      exec llama-server --no-models-autoload --jinja \
        --host 127.0.0.1 --port 8080 -ngl 999 -c 32768 "$@"
    '';
  };
in
{
  imports = [
    ../../../shared/home/linux.nix
    ../../../shared/home/linux-desktop.nix
  ];

  home.stateVersion = "26.05";

  # Host-only user packages; shared ones live in nix/shared/home/.
  home.packages = with pkgs; [
    jira-cli-go
    google-cloud-sdk
    llama-cpp-vulkan
    llama-router
  ];

  llmAgents = [ ];

  # Shortcut to the Hugging Face cache, where downloaded models live.
  home.file."models/huggingface".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.cache/huggingface/hub";

  # Chromium web apps on the work profile.
  xdg.desktopEntries = {
    calendar = {
      name = "Google Calendar";
      exec = "chromium --profile-directory=Work --app=https://calendar.google.com";
      icon = ../webapps/calendar.png;
    };
    linear = {
      name = "Linear";
      exec = "chromium --profile-directory=Work --app=https://linear.app";
      icon = ../webapps/linear.png;
    };
    meet = {
      name = "Google Meet";
      exec = "chromium --profile-directory=Work --app=https://meet.google.com";
      icon = ../webapps/meet.png;
    };
    miro = {
      name = "Miro";
      exec = "chromium --profile-directory=Work --app=https://miro.com/app/dashboard/";
      icon = ../webapps/miro.png;
    };
  };

  programs = {
    # `?submodules=1` pulls in the private submodule at nix/hosts/wily/einride;
    # `inputs.self.submodules` cannot be used, it makes public clones and CI
    # try to fetch the private repo.
    nh.flake = lib.mkForce "${config.home.homeDirectory}/.dotfiles?submodules=1";
  };
}
