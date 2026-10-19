#!/usr/bin/env bash
# Prepares a Codespace (or any dev container) for the workshop. Run once, at creation
# (onCreateCommand, so that Codespaces prebuilds include it). Same steps as the server script.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_VERSION="$(cat "$HERE/claude-version")"
OPT=/opt/workshop

echo "== Claude Code $CLAUDE_VERSION"
if [[ "$(claude --version 2>/dev/null)" != "$CLAUDE_VERSION "* ]]; then
  curl -fsSL https://claude.ai/install.sh | bash -s "$CLAUDE_VERSION"
  sudo install -m 755 "$(readlink -f "$HOME/.local/bin/claude")" /usr/local/bin/claude
fi

echo "== Python environment for the MCP server"
sudo mkdir -p "$OPT" && sudo chown "$(id -u):$(id -g)" "$OPT"
[[ -d "$OPT/venv" ]] || python3 -m venv "$OPT/venv"
"$OPT/venv/bin/pip" install -q --upgrade pip
"$OPT/venv/bin/pip" install -q "mcp[cli]>=2,<3"

echo "== Context gauge (token-weather mod)"
[[ -d "$OPT/claude-code-playground" ]] || \
  git clone -q --depth 1 https://github.com/anthropics/claude-code-playground.git "$OPT/claude-code-playground"

echo "== Commands workshop, replay, workshop-login"
sudo install -m 755 "$HERE/bin/workshop" "$HERE/bin/replay" "$HERE/bin/workshop-login" /usr/local/bin/

# Reminder in every new terminal until the pair has saved its key.
if ! grep -q workshop-login "$HOME/.bashrc" 2>/dev/null; then
  cat >> "$HOME/.bashrc" <<'RC'
[[ -f "$HOME/.workshop-key" ]] || echo "Welcome! First, save the API key of your pair: workshop-login"
RC
fi
echo "== Done"
