{ buildGo127Module }:
# The `kaizen` command, built from kaizen/cli/; its tests run in checkPhase, so
# a failing test fails the rebuild. It runs the scripts kaizen/stow/ links into
# ~/.local/libexec/kaizen/.
buildGo127Module {
  pname = "kaizen";
  version = "0.1.0";
  src = ../cli;
  # The main package's directory names the binary.
  postInstall = "mv $out/bin/cli $out/bin/kaizen";
  vendorHash = "sha256-eM+g1h8K9UV/UqEZeVsD+8v3FWHyk12t03s+/8JC7vY=";
  meta.mainProgram = "kaizen";
}
