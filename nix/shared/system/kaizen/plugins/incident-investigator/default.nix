{ lib, pkgs, ... }:
# `investigate`, the incident investigator's daemon that runs Claude Code on an
# alert's trace. It reads its config from
# ~/.config/kaizen/plugins/incident-investigator.jsonc, and instructions.md and
# claude-plugin/ from the plugin's QML directory, in place.
let
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
  # On the session PATH, for kaizen-incident-investigator (stow/kaizen/) and for
  # the shell to run its client verbs. go and gopls come first on its runs'
  # PATH: the runs' gopls, offline against the module cache Neovim's go fills.
  environment.systemPackages = [
    (pkgs.symlinkJoin {
      inherit (investigate) name meta;
      paths = [ investigate ];
      nativeBuildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
        wrapProgram $out/bin/investigate --prefix PATH : ${
          lib.makeBinPath [
            pkgs.go_latest
            pkgs.gopls
          ]
        }
      '';
    })
  ];
}
