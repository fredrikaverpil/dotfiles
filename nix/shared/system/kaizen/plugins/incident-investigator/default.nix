{
  config,
  lib,
  pkgs,
  ...
}:
# The incident investigator shell plugin and `investigate`, the daemon that runs
# Claude Code on an alert's trace.
let
  cfg = config.host.incidentInvestigator;
  home = config.users.users.fredrik.home;
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

  tagNames = map (tag: tag.name) cfg.tags;
in
{
  options.host.incidentInvestigator = {
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
            # The palette roles of host.notificationRules' border.
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
    alerts = lib.mkOption {
      type = lib.types.listOf (
        lib.types.submodule {
          options = {
            match = lib.mkOption {
              type = lib.types.attrsOf lib.types.str;
              example = {
                app = "^Slack$";
                summary = " in #alerts$";
              };
              description = "As in host.notificationRules";
            };
            tag = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "Tag of the drafts the button creates, one of tags";
            };
          };
        }
      );
      default = [ ];
      description = "Notifications that get the Investigate button. Style their toasts with host.notificationRules entries";
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
    assertions = map (alert: {
      assertion = alert.tag == null || lib.elem alert.tag tagNames;
      message = "host.incidentInvestigator.alerts: tag ${toString alert.tag} is not one of tags";
    }) cfg.alerts;

    host.incidentInvestigator.instructionFiles = lib.mkBefore [ "${dir}/instructions.md" ];

    host.kaizenPlugins = [ dir ];

    host.notificationRules = map (alert: {
      inherit (alert) match;
      actions = [
        {
          label = "Investigate";
          command = [
            "investigate"
            "draft"
          ];
          env = lib.optionalAttrs (alert.tag != null) { INVESTIGATE_TAG = alert.tag; };
        }
      ];
    }) cfg.alerts;

    # On the session PATH, for the shell to run its client verbs.
    environment.systemPackages = [ investigate ];

    # Owns the runs, so a shell reload or crash does not stop an investigation.
    systemd.user.services.kaizen-incident-investigator = {
      description = "Incident investigator runs";
      partOf = [ "graphical-session.target" ];
      wantedBy = [ "wayland-session@niri.target" ];
      # NixOS pins a sparse user-unit PATH; the session's has claude, gcloud,
      # qs and notify-send.
      environment.PATH = lib.mkForce null;
      environment.CLAUDE_CONFIG_DIR = cfg.claudeConfigDir;
      serviceConfig = {
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
    };
  };
}
