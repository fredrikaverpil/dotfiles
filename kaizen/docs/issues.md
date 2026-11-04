# kaizen issues

This is an overview of all upstream bugs kaizen either tracks or works around
via e.g. overrides or patches.

> [!NOTE]
> 
> Use `rg --hidden 'TODO:'` to find all todo comments.

## Checking status

- A merged fix is unreleased until a tag contains it: `git tag --contains SHA`
  in the project's clone under `~/code/public/`.
- Quickshell: compare the pin (`qs --version`) with
  `gh release list -R quickshell-mirror/quickshell`, and list what master has
  since: `git log --oneline v<pin>..origin/master` in
  `~/code/public/github.com/quickshell-mirror/quickshell` after a fetch. A
  release reaches the hosts through nixpkgs, so check
  `nix eval --raw .#nixosConfigurations.<host>.pkgs.quickshell.version` too.
- nixpkgs: a merged PR or commit reaches a host only once the flake's pin has
  it. `gh api repos/NixOS/nixpkgs/compare/SHA...REV --jq .status` says `ahead`
  or `identical` when REV, a branch or the rev in `flake.lock`, contains SHA.

Status is one of: open, merged (unreleased), released (drop the workaround),
not planned, unreported.

## Quickshell

### App ID set after the app is constructed

- Workaround:
  [`quickshell-desktop-file-name.patch`](../nix/quickshell-desktop-file-name.patch),
  applied by the overlay in [`nix/default.nix`](../nix/default.nix).
- Upstream: issue
  [#1293](https://github.com/quickshell-mirror/quickshell/issues/1293), fixed
  by our PR [#1328](https://github.com/quickshell-mirror/quickshell/pull/1328)
  as `9b0f339`; the issue is still open.
- Status: merged (unreleased); latest release v0.3.2.
- Drop: the patch, once nixpkgs has a Quickshell release after v0.3.2.

### Failed Get of an optional D-Bus property logs a warning

- Workaround:
  [`quickshell-optional-property-failed.patch`](../nix/quickshell-optional-property-failed.patch),
  applied by the overlay in [`nix/default.nix`](../nix/default.nix).
- Upstream: issue
  [#862](https://github.com/quickshell-mirror/quickshell/issues/862).
- Status: open; nothing on master.
- Drop: the patch, once a release handles `Failed` as `InvalidArgs`.

### WlSessionLock emits no lockStateChanged on unlock

- Workaround:
  [`quickshell-session-lock-unlock.patch`](../nix/quickshell-session-lock-unlock.patch),
  applied by the overlay in [`nix/default.nix`](../nix/default.nix); and
  `finishUnlock()` in
  [`modules/lock/Service.qml`](../stow/.config/quickshell/kaizen/modules/lock/Service.qml)
  releases the session lock before `lockRequested`.
- Upstream: issue
  [#1230](https://github.com/quickshell-mirror/quickshell/issues/1230), fixed
  by PR [#1289](https://github.com/quickshell-mirror/quickshell/pull/1289) as
  `18c95fa`.
- Status: merged (unreleased).
- Drop: the patch, once nixpkgs has a release after v0.3.2; then check whether
  `finishUnlock()` still needs its order, and update its comment.

### Placeholder types in the qmltypes on Qt 6.12

- Symptom: `qml-lint` and qmlls report `Member "values" not found on type
  "UntypedObjectModel"` and `Could not find property` on `margins.*`, 8
  warnings in all. Each Quickshell module's `.qmltypes` declares the core
  types it uses as empty, opaque types, which qmllint takes for the real ones.
  They also hide later warnings in a function, so a release may surface new
  ones in kaizen's code.
- Workaround: none; `qml-lint` fails on these 8 until the release. A v0.3.2
  build with `2b4501a` applied lints the tree clean. Not patched: the devshell
  takes Quickshell's types from the binary cache, and a patched build is not
  cached, which the Mac devshell cannot build.
- Upstream: `2b4501a` "build: expose dependency metatypes in light dep" on
  master, no issue.
- Status: merged (unreleased).
- Drop: this entry, once the pinned Quickshell includes it and `qml-lint` is
  clean.

## Qt

### qmllint misses a singleton with a relative path

- Symptom: given a relative path, qmllint 6.12 reports `Type X not declared as
  singleton in qmldir but using pragma Singleton` for a singleton that the
  file's own `qmldir` declares. A module `Foo/` with `singleton S 1.0 S.qml`
  reproduces it: `qmllint Foo/S.qml` warns, `qmllint $PWD/Foo/S.qml` does not.
- Workaround: `qml-lint` in [`flake.nix`](../../flake.nix) passes absolute
  paths.
- Upstream: unreported.
- Drop: the absolute paths are harmless; keep them unless they get in the way.

## Plugins

### dcal's stale vendorHash

- Workaround: the `vendorHash` override in
  [`nix/plugins/calendar/default.nix`](../nix/plugins/calendar/default.nix).
- Upstream: PR
  [dux-calendar#151](https://github.com/duxlabs-dev/dux-calendar/pull/151).
- Status: open.
- Drop: the override, once the PR lands and the flake input moves past it.

## Outside kaizen

Workarounds in the repository's `nix/` that kaizen hosts carry.

### Chromium and Electron fall back to basic_text on niri and umbriel

- Workaround: `withGnomeLibsecret` in
  [`nix/shared/overlays/default.nix`](../../nix/shared/overlays/default.nix);
  [`README.md`](../README.md) › Session says why.
- Upstream: [electron#39789](https://github.com/electron/electron/issues/39789)
  closed as completed (2026-02-15);
  [vscode#285777](https://github.com/microsoft/vscode/issues/285777) closed as
  not planned;
  [vscode#187338](https://github.com/microsoft/vscode/issues/187338) open.
- Status: open. Whether the Electron fix detects niri and umbriel, and which
  wrapped apps ship it, is unverified.
- Drop: per app, never by removing the flag alone: an app that encrypted its
  secrets with the keyring is locked out of them without it.

### Proton Authenticator's desktop entry ID has a space

- Workaround: the `symlinkJoin` renaming `Proton Authenticator.desktop` to
  `proton-authenticator.desktop` in
  [`nix/shared/system/linux-desktop.nix`](../../nix/shared/system/linux-desktop.nix).
  uwsm-app rejects the ID (`Invalid Desktop Entry ID`), and will not accept one
  with a space
  ([uwsm#116](https://github.com/Vladimir-csp/uwsm/issues/116), not planned).
- Upstream: issue
  [ProtonMail/WebClients#552](https://github.com/ProtonMail/WebClients/issues/552).
- Status: open.
- Drop: the rename, once a release names its entry without a space.

### Neovim override

- Override: `neovim-unwrapped` at 0.12.6 in
  [`nix/hosts/renoir/users/fredrik.nix`](../../nix/hosts/renoir/users/fredrik.nix)
  and
  [`nix/hosts/wily/users/fredrik.nix`](../../nix/hosts/wily/users/fredrik.nix),
  kept so a release nixpkgs lacks is a version and hash bump.
- Upstream: none pending; nixpkgs ships 0.12.6 too, since
  [NixOS/nixpkgs#572220](https://github.com/NixOS/nixpkgs/pull/572220).
- Status: matches nixpkgs.
- Drop: never. While it is ahead of nixpkgs, name the nixpkgs PR here.

## Limitations

- qmlls hover (`K`) is empty: it shows only Qt's documentation, passed with
  `qmlls -d`, which nixpkgs' Qt does not ship, and Quickshell has none. Go to
  definition stops at the `import` line for a function in an imported JS file,
  and finds nothing for Quickshell's C++ types.
