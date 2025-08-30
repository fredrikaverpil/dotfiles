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
  # Nightly from https://github.com/neovim/neovim/commit/74511a98fdf4569b00781eb3cd677767c1cbdf4e
  rev = "b3d29f396d7d8eac654d51dc972344977f71e016";
  sha = "sha256-eZgb+BIC7pWx5EwLGeSgLQM3mb32PAhFE2xr2ivgPGs=";
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
