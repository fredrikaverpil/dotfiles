# wily (ThinkPad T14 Gen 6 Intel, Lunar Lake)

Work machine. The desktop is promoted here from `renoir` by copying files;
see `CLAUDE.md`. Work-only configuration (YubiKey, CrowdStrike, ...) lives in
the private `fredrikaverpil/dotfiles-einride` repo, mounted as the git
submodule `private/` and imported by `configuration.nix` only when checked
out.

## Rebuilding

Flakes copy the tree from `git ls-files`, which lists the submodule pointer
but not its contents, so a plain flake reference sees `private/` as an empty
directory and silently builds the host without the work config. The flake
reference has to ask for submodules:

```sh
nh os switch                                                        # normal
sudo nixos-rebuild switch --flake "$HOME/.dotfiles?submodules=1#wily"   # what nh runs
```

`programs.nh.flake` in `users/fredrik.nix` carries `?submodules=1`;
`inputs.self.submodules` in `flake.nix` is not an option, because it makes
public clones and CI try to fetch the private repo.

After pulling, `git submodule update --init` brings the submodule to the
pinned commit. CI builds the host without the submodule checked out.
