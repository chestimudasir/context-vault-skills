#!/usr/bin/env bash
# Install the context-vault skills into Claude Code.
#
# What it does:
#   1. Symlinks skills/<name> into ~/.claude/skills/<name> (obs-save, obs-load, harpoon, detective)
#   2. Writes AGENT_CONTEXT_VAULT into the "env" block of ~/.claude/settings.json
#
# Usage:
#   ./install.sh [/absolute/path/to/vault] [--replace] [--skills-only] [--env-only]
#
#   --replace      If ~/.claude/skills/<name> is a real directory (not a symlink),
#                  move it to ~/.claude/skills-backup-<timestamp>/<name> and link the repo version.
#   --skills-only  Only create the symlinks. Do not touch settings.json.
#   --env-only     Only write the env var. Do not create symlinks.
#
# The vault path comes from, in order: the first argument, $AGENT_CONTEXT_VAULT, or a prompt.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
SKILLS_DIR="$CLAUDE_DIR/skills"
SETTINGS="$CLAUDE_DIR/settings.json"
SKILLS=(obs-save obs-load harpoon detective)

REPLACE=0; DO_SKILLS=1; DO_ENV=1; VAULT=""
for arg in "$@"; do
  case "$arg" in
    --replace)     REPLACE=1 ;;
    --skills-only) DO_ENV=0 ;;
    --env-only)    DO_SKILLS=0 ;;
    -h|--help)     sed -n '2,17p' "$0"; exit 0 ;;
    *)             VAULT="$arg" ;;
  esac
done

# ---------- 1. Symlink skills ----------
if [ "$DO_SKILLS" = 1 ]; then
  mkdir -p "$SKILLS_DIR"
  for s in "${SKILLS[@]}"; do
    src="$REPO_DIR/skills/$s"
    dst="$SKILLS_DIR/$s"
    if [ -L "$dst" ]; then
      rm "$dst"
    elif [ -e "$dst" ]; then
      if [ "$REPLACE" = 1 ]; then
        backup="$CLAUDE_DIR/skills-backup-$(date +%Y%m%d-%H%M%S)"
        mkdir -p "$backup"
        mv "$dst" "$backup/$s"
        echo "moved existing $dst -> $backup/$s"
      else
        echo "skip: $dst exists and is not a symlink (rerun with --replace to back it up and replace it)"
        continue
      fi
    fi
    ln -s "$src" "$dst"
    echo "linked $dst -> $src"
  done
fi

# ---------- 2. Write AGENT_CONTEXT_VAULT ----------
if [ "$DO_ENV" = 1 ]; then
  if [ -z "$VAULT" ]; then
    VAULT="${AGENT_CONTEXT_VAULT:-}"
  fi
  if [ -z "$VAULT" ]; then
    read -r -p "Absolute path to your Obsidian vault: " VAULT
  fi
  VAULT="${VAULT%/}"
  case "$VAULT" in
    /*) ;;
    *) echo "error: vault path must be absolute: $VAULT" >&2; exit 1 ;;
  esac
  if [ ! -d "$VAULT" ]; then
    echo "error: vault directory does not exist: $VAULT" >&2
    exit 1
  fi

  mkdir -p "$CLAUDE_DIR"
  [ -f "$SETTINGS" ] || echo '{}' > "$SETTINGS"

  if command -v jq >/dev/null 2>&1; then
    tmp="$(mktemp)"
    jq --arg v "$VAULT" '.env = ((.env // {}) + {AGENT_CONTEXT_VAULT: $v})' "$SETTINGS" > "$tmp"
    mv "$tmp" "$SETTINGS"
    echo "wrote AGENT_CONTEXT_VAULT=$VAULT to $SETTINGS (jq)"
  elif command -v python3 >/dev/null 2>&1; then
    VAULT="$VAULT" SETTINGS="$SETTINGS" python3 - <<'PY'
import json, os
path = os.environ["SETTINGS"]
with open(path) as f:
    data = json.load(f)
data.setdefault("env", {})["AGENT_CONTEXT_VAULT"] = os.environ["VAULT"]
with open(path, "w") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
PY
    echo "wrote AGENT_CONTEXT_VAULT=$VAULT to $SETTINGS (python3)"
  else
    cat <<MSG
Neither jq nor python3 is available. Add this to $SETTINGS by hand:

  "env": {
    "AGENT_CONTEXT_VAULT": "$VAULT"
  }
MSG
  fi
fi

echo
echo "Done. Start a new Claude Code session, then try: /obs-load"
