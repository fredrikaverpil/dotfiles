final: prev: let
  # NOTE: set the rev to the desired tag or commit, then set
  # the SHA to "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  # Perform a ebuild. The proper hash will be printed. Substitute it here.
  #
  # rev = "v0.11.2";
  # sha = "sha256-sNunEdIFrSMqYaNg0hbrSXALRQXxFkdDOl/hhX1L1WA=";
  #
  rev = "v0.11.3";
  sha = "sha256-B/An+SiRWC3Ea0T/sEk8aNBS1Ab9OENx/l4Z3nn8xE4=";
  #
  # rev = "a9a4c271b13fffba2a21567c86b0f40ae4c180a1";
  # sha = "sha256-3clYVRl9XbRZXnPtMU2QuSo4FsUQvPOZCML5J2b9YHc=";
  # NOTE: if there are treesitter query errors, run `checkhealth treesitter`
  # and observe the nix-provided parsers. Re-install them with :TSInstall vim query
in {
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
