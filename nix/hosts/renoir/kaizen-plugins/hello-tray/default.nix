{ pkgs, ... }:
# The minimal tray plugin: an app with its own StatusNotifierItem and menu,
# which the shell's tray shows. It needs no shell code. Its unit and desktop
# entry live in stow/host/renoir/.
let
  hello-tray = pkgs.buildGo127Module {
    pname = "hello-tray";
    version = "0.1.0";
    src = ./.;
    vendorHash = "sha256-D3vwR88HkkSyRY1e4VAjI0pUC4AbIEvUmc9lQ922apM=";
    meta.mainProgram = "hello-tray";
  };
in
{
  environment.systemPackages = [ hello-tray ];
}
