#!/usr/bin/env bash
set -euo pipefail

curl -fsSL https://omp.sh/install | sh
if [ -f "$HOME/.local/bin/omp" ]; then
  sudo install -m 0755 "$HOME/.local/bin/omp" /usr/local/bin/omp
fi
# Alternative via npm/bun:
# sudo npm install -g @oh-my-pi/pi-coding-agent
