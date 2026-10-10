# kaizen: out of Nix

Goal: kaizen runs on any Linux distro that provides the subsystems and programs
it calls. Nix stays the way these dotfiles install those programs and do what
needs root, but holds no kaizen configuration: everything kaizen reads (units,
scripts, rules, plugin selection, plugin config, QML) is a file under Stow,
edited live without a rebuild. **Never pushed unasked.**

Work happens on branch `refactor/kaizen-home-manager`, on renoir in the
worktree `.claude/worktrees/kaizen-home-manager`. Run builds against the
worktree path, not `~/.dotfiles`. Rebased 2026-10-10 onto `main` at
`7fdad478` (kaizen-log JSON and bar indicator).

**Pushed 2026-10-10 at the user's request, to continue on wily:** the branch
to `origin/refactor/kaizen-home-manager`, with this file in its own commit
(`chore: add the kaizen plan`, the branch tip). **Drop that commit before
landing.** einride's commits are pushed to the branch
`refactor/kaizen-home-manager` of `dotfiles-einride` on GitHub, not to its
`main`; at landing, fast-forward einride's `main` to it.

On wily: fetch the branch into `~/.dotfiles` (check `git status` there
first for uncommitted theme edits), then
`git submodule update --init nix/hosts/wily/einride` checks out the pinned
einride commit (GitHub serves it, as the einride branch holds it). wily has
no worktree for this branch; follow Phase 2: deploy and verify › wily.

Two phases, both on this branch. Phase 1 (home-manager split) is done and
stays; phase 2 adds commits on top of it.

**Resume here (2026-10-10, late):** phase 2 is complete and verified on
renoir: commits 1-7, the logging commits 9a-9c and four fixes are committed
and deployed (generation 96, fresh login 14:39); 8 (kaizen-doctor) is
skipped. Branch tip `d46540c2`. What is left: wily, then landing.

`~/.dotfiles` (the main checkout, the live stowed tree) is **detached at the
branch tip** (`d46540c2`) by the user's choice; local `main` stays at
`7fdad478`. It must follow the branch until it lands, since `main` lacks the
stowed units: after new commits, move it with
`git -C ~/.dotfiles switch --detach <tip>`, run `dotfiles-stow` when Stow files
were added, moved or removed, and restart the unlocked shell
(`systemctl --user restart kaizen-shell.service`) for QML changes or a
`kaizen-log` change (the log service runs `kaizen-log --follow` once). Its
`nix/hosts/wily/einride` shows as modified: that clone lacks einride's
unpushed commits; harmless on renoir, do not touch it.

Next steps, in order:

1. Done: renoir rebuilt for 9c (generation 96, hello-tray the only closure
   change), fresh login. hello-tray runs the new binary, started after the
   shell; `kaizen-log` since login holds no "failed to register", only the
   known portal lines and Gitify's (Electron) `IconName` Get warning, also
   seen at the 07:50 login before this branch's deploy (not ours).
   `~/.local/bin` is on the session PATH, `kaizen-focus` resolves (Mod+T's
   spawn); `shell-smoke --panels` passes.
2. wily (Phase 2: deploy and verify), continued in a session on wily: check
   out the pushed branch, build, the user rebuilds, then the wily checks.
   renoir could not SSH into wily: no key of renoir's is in wily's
   `authorized_keys`.
3. Report, offer `/self-review`, land (ask first): drop the plan commit,
   fast-forward einride's `main` and `main`, push both, remove the renoir
   worktree, and move renoir's `~/.dotfiles` back to `main`.

Possible follow-ups, not on this branch unless the user asks: `menu level` /
`popup` reject an unknown id (an invalid `qs ipc call menu level emoji`
repeats `Menu.qml` TypeErrors while open); `Ui/MenuCard.qml:289` logs
"Binding loop detected for property width" (seen 14:10 on 2026-10-10, cause
not looked at); drift between `stow/kaizen/` and `kaizen.nix` (user wants to
discuss later, possibly a kaizen-doctor or a flake check, see 8).

The user prefers fix commits over amending when amending would cost turns
(conflicts); amending HEAD or dropping a commit with a clean rebase is fine.
Pending on the user: push einride's unpushed commits into the main checkout's
clone (see the einride paragraph).

## Phase 1: home-manager split (done)

Commits, oldest first: `8c79ab1b` session scripts into files; `17eb5c3c` the
shell's user half into home-manager (`kaizen.*` options, `home.nix`);
`96568150` hello, `8198a357` gcloud-auth, `2f9935f6` hello-tray, `05bb9fb2`
calendar, `b1a3b9b4` incident investigator → home-manager; `ac794456` session
launcher gated on `/etc/kaizen`; `25cab69e` `checks.x86_64-linux.kaizen-home`.
(Hashes predate the rebase onto `7fdad478`; `git log main..` has the current
ones.)

Private submodule `nix/hosts/wily/einride`, `main`, unpushed: `a5a621b`
(notification rules via home-manager), `5722863` (investigator via
home-manager). In the worktree, einride's `origin` is the main checkout's local
einride clone: commit there, `git push origin main`, then push from the main
checkout's einride to GitHub. Both repos need pushing (einride first) before
another machine can build wily.

Deployed on renoir (generations 89, 90); `shell-smoke` and `--panels` pass.
Not deployed on wily (deferred by the user). `keep-old` was never proven;
phase 2 makes it moot, since no Nix switch manages kaizen's units any more.

## Phase 2: decisions (made with the user, 2026-10-10)

- kaizen stays in this repo; it is distro-agnostic, not a separate project.
- Nix stays, as `kaizen.nix` NixOS modules per scope, declaring only packages
  and what needs root. home-manager leaves kaizen entirely: `home.nix` files,
  the `kaizen.*` options and the `kaizen-home` check go.
- Config files are JSONC (comments, trailing commas).
- Per-host config in `stow/host/<host>/`; private config in a Stow tree inside
  the private submodule.
- Units are plain files under Stow, enabled by `.wants/` symlinks committed in
  the Stow tree.
- Plugin QML moves into Stow; plugins are selected by name.
- New commits on top of phase 1; no cherry-picking.

## Phase 2: target layout

```text
nix/shared/system/kaizen/
  kaizen.nix                              core: session.nix's system half, every package
                                          the shell, binds and scripts run, a quickshell
                                          wrapped with qtimageformats, emoji data
  CLAUDE.md                               symlink to docs/kaizen/CLAUDE.md (stays)
  plugins/calendar/kaizen.nix             dcal via inputs.dankcalendar.lib.mkDcal pkgs
  plugins/incident-investigator/kaizen.nix  builds investigate (+ go, gopls for its runs)
  plugins/incident-investigator/{investigate/,README.md}  stay where they are
nix/hosts/renoir/kaizen-plugins/
  hello-tray/{kaizen.nix,*.go}            builds hello-tray

stow/kaizen/                              every kaizen host
  .config/quickshell/                     core QML (as today)
  .config/quickshell/plugins/<name>/      generic plugins: calendar, gcloud-auth,
                                          incident-investigator (+ claude-plugin/,
                                          instructions.md, tests)
  .config/niri/                           as today
  .config/kaizen/notification-rules.d/10-kaizen.jsonc
  .config/kaizen/icons/*.svg
  .config/systemd/user/kaizen-*.service   core and generic-plugin units
  .config/systemd/user/<target>.wants/    enablement symlinks
  .local/bin/kaizen-*                     focus, ipc, log, sleep-lock-monitor, emoji
  .local/share/applications/bluetui.desktop

stow/host/<host>/
  .config/kaizen/plugins/<name>.jsonc     enables plugin <name> on the host, holds its config
  .config/kaizen/notification-rules.d/50-<what>.jsonc   e.g. the Signal rule
  .config/quickshell/plugins/<name>/      host-only plugin QML (renoir: hello)
  .config/systemd/user/...                host-only units (renoir: kaizen-hello-tray)

nix/hosts/wily/einride/stow/              private, stowed when present
  .config/kaizen/plugins/incident-investigator.jsonc
  .config/kaizen/notification-rules.d/50-einride.jsonc
```

The directories stay (user, 2026-10-10): only the module files changed, to
`kaizen.nix` (done in 7). `nix/shared/system/kaizen/` holds `kaizen.nix`,
`CLAUDE.md` (a symlink importing `docs/kaizen/*.md`, see the repo CLAUDE.md: "A
`CLAUDE.md` symlink in each kaizen directory") and
`plugins/{calendar,incident-investigator}/`.

### Mechanisms

- **JSONC**: a string-aware stripper in JS (`//`, `/* */`, trailing commas;
  regexes and URLs in strings keep their `//`), with a `qml-test`. Go reads the
  same format with `github.com/tailscale/hujson`.
- **Notification rules** (done, commit 1): every `~/.config/kaizen/notification-rules.d/*.jsonc`,
  in file-name order, concatenated; each file holds an array of rules in
  today's schema. Watched, so edits apply live. A rule's `icon`/`badgeIcon`
  resolve relative to its file. The Nix option types become a pure-JS validator
  that drops an invalid rule with `console.warn`, so `kaizen-log` and the bar's
  log indicator surface it. Order today is core, module-added, user's; file
  names `10-kaizen`, `50-*` keep it.
- **Plugins** (done, commit 2): the shell loads `~/.config/quickshell/plugins/<name>/Plugin.qml`
  for each `~/.config/kaizen/plugins/<name>.jsonc`, in name order (matches
  today's orders: renoir `calendar:hello`, wily
  `calendar:gcloud-auth:incident-investigator`). One file both enables and
  configures a plugin, so the private submodule can enable one the public host
  tree does not mention. A plugin with no settings has `{}`. A plugin reads its
  own file. `KAIZEN_PLUGINS` goes.
- **Plugin units** (done, commit 6): enabled for every kaizen host in `stow/kaizen/`, each with
  `ConditionPathExists=%h/.config/kaizen/plugins/<name>.jsonc`, so it runs
  only where the plugin is enabled. Host-only plugin units (hello-tray) and
  their `.wants/` links live in `stow/host/<host>/`.
- **Investigator config** (done, commit 5): `incident-investigator.jsonc` holds
  `claudeConfigDir`, `sourceDirs`, `instructionFiles`, `tags`,
  `entityPatterns`; `investigate serve` reads it (default path, `-config`
  overrides). `instructions.md` and `claude-plugin/` default to the plugin's
  QML directory. `alerts` become plain rules in einride's rules file: one rule
  per alert carries both the style and the Investigate action
  (`["investigate", "draft"]`, `env.INVESTIGATE_TAG`). The daemon's
  existing `checkTag` replaces the tag assertion (commit 5 adds an error
  notification).
  On Nix, a wrapper prefixes go and gopls to `investigate`'s PATH (commit 6;
  in its `kaizen.nix` since 7), so the unit passes no flags; `go env GOMODCACHE`
  gives `~/go/pkg/mod`. `-tool-path` and `-go-mod-cache` remain as optional
  overrides.
- **Firmware backends** (done, commit 3): detected at runtime (fwupd activatable on the system
  bus); `KAIZEN_FIRMWARE_BACKENDS` goes.
- **Emoji** (done, commit 4; Nix side in kaizen.nix since 7): kaizen.nix builds `share/kaizen/emoji.json` (systemPackages, plus
  `environment.pathsToLink = [ "/share/kaizen" ]`); the shell finds it with
  `StandardPaths.locate(GenericDataLocation, "kaizen/emoji.json")`, as it finds
  the notification sound. The jq program moves into
  `stow/kaizen/.local/bin/kaizen-emoji <emoji-test.txt> <emoji.json>`, which
  Nix runs at build time; off Nix the user runs it into
  `~/.local/share/kaizen/`. `KAIZEN_EMOJI` goes.
- **Units** (done, commit 6): `ExecStart=/usr/bin/env quickshell` (systemd resolves bare names in
  a fixed compile-time path, which NixOS leaves empty; UWSM imports the session
  PATH into the user manager). Scripts by `%h/.local/bin/...`. No `Environment=`
  store paths: `QT_PLUGIN_PATH` is baked into the wrapped quickshell (in
  `kaizen.nix` since 7). `X-SwitchMethod` is gone. `dotfiles-stow` runs
  `systemctl --user daemon-reload` after stowing on a kaizen host when a user
  manager answers.
- **Scripts on PATH** (done, commit 6): `~/.local/bin`, which `exports.sh` already prepends
  once the directory exists; niri binds and QML `Process` find `kaizen-focus`,
  `kaizen-log` there. Takes effect at the next login (session PATH).
- **Private Stow trees** (done, commit 1): `dotfiles-stow` also stows `nix/hosts/<host>/*/stow`
  when present (einride today).
- **Activation order** (done, commit 6): `home.activation.handleDotfiles`
  (stow, `nix/shared/home/common.nix`) is
  `entryAfter [ "writeBoundary" "linkGeneration" ]`, so home-manager removes its old unit links
  before Stow adds the new ones (otherwise stow refuses: existing target not
  owned by stow).

## Phase 2: commits

**Progress (2026-10-10): commits 1-7 (and 2b) and three fixes done; 1-6
deployed on renoir (9c awaits a rebuild); 8 skipped.**
`git log --oneline main..` on this branch, newest first:

```text
d46540c2 fix(kaizen): log hello-tray's errors through slog              (9c)
2af8f5d1 fix(kaizen): log investigate serve's failures through slog     (9b)
0809e1df feat(kaizen): list slog warnings and errors in kaizen-log      (9a)
1432cd26 refactor(kaizen)!: replace the home-manager modules with kaizen.nix (7)
f1ea8904 fix(kaizen): start hello-tray once the tray is up
05e9cedf fix(kaizen): link the emoji data into the profiles
83d9bffb fix(kaizen): skip rules files whose view is not created yet
ced262a4 refactor(kaizen)!: move units, scripts and desktop entries into Stow (6)
3cab4fc5 refactor(kaizen)!: read the investigator's config file         (5)
3af64c08 refactor(kaizen): find emoji data in the XDG data dirs         (4)
65d1184a refactor(kaizen): detect firmware backends                    (3)
8ac31ba5 docs(kaizen): fix the investigator README's link to features.md
d70b3f89 test(kaizen): lint the plugins                                (2b)
c822512a refactor(kaizen)!: select plugins by name                     (2)
d24af497 refactor(kaizen)!: read notification rules from rules files   (1)
4b6d3adf feat(stow): stow private trees in host submodules             (1, split)
c7003173 … a5236faf                                                    (phase 1)
```

einride (`nix/hosts/wily/einride`, branch `main`): `82d7f47` (imports
kaizen.nix, commit 7), `1fedc95` (investigator
config, commit 5), `d0a9e08` (plugin file, commit 2), `043917d` (rules file,
commit 1), on top of phase 1's `5722863`, `a5a621b`. **Nothing is pushed
anywhere.** `043917d`, `d0a9e08`, `1fedc95` and `82d7f47` are not
yet in the main checkout's local einride clone either: the auto-mode
classifier blocks `git push origin main` from the submodule, so ask the user
to run `git -C nix/hosts/wily/einride push origin main` (from the worktree)
before anything builds wily from committed state.

wily and einride: the user offered (2026-10-10) to defer them and continue on
wily from this branch later. Not taken so far: einride edits work fine from
here, and keeping them in each commit keeps every commit building wily (later
commits remove options einride's `default.nix` sets). Only the wily deploy and
its runtime checks wait for wily. Revisit if einride work becomes a blocker.

Each commit builds renoir and wily (`git+file://<worktree>?submodules=1#…`;
1-6 also built `kaizen-home`, which 7 removed), passes `nix fmt` (touched files),
`qml-format`, `qml-lint`, `qml-test`, rumdl on touched Markdown (no new
findings against `git show HEAD:<file>`), and updates the docs it touches
(`docs/kaizen/*.md`, `nix/README.md`, the investigator README, comments).
einride commits land in the submodule with the pointer bump in the matching
main commit. Unrelated fixes found on the way get their own commit.

### Done

1. `refactor(kaizen)!: read notification rules from rules files` (split:
   dotfiles-stow first). JSONC reader `Ui/Jsonc.js`, rules dir watcher,
   validator (`ruleCheck` in `NotificationLogic.js`, the schema's docs);
   core rules and icons in `stow/kaizen/.config/kaizen/`; Signal rule in
   `stow/host/{renoir,wily}`; einride's rules and alerts in its `stow/`.
   Decisions: icon paths resolve relative to the rules file; unknown fields
   (match keys other than app/summary/body included) drop the rule with a
   warning.
2. `refactor(kaizen)!: select plugins by name`. `shell.qml`: a
   `FolderListModel` over `Ui.Paths.config + "/plugins"` (`*.jsonc`, name
   order) and an `Instantiator` of `Loader`s, each loading
   `Quickshell.shellPath("plugins/" + fileBaseName + "/Plugin.qml")`;
   `root.plugins` is rebuilt in `loadPlugins()`. Plugin QML in
   `stow/kaizen/.config/quickshell/plugins/{calendar,gcloud-auth,incident-investigator}`
   (+ the investigator's `instructions.md`, `claude-plugin/`, tests), hello in
   `stow/host/renoir/.config/quickshell/plugins/hello`. Plugins import
   `"../../Ui" as Ui` (relative, like core), not `qs.Ui`. Selection files
   (`{}`): renoir calendar, hello; wily calendar, gcloud-auth; einride
   incident-investigator. gcloud-auth and hello have no Nix module any more.
   The investigator's unit reads `-plugin-dir` and instructions from
   `${config.xdg.configHome}/quickshell/plugins/incident-investigator`. Its
   README stays beside its Nix module and Go source (revisit in 5/7).
   `qml-test` runs `qmltestrunner -input plugins` (recursive).
2b. `test(kaizen): lint the plugins`. `qml-lint` covers `plugins/`; the
   investigator's lookups are cast (`itemAt(0) as Form` / `as Detail`,
   `property Selectable selection`); untyped `Loader.item` and the anonymous
   message delegate get `// qmllint disable missing-property`; the test
   helper `state()` became `actionState()`. Plus `8ac31ba5`, a pre-existing
   broken link.
3. `refactor(kaizen): detect firmware backends`. A `Process` runs
   `busctl --system --json=short call org.freedesktop.DBus
   /org/freedesktop/DBus org.freedesktop.DBus ListActivatableNames` once at
   start; `FirmwareModel.backends(output, known)` keeps the backends whose
   module's `busName` is listed (`Fwupd.js`: `org.freedesktop.fwupd`).
   `kaizen.firmwareBackends`, `KAIZEN_FIRMWARE_BACKENDS` and the
   `services.fwupd.enable` mapping in `session.nix` are gone; `home.nix` and
   `session.nix` now take only `{ pkgs, ... }`.

4. `refactor(kaizen): find emoji data in the XDG data dirs`. The jq program
   is `stow/kaizen/.local/bin/kaizen-emoji <emoji-test.txt> <emoji.json>`
   (stdout); `home.nix` runs it with `bash` into package `kaizen-emoji`
   (`share/kaizen/emoji.json`, in `home.packages` until 7; home-path links
   it). `Ui.Paths.emoji` locates it via `StandardPaths`; Menu.qml and
   notifications' Service.qml read it. Output byte-identical to the old
   `KAIZEN_EMOJI`. `KAIZEN_EMOJI` is gone; the unit's environment holds only
   `QT_PLUGIN_PATH`.

5. `refactor(kaizen)!: read the investigator's config file`. `investigate
   serve [-config FILE] [-dir DIR] [-tool-path PATH] [-go-mod-cache DIR]`
   reads the plugin file (`readConfig` → `readJSONC`, hujson, unknown fields
   rejected): `claudeConfigDir` (required), `sourceDirs`,
   `instructionFiles` (after `-dir`'s `instructions.md`), `tags`,
   `entityPatterns`; paths absolute or `~/`. `-dir` defaults to
   `~/.config/quickshell/plugins/incident-investigator` (`claude-plugin/`).
   `CLAUDE_CONFIG_DIR` is set per run; `go env GOMODCACHE` without
   `-go-mod-cache`; a failed `draft` runs `notify-send -u critical`. The
   `kaizen.incidentInvestigator` options are gone (the unit's
   `-tool-path`/`-go-mod-cache` flags were replaced by a wrapper in 6). einride's values moved into its plugin file
   (verified equal). README documents the file; note: `kaizen-log` shows
   only systemd's failure line for a bad config, since `investigate:` errors
   carry no level word (possible follow-up: prefix `error:`).

6. `refactor(kaizen)!: move units, scripts and desktop entries into Stow`.
   Decisions (user, 2026-10-10): investigate gets go/gopls through a wrapper
   prefixing PATH (flags stay optional); `dotfiles-stow` runs the
   daemon-reload (not a manual documented step).
   Units in `stow/kaizen/.config/systemd/user/` (shell, tray-ready,
   sleep-lock, dcal, incident-investigator; the last two with
   `ConditionPathExists` on their plugin file) and renoir's hello-tray in
   `stow/host/renoir/`, each enabled by a committed `.wants/` link. Programs
   through `/usr/bin/env` (user manager PATH has the per-user profile),
   scripts (`kaizen-{focus,ipc,log,sleep-lock-monitor}`, moved from
   `nix/shared/system/kaizen/scripts/`) from `%h/.local/bin`, tray-ready an
   inline `/bin/sh -c`. Desktop entries: `stow/kaizen/.local/share/
   applications/bluetui.desktop`, renoir's `hello-tray.desktop`. Wrappers in
   home.nix: quickshell (`QT_PLUGIN_PATH`, `lib.hiPrio` over the plain
   quickshell dankcalendar's module installs), investigate (`--prefix PATH`
   go, gopls). `dotfiles-stow` daemon-reloads on a kaizen host;
   `handleDotfiles` after `linkGeneration`. Docs: README Where it lives
   (unit rows, `.wants/` bullet, Adding something), plugins.md,
   development.md, investigator README, nix/README.md, `kaizen_units`
   comment. Checked: home-files now hold only `tray.target`; the home
   profile's `qs`/`quickshell` carry `QT_PLUGIN_PATH`, wily's `investigate`
   the go/gopls PATH; `systemd-analyze verify` clean but for the unstowed
   script; stow into a scratch target resolves every link. Deploy note:
   `~/.local/bin` does not exist on renoir yet, so `kaizen-focus` (Mod+T)
   and the shell's `kaizen-log` need a fresh login after the deploy.

7. Done (`1432cd26`). Packages diffed by name against the previous commit on
   both hosts: every kaizen package left `home.packages` and is in
   `environment.systemPackages`, one quickshell (the wrapper). Toplevels
   checked: `sw/share/kaizen/emoji.json`, `sw/share/sounds/freedesktop`, `qs`
   and `quickshell` carry `QT_PLUGIN_PATH`, `dcal`, renoir `hello-tray`, wily
   `investigate` with go and gopls on PATH. dcal's package carries
   `share/systemd/user/dcal.service` into `/run/current-system/sw`, which is
   on the user unit path; it is disabled, as the same unit already was from
   the home-manager profile. Off NixOS docs now list the packages and the
   manual `kaizen-emoji` run; no standalone home-manager.
   Layout: `nix/shared/system/kaizen/kaizen.nix` (session.nix's content,
   home.nix's packages in `environment.systemPackages`, the quickshell
   wrapper without `hiPrio`, the emoji runCommand, `pathsToLink`);
   `plugins/calendar/kaizen.nix` (`inputs.dankcalendar.lib.mkDcal pkgs`, not
   its modules); `plugins/incident-investigator/kaizen.nix` (investigate +
   go/gopls wrapper); renoir's `kaizen-plugins/hello-tray/kaizen.nix`. Hosts
   import each `kaizen.nix` by file; einride's `default.nix` imports the
   investigator's. `checks.x86_64-linux.kaizen-home` is gone from
   `flake.nix`. Docs: README (Where it lives, Off NixOS rewritten, Adding
   something), plugins.md, development.md, nix/README.md, the investigator
   README; comments in `dotfiles-stow`, `sourcing.sh`, calendar `Plugin.qml`.
   Deploy checks: Next steps 1.


Fixes found deploying 1-6 on renoir (own commits, not amends):

- `83d9bffb` (bug from 1): `loadRules()` in notifications' `Service.qml`
  skips a null `ruleFiles.objectAt(i)`; the `Instantiator` reports
  `objectAdded` for a file while later files' views are not created yet,
  which logged `TypeError: Cannot read property 'path' of null` per file.
- `05e9cedf` (bug from 4): `environment.pathsToLink = [ "/share/kaizen" ]` in
  `session.nix`. With `home-manager.useUserPackages`, `home.packages` land in
  `/etc/profiles/per-user/<user>`, a NixOS buildEnv that links only
  `pathsToLink`, so `emoji.json` never reached the XDG data dirs. Commit 7
  moves the line into `kaizen.nix`.
- `f1ea8904` (pre-existing since phase 1): renoir's `kaizen-hello-tray` is
  `WantedBy=wayland-session-xdg-autostart@niri.target` (link moved to that
  `.wants/`) and `After=kaizen-shell.service kaizen-tray-ready.service`; it
  had registered before the shell's StatusNotifierWatcher and logged
  "systray error: failed to register" every login, lighting the log
  indicator. `plugins.md`'s tray-plugin bullet says so.

### 8 and 9

8. Skipped (user, 2026-10-10): `kaizen-doctor`, checking the programs, D-Bus
   names and files a session needs. NixOS hosts get them from `kaizen.nix`;
   it pays off only once kaizen runs off NixOS, so write it then, against a
   real machine. The drift it would catch on NixOS (Stow calling a program
   `kaizen.nix` does not install) could instead be a flake check grepping
   `stow/kaizen/` for program names against the toplevel's `sw/bin`; not
   planned unless drift bites.
9. Logging (decided with the user, 2026-10-10). Rule: `kaizen-log` lists
   what nothing on screen shows: the shell's QML/JS, units and plugin
   daemons; an error an application shows in its window or a toast stays out
   (features.md › Log, plugins.md). Go daemons and tray apps log through slog
   (`slog.NewTextHandler(os.Stderr, nil)`, default `time=`), never hand-made
   level words or Go's levelless `log`.
   - 9a `0809e1df`: `kaizen-log` reads slog's `level=` field, anchored
     `^(time=\S+ )?level=`, and drops `time=` from the message; docs.
   - 9b `2af8f5d1`: `investigate serve`'s body moved into `runServe`; any
     error it returns is logged with serve's slog logger (a bad config shows
     with its reason). `main()` still prints `investigate: <err>` (a second,
     unlisted journal line; user accepted). Client verbs keep plain stderr:
     the window's banner collects it, and `draft` from a notification button
     runs through `execDetached`, whose stdout/stderr Quickshell 0.3.1 sends
     to /dev/null (`unbindStdout` defaults true), showing a toast instead.
     The daemon's slog lines cover only backend failures (save, transcript,
     notify, tray, skipped state files); request errors go to the client
     (`resp.Error`) and run failures to the window (`inv.Error`).
   - 9c `d46540c2`: hello-tray sets a slog TextHandler as default;
     `slog.Error` + `os.Exit(1)` replace `log.Fatal`.
   - A first attempt, `e0c607c4` (`investigate: error:` prefixes), was
     dropped from the branch: the user wants Go's own logging, not level
     words.

## Phase 2: deploy and verify (renoir, then wily)

- Renoir got 1-6 on 2026-10-10 (user rebuilt from `~/.dotfiles` detached at
  `ced262a4`). As expected, the switch stopped the units home-manager no
  longer managed; `systemctl --user daemon-reload && systemctl --user start
  kaizen-shell kaizen-sleep-lock` recovered, and a full logout and login
  started the rest and put `~/.local/bin` on the session PATH. Later commits
  deploy by moving the detached checkout (see Resume here) and, for Nix
  changes, a user-run rebuild. Always from an unlocked session; idle locking
  was already off on renoir (`enabled: false`), nothing to restore.
- Check: units load from `~/.config/systemd/user` as Stow links;
  `systemctl --user list-dependencies wayland-session@niri.target`; plugin
  units skip where their condition fails; `kaizen-log` empty; `shell-smoke`,
  `--panels`; edit a rules file and a plugin's QML and see them apply without a
  rebuild; a Signal-style `notify-send` gets its rule; the log indicator and
  Mod+T work (`~/.local/bin` on PATH); `qs` has `QT_PLUGIN_PATH` (WebP
  wallpaper thumbnails); bluetui and hello-tray appear in Apps; `kaizen_units mask`
  still masks (Stow units sit in `~/.config/systemd/user`, below
  `user.control`); the sound and emoji picker work; firmware panel reads fwupd.
- Renoir, 9a-9b: `~/.dotfiles` at `d46540c2`, shell restarted, the log
  service follows the new `kaizen-log`; `kaizen-log --json` output identical
  to the old script's on this boot; synthetic slog, Quickshell, Go `log` and
  plain lines filtered as intended (INFO and `level=` inside a quoted value
  dropped). 9c awaits the rebuild.
- Renoir, generation 95 (7), 2026-10-10: `qs`, `quickshell`, `dcal`,
  `hello-tray` in `/run/current-system/sw/bin`, none in the per-user profile;
  the restarted shell runs the wrapper (its `QT_PLUGIN_PATH` holds
  qtimageformats); `sw/share/kaizen/emoji.json` and the freedesktop sounds
  present; the emoji picker lists emoji; `systemctl --user --failed` empty;
  kaizen-shell, -dcal, -sleep-lock, -hello-tray active; `shell-smoke --panels`
  passes; `kaizen-log` since the restart holds only the known portal line.
  Item 2 of Next steps (hello-tray at login, Mod+T) still open.
- Renoir, 2026-10-10 (1-6 + fixes): units are Stow links, plugin units start
  or skip by condition, `~/.local/bin` on the session PATH after a fresh
  login, `shell-smoke --panels` passes, the Signal rule styles a faked toast,
  a rules-file edit applies live, removing `hello.jsonc` drops the plugin
  live, fwupd detected, bluetui/hello-tray entries, the shell has
  qtimageformats and the sound, the emoji picker lists emoji (after the
  `pathsToLink` rebuild). Still open on renoir: hello-tray's ordering at the next login (no
  "failed to register" in `kaizen-log`); Mod+T. `kaizen_units mask` not
  exercised (user.control outranks `~/.config/systemd/user` per systemd).
- Verified on renoir: 1 (rules apply live, server loads), 2 (plugins load
  and unload live), 3 (fwupd), 4 (emoji picker, after `05e9cedf`). Slack
  shortcodes not seen yet.
- wily: also the investigator (the daemon starts from the JSONC file and
  `kaizen-log` is empty; a broken plugin file, e.g. an unknown field, puts
  `level=ERROR msg=serve error=…` in `kaizen-log` (restore it after); a draft with an unknown `INVESTIGATE_TAG`, e.g.
  `NOTIFICATION_APP=x INVESTIGATE_TAG=nope investigate draft`, shows the
  critical toast; draft from a faked alert, tag check, the
  `as Form`/`as Detail` casts, a run's gopls finds go (wrapper PATH): Enter on a row focuses the draft's notes or
  the follow-up field, palette Run/Discard on a draft), gcloud-auth's
  indicator, and einride's private tree stowed.
- Then report, offer `/self-review`, and land (ask first): fast-forward `main`,
  push einride, then main; remove the worktree.

## Risks and open points

- `~/.dotfiles` is detached at the branch tip until the branch lands. Other
  sessions committing kaizen edits on `~/.dotfiles` would land on the
  detached HEAD; at landing, check `git -C ~/.dotfiles log` for such commits
  before switching it back to `main`.
- QtTest cannot load Quickshell types, so QML runtime behaviour is only
  proven on the deployed shell (as 1-3 were on renoir).
- 7 moved kaizen's packages from `/etc/profiles/per-user/fredrik` to the
  system profile (`/run/current-system/sw`). The built toplevel has
  `sw/share/sounds/freedesktop` and `sw/share/kaizen/emoji.json`; that the
  running session finds them is checked after the rebuild (Next steps 1).

## Handy commands

```sh
# Builds, from the worktree root; wily needs submodules. Build from the working
# tree: `?ref=HEAD` fetches einride from GitHub, which lacks the unpushed commits.
nix build "git+file://$PWD?submodules=1#nixosConfigurations.renoir.config.system.build.toplevel" --no-link
nix build "git+file://$PWD?submodules=1#nixosConfigurations.wily.config.system.build.toplevel" --no-link
# A home-manager attribute, e.g. to inspect generated files or the profile:
#   …#nixosConfigurations.<host>.config.home-manager.users.fredrik.home-files
#   …#nixosConfigurations.<host>.config.home-manager.users.fredrik.home.path

# Package names per host, e.g. to diff before/after a Nix change:
nix eval --json "git+file://$PWD?submodules=1#nixosConfigurations.renoir.config" \
  --apply 'c: { sys = map (p: p.name or "?") c.environment.systemPackages;
                home = map (p: p.name or "?") c.home-manager.users.fredrik.home.packages; }'

# Units and stow: validate, and stow into a scratch target to check the links.
systemd-analyze --user verify stow/kaizen/.config/systemd/user/*.service
nix shell nixpkgs#stow -c stow --dir=stow --target=<scratch> --no-folding kaizen

# QML checks (the repo devshell, not #dev); the tasks cd to the tree themselves.
nix develop . -c bash -c "qml-format && qml-lint && qml-test"

# Format touched Nix files only: plain `nix fmt` is nixfmt reading stdin, and hangs.
nix fmt -- path/a.nix path/b.nix
```

Baseline before phase 2: `qml-test` and `qml-lint` pass; `qml-lint` prints one
known Info (unused import in `modules/services/idle/Service.qml`).

Gotchas:

- Builds use `git+file://`, which sees only tracked files: `git add` new
  files a build needs (untracked Stow files do not matter to Nix).
- rumdl: run from the file's directory through `nix develop ~/.dotfiles#dev -c
  rumdl fmt --config 'global.disable = ["MD034", "MD036", "MD040"]' --config
  "MD013.line-length = 80" --config "MD013.reflow = true" <file>`. Pre-existing
  findings: docs/kaizen/README.md lines 48/52 (mermaid), development.md's
  rsync line, the investigator README's long lines.
- `nix build … | grep` reports grep's status; use `nix build … 2>/dev/null &&
  echo OK`.
- `qml-format` moves a trailing `// qmllint disable` off an unbraced `if`/`else
  if` body; brace the branch.
- Quickshell watches only files its scanner reaches by import from
  `shell.qml` (`src/core/scan.cpp` in
  `~/code/public/github.com/quickshell-mirror/quickshell`, v0.3.1), so plugins
  need `qs ipc call shell reload`.
- The Bash tool runs zsh: a word starting with `=` (`echo =====`) is command
  expansion, an unmatched glob is an error (nomatch), and `$VAR` holding
  several paths is not word-split (spell the paths out).
- Format only touched files (memory: repo-wide format pending); rumdl with the
  flags in `stow/shared/.config/nvim-fredrik/plugin/conform.lua`.
- Equivalence check when moving config out of Nix: `nix eval --json` the old
  option from the working tree before deleting it (e.g.
  `…#nixosConfigurations.wily.config.home-manager.users.fredrik.kaizen.plugins`),
  then compare with the new files parsed through `Ui/Jsonc.js` (node from
  `nix develop ~/.dotfiles#dev`). Commit 1 did this for both hosts' rules.
