#!/usr/bin/env bash
# shellcheck shell=bash
set -e

# In the Claude Code cloud sandbox, commits would otherwise be authored as
# Claude and signed with Claude's key. Override with my identity and disable
# signing (no private key exists in the sandbox). Use global config: the
# sandbox is ephemeral and may hold multiple repos (CLAUDE_PROJECT_DIR is
# unset in multi-repo sessions), so this covers every repo in the session,
# including ones added mid-session. Because CLAUDE_PROJECT_DIR is unset in
# those sessions, settings.json invokes this script with a fallback path of
# /home/user/dotfiles — the fixed clone location in the cloud sandbox. On a
# developer machine the stowed ~/.gitconfig already handles identity and
# signing, so do nothing.
if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

git config --global user.name "Fredrik Averpil"
git config --global user.email "fredrik.averpil@proton.me"
git config --global commit.gpgsign false
