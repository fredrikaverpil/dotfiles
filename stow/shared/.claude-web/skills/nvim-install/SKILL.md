---
name: nvim-install
description: Install Neovim and stand up the nvim-fredrik config in the Claude Code web sandbox (the cloud environment), where no Neovim exists. Use this before testing any Neovim config change in a web session, e.g. checking out a PR branch that touches nvim-fredrik and observing its runtime behavior. Installs bob via Nix and a stable/nightly Neovim via bob, wires the repo's config into place, launches Neovim headless with a listen socket, and exports $NVIM so the `neovim` RPC skill can drive it. Web-sandbox only.
---

# Install Neovim in the web sandbox

This skill bootstraps a real, running Neovim in the Claude Code web sandbox so
config changes (e.g. a PR against `nvim-fredrik`) can be exercised and observed.
It is the missing half of the `neovim` RPC skill: that skill assumes a running
Neovim exposed via `$NVIM`, but the sandbox has neither the binary nor a parent
editor. This skill installs the binary, launches Neovim **headless** with a
listen socket, and exports `$NVIM` so every command in the `neovim` skill works
verbatim afterwards.

Neovim is installed with **bob** — the same version manager used on the real
machines, so stable/nightly is a one-word switch — and bob itself is installed
with **Nix**.

**Scope:** web sandbox only (`CLAUDE_CODE_REMOTE=true`). Do not run on a real
machine — there bob already manages Neovim at
`~/.local/share/bob/nvim-bin/nvim`.

## Step 0 — Network prerequisites

Two independent needs, in order of when they bite:

1. **bob + the Neovim binary:** bob is installed from the Nix cache (no GitHub),
   but bob then downloads Neovim from **github.com/neovim/neovim**. In the
   sandbox, GitHub is gated by the proxy to this session's repo scope, so bob's
   download is denied until `neovim/neovim` is in scope. Enable it with
   `add_repo neovim/neovim` (ask Claude: *"add the neovim/neovim repo"* — Claude
   only runs `add_repo` when you ask), or widen the environment network policy
   to allow `github.com` / `api.github.com` / `objects.githubusercontent.com`.
2. **The plugins (to actually run `nvim-fredrik`):** at startup `vim.pack` clones
   ~50 plugins from **github.com** and **codeberg.org**. Both are blocked by
   default (`403`), so the config installs and *starts* but plugin cloning fails
   until the environment network policy allows those hosts. This is an
   environment-config change (claude.ai environment editor → network / allowed
   hosts: add `github.com` and `codeberg.org`), then rebuild. See
   https://code.claude.com/docs/en/claude-code-on-the-web.

Widening the network policy to allow `github.com` satisfies both at once, which
is the simplest route to a full config run.

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

## Step 2 — Install bob via Nix, then Neovim via bob

The nixpkgs attribute is `bob-nvim` (the binary is `bob`), substituted from the
cache with no GitHub. Then bob installs Neovim (needs Step 0 item 1).
`nvim-fredrik` requires **nightly** (`vim.pack` + `vim._core.ui2`); for other
configs swap `nightly` for `stable` or a version like `v0.11.0`.

```bash
TARBALL=https://channels.nixos.org/nixpkgs-unstable/nixexprs.tar.xz
nix-env -iA bob-nvim -f "$TARBALL"
export PATH="$HOME/.nix-profile/bin:$PATH"
bob --version

bob use nightly     # installs if missing, then makes it the active version
export PATH="$HOME/.local/share/bob/nvim-bin:$PATH"
nvim --version | head -1                                              # NVIM v0.12.x
nvim --headless -c 'lua io.write(tostring(vim.pack ~= nil))' -c 'qa'  # expect: true
```

## Step 3 — Wire the config into place and persist the environment

The config lives in the cloned repo. `NVIM_APPNAME=nvim-fredrik` makes Neovim
read `~/.config/nvim-fredrik`, and the config expects `$DOTFILES` set (it
defaults to `~/.dotfiles`, which does not exist here).

**The sandbox runs each command in a fresh shell initialized from your
profile**, so plain `export`s do not survive from one Bash call to the next —
and the `neovim` skill you hand off to later relies on `$NVIM` being present.
Persist the environment into a file the profile sources, so every subsequent
shell (and the `neovim` skill) inherits it:

```bash
repo="/home/user/dotfiles"        # adjust if the repo is cloned elsewhere
mkdir -p ~/.config
ln -sfn "$repo/nvim-fredrik" ~/.config/nvim-fredrik

cat > ~/.nvim-sandbox.env <<EOF
export PATH="\$HOME/.nix-profile/bin:\$HOME/.local/share/bob/nvim-bin:\$PATH"
export DOTFILES="$repo"
export NVIM_APPNAME=nvim-fredrik
export NVIM=/tmp/nvim-fredrik.sock
EOF
grep -qxF 'source ~/.nvim-sandbox.env' ~/.bashrc 2>/dev/null \
  || echo 'source ~/.nvim-sandbox.env' >> ~/.bashrc
source ~/.nvim-sandbox.env
```

## Step 4 — Launch Neovim headless with a listen socket

This is the bridge to the `neovim` skill. Start a backgrounded headless
instance listening on `$NVIM` (persisted in Step 3), so the RPC skill's
commands — which all key off `$NVIM` — work unchanged. The **first** launch
clones all plugins via `vim.pack` (needs Step 0 item 2) and can take a few
minutes.

```bash
rm -f "$NVIM"
# --headless keeps it alive as long as the socket is served; run detached.
nohup nvim --headless --listen "$NVIM" >/tmp/nvim-headless.log 2>&1 &
# Wait for the socket to accept RPC (plugin cloning happens during startup).
for i in $(seq 1 120); do
  [ -S "$NVIM" ] && nvim --server "$NVIM" --remote-expr '1' >/dev/null 2>&1 && break
  sleep 2
done
echo "NVIM socket: $NVIM"; tail -8 /tmp/nvim-headless.log
```

`403` / `CONNECT tunnel failed` lines in the log mean github.com/codeberg.org
are still not allowed (back to Step 0 item 2). The editor still runs; only the
plugins that failed to clone are missing.

## Step 5 — Verify and hand off to the `neovim` skill

```bash
nvim --server "$NVIM" --remote-expr 'v:version'
nvim --server "$NVIM" --remote-expr 'luaeval("vim.fn.stdpath(\"config\")")'
```

`$NVIM` is now set exactly as if Claude Code were running inside a Neovim
terminal, so **switch to the `neovim` skill** for all further interaction
(buffer state, running Lua, inspecting diagnostics, LSP, plugins). Note: the
`neovim` skill's `NVIM_APPNAME` stdout-warning filter targets the dotfiles
`nvim` wrapper; here you invoke the real binary directly, so the warning usually
does not appear — the filter is harmless either way.

## Testing a config-change PR

The `nvim-fredrik` config is part of *this* repo, so a PR that changes it is
just a branch checkout — no separate config repo:

```bash
git -C /home/user/dotfiles fetch origin <pr-branch>
git -C /home/user/dotfiles checkout <pr-branch>
```

Then restart the headless instance so the new config is sourced:

```bash
nvim --server "$NVIM" --remote-expr 'execute("qa!")' 2>/dev/null || true
rm -f "$NVIM"
nohup nvim --headless --listen "$NVIM" >/tmp/nvim-headless.log 2>&1 &
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

## Alternative: Neovim directly via Nix (no GitHub for the binary)

If you only need a modern Neovim and don't want to allowlist GitHub for the
binary, skip bob — `nixpkgs-unstable` currently ships Neovim 0.12.x (which has
`vim.pack` and `vim._core.ui2`), substituted straight from the cache:

```bash
nix-env -iA neovim -f https://channels.nixos.org/nixpkgs-unstable/nixexprs.tar.xz
export PATH="$HOME/.nix-profile/bin:$PATH"
```

Update Step 3's persisted `PATH` to drop the bob path if you use this. The
plugin-network prerequisite (Step 0 item 2) still applies to a full config run.

## Caveats

- **First launch is slow** — plugin cloning is network-bound and serial.
- **Mason / LSP servers and treesitter parsers are best-effort.** They pull
  extra tools from GitHub and compile locally; if a change under test doesn't
  depend on a language server, you don't need them. Failures are logged in
  `/tmp/nvim-headless.log` and don't prevent the rest of the config loading.
- **Headless has no UI.** Inspect state via RPC (`vim.diagnostic.get`,
  `vim.lsp.get_clients`, buffer APIs), not by looking at a screen.
- **Ephemeral.** The install and config live only for this environment's
  lifetime; nothing is committed. Re-run the skill in a fresh environment.
