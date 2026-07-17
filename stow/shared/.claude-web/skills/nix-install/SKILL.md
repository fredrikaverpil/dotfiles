---
name: nix-install
description: Install Nix in the Claude Code web sandbox (the cloud environment) as a general-purpose package installer, then install packages from the Nix binary cache with no GitHub access. Use whenever a web session needs a tool that isn't preinstalled and isn't in a language registry (npm/pypi/crates/go) — Neovim, ripgrep, a compiler, anything in nixpkgs. Installs nix-bin via apt, configures single-user mode, and installs packages via nix-env against the nixpkgs channel tarball. Web-sandbox only.
---

# Install Nix in the web sandbox

Nix is the most general way to install tools in the Claude Code web sandbox. The
sandbox network is locked to package registries plus this session's GitHub
repos, but two facts make Nix work anyway:

- `apt` reaches the main Ubuntu archive, and **`nix-bin` is in it**.
- `cache.nixos.org` and `channels.nixos.org` are reachable through the proxy, so
  Nix substitutes prebuilt binaries and pulls the nixpkgs expression **without
  any GitHub access**.

**Scope:** web sandbox only (`CLAUDE_CODE_REMOTE=true`). On a real machine Nix
is already the system package manager — do not run this there.

## Step 0 — Verify the network path (usually already open)

```bash
curl -sSI -o /dev/null -w "cache:    %{http_code}\n" https://cache.nixos.org
curl -sSI -o /dev/null -w "channels: %{http_code}\n" https://channels.nixos.org/nixpkgs-unstable/nixexprs.tar.xz
```

`200`/`302` on both → proceed. If either is blocked, the environment's network
policy is stricter than default; widen it (claude.ai environment editor →
network / allowed hosts) to include `cache.nixos.org` and `channels.nixos.org`.

## Step 1 — Install Nix (via apt)

The Claude Code web docs recommend refreshing the apt index first; do that, then
install `nix-bin`:

```bash
apt-get update
apt-get install -y --no-install-recommends nix-bin
# Single-user (rootless-build) mode: the sandbox has no 'nixbld' build-users
# group, so disable multi-user builds or nix-env operations fail.
mkdir -p /etc/nix
grep -q '^build-users-group' /etc/nix/nix.conf 2>/dev/null \
  || echo 'build-users-group =' >> /etc/nix/nix.conf
nix --version
```

## Step 2 — Install packages

Use classic `nix-env` against the channel tarball. **Do not** use flakes / `nix
run nixpkgs#pkg` here: the `nixpkgs` flake reference resolves to
github.com/NixOS/nixpkgs, which the proxy blocks. The channel tarball is served
from the reachable `channels.nixos.org`, so this needs no GitHub:

```bash
TARBALL=https://channels.nixos.org/nixpkgs-unstable/nixexprs.tar.xz
nix-env -iA ripgrep -f "$TARBALL"     # attribute name = nixpkgs attr path
export PATH="$HOME/.nix-profile/bin:$PATH"
rg --version
```

Finding an attribute name quickly — query the single attribute, not all of
nixpkgs (a bare `nix-env -qaP` evaluates everything and is very slow):

```bash
nix-env -f "$TARBALL" -qaP -A ripgrep   # -> "ripgrep  ripgrep-14.x"
```

## Persisting the environment

The sandbox runs each command in a fresh shell initialized from your profile, so
a plain `export PATH=...` does not survive to the next Bash call. Persist it:

```bash
grep -qxF 'export PATH="$HOME/.nix-profile/bin:$PATH"' ~/.bashrc 2>/dev/null \
  || echo 'export PATH="$HOME/.nix-profile/bin:$PATH"' >> ~/.bashrc
```

## Caveats

- **Ephemeral.** The install lives only for this environment's lifetime; nothing
  is committed. Re-run in a fresh environment.
- **`nixpkgs-unstable` is a moving target.** The version you get today may differ
  tomorrow. Pin a specific channel (e.g. a `nixos-XX.YY` tarball URL) if you need
  reproducibility.
- **GitHub-sourced packages still need GitHub.** Anything Nix fetches from
  github.com at build time (flake inputs, `fetchFromGitHub` on a cache miss) is
  subject to the proxy's GitHub scoping. Prebuilt substitutes from
  `cache.nixos.org` avoid this for anything already cached — which is the common
  case for nixpkgs packages.
