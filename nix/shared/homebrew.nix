{ pkgs, config, ... }:

{
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      upgrade = true;
      cleanup = "zap";
    };

    taps = [
      "dustinblackman/tap"
      "go-task/tap"
      "joshmedeski/sesh"
      "1password/tap"
      "nikitabobko/tap"
      "sst/tap"  # for opencode
    ];

    brews = [
      # CLI tools moved to Nix packages in home-common.nix:
      # direnv, atuin, eza, gh, starship, yq, zoxide, etc.
      
      # Packages not available in nixpkgs
      "cloud-sql-proxy"
      "git-standup"
      
      # Presentation tools
      "slides"
      "chafa"  # Required for showing images in slides
      
      # Packages from custom taps that aren't in nixpkgs
      "go-task/tap/go-task"
      "joshmedeski/sesh/sesh"
      "sst/tap/opencode"
    ] ++ config.dotfiles.extraBrews;

    casks = [
      "1password"
      "1password-cli"
      "aerospace"
      "appcleaner"
      "font-jetbrains-mono"
      "font-jetbrains-mono-nerd-font"
      "font-maple-mono"
      "font-noto-color-emoji"
      "font-noto-emoji"
      "font-symbols-only-nerd-font"
      "ghostty"
      "gitify"
      "gcloud-cli"
      "kitty"
      "obsidian"
      "signal"
      "spotify"
      "visual-studio-code"
      "wacom-tablet"
      "wezterm"
      "zed"
    ] ++ config.dotfiles.extraCasks;

    masApps = {
      "Keka" = 470158793;
      "Slack" = 803453959;
      "Pandan" = 1569600264;
    };
  };
}
