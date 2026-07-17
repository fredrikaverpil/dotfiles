---
name: nvim-install
description: Install Neovim (via bob) and stand up the nvim-fredrik config in the Claude Code web sandbox (the cloud environment), where no Neovim exists. Use this before testing any Neovim config change in a web session, e.g. checking out a PR branch that touches nvim-fredrik and observing its runtime behavior. Installs bob with cargo, uses bob to install a stable or nightly Neovim, wires the repo's config into place, launches Neovim headless with a listen socket, and exports $NVIM so the `neovim` RPC skill can drive it. Web-sandbox only; on a real machine Neovim is already managed by bob.
---

# Install Neovim in the web sandbox

This skill bootstraps a real, running Neovim in the Claude Code web sandbox so
config changes (e.g. a PR against `nvim-fredrik`) can be exercised and observed.
It is the missing half of the `neovim` RPC skill: that skill assumes a running
Neovim exposed via `$NVIM`, but the sandbox has neither the binary nor a parent
editor. This skill installs Neovim with **bob** (the same version manager used
on the real machines, so stable/nightly is a one-word switch), launches Neovim
**headless** with a listen socket, and exports `$NVIM` so every command in the
`neovim` skill works verbatim afterwards.

**Scope:** web sandbox only (`CLAUDE_CODE_REMOTE=true`). Do not run on a real
machine — there bob already manages Neovim at
`~/.local/share/bob/nvim-bin/nvim`.

## Step 0 — GitHub access is a hard prerequisite

bob fetches Neovim from **github.com/neovim/neovim** (release list via
`api.github.com`, binaries via the release asset host). In the sandbox, GitHub
traffic is gated by the agent proxy to the **repos in this session's scope** —
by default only this dotfiles repo. bob's calls to `neovim/neovim` are denied
until that repo is in scope, failing with:

> ERROR Error: GitHub access to this repository is not enabled for this
> session. Use add_repo to request access.

**Enable access before continuing.** The simplest path is to bring
`neovim/neovim` into the session scope with `add_repo` (ask Claude: *"add the
neovim/neovim repo"* — Claude only runs `add_repo` when you ask). Alternatively,
widen the environment's network policy / allowed hosts to include
`github.com`, `api.github.com`, `objects.githubusercontent.com`, and
`github-releases.githubusercontent.com`, then rebuild the environment. See
https://code.claude.com/docs/en/claude-code-on-the-web for how network policy
and session scope work.

Preflight — once access is enabled, this lists remote versions instead of
erroring:

```bash
export PATH="$HOME/.cargo/bin:$PATH"
bob list-remote 2>&1 | tail -5    # errors here => GitHub access still not enabled
```

## Step 1 — Install bob (via cargo)

The sandbox ships the Rust toolchain (`cargo`, `rustc`), and cargo can reach
crates.io, so bob builds from source in ~90s. bob itself needs **no** GitHub
access to install — only its later Neovim downloads do (Step 0).

```bash
command -v bob >/dev/null || cargo install bob-nvim
export PATH="$HOME/.cargo/bin:$PATH"
bob --version
```

## Step 2 — Install and select a Neovim version

`nvim-fredrik` requires **nightly** Neovim: it uses `vim.pack.add` and
`vim._core.ui2`, which are not in any stable release. (For other configs, swap
`nightly` for `stable` or a version like `v0.11.0` — that's the whole benefit
of bob.)

```bash
bob use nightly        # installs if missing, then makes it the active version
```

bob places the active binary at `~/.local/share/bob/nvim-bin/nvim`. Add that to
`PATH`:

```bash
export PATH="$HOME/.local/share/bob/nvim-bin:$PATH"
nvim --version | head -1   # expect a v0.12.0-dev... nightly build
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
export PATH="\$HOME/.cargo/bin:\$HOME/.local/share/bob/nvim-bin:\$PATH"
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
clones all plugins via `vim.pack.add` (needs the Step 0 GitHub access) and can
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
almost always mean GitHub access is still not enabled (back to Step 0).

## Step 5 — Verify and hand off to the `neovim` skill

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
result=$(nvim --server "$NVIM" --remote-expr 'luaeval("vim.json.encode(vim.diagnostic.get(0))")') && echo "$result" | grep -v '^Warning: Using NVIM_APPNAME='
```

## Caveats

- **First launch is slow** — plugin cloning is network-bound and serial.
- **Mason / LSP servers and treesitter parsers are best-effort.** They pull
  extra tools from GitHub and compile locally; if a change under test doesn't
  depend on a language server, you don't need them. Failures here are logged in
  `/tmp/nvim-headless.log` and don't prevent the rest of the config loading.
- **Headless has no UI.** Inspect state via RPC (`vim.diagnostic.get`,
  `vim.lsp.get_clients`, buffer APIs), not by looking at a screen.
- **Ephemeral.** bob's install and the config live only for this environment's
  lifetime; nothing is committed. Re-run the skill in a fresh environment.
- **Fallback without bob:** if cargo/bob is unavailable, download a release
  tarball directly (no Rust needed) — the tag selects the channel:
  `curl -fL https://github.com/neovim/neovim/releases/download/nightly/nvim-linux-$(uname -m).tar.gz | tar -xz -C /opt/nvim --strip-components=1`
  (same GitHub-access prerequisite as Step 0).
