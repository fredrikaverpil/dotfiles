#!/usr/bin/env bash
# shellcheck shell=bash
set -e

# In the Claude Code cloud sandbox, commits would otherwise be authored as
# Claude and signed with Claude's key. Override with my identity and disable
# signing: the sandbox's SSH signing key is registered to
# noreply@anthropic.com, so a signed commit with any other committer email
# shows as "Unverified" on GitHub — unsigned is intentional. Disabling
# commit.gpgsign also skips the sandbox Stop hook's identity check, which
# would otherwise instruct the agent to reset the identity back to Claude.
#
# Invocation: the git-commit skill runs this before every commit. That is
# the primary path — the SessionStart hook in .claude/settings.json only
# fires when this repo is the session root (single-repo session); in
# multi-repo sessions repo-level settings.json is never loaded. Even when it
# does fire, the sandbox's own SessionStart hook re-asserts the Claude
# identity on every session start, so per-commit re-assertion is what makes
# this stick. Use global config: the sandbox may hold multiple repos, and
# this covers all of them, including ones added mid-session. On a developer
# machine the stowed ~/.gitconfig already handles identity and signing, so
# do nothing.
if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

git config --global user.name "Fredrik Averpil"
git config --global user.email "fredrik.averpil@proton.me"
git config --global commit.gpgsign false
