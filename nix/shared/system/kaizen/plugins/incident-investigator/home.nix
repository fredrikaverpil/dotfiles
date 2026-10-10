{
  config,
  lib,
  pkgs,
  ...
}:
# The incident investigator shell plugin and `investigate`, the daemon that runs
# Claude Code on an alert's trace.
let
  cfg = config.kaizen.incidentInvestigator;
  home = config.home.homeDirectory;
  # Read from the checkout, so `qs ipc call shell reload` applies QML edits and
  # the next run picks up instruction edits.
  dir = "${home}/.dotfiles/nix/shared/system/kaizen/plugins/incident-investigator";

  investigate = pkgs.buildGo127Module {
    pname = "investigate";
    version = "0.1.0";
    src = ./investigate;
    vendorHash = "sha256-vS1glGEsG1Tj7vCJVxy2TYgs2Ps3wS39x8iRXv/Q62E=";
    # TestCheckout builds a repository.
    nativeCheckInputs = [ pkgs.git ];
    meta.mainProgram = "investigate";
  };
in
{
  options.kaizen.incidentInvestigator = {
    claudeConfigDir = lib.mkOption {
      type = lib.types.str;
      example = "/home/me/.claude-oncall";
      description = "The Claude Code profile (account and sessions) every run uses";
    };
    sourceDirs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Directories holding clones of the services' repositories, which runs may read at the deployed commit. Empty: runs read logs and alerts only";
    };
    instructionFiles = lib.mkOption {
      type = lib.types.listOf lib.types.path;
      default = [ ];
      description = "Files appended to Claude's system prompt on every turn, in order, after the plugin's instructions.md. A path is copied to the store; an absolute path as a string is read in place. lib.mkForce replaces instructions.md too";
    };
    tags = lib.mkOption {
      type = lib.types.listOf (
        lib.types.submodule {
          options = {
            name = lib.mkOption {
              type = lib.types.str;
              description = "Label shown on the investigation's badge and filter";
            };
            # The palette roles of a notification rule's border.
            color = lib.mkOption {
              type = lib.types.enum [
                "rose"
                "leaf"
                "wood"
                "water"
                "blossom"
                "sky"
              ];
              description = "Palette colour of the badge";
            };
          };
        }
      );
      default = [ ];
      description = "Labels an investigation can carry, for the window's filters and badges";
    };
    entityPatterns = lib.mkOption {
      type = lib.types.listOf (
        lib.types.submodule {
          options = {
            kind = lib.mkOption {
              type = lib.types.enum [
                "user"
                "organization"
              ];
              description = "What the id names";
            };
            regex = lib.mkOption {
              type = lib.types.str;
              description = "Go regex whose first group is the id";
            };
          };
        }
      );
      default = [ ];
      description = "Ids in tool output listed as users and organizations, besides the `users/ID` and `organizations/ID` resource names";
    };
  };

  config = {
    kaizen.incidentInvestigator.instructionFiles = lib.mkBefore [ "${dir}/instructions.md" ];

    kaizen.plugins = [ dir ];

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
        Environment = [ "CLAUDE_CONFIG_DIR=${cfg.claudeConfigDir}" ];
        ExecStart = lib.concatStringsSep " " (
          [
            "${lib.getExe investigate} serve"
            "-plugin-dir ${dir}/claude-plugin"
            "-config ${
              pkgs.writeText "incident-investigator.json" (builtins.toJSON { inherit (cfg) tags entityPatterns; })
            }"
          ]
          ++ map (file: "-instructions ${file}") cfg.instructionFiles
          ++ map (sourceDir: "-source-dir ${sourceDir}") cfg.sourceDirs
          ++ lib.optionals (cfg.sourceDirs != [ ]) [
            # The runs' gopls, offline against the module cache Neovim's go fills.
            "-tool-path ${
              lib.makeBinPath [
                pkgs.go_latest
                pkgs.gopls
              ]
            }"
            "-go-mod-cache ${home}/go/pkg/mod"
          ]
        );
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
