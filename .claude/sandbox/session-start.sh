#!/usr/bin/env bash
# shellcheck shell=bash
set -e

# User-scope SessionStart hook, registered by bootstrap.sh. The environment
# snapshot that carries the bootstrap output can be up to ~7 days old, so
# refresh the dotfiles clone and re-run the bootstrap each session start.
# The pull is best-effort: it only applies to the setup-script clone of the
# default branch — a side-by-side session clone sits on a session branch
# where --ff-only is a no-op.
DOTFILES_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
git -C "$DOTFILES_ROOT" pull --ff-only --quiet 2>/dev/null || true
SANDBOX_BOOTSTRAP=1 "$DOTFILES_ROOT/.claude/sandbox/bootstrap.sh" >/dev/null
