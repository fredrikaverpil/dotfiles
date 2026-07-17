#!/usr/bin/env bash
# shellcheck shell=bash
set -e

# In the Claude Code cloud sandbox, commits would otherwise be authored as
# Claude and signed with Claude's key. Override with my identity and disable
# signing (no private key exists in the sandbox). On a developer machine the
# stowed ~/.gitconfig already handles identity and signing, so do nothing.
if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

cd "${CLAUDE_PROJECT_DIR:?}"
git config user.name "Fredrik Averpil"
git config user.email "fredrik.averpil@proton.me"
git config commit.gpgsign false
