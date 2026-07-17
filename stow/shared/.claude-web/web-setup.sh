#!/usr/bin/env bash
# shellcheck shell=bash
set -e

# Setup script for Claude Code on the web (the cloud sandbox).
#
# This is NOT run automatically by being in the repo. Register it in the cloud
# environment's "Setup script" field (web UI: environment selector -> edit
# environment -> Setup script) with a one-line bootstrap that calls this file:
#
#   bash /home/user/dotfiles/stow/shared/.claude-web/web-setup.sh || true
#
# The environment clones the repo before the setup script runs, so that path
# exists. Setup scripts run as root, once per environment build (result is
# cached; skipped on later/resumed sessions until the script or allowed hosts
# change, or the cache expires), before Claude Code launches. Scope is
# cloud-only, but guard anyway so a stray local invocation is a no-op.
if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

# Project-level Claude config for the dotfiles repo.
#
# The real content lives here in stow/shared/.claude-web (settings + a curated
# subset of skill symlinks into stow/shared/.claude/skills). Claude Code on the
# web reads <repo>/.claude, so link this package into place at the repo root.
# The link is recreated on every run so it always tracks the current target; it
# is git-ignored, so it never exists on local (non-web) checkouts.
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
if [ -d "$repo_root/stow/shared/.claude-web" ]; then
  rm -rf "$repo_root/.claude"
  ln -s stow/shared/.claude-web "$repo_root/.claude"
fi

# Git identity.
#
# The launcher re-asserts `git config --global user.{name,email}=Claude` on
# every session start so its SSH-signed commits verify on GitHub, so global is
# not ours to own. Write LOCAL identity to each cloned repo instead: local
# always overrides global, and the launcher never touches local config. This
# also means commits are attributed to me but show as "Unverified" on GitHub
# (no personal signing key exists in the sandbox), which is the intended
# trade-off.
git_name="Fredrik Averpil"
git_email="fredrik.averpil@proton.me"
for gitdir in /home/user/*/.git; do
  [ -d "$gitdir" ] || continue
  repo="${gitdir%/.git}"
  git -C "$repo" config user.name "$git_name"
  git -C "$repo" config user.email "$git_email"
  git -C "$repo" config commit.gpgsign false
done
