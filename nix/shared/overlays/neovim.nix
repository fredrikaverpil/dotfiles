final: prev:
let
  # NOTE: set the rev to the desired tag or commit, then set
  # the SHA to "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  # Perform a ebuild. The proper hash will be printed. Substitute it here.
  #
  # rev = "v0.11.2";
  # sha = "sha256-sNunEdIFrSMqYaNg0hbrSXALRQXxFkdDOl/hhX1L1WA=";
  #
  # rev = "v0.11.3";
  # sha = "sha256-B/An+SiRWC3Ea0T/sEk8aNBS1Ab9OENx/l4Z3nn8xE4=";
  #
  # rev = "v0.11.4";
  # sha = "sha256-IpMHxIDpldg4FXiXPEY2E51DfO/Z5XieKdtesLna9Xw=";
  #
  # Nightly from https://github.com/neovim/neovim/commit/b756a6165a06a1bca018a30dfa6b6394dc5f1208
  rev = "a08aa77e4084e2b380f23b7a10f41eb20371d6c3";
  sha = "sha256-5O/Dvv7ltyePItr8zl6MMvl3QxjgbNR6ttDGqEbtLpE=";
in
{
  neovim-custom = prev.neovim-unwrapped.overrideAttrs (old: {
    version = rev;
    src = prev.fetchFromGitHub {
      owner = "neovim";
      repo = "neovim";
      rev = rev;
      sha256 = sha;
    };
    # Skip version checks for nightly builds
    doCheck = false;
    doInstallCheck = false;
  });
}
