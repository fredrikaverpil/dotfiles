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
# Invocation: the user-scope PreToolUse hook registered by bootstrap.sh
# runs this before every Bash call — the sandbox's own SessionStart hook
# re-asserts the Claude identity on every session start, so per-call
# re-assertion is what makes this stick. bootstrap.sh also runs it once
# directly, and the git-commit skill verifies the result before committing.
# Use global config: the sandbox may hold multiple repos, and this covers
# all of them, including ones added mid-session. On a developer machine the
# stowed ~/.gitconfig already handles identity and signing, so do nothing.
# Same defense-in-depth as bootstrap.sh: CLAUDE_CODE_REMOTE alone could in
# principle leak into a local session's environment, and this script rewrites
# global git config — so also require a cloud-container marker (or the
# explicit SANDBOX_BOOTSTRAP override used during the setup-script phase).
if [ "${SANDBOX_BOOTSTRAP:-}" != "1" ]; then
  if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
    exit 0
  fi
  if [ -z "${CLAUDE_CODE_CONTAINER_ID:-}" ] && [ -z "${CLAUDE_CODE_REMOTE_ENVIRONMENT_TYPE:-}" ]; then
    exit 0
  fi
fi

git config --global user.name "Fredrik Averpil"
git config --global user.email "fredrik.averpil@proton.me"
git config --global commit.gpgsign false
