{
  config,
  lib,
  pkgs,
  ...
}:
# `investigate`, the incident investigator's daemon that runs Claude Code on an
# alert's trace. It reads its config from
# ~/.config/kaizen/plugins/incident-investigator.jsonc, and instructions.md and
# claude-plugin/ from the plugin's QML directory, in place.
let
  home = config.home.homeDirectory;

  investigate = pkgs.buildGo127Module {
    pname = "investigate";
    version = "0.1.0";
    src = ./investigate;
    vendorHash = "sha256-mN0CEwQazxP6E6xnKfUYikIVJxLvvnHqrF9qQtesVRI=";
    # TestCheckout builds a repository.
    nativeCheckInputs = [ pkgs.git ];
    meta.mainProgram = "investigate";
  };
in
{
  config = {
    # On the session PATH, for the shell to run its client verbs.
    home.packages = [ investigate ];

    # Owns the runs, so a shell reload or crash does not stop an investigation.
    # A switch never restarts it either; the session PATH it inherits has
    # claude, gcloud, qs and notify-send.
    systemd.user.services.kaizen-incident-investigator = {
      Unit = {
        Description = "Incident investigator runs";
        PartOf = [ "graphical-session.target" ];
        X-SwitchMethod = "keep-old";
      };
      Service = {
        ExecStart = lib.concatStringsSep " " [
          "${lib.getExe investigate} serve"
          # The runs' gopls, offline against the module cache Neovim's go fills;
          # used only with sourceDirs.
          "-tool-path ${
            lib.makeBinPath [
              pkgs.go_latest
              pkgs.gopls
            ]
          }"
          "-go-mod-cache ${home}/go/pkg/mod"
        ];
        # $STATE_DIRECTORY; transcripts hold the logs and code runs read.
        StateDirectory = "kaizen-shell/plugins/incident-investigator";
        StateDirectoryMode = "0700";
        Restart = "on-failure";
        Slice = "app.slice";
      };
      Install.WantedBy = [ "wayland-session@niri.target" ];
    };
  };
}
