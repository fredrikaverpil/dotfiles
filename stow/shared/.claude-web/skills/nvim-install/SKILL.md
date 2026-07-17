---
name: nvim-install
description: Install Neovim and stand up the nvim-fredrik config in the Claude Code web sandbox (the cloud environment), where no Neovim exists. Use this before testing any Neovim config change in a web session, e.g. checking out a PR branch that touches nvim-fredrik and observing its runtime behavior. Installs Neovim via Nix from the binary cache with no GitHub access, wires the repo's config into place, launches Neovim headless with a listen socket, and exports $NVIM so the `neovim` RPC skill can drive it. Web-sandbox only.
---

# Install Neovim in the web sandbox

This is the missing half of the `neovim` RPC skill: that skill drives a running
Neovim via `$NVIM`, but the sandbox ships neither the binary nor a parent
editor. This skill installs Neovim, launches it **headless** on a listen socket,
and exports `$NVIM` so the `neovim` skill's commands work verbatim afterwards.

**Scope:** web sandbox only (`CLAUDE_CODE_REMOTE=true`). Do not run on a real
machine — there Neovim is managed by bob at `~/.local/share/bob/nvim-bin/nvim`.

## Why Nix, not bob

Nix installs Neovim from `*.nixos.org` (allow-listed by default), so the binary
needs **no GitHub access** — and `nixpkgs-unstable` ships a current Neovim with
`vim.pack`, which `nvim-fredrik` requires.
bob is available too (see the end), but `bob install` downloads Neovim as a
**GitHub release asset**, which the GitHub proxy blocks unless `neovim/neovim`
is attached to the session — regardless of network level. So Nix is the default;
bob is an opt-in.

## Step 0 — Network prerequisites

Two independent mechanisms gate traffic; they bite at different points.

1. **The binary (this skill):** substituted from the Nix cache (`*.nixos.org`),
   reachable under the default **Trusted** network policy. No GitHub, no action.
   Verify:

   ```bash
   curl -sSI -o /dev/null -w "cache:    %{http_code}\n" https://cache.nixos.org
   curl -sSI -o /dev/null -w "channels: %{http_code}\n" https://channels.nixos.org/nixpkgs-unstable/nixexprs.tar.xz
   ```

2. **The plugins (a full `nvim-fredrik` run):** at startup `vim.pack` clones ~50
   plugins. These split three ways:
   - **Public GitHub clones** — already work under the default Trusted policy
     (`github.com` is allow-listed). No action.
   - **codeberg.org plugins** (nvim-lint, nvim-dap, nvim-dap-python) —
     **required and blocked by default.** Edit the environment → **Network
     access** selector → **Custom** → in **Allowed domains** add the bare
     `codeberg.org` → tick *"Also include default list of common package
     managers"* → save. This rebuilds the environment. See
     https://code.claude.com/docs/en/claude-code-on-the-web. **Gotcha:** use the
     apex `codeberg.org`, not `*.codeberg.org` — the wildcard matches only
     subdomains, but the plugin `src` URLs are `https://codeberg.org/...`, so a
     `*.codeberg.org`-only allowlist still 403s the clones. (`Full` network
     access also works but is broader than needed.)
   - **GitHub release assets** (codediff's prebuilt lib, Mason LSP servers,
     treesitter parsers) — gated by the GitHub proxy to *attached* repos
     **regardless of network level**, so they may 403. Optional for observing
     most config behavior; attach a specific repo with `add_repo` only if the
     change under test needs it.

## Step 1 — Ensure Nix is installed

Follow the **`nix-install`** skill (apt `nix-bin` + single-user config). In
short:

```bash
apt-get update
apt-get install -y --no-install-recommends nix-bin
mkdir -p /etc/nix
grep -q '^build-users-group' /etc/nix/nix.conf 2>/dev/null \
  || echo 'build-users-group =' >> /etc/nix/nix.conf
```

## Step 2 — Install Neovim from nixpkgs-unstable

Everything is substituted from `cache.nixos.org`; nothing is compiled and no
GitHub is touched.

```bash
nix-env -iA neovim -f https://channels.nixos.org/nixpkgs-unstable/nixexprs.tar.xz
export PATH="$HOME/.nix-profile/bin:$PATH"
nvim --version | head -1                                              # NVIM v0.12.x
nvim --headless -c 'lua io.write(tostring(vim.pack ~= nil))' -c 'qa'  # expect: true
```

## Step 3 — Wire the config into place and persist the environment

The config lives in the cloned repo. Two env vars point Neovim at it:

- **`NVIM_APPNAME=nvim-fredrik`** makes Neovim read `~/.config/nvim-fredrik`
  (the symlink created below).
- **`$DOTFILES`** is the **dotfiles repo root**. The config builds paths from it
  (Mason lockfile, lint configs, snippets); left unset it falls back to
  `~/.dotfiles`, which doesn't exist in the sandbox, so those lookups silently
  resolve to missing files. Point it at the clone root.

**Each Bash call is a fresh shell whose environment is snapshotted at session
start** — `~/.bashrc` is not re-run per call (its non-interactive `return` guard
exits early), so appending an `export` or `source` line there does **not** reach
later calls. The filesystem does persist, though: write the env to a file and
`source` it at the top of every later call that needs it — including every
`neovim`-skill call, which keys off `$NVIM`.

```bash
repo="/home/user/dotfiles"        # adjust if the repo is cloned elsewhere
mkdir -p ~/.config
ln -sfn "$repo/nvim-fredrik" ~/.config/nvim-fredrik

cat > ~/.nvim-sandbox.env <<EOF
export PATH="\$HOME/.nix-profile/bin:\$PATH"
export DOTFILES="$repo"
export NVIM_APPNAME=nvim-fredrik
export NVIM=/tmp/nvim-fredrik.sock
EOF
source ~/.nvim-sandbox.env
```

## Step 4 — Launch Neovim headless with a listen socket

This is the bridge to the `neovim` skill. Start a backgrounded headless
instance listening on `$NVIM`, so the RPC skill's commands — which all key off
`$NVIM` — work unchanged. The **first** launch clones all plugins via `vim.pack`
(needs Step 0 item 2) and can take a few minutes.

```bash
source ~/.nvim-sandbox.env        # env doesn't persist across calls; re-source
rm -f "$NVIM"
# --headless keeps it alive as long as the socket is served; run detached.
nohup nvim --headless --listen "$NVIM" >/tmp/nvim-headless.log 2>&1 &
echo $! > /tmp/nvim-fredrik.pid   # record PID so a later restart can kill it
# Wait for the socket to accept RPC (plugin cloning happens during startup).
for i in $(seq 1 120); do
  [ -S "$NVIM" ] && nvim --server "$NVIM" --remote-expr '1' >/dev/null 2>&1 && break
  sleep 2
done
echo "NVIM socket: $NVIM"; tail -8 /tmp/nvim-headless.log
```

`403` / `CONNECT tunnel failed` lines in the log point at the Step 0 item 2
gaps (usually `codeberg.org` if it isn't allowed yet, or a GitHub release
asset). The editor still runs; only the plugins that failed to clone are
missing.

## Step 5 — Verify and hand off to the `neovim` skill

```bash
source ~/.nvim-sandbox.env
nvim --server "$NVIM" --remote-expr 'v:version'
nvim --server "$NVIM" --remote-expr 'luaeval("vim.fn.stdpath(\"config\")")'
```

With `~/.nvim-sandbox.env` sourced, `$NVIM` is set exactly as if Claude Code
were running inside a Neovim terminal, so **switch to the `neovim` skill** for
all further interaction (buffer state, running Lua, inspecting diagnostics, LSP,
plugins). Start each of those Bash calls with `source ~/.nvim-sandbox.env` too —
the env doesn't carry over on its own.

## One-shot checks (skip the persistent server)

Steps 4–5 stand up a *persistent* `--listen` server so the `neovim` skill can
drive it across turns. You only need that for interactive, multi-step work. For
an observe-once question — *does this config change load cleanly? what does the
formatter do to this file?* — skip the socket entirely and use a
**self-terminating** headless run that loads the real config, does its thing,
prints, and quits with `qa!`. It exits cleanly and sidesteps all of the
launch/restart/socket handling (and its footguns) above. Prefer it whenever you
don't actually need cross-turn RPC.

```bash
source ~/.nvim-sandbox.env
# "does my config change load without error?"
nvim --headless \
  -c 'lua io.write("config="..vim.fn.stdpath("config").."\n")' \
  -c 'qa!'
```

Exercising behaviour follows the same shape — open a file so its filetype
plugins load, run the operation, print, quit:

```bash
source ~/.nvim-sandbox.env
nvim --headless path/to/file.go \
  -c '<command that performs the operation, e.g. runs the formatter>' \
  -c 'lua io.write(table.concat(vim.fn.getline(1, "$"), "\n").."\n")' \
  -c 'qa!'
```

`-c` commands run in order after startup. Opening a file fires `FileType`
loading, but a plugin that lazy-loads on its *own* event or command only
activates once you invoke that command — so trigger the real operation rather
than assuming the plugin is already loaded.

## Testing a config-change PR

The `nvim-fredrik` config is part of *this* repo, so a PR that changes it is
just a branch checkout — no separate config repo:

```bash
git -C /home/user/dotfiles fetch origin <pr-branch>
git -C /home/user/dotfiles checkout <pr-branch>
```

Then restart the headless instance so the new config is sourced. Kill the old
instance by the PID recorded at launch and **wait until it is actually gone**
before relaunching. Two traps make this fiddlier than it looks:

- **Don't `pkill -f 'nvim --headless --listen'`.** Each Bash call runs as
  `bash -c '<the whole script>'`, so that string is in the script shell's own
  arguments; `pkill -f` matches and kills the script itself, which dies with a
  `128 + signal` exit (e.g. `143`/`144`) before it ever relaunches. Killing the
  recorded PID sidesteps the pattern entirely.
- **Let the old process exit before reusing `$NVIM`.** A dying nvim unlinks its
  own socket on the way out. Relaunch on the same path too soon and the old
  instance's cleanup deletes the *new* socket — RPC then fails with "connection
  refused" even though the new process is alive. So confirm it's gone (SIGKILL
  as a fallback) before `rm`-ing the path and starting fresh.

```bash
source ~/.nvim-sandbox.env
oldpid="$(cat /tmp/nvim-fredrik.pid 2>/dev/null)"
if [ -n "$oldpid" ]; then
  kill "$oldpid" 2>/dev/null || true
  for i in $(seq 1 50); do kill -0 "$oldpid" 2>/dev/null || break; sleep 0.2; done
  kill -9 "$oldpid" 2>/dev/null || true   # force if it ignored SIGTERM
fi
rm -f "$NVIM"
nohup nvim --headless --listen "$NVIM" >/tmp/nvim-headless.log 2>&1 &
echo $! > /tmp/nvim-fredrik.pid
for i in $(seq 1 120); do
  [ -S "$NVIM" ] && nvim --server "$NVIM" --remote-expr '1' >/dev/null 2>&1 && break
  sleep 2
done
```

Now drive the behavior under test via the `neovim` skill — e.g. for a
neotest/diagnostics change, open a test file, run the command, then read the
diagnostics:

```bash
nvim --server "$NVIM" --remote-expr 'luaeval("vim.json.encode(vim.diagnostic.get(0))")'
```

## Optional: bob for explicit stable/nightly management

If you specifically want a bob-managed version (one-word stable/nightly switch,
matching the real machines), install bob from Nix and let it fetch Neovim — but
note bob's download is a GitHub **release asset**, so `neovim/neovim` must be
attached to the session first (`add_repo neovim/neovim`; Claude only runs it
when you ask). Network level alone will not unblock it.

```bash
TARBALL=https://channels.nixos.org/nixpkgs-unstable/nixexprs.tar.xz
nix-env -iA bob-nvim -f "$TARBALL"          # the binary is `bob`
export PATH="$HOME/.nix-profile/bin:$PATH"
bob use nightly                              # needs neovim/neovim attached
export PATH="$HOME/.local/share/bob/nvim-bin:$PATH"
```

If you use this, add `$HOME/.local/share/bob/nvim-bin` to the `PATH` line in
`~/.nvim-sandbox.env` (Step 3). For most sandbox testing the Step 2 Nix binary
is simpler and needs no attachment.

## Caveats

- **First launch is slow** — plugin cloning is network-bound and serial.
- **Mason / LSP servers and treesitter parsers are best-effort.** They pull
  extra tools from GitHub release assets and compile locally; if a change under
  test doesn't depend on a language server, you don't need them. Failures are
  logged in `/tmp/nvim-headless.log` and don't prevent the rest of the config
  loading.
- **Headless has no UI.** Inspect state via RPC (`vim.diagnostic.get`,
  `vim.lsp.get_clients`, buffer APIs), not by looking at a screen.
- **Ephemeral.** The install and config live only for this environment's
  lifetime; nothing is committed. Re-run the skill in a fresh environment.
