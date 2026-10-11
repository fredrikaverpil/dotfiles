{
  config,
  lib,
  pkgs,
  ...
}:
# Fails the system build on a `cmd`, `file` or `data` line, not ending in
# `warn`, of the core's requires or of a plugin this host enables that the
# host does not provide. `kaizen doctor` checks every line at runtime.
let
  host = config.networking.hostName;
  hostDir = ../../nix/hosts + "/${host}";
  shellPlugins = ../stow/.config/quickshell/kaizen/plugins;

  # The host's stowed trees, as stow.sh finds them.
  trees = lib.filter builtins.pathExists (
    [ (../../stow/host + "/${host}") ]
    ++ lib.mapAttrsToList (name: _: hostDir + "/${name}/stow") (
      lib.filterAttrs (_: type: type == "directory") (builtins.readDir hostDir)
    )
  );

  # The plugins a tree enables: its plugins/<name>.jsonc.
  enabled =
    tree:
    let
      dir = tree + "/.config/kaizen/plugins";
    in
    lib.optionals (builtins.pathExists dir) (
      lib.mapAttrsToList (name: _: lib.removeSuffix ".jsonc" name) (
        lib.filterAttrs (name: _: lib.hasSuffix ".jsonc" name && !lib.hasPrefix "." name) (
          builtins.readDir dir
        )
      )
    );

  # LABEL KIND NAME for each cmd, file and data line of file not ending in
  # `warn`; doctor reports a line in another form.
  lines =
    label: file:
    lib.concatMap (
      line:
      let
        fields = lib.filter (field: lib.isString field && field != "") (builtins.split "[[:space:]]+" line);
      in
      lib.optional (
        lib.length fields == 2
        && lib.elem (lib.head fields) [
          "cmd"
          "file"
          "data"
        ]
      ) "${label} ${lib.concatStringsSep " " fields}"
    ) (lib.splitString "\n" (builtins.readFile file));

  plugins = lib.unique (lib.concatMap enabled trees);
  required =
    lines "requires" ../stow/.config/quickshell/kaizen/requires
    ++ lib.concatMap (
      name:
      lib.concatMap (lines "plugins/${name}/requires") (
        lib.filter builtins.pathExists (
          map (dir: dir + "/${name}/requires") (
            [ shellPlugins ] ++ map (tree: tree + "/.config/kaizen/plugins") trees
          )
        )
      )
    ) plugins;

  # The system profile and each user's: home-manager's packages.
  profiles = [
    config.system.path
  ]
  ++ lib.mapAttrsToList (_: entry: entry.source) (
    lib.filterAttrs (name: _: lib.hasPrefix "profiles/per-user/" name) config.environment.etc
  );
in
{
  system.checks = [
    (pkgs.runCommand "kaizen-requires"
      {
        inherit profiles;
        etc = lib.concatMapStrings (entry: "/etc/${entry.target}\n") (
          lib.filter (entry: entry.enable) (lib.attrValues config.environment.etc)
        );
        required = lib.concatMapStrings (line: line + "\n") required;
        passAsFile = [
          "etc"
          "required"
        ];
      }
      ''
        failed=false
        while read -r label kind name; do
          case $kind in
          file) grep -qxF "$name" "$etcPath" && continue ;;
          *)
            sub=share
            [ "$kind" = cmd ] && sub=bin
            for profile in $profiles; do
              [ -e "$profile/$sub/$name" ] && continue 2
            done
            ;;
          esac
          printf '%s: missing %s %s\n' "$label" "$kind" "$name" >&2
          failed=true
        done <"$requiredPath"
        if $failed; then
          exit 1
        fi
        touch "$out"
      ''
    )
  ];
}
