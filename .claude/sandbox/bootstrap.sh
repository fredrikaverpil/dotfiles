#!/usr/bin/env bash
# shellcheck shell=bash
set -e

# Bootstrap Claude cloud sandbox customizations into user scope
# ($HOME/.claude): git identity, hooks, attribution settings, skills, and a
# sandbox-only CLAUDE.md. User scope loads in every sandbox session
# regardless of which repos the session contains — unlike repo-level
# .claude/settings.json, which only loads when the repo is the session root
# (never the case when dotfiles is cloned side-by-side with a work repo).
#
# Invocation paths:
#   1. Environment setup script (configured once on claude.ai, runs before
#      Claude Code launches; the filesystem snapshot then carries the
#      user-scope config into every future session in that environment):
#        git clone --depth=1 https://github.com/fredrikaverpil/dotfiles /root/dotfiles \
#          && SANDBOX_BOOTSTRAP=1 /root/dotfiles/.claude/sandbox/bootstrap.sh
#   2. The SessionStart hook registered below (refreshes config each session).
#   3. The agent, instructed by CLAUDE.md, when neither of the above has run.
#
# User scope on a developer machine is managed by stow, so refuse to run
# outside the sandbox.
if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ] && [ "${SANDBOX_BOOTSTRAP:-}" != "1" ]; then
  echo "Refusing to run outside the Claude cloud sandbox (set SANDBOX_BOOTSTRAP=1 to override)." >&2
  exit 1
fi

DOTFILES_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
CLAUDE_DIR="$HOME/.claude"
mkdir -p "$CLAUDE_DIR/skills"

# Git identity + signing off. The script guards on CLAUDE_CODE_REMOTE, which
# is not set in the setup-script phase, so assert it explicitly.
CLAUDE_CODE_REMOTE=true "$DOTFILES_ROOT/.claude/hooks/sandbox-git-identity.sh"

# User-scope settings. The PreToolUse hook re-asserts the git identity before
# every Bash call: the sandbox's own SessionStart hook re-writes the Claude
# identity on every session start, so a one-time assertion cannot stick —
# per-tool-call assertion makes hook ordering irrelevant. Merge on top of any
# existing user settings rather than clobbering them.
settings=$(cat <<EOF
{
  "attribution": {
    "commit": "",
    "pr": "",
    "sessionUrl": false
  },
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "$DOTFILES_ROOT/.claude/sandbox/session-start.sh"
          }
        ]
      }
    ],
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "CLAUDE_CODE_REMOTE=true $DOTFILES_ROOT/.claude/hooks/sandbox-git-identity.sh"
          }
        ]
      }
    ]
  }
}
EOF
)
if [ -f "$CLAUDE_DIR/settings.json" ]; then
  merged=$(jq -s '.[0] * .[1]' "$CLAUDE_DIR/settings.json" <(printf '%s' "$settings"))
  printf '%s\n' "$merged" >"$CLAUDE_DIR/settings.json"
else
  printf '%s\n' "$settings" >"$CLAUDE_DIR/settings.json"
fi

# Skills: symlink each dotfiles skill into user scope so they load even in
# sessions that don't include the dotfiles repo. Symlink per-skill rather
# than replacing the whole directory — the sandbox ships its own skills there.
for skill in "$DOTFILES_ROOT"/.claude/skills/*/; do
  ln -sfn "${skill%/}" "$CLAUDE_DIR/skills/$(basename "$skill")"
done

# Sandbox-only user memory: exists only in the sandbox, never on developer
# machines, so instructions here are inherently sandbox-scoped.
cp "$DOTFILES_ROOT/.claude/sandbox/CLAUDE.sandbox.md" "$CLAUDE_DIR/CLAUDE.md"

echo "Sandbox bootstrap complete (dotfiles: $DOTFILES_ROOT)."
