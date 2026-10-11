{ lib, ... }:
# Deletes an agent-built ~/.local/bin/kaizen (kaizen/cli/build.sh), which shadows
# the system profile's, so a rebuild returns to it. A link is someone else's.
{
  home.activation.kaizenOverride = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    kaizen="$HOME/.local/bin/kaizen"
    if [ -f "$kaizen" ] && [ ! -L "$kaizen" ]; then
      $DRY_RUN_CMD rm -f "$kaizen"
    fi
  '';
}
