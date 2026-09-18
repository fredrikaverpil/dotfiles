# Desktop fonts for the niri + Quickshell hosts. Servers do not import this.
{ pkgs, ... }:
{
  # NOTE: Berkeley Mono is installed manually, as it requires a license.
  fonts.packages = with pkgs; [
    nerd-fonts.fira-code
    nerd-fonts.fira-mono
    nerd-fonts.hack
    nerd-fonts.jetbrains-mono
    maple-mono.truetype
    maple-mono.variable
    # noto-fonts-color-emoji # NOTE: takes a very long time to build
    nerd-fonts.symbols-only
  ];

  # Berkeley Mono is licensed, so it is copied into ~/.local/share/fonts by
  # hand. Both rules below name JetBrains Mono as the next candidate, so a
  # host without Berkeley Mono falls back to it instead of DejaVu.
  fonts.fontconfig.defaultFonts.monospace = [
    "Berkeley Mono Variable"
    "JetBrainsMono Nerd Font"
  ];

  # Applications that ask for JetBrains Mono by name bypass the generic
  # monospace alias. Qt resolves an installed family directly, so this rule
  # never reaches Quickshell; Ui/Fonts.qml picks the family there instead.
  fonts.fontconfig.localConf = ''
    <?xml version="1.0"?>
    <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
    <fontconfig>
      <match target="pattern">
        <test name="family"><string>JetBrainsMono Nerd Font</string></test>
        <edit name="family" mode="prepend" binding="strong">
          <string>Berkeley Mono Variable</string>
        </edit>
      </match>
    </fontconfig>
  '';
}
