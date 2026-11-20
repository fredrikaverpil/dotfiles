# kaizen issues

Overview of upstream bugs tracked or worked around by kaizen and the shared
toolchain ([`nix/shared/toolchain.nix`](../../nix/shared/toolchain.nix)), via
patches, overrides, or `TODO`s.

> [!NOTE]
>
> Run `rg --hidden 'TODO:'` to find all `TODO` comments across the repo.

## Checking status

- **Merged vs. released:** A merged commit is still unreleased until a release
  tag contains it. Check with `git tag --contains SHA` in the local clone under
  `~/code/public/`.
- **Quickshell:** Compare the pinned version (`qs --version`) against
  `gh release list -R quickshell-mirror/quickshell`, and check commits on
  `master` since the pin with `git log --oneline v<pin>..origin/master` in
  `~/code/public/github.com/quickshell-mirror/quickshell` after fetching.
  Because hosts receive Quickshell through nixpkgs, also verify
  `nix eval --raw .#nixosConfigurations.<host>.pkgs.quickshell.version`.
- **nixpkgs:** A merged PR or commit reaches hosts only once the flake pin
  includes it. `gh api repos/NixOS/nixpkgs/compare/SHA...REV --jq .status`
  returns `ahead` or `identical` when `REV` (a branch or commit in
  `flake.lock`) contains `SHA`.

Status values: `open`, `merged (unreleased)`, `released (drop the workaround)`,
`not planned`, `unreported`.

## Quickshell

### App ID set after the app is constructed

- **Workaround:**
  [`quickshell-desktop-file-name.patch`](../nix/quickshell-desktop-file-name.patch),
  applied by the overlay in [`nix/default.nix`](../nix/default.nix).
- **Upstream:** issue
  [#1293](https://github.com/quickshell-mirror/quickshell/issues/1293), fixed
  by our PR [#1328](https://github.com/quickshell-mirror/quickshell/pull/1328)
  (`9b0f339`); the issue remains open.
- **Status:** merged (unreleased); latest release is v0.3.2.
- **Drop when:** nixpkgs includes a Quickshell release newer than v0.3.2.

### Failed Get of an optional D-Bus property logs a warning

- **Workaround:**
  [`quickshell-optional-property-failed.patch`](../nix/quickshell-optional-property-failed.patch),
  applied by the overlay in [`nix/default.nix`](../nix/default.nix).
- **Upstream:** issue
  [#862](https://github.com/quickshell-mirror/quickshell/issues/862).
- **Status:** open; no fix on `master`.
- **Drop when:** a Quickshell release treats `Failed` the same as `InvalidArgs`.

### WlSessionLock emits no lockStateChanged on unlock

- **Workaround:**
  [`quickshell-session-lock-unlock.patch`](../nix/quickshell-session-lock-unlock.patch),
  applied by the overlay in [`nix/default.nix`](../nix/default.nix); also
  `finishUnlock()` in
  [`modules/lock/Service.qml`](../stow/.config/quickshell/kaizen/modules/lock/Service.qml)
  releases the session lock before clearing `lockRequested`.
- **Upstream:** issue
  [#1230](https://github.com/quickshell-mirror/quickshell/issues/1230), closed
  by PR [#1289](https://github.com/quickshell-mirror/quickshell/pull/1289)
  (`18c95fa`).
- **Status:** merged (unreleased).
- **Drop when:** nixpkgs includes a Quickshell release newer than v0.3.2; then
  check whether `finishUnlock()` still needs its ordering and update its
  comment.

### Placeholder types in the qmltypes on Qt 6.12

- **Symptom:** `qml-lint` and `qmlls` emit 7 warnings:
  `Member "values" not found on type "UntypedObjectModel"` and
  `Could not find property` on `margins.*`. Each Quickshell module's
  `.qmltypes` declares core types it depends on as empty opaque placeholders,
  which `qmllint` mistakes for the real types. Those errors also mask later
  warnings in the same function, so upgrading may surface new warnings in
  kaizen's QML.
- **Workaround:** None; `qml-lint` fails on these 7 warnings until the next
  release (a v0.3.2 build with `2b4501a` applied lints clean). We intentionally
  do not patch it in the devshell because the devshell pulls Quickshell's
  metadata from the binary cache; patching would invalidate the cache and break
  the macOS devshell, which cannot build Quickshell locally.
- **Upstream:** `2b4501a` ("build: expose dependency metatypes in light dep")
  on `master`; no issue filed.
- **Status:** merged (unreleased).
- **Drop when:** the pinned Quickshell includes `2b4501a` and `qml-lint` passes
  clean.

## Qt

### qmllint misses a singleton with a relative path

- **Symptom:** When passed a relative path, `qmllint` 6.12 warns
  `Type X not declared as singleton in qmldir but using pragma Singleton` even
  when the file's own `qmldir` declares it. For a module `Foo/` containing
  `singleton S 1.0 S.qml`, `qmllint Foo/S.qml` warns while
  `qmllint $PWD/Foo/S.qml` succeeds.
- **Workaround:** `qml-lint` in [`flake.nix`](../../flake.nix) passes absolute
  paths.
- **Upstream:** unreported.
- **Drop when:** never needed—absolute paths are harmless; keep them unless
  they get in the way.

### Markdown drops a list item that starts with HTML

- **Symptom:** In Qt 6.12's `QTextMarkdownImporter`, starting a list item or
  block quote with inline HTML or an HTML entity breaks that item out of its
  list or quote. If it is the first item in a list, the entire list loses its
  bullets and the next item logs
  `attempted to insert into a list that no longer exists`. Because the
  incident investigator's `Format.literals` wraps inline code and URLs in HTML
  spans, items like `- \`foo\` does…` hit this on every render.
- **Workaround:** `Format.literals` in
  [`plugins/incident-investigator/Format.js`](../stow/.config/quickshell/kaizen/plugins/incident-investigator/Format.js)
  inserts a literal U+200B zero-width space before any span immediately
  following a list or quote marker (using `&#8203;` would trigger the same HTML
  bug). Copying affected lines includes the zero-width space.
- **Upstream:** unreported; still present on `qtbase`'s `dev` branch
  (2026-11-16).
- **Drop when:** a pinned Qt version preserves the list without the zero-width
  space.

## Outside kaizen

Workarounds in the repository's `nix/` tree carried by kaizen hosts.

### Chromium and Electron fall back to basic_text on niri and umbriel

- **Workaround:** `withGnomeLibsecret` in
  [`nix/shared/overlays/default.nix`](../../nix/shared/overlays/default.nix);
  see [`README.md`](../README.md) › Session for details.
- **Upstream:**
  [electron#39789](https://github.com/electron/electron/issues/39789) (closed as
  completed 2026-02-15);
  [vscode#285777](https://github.com/microsoft/vscode/issues/285777) (closed as
  not planned);
  [vscode#187338](https://github.com/microsoft/vscode/issues/187338) (open).
- **Status:** open. It is unverified whether the Electron fix detects niri and
  umbriel, or which wrapped apps ship it.
- **Drop when:** evaluate per app, and never drop the flag casually—an app that
  encrypted secrets using the keyring will be locked out of them without it.

### Proton Authenticator's desktop entry ID has a space

- **Workaround:** `symlinkJoin` renames `Proton Authenticator.desktop` to
  `proton-authenticator.desktop` in
  [`nix/shared/system/linux-desktop.nix`](../../nix/shared/system/linux-desktop.nix).
  `uwsm-app` rejects IDs containing spaces (`Invalid Desktop Entry ID`) and
  will not support them
  ([uwsm#116](https://github.com/Vladimir-csp/uwsm/issues/116), not planned).
- **Upstream:**
  [ProtonMail/WebClients#552](https://github.com/ProtonMail/WebClients/issues/552).
- **Status:** open.
- **Drop when:** an upstream release removes the space from the desktop entry
  filename.

### LightCraft lacks fixes for the X100VI

- **Symptom:** `renoir` installs `lightcraft` 0.21.1 from nixpkgs (upstream's
  latest) in
  [`nix/hosts/renoir/configuration.nix`](../../nix/hosts/renoir/configuration.nix)
  to test Fujifilm X100VI RAF files (40 MP X-Trans CMOS 5 HR, the same sensor
  as the X-T5). Fujifilm fixes reach `renoir` only via nixpkgs.
- **Workaround:** None. Upstream's flake has failed offline builds since 0.15.0
  because `Cargo.toml` leaves unused `[patch.crates-io]` entries unvendored
  ([storytold/lightcraft#3404](https://github.com/storytold/lightcraft/issues/3404),
  open). nixpkgs strips them in `postPatch`
  ([NixOS/nixpkgs#580713](https://github.com/NixOS/nixpkgs/pull/580713)), so
  tracking upstream directly would require repeating that patch and compiling
  locally on every bump.
- **Wanted for the X100VI (all currently open upstream):**
  - Improved X-Trans demosaicing with less false color
    ([#2926](https://github.com/storytold/lightcraft/pull/2926)); the current
    algorithm shifts colors in fine textures and causes magenta fringing on
    clipped highlights
    ([#3451](https://github.com/storytold/lightcraft/issues/3451)).
  - Film simulations as looks
    ([#380](https://github.com/storytold/lightcraft/issues/380)):
    [#3339](https://github.com/storytold/lightcraft/pull/3339) adds the eleven
    X-T5 simulations (same sensor), building on the X-T4 looks in
    [#2445](https://github.com/storytold/lightcraft/pull/2445), while
    [#3330](https://github.com/storytold/lightcraft/pull/3330) reads the film
    simulation from maker notes.
  - AI denoise for X-Trans sensors, currently refused
    ([#1760](https://github.com/storytold/lightcraft/issues/1760)):
    [#1828](https://github.com/storytold/lightcraft/pull/1828) or
    [#2355](https://github.com/storytold/lightcraft/pull/2355).
  - Kelvin white balance: without color matrices, the X100VI only exposes a
    relative slider
    ([#730](https://github.com/storytold/lightcraft/issues/730));
    [#2527](https://github.com/storytold/lightcraft/pull/2527) reads it from
    the RAF's neutral multipliers.
- **Status:** open; all items above remain unmerged.
- **Drop when:** remove each bullet once nixpkgs ships a release containing it
  (verify via
  `nix eval --raw .#nixosConfigurations.renoir.pkgs.lightcraft.version` and
  `gh api repos/storytold/lightcraft/compare/SHA...vX.Y.Z --jq .status`);
  remove this entry once none remain or if `renoir` drops `lightcraft`.

### Git's three-way merge overflows the heap

- **Symptom:**
  [CVE-2026-105437](https://nvd.nist.gov/vuln/detail/CVE-2026-105437) (CVSS
  7.5): a committed `.gitattributes` with a huge `conflict-marker-size`
  overflows a 32-bit size in `xdiff`'s merge logic. Running `git merge`,
  `rebase`, `cherry-pick`, or `merge-tree` on untrusted branches can crash Git
  or corrupt its heap with attacker-controlled data.
- **Workaround:** None globally. Upstream's mitigation
  (`* conflict-marker-size=7` in `.git/info/attributes`) applies per repository
  only, because a global `core.attributesFile` has lower precedence than an
  in-tree `.gitattributes`.
- **Upstream:** Fixed in
  [v2.56.1](https://github.com/git/git/blob/v2.56.1/Documentation/RelNotes/2.56.1.adoc)
  alongside five other CVEs; merged into nixpkgs `staging` via
  [NixOS/nixpkgs#586339](https://github.com/NixOS/nixpkgs/pull/586339)
  (2026-11-10).
- **Status:** released in 2.56.1; `nixpkgs-unstable` and the flake pin are on
  2.56.0.
- **Drop when:** `nix eval --raw .#nixosConfigurations.<host>.pkgs.git.version`
  reports 2.56.1 or later.

### Neovim override

- **Override:** `neovim-unwrapped` pinned to 0.12.6 in
  [`nix/hosts/renoir/users/fredrik.nix`](../../nix/hosts/renoir/users/fredrik.nix)
  and
  [`nix/hosts/wily/users/fredrik.nix`](../../nix/hosts/wily/users/fredrik.nix),
  kept in place so adopting a release before nixpkgs packages it only takes a
  version and hash bump.
- **Upstream:** None pending; nixpkgs also ships 0.12.6 since
  [NixOS/nixpkgs#572220](https://github.com/NixOS/nixpkgs/pull/572220).
- **Status:** matches nixpkgs.
- **Drop when:** keep permanently. Whenever the override is ahead of nixpkgs,
  record the tracking nixpkgs PR here.

## Limitations

- `qmlls` hover (`K`) is empty: it only displays Qt docs passed via `qmlls -d`,
  which nixpkgs' Qt does not ship, and Quickshell ships none. Go-to-definition
  stops at the `import` statement for functions in imported JS files and finds
  nothing for Quickshell's C++ types.
