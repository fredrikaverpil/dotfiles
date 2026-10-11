{ buildGo127Module }:
# The `kaizen` command, built from kaizen/; its tests run in checkPhase, so a
# failing test fails the rebuild. It runs the scripts stow/kaizen/ links into
# ~/.local/libexec/kaizen/.
buildGo127Module {
  pname = "kaizen";
  version = "0.1.0";
  src = ../../../../kaizen;
  vendorHash = "sha256-eM+g1h8K9UV/UqEZeVsD+8v3FWHyk12t03s+/8JC7vY=";
  meta.mainProgram = "kaizen";
}
