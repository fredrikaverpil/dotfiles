---
name: nvim-install
description: Install Neovim and stand up the nvim-fredrik config in the Claude Code web sandbox (the cloud environment), where no Neovim exists. Use this before testing any Neovim config change in a web session, e.g. checking out a PR branch that touches nvim-fredrik and observing its runtime behavior. Downloads the nightly Neovim tarball, wires the repo's config into place, launches Neovim headless with a listen socket, and exports $NVIM so the `neovim` RPC skill can drive it. Web-sandbox only; on a real machine Neovim is managed by Bob.
---

# Install Neovim in the web sandbox

This skill bootstraps a real, running Neovim in the Claude Code web sandbox so
that config changes (e.g. a PR against `nvim-fredrik`) can be exercised and
observed. It is the missing half of the `neovim` RPC skill: that skill assumes
a running Neovim exposed via `$NVIM`, but the sandbox has neither the binary
nor a parent editor. This skill installs the binary, launches Neovim
**headless** with a listen socket, and exports `$NVIM` so every command in the
`neovim` skill works verbatim afterwards.

**Scope:** web sandbox only (`CLAUDE_CODE_REMOTE=true`). Do not run on a real
machine — there Neovim is managed by Bob at `~/.local/share/bob/nvim-bin/nvim`.

## Step 0 — Network policy is a hard prerequisite

The `nvim-fredrik` config bootstraps plugins with `vim.pack.add`, which clones
from **github.com** on first launch. Mason and treesitter fetch from GitHub
too. The sandbox network policy is registry-only by default, so GitHub is
**blocked** until the environment allowlists it.

Check reachability first:

```bash
curl -sSI -o /dev/null -w "%{http_code}\n" https://github.com/neovim/neovim/releases/tag/nightly
```

`200`/`302` → proceed. `403`/`000` → **stop.** The environment must allowlist
these hosts before anything here can work:

- `github.com`
- `objects.githubusercontent.com`
- `raw.githubusercontent.com`
- `github-releases.githubusercontent.com`

Tell the user to add them to the environment's allowed hosts (claude.ai
environment editor → network / allowed hosts) and rebuild the environment, then
re-run this skill. This is an environment-config change; nothing in the repo can
route around it. See
https://code.claude.com/docs/en/claude-code-on-the-web for how network policy
and allowed hosts work.

## Step 1 — Install the Neovim binary (nightly)

`nvim-fredrik` requires **nightly** Neovim: it uses `vim.pack.add` and
`vim._core.ui2`, which are not in any stable release. Use the `.tar.gz`
(no FUSE/AppImage dependency):

```bash
set -e
arch="$(uname -m)"   # x86_64 in the sandbox; arm64 hosts use nvim-linux-arm64
asset="nvim-linux-${arch}.tar.gz"
curl -fL -o "/tmp/${asset}" \
  "https://github.com/neovim/neovim/releases/download/nightly/${asset}"
rm -rf /opt/nvim && mkdir -p /opt/nvim
tar -xzf "/tmp/${asset}" -C /opt/nvim --strip-components=1
export PATH="/opt/nvim/bin:$PATH"
nvim --version | head -1   # expect a v0.12.0-dev... nightly build
```

(This `export` is only for the immediate check — Step 2 persists `PATH` and the
rest so they survive across shells.)

If the asset name 404s, list the release assets and pick the current Linux
tarball name — Neovim has renamed these before (`nvim-linux64.tar.gz` →
`nvim-linux-x86_64.tar.gz`):

```bash
curl -fL https://api.github.com/repos/neovim/neovim/releases/tags/nightly \
  | grep -o '"name": "nvim-linux[^"]*"'
```

## Step 2 — Wire the nvim-fredrik config into place

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
export PATH="/opt/nvim/bin:\$PATH"
export DOTFILES="$repo"
export NVIM_APPNAME=nvim-fredrik
export NVIM=/tmp/nvim-fredrik.sock
EOF
grep -qxF 'source ~/.nvim-sandbox.env' ~/.bashrc 2>/dev/null \
  || echo 'source ~/.nvim-sandbox.env' >> ~/.bashrc
source ~/.nvim-sandbox.env
```

## Step 3 — Launch Neovim headless with a listen socket

This is the bridge to the `neovim` skill. Start a backgrounded headless
instance listening on `$NVIM` (persisted in Step 2), so the RPC skill's
commands — which all key off `$NVIM` — work unchanged. The **first** launch
clones all plugins via `vim.pack.add` (needs the Step 0 network access) and can
take a few minutes.

```bash
rm -f "$NVIM"
# --headless keeps it alive as long as the socket is served; run detached.
nohup nvim --headless --listen "$NVIM" >/tmp/nvim-headless.log 2>&1 &
# Wait for the socket to accept RPC (plugin cloning happens during startup).
for i in $(seq 1 120); do
  [ -S "$NVIM" ] && nvim --server "$NVIM" --remote-expr '1' >/dev/null 2>&1 && break
  sleep 2
done
echo "NVIM socket: $NVIM"; tail -5 /tmp/nvim-headless.log
```

If the loop times out, read `/tmp/nvim-headless.log` — plugin clone failures
almost always mean a GitHub host is still not allowlisted (back to Step 0).

## Step 4 — Verify and hand off to the `neovim` skill

Because `NVIM_APPNAME` is set, every `nvim --server` command prints a
`Warning: Using NVIM_APPNAME=...` line on **stdout** that corrupts parsed
output. Filter it exactly as the `neovim` skill documents:

```bash
result=$(nvim --server "$NVIM" --remote-expr 'v:version') && echo "$result" | grep -v '^Warning: Using NVIM_APPNAME='
result=$(nvim --server "$NVIM" --remote-expr 'luaeval("vim.fn.stdpath(\"config\")")') && echo "$result" | grep -v '^Warning: Using NVIM_APPNAME='
```

From here, `$NVIM` is set exactly as if Claude Code were running inside a
Neovim terminal, so **switch to the `neovim` skill** for all further
interaction (buffer state, running Lua, inspecting diagnostics, LSP, plugins) —
including its `grep -v` filtering pattern.

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

Now drive the behavior under test via the `neovim` skill. For example, to
exercise a neotest/diagnostics change: open a test file, run the relevant
command, then read the diagnostics namespace:

```bash
nvim --server "$NVIM" --remote-expr 'luaeval("vim.json.encode(vim.diagnostic.get(0))")'
```

## Caveats

- **First launch is slow** — plugin cloning is network-bound and serial.
- **Mason / LSP servers and treesitter parsers are best-effort.** They pull
  extra tools from GitHub and compile locally; if a change under test doesn't
  depend on a language server, you don't need them. Failures here are logged in
  `/tmp/nvim-headless.log` and don't prevent the rest of the config loading.
- **Headless has no UI.** Inspect state via RPC (`vim.diagnostic.get`,
  `vim.lsp.get_clients`, buffer APIs), not by looking at a screen.
- **Ephemeral.** The install lives only for this environment's lifetime; nothing
  is committed. Re-run the skill in a fresh environment.
