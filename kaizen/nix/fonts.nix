# Fonts the shell and the GTK apps it launches draw with. Berkeley Mono is
# licensed and installed by hand; Ui/Fonts.qml falls back to JetBrains Mono
# without it.
{ pkgs, ... }:
{
  fonts.packages = with pkgs; [
    # GTK's default UI font (`font-name`): portal dialogs, nm-connection-editor.
    adwaita-fonts
    nerd-fonts.jetbrains-mono
    # Nerd glyphs Berkeley Mono lacks; Qt falls back per glyph.
    nerd-fonts.symbols-only
    noto-fonts-color-emoji
  ];
}
